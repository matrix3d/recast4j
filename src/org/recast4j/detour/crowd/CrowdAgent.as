/*
Copyright (c) 2009-2010 Mikko Mononen memon@inside.org
Recast4J Copyright (c) 2015 Piotr Piastucki piotr@jtilia.org

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.
Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented; you must not
 claim that you wrote the original software. If you use this software
 in a product, an acknowledgment in the product documentation would be
 appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
 misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
*/
package org.recast4j.detour.crowd {
import static org.recast4j.detour.DetourCommon.vAdd;
import static org.recast4j.detour.DetourCommon.vCopy;
import static org.recast4j.detour.DetourCommon.vDist2D;
import static org.recast4j.detour.DetourCommon.vDist2DSqr;
import static org.recast4j.detour.DetourCommon.vLen;
import static org.recast4j.detour.DetourCommon.vMad;
import static org.recast4j.detour.DetourCommon.vNormalize;
import static org.recast4j.detour.DetourCommon.vScale;
import static org.recast4j.detour.DetourCommon.vSet;
import static org.recast4j.detour.DetourCommon.vSub;

import org.recast4j.detour.NavMeshQuery;
import org.recast4j.detour.VectorPtr;
import org.recast4j.detour.crowd.Crowd.CrowdNeighbour;
import org.recast4j.detour.crowd.Crowd.MoveRequestState;

/// Represents an agent managed by a #dtCrowd object.
/// @ingroup crowd

internal class CrowdAgent {

	/// The type of navigation mesh polygon the agent is currently traversing.
	/// @ingroup crowd
	public enum CrowdAgentState
	{
		DT_CROWDAGENT_STATE_INVALID,		///< The agent is not in a valid state.
		DT_CROWDAGENT_STATE_WALKING,		///< The agent is traversing a normal navigation mesh polygon.
		DT_CROWDAGENT_STATE_OFFMESH,		///< The agent is traversing an off-mesh connection.
	};
	
	/// True if the agent is active, false if the agent is in an unused slot in the agent pool.
	var active:Boolean;

	/// The type of mesh polygon the agent is traversing. (See: #CrowdAgentState)
	var state:CrowdAgentState;

	/// True if the agent has valid path (targetState == DT_CROWDAGENT_TARGET_VALID) and the path does not lead to the requested position, else false.
	var partial:Boolean;

	/// The path corridor the agent is using.
	var corridor:PathCorridor;

	/// The local boundary data for the agent.
	var boundary:LocalBoundary;

	/// Time since the agent's path corridor was optimized.
	var topologyOptTime:Number;

	/// The known neighbors of the agent.
	var neis:Array= new CrowdNeighbour[Crowd.DT_CROWDAGENT_MAX_NEIGHBOURS];

	/// The number of neighbors.
	var nneis:int;

	/// The desired speed.
	var desiredSpeed:Number;

	var npos:Array= new float[3]; ///< The current agent position. [(x, y, z)]
	var disp:Array= new float[3];
	var dvel:Array= new float[3]; ///< The desired velocity of the agent. [(x, y, z)]
	var nvel:Array= new float[3];
	var vel:Array= new float[3]; ///< The actual velocity of the agent. [(x, y, z)]

	/// The agent's configuration parameters.
	var params:CrowdAgentParams;

	/// The local path corridor corners for the agent. (Staight path.) [(x, y, z) * #ncorners]
	var cornerVerts:Array= new float[Crowd.DT_CROWDAGENT_MAX_CORNERS * 3];

	/// The local path corridor corner flags. (See: #dtStraightPathFlags) [(flags) * #ncorners]
	var cornerFlags:Array= []//Crowd.DT_CROWDAGENT_MAX_CORNERS];

	/// The reference id of the polygon being entered at the corner. [(polyRef) * #ncorners]
	var cornerPolys:Array= new long[Crowd.DT_CROWDAGENT_MAX_CORNERS];

	/// The number of corners.
	var ncorners:int;

	var targetState:MoveRequestState; ///< State of the movement request.
	var targetRef:Number; ///< Target polyref of the movement request.
	var targetPos:Array= new float[3]; ///< Target position of the movement request (or velocity in case of DT_CROWDAGENT_TARGET_VELOCITY).
	var targetPathqRef:Number; ///< Path finder ref.
	var targetReplan:Boolean; ///< Flag indicating that the current path is being replanned.
	var targetReplanTime:Number; /// <Time since the agent's target was replanned.

	public function CrowdAgent() {
		corridor = new PathCorridor();
		boundary = new LocalBoundary();
	}
	
	function integrate(dt:Number):void {
		// Fake dynamic constraint.
		var maxDelta:Number= params.maxAcceleration * dt;
		var dv:Array= vSub(nvel, vel);
		var ds:Number= vLen(dv);
		if (ds > maxDelta)
			dv = vScale(dv, maxDelta / ds);
		vel = vAdd(vel, dv);

		// Integrate
		if (vLen(vel) > 0.0001)
			npos = vMad(npos, vel, dt);
		else
			vSet(vel, 0, 0, 0);
	}

	function overOffmeshConnection(radius:Number):Boolean {
		if (ncorners == 0)
			return false;

		var offMeshConnection:Boolean= ((cornerFlags[ncorners - 1] & NavMeshQuery.DT_STRAIGHTPATH_OFFMESH_CONNECTION) != 0)
				? true : false;
		if (offMeshConnection) {
			var distSq:Number= vDist2DSqr(new VectorPtr(npos), new VectorPtr(cornerVerts, (ncorners - 1) * 3));
			if (distSq < radius * radius)
				return true;
		}

		return false;
	}

	function getDistanceToGoal(range:Number):Number {
		if (ncorners == 0)
			return range;

		var endOfPath:Boolean= ((cornerFlags[ncorners - 1] & NavMeshQuery.DT_STRAIGHTPATH_END) != 0) ? true : false;
		if (endOfPath)
			return Math.min(vDist2D(new VectorPtr(npos), new VectorPtr(cornerVerts, (ncorners - 1) * 3)), range);

		return range;
	}

	public float[] calcSmoothSteerDirection() {
		var dir:Array= new float[3];
		if (ncorners != 0) {

			var ip0:int= 0;
			var ip1:int= Math.min(1, ncorners - 1);
			var p0:VectorPtr= new VectorPtr(cornerVerts, ip0 * 3);
			var p1:VectorPtr= new VectorPtr(cornerVerts, ip1 * 3);
			var vnpos:VectorPtr= new VectorPtr(npos);

			var dir0:Array= vSub(p0, vnpos);
			var dir1:Array= vSub(p1, vnpos);
			dir0[1] = 0;
			dir1[1] = 0;

			var len0:Number= vLen(dir0);
			var len1:Number= vLen(dir1);
			if (len1 > 0.001)
				dir1 = vScale(dir1, 1.0/ len1);

			dir[0] = dir0[0] - dir1[0] * len0 * 0.5;
			dir[1] = 0;
			dir[2] = dir0[2] - dir1[2] * len0 * 0.5;

			vNormalize(dir);
		}
		return dir;
	}

	public float[] calcStraightSteerDirection() {
		var dir:Array= new float[3];
		if (ncorners != 0) {
			dir = vSub(cornerVerts, npos);
			dir[1] = 0;
			vNormalize(dir);
		}
		return dir;
	}

	
	function setTarget(ref:Number, pos:Array):void {
		targetRef = ref;
		vCopy(targetPos, pos);
		targetPathqRef = PathQueue.DT_PATHQ_INVALID;
		if (targetRef != 0)
			targetState = MoveRequestState.DT_CROWDAGENT_TARGET_REQUESTING;
		else
			targetState = MoveRequestState.DT_CROWDAGENT_TARGET_FAILED;
	}

}
}
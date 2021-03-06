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
import static org.recast4j.detour.DetourCommon.vCopy;

import java.util.ArrayList;

import org.recast4j.detour.FindPathResult;
import org.recast4j.detour.NavMesh;
import org.recast4j.detour.NavMeshQuery;
import org.recast4j.detour.QueryFilter;
import org.recast4j.detour.Status;
import org.recast4j.detour.UpdateSlicedPathResult;

public class PathQueue {

	private static const MAX_QUEUE:int= 8;
	static const DT_PATHQ_INVALID:int= 0;
	private static const MAX_KEEP_ALIVE:int= 2; // in update ticks.

	var m_queue:Array= new PathQuery[MAX_QUEUE];
	var m_nextHandle:Number= 1;
	var m_queueHead:int;
	var m_navquery:NavMeshQuery;

	protected function PathQueue() {
		for (var i:int= 0; i < MAX_QUEUE; ++i) {
			m_queue[i] = new PathQuery();
		}
	}

	protected function purge():void {
		m_navquery = null;
		for (var i:int= 0; i < MAX_QUEUE; ++i) {
			m_queue[i].path = null;
		}
	}

	protected function init(maxSearchNodeCount:int, nav:NavMesh):void {
		purge();
		m_navquery = new NavMeshQuery(nav);
		for (var i:int= 0; i < MAX_QUEUE; ++i) {
			m_queue[i].ref = DT_PATHQ_INVALID;
			m_queue[i].path = new ArrayList<Long>(256);
		}
		m_queueHead = 0;
	}

	protected function update(maxIters:int):void {
		// Update path request until there is nothing to update
		// or upto maxIters pathfinder iterations has been consumed.
		var iterCount:int= maxIters;

		for (var i:int= 0; i < MAX_QUEUE; ++i) {
			var q:PathQuery= m_queue[m_queueHead % MAX_QUEUE];

			// Skip inactive requests.
			if (q.ref == DT_PATHQ_INVALID) {
				m_queueHead++;
				continue;
			}

			// Handle completed request.
			if (q.status != null && (q.status.isSuccess() || q.status.isFailed())) {
				// If the path result has not been read in few frames, free the slot.
				q.keepAlive++;
				if (q.keepAlive > MAX_KEEP_ALIVE) {
					q.ref = DT_PATHQ_INVALID;
					q.status = null;
				}

				m_queueHead++;
				continue;
			}

			// Handle query start.
			if (q.status == null) {
				q.status = m_navquery.initSlicedFindPath(q.startRef, q.endRef, q.startPos, q.endPos, q.filter, 0);
			}
			// Handle query in progress.
			if (q.status.isInProgress()) {
				var iters:int= 0;
				var res:UpdateSlicedPathResult= m_navquery.updateSlicedFindPath(iterCount);
				iters = res.getIterations();
				q.status = res.getStatus();
				iterCount -= iters;
			}
			if (q.status.isSuccess()) {
				var path:FindPathResult= m_navquery.finalizeSlicedFindPath();
				q.status = path.getStatus();
				q.path = path.getRefs();
			}

			if (iterCount <= 0)
				break;

			m_queueHead++;
		}

	}

	protected function request(startRef:Number, endRef:Number, startPos:Array, endPos:Array, filter:QueryFilter):Number {
		// Find empty slot
		var slot:int= -1;
		for (var i:int= 0; i < MAX_QUEUE; ++i) {
			if (m_queue[i].ref == DT_PATHQ_INVALID) {
				slot = i;
				break;
			}
		}
		// Could not find slot.
		if (slot == -1)
			return DT_PATHQ_INVALID;

		var ref:Number= m_nextHandle++;
		if (m_nextHandle == DT_PATHQ_INVALID)
			m_nextHandle++;

		var q:PathQuery= m_queue[slot];
		q.ref = ref;
		vCopy(q.startPos, startPos);
		q.startRef = startRef;
		vCopy(q.endPos, endPos);
		q.endRef = endRef;
		q.status = null;
		q.filter = filter;
		q.keepAlive = 0;
		return ref;

	}

	function getRequestStatus(ref:Number):Status {
		for (var i:int= 0; i < MAX_QUEUE; ++i) {
			if (m_queue[i].ref == ref)
				return m_queue[i].status;
		}
		return Status.FAILURE;

	}

	function getPathResult(ref:Number):FindPathResult {
		for (var i:int= 0; i < MAX_QUEUE; ++i) {
			if (m_queue[i].ref == ref) {
				var q:PathQuery= m_queue[i];
				// Free request for reuse.
				q.ref = DT_PATHQ_INVALID;
				q.status = null;
				return new FindPathResult(Status.SUCCSESS, q.path);
			}
		}
		return new FindPathResult(Status.FAILURE, null);
	}
}
}
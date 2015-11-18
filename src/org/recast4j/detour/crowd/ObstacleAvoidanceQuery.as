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
import org.recast4j.detour.Tupple3;
import static org.recast4j.detour.DetourCommon.*;

import org.recast4j.detour.Tupple2;

public class ObstacleAvoidanceQuery {

	private static const DT_MAX_PATTERN_DIVS:int= 32;	///< Max numver of adaptive divs.
	private static const DT_MAX_PATTERN_RINGS:int= 4;	///< Max number of adaptive rings.

	
	static 
internal class ObstacleCircle {
		/** Position of the obstacle */
		var p:Array= new float[3];
		/** Velocity of the obstacle */
		var vel:Array= new float[3];
		/** Velocity of the obstacle */
		var dvel:Array= new float[3];
		/** Radius of the obstacle */
		var rad:Number;
		/** Use for side selection during sampling. */
		var dp:Array= new float[3];
		/** Use for side selection during sampling. */
		var np:Array= new float[3];
	}

	static 
internal class ObstacleSegment {
		/** End points of the obstacle segment */
		var p:Array= new float[3];
		/** End points of the obstacle segment */
		var q:Array= new float[3];
		var touch:Boolean;
	}
	
	static 
internal class ObstacleAvoidanceDebugData {
		var m_nsamples:int;
		var m_maxSamples:int;
		var m_vel:Array;
		var m_ssize:Array;
		var m_pen:Array;
		var m_vpen:Array;
		var m_vcpen:Array;
		var m_spen:Array;
		var m_tpen:Array;


		function init(maxSamples:int):void {
			m_maxSamples = maxSamples;
			m_vel = new float[3* m_maxSamples];
			m_pen = new float[m_maxSamples];
			m_ssize = new float[m_maxSamples];
			m_vpen = new float[m_maxSamples];
			m_vcpen = new float[m_maxSamples];
			m_spen = new float[m_maxSamples];
			m_tpen = new float[m_maxSamples];
		}

		function reset():void {
			m_nsamples = 0;
		}

		function normalizeArray(arr:Array, n:int):void {
			// Normalize penaly range.
			var minPen:Number= Float.MAX_VALUE;
			var maxPen:Number= -Float.MAX_VALUE;
			for (var i:int= 0; i < n; ++i) {
				minPen = Math.min(minPen, arr[i]);
				maxPen = Math.max(maxPen, arr[i]);
			}
			var penRange:Number= maxPen - minPen;
			var s:Number= penRange > 0.001? (1.0/ penRange) : 1;
			for (var i:int= 0; i < n; ++i)
				arr[i] = clamp((arr[i] - minPen) * s, 0.0, 1.0);
		}

		function normalizeSamples():void {
			normalizeArray(m_pen, m_nsamples);
			normalizeArray(m_vpen, m_nsamples);
			normalizeArray(m_vcpen, m_nsamples);
			normalizeArray(m_spen, m_nsamples);
			normalizeArray(m_tpen, m_nsamples);
		}

		function addSample(vel:Array, ssize:Number, pen:Number, vpen:Number, vcpen:Number, spen:Number, tpen:Number):void {
			if (m_nsamples >= m_maxSamples)
				return;
			m_vel[m_nsamples * 3] = vel[0];
			m_vel[m_nsamples * 3+ 1] = vel[1];
			m_vel[m_nsamples * 3+ 2] = vel[2];
			m_ssize[m_nsamples] = ssize;
			m_pen[m_nsamples] = pen;
			m_vpen[m_nsamples] = vpen;
			m_vcpen[m_nsamples] = vcpen;
			m_spen[m_nsamples] = spen;
			m_tpen[m_nsamples] = tpen;
			m_nsamples++;
		}

		public function getSampleCount():int {
			return m_nsamples;
		}

		public float[] getSampleVelocity(var i:int) {
			var vel:Array= new float[3];
			vel[0] = m_vel[i * 3];
			vel[1] = m_vel[i * 3+ 1];
			vel[2] = m_vel[i * 3+ 2];
			return vel;
		}

		public function getSampleSize(i:int):Number {
			return m_ssize[i];
		}

		public function getSamplePenalty(i:int):Number {
			return m_pen[i];
		}

		public function getSampleDesiredVelocityPenalty(i:int):Number {
			return m_vpen[i];
		}

		public function getSampleCurrentVelocityPenalty(i:int):Number {
			return m_vcpen[i];
		}

		public function getSamplePreferredSidePenalty(i:int):Number {
			return m_spen[i];
		}

		public function getSampleCollisionTimePenalty(i:int):Number {
			return m_tpen[i];
		}
	}

	static 
internal class ObstacleAvoidanceParams {
		var velBias:Number;
		var weightDesVel:Number;
		var weightCurVel:Number;
		var weightSide:Number;
		var weightToi:Number;
		var horizTime:Number;
		var gridSize:int; ///< grid
		var adaptiveDivs:int; ///< adaptive
		var adaptiveRings:int; ///< adaptive
		var adaptiveDepth:int; ///< adaptive
	};
	

	private var m_params:ObstacleAvoidanceParams;
	private var m_invHorizTime:Number;
	private var m_vmax:Number;
	private var m_invVmax:Number;

	private var m_maxCircles:int;
	private var m_circles:Array;
	private var m_ncircles:int;

	private var m_maxSegments:int;
	private var m_segments:Array;
	private var m_nsegments:int;

	public function init(maxCircles:int, maxSegments:int):void {
		m_maxCircles = maxCircles;
		m_ncircles = 0;
		m_circles = new ObstacleCircle[m_maxCircles];
		for (var i:int= 0; i < m_maxCircles; i++) {
			m_circles[i] = new ObstacleCircle();
		}
		m_maxSegments = maxSegments;
		m_nsegments = 0;
		m_segments = new ObstacleSegment[m_maxSegments];
		for (var i:int= 0; i < m_maxSegments; i++) {
			m_segments[i] = new ObstacleSegment();
		}
	}

	public function reset():void {
		m_ncircles = 0;
		m_nsegments = 0;
	}

	public function addCircle(pos:Array, rad:Number, vel:Array, dvel:Array):void {
		if (m_ncircles >= m_maxCircles)
			return;

		var cir:ObstacleCircle= m_circles[m_ncircles++];
		vCopy(cir.p, pos);
		cir.rad = rad;
		vCopy(cir.vel, vel);
		vCopy(cir.dvel, dvel);
	}

	public function addSegment(p:Array, q:Array):void {
		if (m_nsegments >= m_maxSegments)
			return;
		var seg:ObstacleSegment= m_segments[m_nsegments++];
		vCopy(seg.p, p);
		vCopy(seg.q, q);
	}


	
	public function getObstacleCircleCount():int {
		return m_ncircles;
	}

	public function getObstacleCircle(i:int):ObstacleCircle {
		return m_circles[i];
	}

	public function getObstacleSegmentCount():int {
		return m_nsegments;
	}

	public function getObstacleSegment(i:int):ObstacleSegment {
		return m_segments[i];
	}

	private function prepare(pos:Array, dvel:Array):void {
		// Prepare obstacles
		for (var i:int= 0; i < m_ncircles; ++i) {
			var cir:ObstacleCircle= m_circles[i];

			// Side
			var pa:Array= pos;
			var pb:Array= cir.p;

			var orig:Array= { 0, 0, 0};
			var dv:Array= new float[3];
			vCopy(cir.dp, vSub(pb, pa));
			vNormalize(cir.dp);
			dv = vSub(cir.dvel, dvel);

			var a:Number= triArea2D(orig, cir.dp, dv);
			if (a < 0.01) {
				cir.np[0] = -cir.dp[2];
				cir.np[2] = cir.dp[0];
			} else {
				cir.np[0] = cir.dp[2];
				cir.np[2] = -cir.dp[0];
			}
		}

		for (var i:int= 0; i < m_nsegments; ++i) {
			var seg:ObstacleSegment= m_segments[i];

			// Precalc if the agent is really close to the segment.
			var r:Number= 0.01;
			Tupple2<Float, Float> dt = distancePtSegSqr2D(pos, seg.p, seg.q);
			seg.touch = dt.first < sqr(r);
		}
	}

	Tupple3<Boolean, Float, Float> sweepCircleCircle(var c0:Array, var r0:Number, var v:Array, var c1:Array, var r1:Number) {
		var EPS:Number= 0.0001;
		var s:Array= vSub(c1, c0);
		var r:Number= r0 + r1;
		var c:Number= vDot2D(s, s) - r * r;
		var a:Number= vDot2D(v, v);
		if (a < EPS)
			return new Tupple3<Boolean, Float, Float>(false, 0, 0); // not moving

		// Overlap, calc time to exit.
		var b:Number= vDot2D(v, s);
		var d:Number= b * b - a * c;
		if (d < 0.0)
			return new Tupple3<Boolean, Float, Float>(false, 0, 0); // no intersection.
		a = 1.0/ a;
		var rd:Number= float(Math.sqrt(d));
		return new Tupple3<Boolean, Float, Float>(true, (b - rd) * a, (b + rd) * a);
	}

	Tupple2<Boolean, Float> isectRaySeg(var ap:Array, var u:Array, var bp:Array, var bq:Array) {
		var v:Array= vSub(bq, bp);
		var w:Array= vSub(ap, bp);
		var d:Number= vPerp2D(u, v);
		if (Math.abs(d) < 1e-6)
			return new Tupple2<Boolean, Float>(false, 0);
		d = 1.0/ d;
		var t:Number= vPerp2D(v, w) * d;
		if (t < 0|| t > 1)
			return new Tupple2<Boolean, Float>(false, 0);
		var s:Number= vPerp2D(u, w) * d;
		if (s < 0|| s > 1)
			return new Tupple2<Boolean, Float>(false, 0);
		return new Tupple2<Boolean, Float>(true, t);
	}
	

	/** Calculate the collision penalty for a given velocity vector
	 * 
	 * @param vcand sampled velocity
	 * @param dvel desired velocity
	 * @param minPenalty threshold penalty for early out
	 */
	private function processSample(vcand:Array, cs:Number, pos:Array, rad:Number, vel:Array, dvel:Array,
			minPenalty:Number, debug:ObstacleAvoidanceDebugData):Number {
		// penalty for straying away from the desired and current velocities
		var vpen:Number= m_params.weightDesVel * (vDist2D(vcand, dvel) * m_invVmax);
		var vcpen:Number= m_params.weightCurVel * (vDist2D(vcand, vel) * m_invVmax);

		// find the threshold hit time to bail out based on the early out penalty
		// (see how the penalty is calculated below to understnad)
		var minPen:Number= minPenalty - vpen - vcpen;
		var tThresold:Number= float((((double) m_params.weightToi / (double) minPen - 0.1)
				* (double) m_params.horizTime));
		if (tThresold - m_params.horizTime > -Float.MIN_VALUE)
			return minPenalty; // already too much

		// Find min time of impact and exit amongst all obstacles.
		var tmin:Number= m_params.horizTime;
		var side:Number= 0;
		var nside:int= 0;

		for (var i:int= 0; i < m_ncircles; ++i) {
			var cir:ObstacleCircle= m_circles[i];

			// RVO
			var vab:Array= vScale(vcand, 2);
			vab = vSub(vab, vel);
			vab = vSub(vab, cir.vel);

			// Side
			side += clamp(Math.min(vDot2D(cir.dp, vab) * 0.5+ 0.5, vDot2D(cir.np, vab) * 2), 0.0, 1.0);
			nside++;

			Tupple3<Boolean, Float, Float> sres = sweepCircleCircle(pos, rad, vab, cir.p, cir.rad);
			if (!sres.first)
				continue;
			var htmin:Number= sres.second, htmax = sres.third;

			// Handle overlapping obstacles.
			if (htmin < 0.0&& htmax > 0.0) {
				// Avoid more when overlapped.
				htmin = -htmin * 0.5;
			}

			if (htmin >= 0.0) {
				// The closest obstacle is somewhere ahead of us, keep track of nearest obstacle.
				if (htmin < tmin) {
					tmin = htmin;
					if (tmin < tThresold)
						return minPenalty;
				}
			}
		}

		for (var i:int= 0; i < m_nsegments; ++i) {
			var seg:ObstacleSegment= m_segments[i];
			var htmin:Number= 0;

			if (seg.touch) {
				// Special case when the agent is very close to the segment.
				var sdir:Array= vSub(seg.q, seg.p);
				var snorm:Array= new float[3];
				snorm[0] = -sdir[2];
				snorm[2] = sdir[0];
				// If the velocity is pointing towards the segment, no collision.
				if (vDot2D(snorm, vcand) < 0.0)
					continue;
				// Else immediate collision.
				htmin = 0.0;
			} else {
				Tupple2<Boolean, Float> ires = isectRaySeg(pos, vcand, seg.p, seg.q);
				if (!ires.first)
					continue;
				htmin = ires.second;
			}

			// Avoid less when facing walls.
			htmin *= 2.0;

			// The closest obstacle is somewhere ahead of us, keep track of nearest obstacle.
			if (htmin < tmin) {
				tmin = htmin;
				if (tmin < tThresold)
					return minPenalty;
			}
		}

		// Normalize side bias, to prevent it dominating too much.
		if (nside != 0)
			side /= nside;

		var spen:Number= m_params.weightSide * side;
		var tpen:Number= m_params.weightToi * (1.0/ (0.1+ tmin * m_invHorizTime));

		var penalty:Number= vpen + vcpen + spen + tpen;

		// Store different penalties for debug viewing
		if (debug != null)
			debug.addSample(vcand, cs, penalty, vpen, vcpen, spen, tpen);

		return penalty;
	}
	
	public Tupple2<Integer, float[]> sampleVelocityGrid(var pos:Array, var rad:Number, var vmax:Number, var vel:Array, var dvel:Array,
			var params:ObstacleAvoidanceParams, var debug:ObstacleAvoidanceDebugData) {
		prepare(pos, dvel);
		m_params = params;
		m_invHorizTime = 1.0/ m_params.horizTime;
		m_vmax = vmax;
		m_invVmax = vmax > 0? 1.0/ vmax : Float.MAX_VALUE;

		var nvel:Array= new float[3];
		vSet(nvel, 0, 0, 0);

		if (debug != null)
			debug.reset();

		var cvx:Number= dvel[0] * m_params.velBias;
		var cvz:Number= dvel[2] * m_params.velBias;
		var cs:Number= vmax * 2* (1- m_params.velBias) / float((m_params.gridSize - 1));
		var half:Number= (m_params.gridSize - 1) * cs * 0.5;

		var minPenalty:Number= Float.MAX_VALUE;
		var ns:int= 0;

		for (var y:int= 0; y < m_params.gridSize; ++y) {
			for (var x:int= 0; x < m_params.gridSize; ++x) {
				var vcand:Array= new float[3];
				vSet(vcand, cvx + x * cs - half, 0, cvz + y * cs - half);

				if (sqr(vcand[0]) + sqr(vcand[2]) > sqr(vmax + cs / 2))
					continue;

				var penalty:Number= processSample(vcand, cs, pos, rad, vel, dvel, minPenalty, debug);
				ns++;
				if (penalty < minPenalty) {
					minPenalty = penalty;
					vCopy(nvel, vcand);
				}
			}
		}

		return new Tupple2<Integer, float[]>(ns, nvel);
	}

	// vector normalization that ignores the y-component.
	function dtNormalize2D(v:Array):void {
		var d:Number= float(Math.sqrt(v[0] * v[0] + v[2] * v[2]));
		if (d == 0)
			return;
		d = 1.0/ d;
		v[0] *= d;
		v[2] *= d;
	}

	// vector normalization that ignores the y-component.
	float[] dtRotate2D(var v:Array, var ang:Number) {
		var dest:Array= new float[3];
		var c:Number= float(Math.cos(ang));
		var s:Number= float(Math.sin(ang));
		dest[0] = v[0] * c - v[2] * s;
		dest[2] = v[0] * s + v[2] * c;
		dest[1] = v[1];
		return dest;
	}
	
	static const DT_PI:Number= 3.14159265;

	public Tupple2<Integer, float[]> sampleVelocityAdaptive(var pos:Array, var rad:Number, var vmax:Number, var vel:Array,
			var dvel:Array, var params:ObstacleAvoidanceParams, var debug:ObstacleAvoidanceDebugData) {
		prepare(pos, dvel);
		m_params = params;
		m_invHorizTime = 1.0/ m_params.horizTime;
		m_vmax = vmax;
		m_invVmax = vmax > 0? 1.0/ vmax : Float.MAX_VALUE;

		var nvel:Array= new float[3];
		vSet(nvel, 0, 0, 0);

		if (debug != null)
			debug.reset();

		// Build sampling pattern aligned to desired velocity.
		var pat:Array= new float[(DT_MAX_PATTERN_DIVS * DT_MAX_PATTERN_RINGS + 1) * 2];
		var npat:int= 0;

		var ndivs:int= int(m_params.adaptiveDivs);
		var nrings:int= int(m_params.adaptiveRings);
		var depth:int= int(m_params.adaptiveDepth);

		var nd:int= clamp(ndivs, 1, DT_MAX_PATTERN_DIVS);
		var nr:int= clamp(nrings, 1, DT_MAX_PATTERN_RINGS);
		var nd2:int= nd / 2;
		var da:Number= (1.0/ nd) * DT_PI * 2;
		var ca:Number= float(Math.cos(da));
		var sa:Number= float(Math.sin(da));

		// desired direction
		var ddir:Array= new float[6];
		vCopy(ddir, dvel);
		dtNormalize2D(ddir);
		var rotated:Array= dtRotate2D(ddir, da * 0.5); // rotated by da/2
		ddir[3] = rotated[0];
		ddir[4] = rotated[1];
		ddir[5] = rotated[2];

		// Always add sample at zero
		pat[npat * 2+ 0] = 0;
		pat[npat * 2+ 1] = 0;
		npat++;

		for (var j:int= 0; j < nr; ++j) {
			var r:Number= float((nr - j) )/ float(nr);
			pat[npat * 2+ 0] = ddir[(j % 1) * 3] * r;
			pat[npat * 2+ 1] = ddir[(j % 1) * 3+ 2] * r;
			var last1:int= npat * 2;
			var last2:int= last1;
			npat++;

			for (var i:int= 1; i < nd - 1; i += 2) {
				// get next point on the "right" (rotate CW)
				pat[npat * 2+ 0] = pat[last1] * ca + pat[last1 + 1] * sa;
				pat[npat * 2+ 1] = -pat[last1] * sa + pat[last1 + 1] * ca;
				// get next point on the "left" (rotate CCW)
				pat[npat * 2+ 2] = pat[last2] * ca - pat[last2 + 1] * sa;
				pat[npat * 2+ 3] = pat[last2] * sa + pat[last2 + 1] * ca;

				last1 = npat * 2;
				last2 = last1 + 2;
				npat += 2;
			}

			if ((nd & 1) == 0) {
				pat[npat * 2+ 2] = pat[last2] * ca - pat[last2 + 1] * sa;
				pat[npat * 2+ 3] = pat[last2] * sa + pat[last2 + 1] * ca;
				npat++;
			}
		}

		// Start sampling.
		var cr:Number= vmax * (1.0- m_params.velBias);
		var res:Array= new float[3];
		vSet(res, dvel[0] * m_params.velBias, 0, dvel[2] * m_params.velBias);
		var ns:int= 0;

		for (var k:int= 0; k < depth; ++k) {
			var minPenalty:Number= Float.MAX_VALUE;
			var bvel:Array= new float[3];
			vSet(bvel, 0, 0, 0);

			for (var i:int= 0; i < npat; ++i) {
				var vcand:Array= new float[3];
				vSet(vcand, res[0] + pat[i * 2+ 0] * cr, 0, res[2] + pat[i * 2+ 1] * cr);

				if (sqr(vcand[0]) + sqr(vcand[2]) > sqr(vmax + 0.001))
					continue;

				var penalty:Number= processSample(vcand, cr / 10, pos, rad, vel, dvel, minPenalty, debug);
				ns++;
				if (penalty < minPenalty) {
					minPenalty = penalty;
					vCopy(bvel, vcand);
				}
			}

			vCopy(res, bvel);

			cr *= 0.5;
		}

		vCopy(nvel, res);

		return new Tupple2<Integer, float[]>(ns, nvel);
	}
}
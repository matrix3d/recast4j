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
package org.recast4j.detour {
public class DetourCommon {

	static var EPS:Number= 1e-4;

	/// Performs a scaled vector addition. (@p v1 + (@p v2 * @p s))
	/// @param[out] dest The result vector. [(x, y, z)]
	/// @param[in] v1 The base vector. [(x, y, z)]
	/// @param[in] v2 The vector to scale and add to @p v1. [(x, y, z)]
	/// @param[in] s The amount to scale @p v2 by before adding to @p v1.
	public static float[] vMad(var v1:Array, var v2:Array, var s:Number) {
		var dest:Array= new float[3];
		dest[0] = v1[0] + v2[0] * s;
		dest[1] = v1[1] + v2[1] * s;
		dest[2] = v1[2] + v2[2] * s;
		return dest;
	}

	/// Performs a linear interpolation between two vectors. (@p v1 toward @p
	/// v2)
	/// @param[out] dest The result vector. [(x, y, x)]
	/// @param[in] v1 The starting vector.
	/// @param[in] v2 The destination vector.
	/// @param[in] t The interpolation factor. [Limits: 0 <= value <= 1.0]
	public static float[] vLerp(var v1:VectorPtr, var v2:VectorPtr, var t:Number) {
		var dest:Array= new float[3];
		dest[0] = v1.get(0) + (v2.get(0) - v1.get(0)) * t;
		dest[1] = v1.get(1) + (v2.get(1) - v1.get(1)) * t;
		dest[2] = v1.get(2) + (v2.get(2) - v1.get(2)) * t;
		return dest;
	}

	public static float[] vLerp(var verts:Array, var v1:int, var v2:int, var t:Number) {
		var dest:Array= new float[3];
		dest[0] = verts[v1 + 0] + (verts[v2 + 0] - verts[v1 + 0]) * t;
		dest[1] = verts[v1 + 1] + (verts[v2 + 1] - verts[v1 + 1]) * t;
		dest[2] = verts[v1 + 2] + (verts[v2 + 2] - verts[v1 + 2]) * t;
		return dest;
	}

	public static float[] vLerp(var v1:Array, var v2:Array, var t:Number) {
		var dest:Array= new float[3];
		dest[0] = v1[0] + (v2[0] - v1[0]) * t;
		dest[1] = v1[1] + (v2[1] - v1[1]) * t;
		dest[2] = v1[2] + (v2[2] - v1[2]) * t;
		return dest;
	}

	public static float[] vSub(var v1:VectorPtr, var v2:VectorPtr) {
		var dest:Array= new float[3];
		dest[0] = v1.get(0) - v2.get(0);
		dest[1] = v1.get(1) - v2.get(1);
		dest[2] = v1.get(2) - v2.get(2);
		return dest;
	}

	public static float[] vSub(var v1:Array, var v2:Array) {
		var dest:Array= new float[3];
		dest[0] = v1[0] - v2[0];
		dest[1] = v1[1] - v2[1];
		dest[2] = v1[2] - v2[2];
		return dest;
	}

	static float[] vAdd(var v1:VectorPtr, var v2:VectorPtr) {
		var dest:Array= new float[3];
		dest[0] = v1.get(0) + v2.get(0);
		dest[1] = v1.get(1) + v2.get(1);
		dest[2] = v1.get(2) + v2.get(2);
		return dest;
	}

	public static float[] vAdd(var v1:Array, var v2:Array) {
		var dest:Array= new float[3];
		dest[0] = v1[0] + v2[0];
		dest[1] = v1[1] + v2[1];
		dest[2] = v1[2] + v2[2];
		return dest;
	}

	public static float[] vCopy(var in:Array) {
		var out:Array= new float[3];
		out[0] = in[0];
		out[1] = in[1];
		out[2] = in[2];
		return out;
	}

	public static function vSet(out:Array, a:Number, b:Number, c:Number):void {
		out[0] = a;
		out[1] = b;
		out[2] = c;
	}

	public static function vCopy(out:Array, in:Array):void {
		out[0] = in[0];
		out[1] = in[1];
		out[2] = in[2];
	}

	public static function vCopy(out:Array, in:Array, i:int):void {
		out[0] = in[i];
		out[1] = in[i + 1];
		out[2] = in[i + 2];
	}

	static function vMin(out:Array, in:Array, i:int):void {
		out[0] = Math.min(out[0], in[i]);
		out[1] = Math.min(out[1], in[i + 1]);
		out[2] = Math.min(out[2], in[i + 2]);
	}

	static function vMax(out:Array, in:Array, i:int):void {
		out[0] = Math.max(out[0], in[i]);
		out[1] = Math.max(out[1], in[i + 1]);
		out[2] = Math.max(out[2], in[i + 2]);
	}

	/// Returns the distance between two points.
	/// @param[in] v1 A point. [(x, y, z)]
	/// @param[in] v2 A point. [(x, y, z)]
	/// @return The distance between the two points.
	static function vDist(v1:Array, v2:Array):Number {
		var dx:Number= v2[0] - v1[0];
		var dy:Number= v2[1] - v1[1];
		var dz:Number= v2[2] - v1[2];
		return float(Math.sqrt(dx * dx + dy * dy + dz * dz));
	}

	/// Returns the distance between two points.
	/// @param[in] v1 A point. [(x, y, z)]
	/// @param[in] v2 A point. [(x, y, z)]
	/// @return The distance between the two points.
	static function vDistSqr(v1:Array, v2:Array):Number {
		var dx:Number= v2[0] - v1[0];
		var dy:Number= v2[1] - v1[1];
		var dz:Number= v2[2] - v1[2];
		return dx * dx + dy * dy + dz * dz;
	}

	public static function sqr(a:Number):Number {
		return a * a;
	}

	/// Derives the square of the scalar length of the vector. (len * len)
	/// @param[in] v The vector. [(x, y, z)]
	/// @return The square of the scalar length of the vector.
	public static function vLenSqr(v:Array):Number {
		return v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
	}

	public static function vLen(v:Array):Number {
		return float(Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]));
	}

	static function vDist(v1:Array, verts:Array, i:int):Number {
		var dx:Number= verts[i] - v1[0];
		var dy:Number= verts[i + 1] - v1[1];
		var dz:Number= verts[i + 2] - v1[2];
		return float(Math.sqrt(dx * dx + dy * dy + dz * dz));
	}

	public static function clamp(v:Number, min:Number, max:Number):Number {
		return Math.max(Math.min(v, max), min);
	}

	public static function clamp(v:int, min:int, max:int):int {
		return Math.max(Math.min(v, max), min);
	}

	/// Derives the distance between the specified points on the xz-plane.
	/// @param[in] v1 A point. [(x, y, z)]
	/// @param[in] v2 A point. [(x, y, z)]
	/// @return The distance between the point on the xz-plane.
	///
	/// The vectors are projected onto the xz-plane, so the y-values are
	/// ignored.
	public static function vDist2D(v1:VectorPtr, v2:VectorPtr):Number {
		var dx:Number= v2.get(0) - v1.get(0);
		var dz:Number= v2.get(2) - v1.get(2);
		return float(Math.sqrt(dx * dx + dz * dz));
	}

	public static function vDist2D(v1:Array, v2:Array):Number {
		var dx:Number= v2[0] - v1[0];
		var dz:Number= v2[2] - v1[2];
		return float(Math.sqrt(dx * dx + dz * dz));
	}

	public static function vDist2DSqr(v1:VectorPtr, v2:VectorPtr):Number {
		var dx:Number= v2.get(0) - v1.get(0);
		var dz:Number= v2.get(2) - v1.get(2);
		return dx * dx + dz * dz;
	}

	public static function vDist2DSqr(v1:Array, v2:Array):Number {
		var dx:Number= v2[0] - v1[0];
		var dz:Number= v2[2] - v1[2];
		return dx * dx + dz * dz;
	}

	/// Normalizes the vector.
	/// @param[in,out] v The vector to normalize. [(x, y, z)]
	public static function vNormalize(v:Array):void {
		var d:Number= float((1.0f / Math.sqrt(sqr(v[0]) + sqr(v[1]) + sqr(v[2]))));
		v[0] *= d;
		v[1] *= d;
		v[2] *= d;
	}

	static const thr:Number= sqr(1.0/ 16384.0);

	/// Performs a 'sloppy' colocation check of the specified points.
	/// @param[in] p0 A point. [(x, y, z)]
	/// @param[in] p1 A point. [(x, y, z)]
	/// @return True if the points are considered to be at the same location.
	///
	/// Basically, this function will return true if the specified points are
	/// close enough to eachother to be considered colocated.
	static function vEqual(p0:Array, p1:Array):Boolean {
		var d:Number= vDistSqr(p0, p1);
		return d < thr;
	}

	/// Derives the dot product of two vectors on the xz-plane. (@p u . @p v)
	/// @param[in] u A vector [(x, y, z)]
	/// @param[in] v A vector [(x, y, z)]
	/// @return The dot product on the xz-plane.
	///
	/// The vectors are projected onto the xz-plane, so the y-values are
	/// ignored.
	public static function vDot2D(u:Array, v:Array):Number {
		return u[0] * v[0] + u[2] * v[2];
	}

	static function vDot2D(u:Array, v:Array, vi:int):Number {
		return u[0] * v[vi] + u[2] * v[vi + 2];
	}

	/// Derives the xz-plane 2D perp product of the two vectors. (uz*vx - ux*vz)
	/// @param[in] u The LHV vector [(x, y, z)]
	/// @param[in] v The RHV vector [(x, y, z)]
	/// @return The dot product on the xz-plane.
	///
	/// The vectors are projected onto the xz-plane, so the y-values are
	/// ignored.
	public static function vPerp2D(u:Array, v:Array):Number {
		return u[2] * v[0] - u[0] * v[2];
	}

	/// @}
	/// @name Computational geometry helper functions.
	/// @{

	/// Derives the signed xz-plane area of the triangle ABC, or the
	/// relationship of line AB to point C.
	/// @param[in] a Vertex A. [(x, y, z)]
	/// @param[in] b Vertex B. [(x, y, z)]
	/// @param[in] c Vertex C. [(x, y, z)]
	/// @return The signed xz-plane area of the triangle.
	public static function triArea2D(verts:Array, a:int, b:int, c:int):Number {
		var abx:Number= verts[b] - verts[a];
		var abz:Number= verts[b + 2] - verts[a + 2];
		var acx:Number= verts[c] - verts[a];
		var acz:Number= verts[c + 2] - verts[a + 2];
		return acx * abz - abx * acz;
	}

	public static function triArea2D(a:Array, b:Array, c:Array):Number {
		var abx:Number= b[0] - a[0];
		var abz:Number= b[2] - a[2];
		var acx:Number= c[0] - a[0];
		var acz:Number= c[2] - a[2];
		return acx * abz - abx * acz;
	}

	/// Determines if two axis-aligned bounding boxes overlap.
	/// @param[in] amin Minimum bounds of box A. [(x, y, z)]
	/// @param[in] amax Maximum bounds of box A. [(x, y, z)]
	/// @param[in] bmin Minimum bounds of box B. [(x, y, z)]
	/// @param[in] bmax Maximum bounds of box B. [(x, y, z)]
	/// @return True if the two AABB's overlap.
	/// @see dtOverlapBounds
	static function overlapQuantBounds(int amin[], int amax[], int bmin[], int bmax[]):Boolean {
		var overlap:Boolean= true;
		overlap = (amin[0] > bmax[0] || amax[0] < bmin[0]) ? false : overlap;
		overlap = (amin[1] > bmax[1] || amax[1] < bmin[1]) ? false : overlap;
		overlap = (amin[2] > bmax[2] || amax[2] < bmin[2]) ? false : overlap;
		return overlap;
	}

	/// Determines if two axis-aligned bounding boxes overlap.
	/// @param[in] amin Minimum bounds of box A. [(x, y, z)]
	/// @param[in] amax Maximum bounds of box A. [(x, y, z)]
	/// @param[in] bmin Minimum bounds of box B. [(x, y, z)]
	/// @param[in] bmax Maximum bounds of box B. [(x, y, z)]
	/// @return True if the two AABB's overlap.
	/// @see dtOverlapQuantBounds
	static function overlapBounds(amin:Array, amax:Array, bmin:Array, bmax:Array):Boolean {
		var overlap:Boolean= true;
		overlap = (amin[0] > bmax[0] || amax[0] < bmin[0]) ? false : overlap;
		overlap = (amin[1] > bmax[1] || amax[1] < bmin[1]) ? false : overlap;
		overlap = (amin[2] > bmax[2] || amax[2] < bmin[2]) ? false : overlap;
		return overlap;
	}

	public static Tupple2<Float, Float> distancePtSegSqr2D(var pt:Array, var p:Array, var q:Array) {
		var pqx:Number= q[0] - p[0];
		var pqz:Number= q[2] - p[2];
		var dx:Number= pt[0] - p[0];
		var dz:Number= pt[2] - p[2];
		var d:Number= pqx * pqx + pqz * pqz;
		var t:Number= pqx * dx + pqz * dz;
		if (d > 0)
			t /= d;
		if (t < 0)
			t = 0;
		else if (t > 1)
			t = 1;
		dx = p[0] + t * pqx - pt[0];
		dz = p[2] + t * pqz - pt[2];
		return new Tupple2<>(dx * dx + dz * dz, t);
	}

	static Tupple2<Boolean, Float> closestHeightPointTriangle(var p:VectorPtr, var a:VectorPtr, var b:VectorPtr, var c:VectorPtr) {
		var v0:Array= vSub(c, a);
		var v1:Array= vSub(b, a);
		var v2:Array= vSub(p, a);

		var dot00:Number= vDot2D(v0, v0);
		var dot01:Number= vDot2D(v0, v1);
		var dot02:Number= vDot2D(v0, v2);
		var dot11:Number= vDot2D(v1, v1);
		var dot12:Number= vDot2D(v1, v2);

		// Compute barycentric coordinates
		var invDenom:Number= 1.0/ (dot00 * dot11 - dot01 * dot01);
		var u:Number= (dot11 * dot02 - dot01 * dot12) * invDenom;
		var v:Number= (dot00 * dot12 - dot01 * dot02) * invDenom;

		// The (sloppy) epsilon is needed to allow to get height of points which
		// are interpolated along the edges of the triangles.

		// If point lies inside the triangle, return interpolated ycoord.
		if (u >= -EPS && v >= -EPS && (u + v) <= 1+ EPS) {
			var h:Number= a.get(1) + v0[1] * u + v1[1] * v;
			return new Tupple2<>(true, h);
		}

		return new Tupple2<>(false, null);
	}

	/// @par
	///
	/// All points are projected onto the xz-plane, so the y-values are ignored.
	static function pointInPolygon(pt:Array, verts:Array, nverts:int):Boolean {
		// TODO: Replace pnpoly with triArea2D tests?
		var i:int, j;
		var c:Boolean= false;
		for (i = 0, j = nverts - 1; i < nverts; j = i++) {
			var vi:int= i * 3;
			var vj:int= j * 3;
			if (((verts[vi + 2] > pt[2]) != (verts[vj + 2] > pt[2])) && (pt[0] < (verts[vj + 0] - verts[vi + 0])
					* (pt[2] - verts[vi + 2]) / (verts[vj + 2] - verts[vi + 2]) + verts[vi + 0]))
				c = !c;
		}
		return c;
	}

	static function distancePtPolyEdgesSqr(pt:Array, verts:Array, nverts:int, ed:Array, et:Array):Boolean {
		// TODO: Replace pnpoly with triArea2D tests?
		var i:int, j;
		var c:Boolean= false;
		for (i = 0, j = nverts - 1; i < nverts; j = i++) {
			var vi:int= i * 3;
			var vj:int= j * 3;
			if (((verts[vi + 2] > pt[2]) != (verts[vj + 2] > pt[2])) && (pt[0] < (verts[vj + 0] - verts[vi + 0])
					* (pt[2] - verts[vi + 2]) / (verts[vj + 2] - verts[vi + 2]) + verts[vi + 0]))
				c = !c;
			Tupple2<Float, Float> edet = distancePtSegSqr2D(pt, verts, vj, vi);
			ed[j] = edet.first;
			et[j] = edet.second;
		}
		return c;
	}

	static float[] projectPoly(var axis:Array, var poly:Array, var npoly:int) {
		var rmin:Number, rmax;
		rmin = rmax = vDot2D(axis, poly, 0);
		for (var i:int= 1; i < npoly; ++i) {
			var d:Number= vDot2D(axis, poly, i * 3);
			rmin = Math.min(rmin, d);
			rmax = Math.max(rmax, d);
		}
		return new float[] { rmin, rmax };
	}

	static function overlapRange(amin:Number, amax:Number, bmin:Number, bmax:Number, eps:Number):Boolean {
		return ((amin + eps) > bmax || (amax - eps) < bmin) ? false : true;
	}

	static var eps:Number= 1e-4;

	/// @par
	///
	/// All vertices are projected onto the xz-plane, so the y-values are ignored.
	static function overlapPolyPoly2D(polya:Array, npolya:int, polyb:Array, npolyb:int):Boolean {

		for (var i:int= 0, j = npolya - 1; i < npolya; j = i++) {
			var va:int= j * 3;
			var vb:int= i * 3;

			var n:Array= new float[] { polya[vb + 2] - polya[va + 2], 0, -(polya[vb + 0] - polya[va + 0]) };

			var aminmax:Array= projectPoly(n, polya, npolya);
			var bminmax:Array= projectPoly(n, polyb, npolyb);
			if (!overlapRange(aminmax[0], aminmax[1], bminmax[0], bminmax[1], eps)) {
				// Found separating axis
				return false;
			}
		}
		for (var i:int= 0, j = npolyb - 1; i < npolyb; j = i++) {
			var va:int= j * 3;
			var vb:int= i * 3;

			var n:Array= new float[] { polyb[vb + 2] - polyb[va + 2], 0, -(polyb[vb + 0] - polyb[va + 0]) };

			var aminmax:Array= projectPoly(n, polya, npolya);
			var bminmax:Array= projectPoly(n, polyb, npolyb);
			if (!overlapRange(aminmax[0], aminmax[1], bminmax[0], bminmax[1], eps)) {
				// Found separating axis
				return false;
			}
		}
		return true;
	}

	// Returns a random point in a convex polygon.
	// Adapted from Graphics Gems article.
	static float[] randomPointInConvexPoly(var pts:Array, var npts:int, var areas:Array, var s:Number, var t:Number) {
		// Calc triangle araes
		var areasum:Number= 0.0;
		for (var i:int= 2; i < npts; i++) {
			areas[i] = triArea2D(pts, 0, (i - 1) * 3, i * 3);
			areasum += Math.max(0.001, areas[i]);
		}
		// Find sub triangle weighted by area.
		var thr:Number= s * areasum;
		var acc:Number= 0.0;
		var u:Number= 0.0;
		var tri:int= 0;
		for (var i:int= 2; i < npts; i++) {
			var dacc:Number= areas[i];
			if (thr >= acc && thr < (acc + dacc)) {
				u = (thr - acc) / dacc;
				tri = i;
				break;
			}
			acc += dacc;
		}

		var v:Number= float(Math.sqrt(t));

		var a:Number= 1- v;
		var b:Number= (1- u) * v;
		var c:Number= u * v;
		var pa:int= 0;
		var pb:int= (tri - 1) * 3;
		var pc:int= tri * 3;

		return new float[] { a * pts[pa] + b * pts[pb] + c * pts[pc],
				a * pts[pa + 1] + b * pts[pb + 1] + c * pts[pc + 1],
				a * pts[pa + 2] + b * pts[pb + 2] + c * pts[pc + 2] };
	}

	static function nextPow2(v:int):int {
		v--;
		v |= v >> 1;
		v |= v >> 2;
		v |= v >> 4;
		v |= v >> 8;
		v |= v >> 16;
		v++;
		return v;
	}
}



	public static 
internal class IntersectResult {
		var intersects:Boolean;
		var tmin:Number;
		var tmax:Number= 1;
		var segMin:int= -1;
		var segMax:int= -1;
	}

	static function intersectSegmentPoly2D(p0:Array, p1:Array, verts:Array, nverts:int):IntersectResult {

		var result:IntersectResult= new IntersectResult();
		var EPS:Number= 0.00000001;
		var dir:Array= vSub(p1, p0);

		var p0v:VectorPtr= new VectorPtr(p0);
		for (var i:int= 0, j = nverts - 1; i < nverts; j = i++) {
			var vpj:VectorPtr= new VectorPtr(verts, j * 3);
			var edge:Array= vSub(new VectorPtr(verts, i * 3), vpj);
			var diff:Array= vSub(p0v, vpj);
			var n:Number= vPerp2D(edge, diff);
			var d:Number= vPerp2D(dir, edge);
			if (Math.abs(d) < EPS) {
				// S is nearly parallel to this edge
				if (n < 0)
					return result;
				else
					continue;
			}
			var t:Number= n / d;
			if (d < 0) {
				// segment S is entering across this edge
				if (t > result.tmin) {
					result.tmin = t;
					result.segMin = j;
					// S enters after leaving polygon
					if (result.tmin > result.tmax)
						return result;
				}
			} else {
				// segment S is leaving across this edge
				if (t < result.tmax) {
					result.tmax = t;
					result.segMax = j;
					// S leaves before entering polygon
					if (result.tmax < result.tmin)
						return result;
				}
			}
		}
		result.intersects = true;
		return result;
	}

	public static Tupple2<Float, Float> distancePtSegSqr2D(var pt:Array, var verts:Array, var p:int, var q:int) {
		var pqx:Number= verts[q + 0] - verts[p + 0];
		var pqz:Number= verts[q + 2] - verts[p + 2];
		var dx:Number= pt[0] - verts[p + 0];
		var dz:Number= pt[2] - verts[p + 2];
		var d:Number= pqx * pqx + pqz * pqz;
		var t:Number= pqx * dx + pqz * dz;
		if (d > 0)
			t /= d;
		if (t < 0)
			t = 0;
		else if (t > 1)
			t = 1;
		dx = verts[p + 0] + t * pqx - pt[0];
		dz = verts[p + 2] + t * pqz - pt[2];
		return new Tupple2<>(dx * dx + dz * dz, t);
	}

	static function oppositeTile(side:int):int {
		return (side + 4) & 0x7;
	}

	static function vperpXZ(a:Array, b:Array):Number {
		return a[0] * b[2] - a[2] * b[0];
	}

	static Tupple3<Boolean, Float, Float> intersectSegSeg2D(var ap:Array, var aq:Array, var bp:Array, var bq:Array) {
		var u:Array= vSub(aq, ap);
		var v:Array= vSub(bq, bp);
		var w:Array= vSub(ap, bp);
		var d:Number= vperpXZ(u, v);
		if (Math.abs(d) < 1e-6)
			return new Tupple3<>(false, 0, 0);
		var s:Number= vperpXZ(v, w) / d;
		var t:Number= vperpXZ(u, w) / d;
		return new Tupple3<>(true, s, t);
	}

	public static float[] vScale(var in:Array, var scale:Number) {
		var out:Array= new float[3];
		out[0] = in[0] * scale;
		out[1] = in[1] * scale;
		out[2] = in[2] * scale;
		return out;
	}

}
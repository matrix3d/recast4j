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
package org.recast4j.recast {
	import org.recast4j.Arrays;
	import org.recast4j.System;

public class RecastMeshDetail {

	public static const MAX_VERTS:int= 127;
	public static const MAX_TRIS:int= 255; // Max tris for delaunay is 2n-2-k (n=num verts, k=num hull verts).
	public static const MAX_VERTS_PER_EDGE:int= 32;

	public static const RC_UNSET_HEIGHT:int= 0;
	public static const EV_UNDEF:int= -1;
	public static const EV_HULL:int= -2;

	

	private static function vdot2(a:Array, b:Array):Number {
		return a[0] * b[0] + a[2] * b[2];
	}

	private static function vdistSq2(verts:Array, p:int, q:int):Number {
		var dx:Number= verts[q + 0] - verts[p + 0];
		var dy:Number= verts[q + 2] - verts[p + 2];
		return dx * dx + dy * dy;
	}

	private static function vdist2(verts:Array, p:int, q:int):Number {
		return (Math.sqrt(vdistSq2(verts, p, q)));
	}

	private static function vdistSq22(p:Array, q:Array):Number {
		var dx:Number= q[0] - p[0];
		var dy:Number= q[2] - p[2];
		return dx * dx + dy * dy;
	}

	private static function vdist22(p:Array, q:Array):Number {
		return (Math.sqrt(vdistSq22(p, q)));
	}

	private static function vdistSq23(p:Array, verts:Array, q:int):Number {
		var dx:Number= verts[q + 0] - p[0];
		var dy:Number= verts[q + 2] - p[2];
		return dx * dx + dy * dy;
	}

	private static function vdist23(p:Array, verts:Array, q:int):Number {
		return (Math.sqrt(vdistSq23(p, verts, q)));
	}

	private static function vcross2(verts:Array, p1:int, p2:int, p3:int):Number {
		var u1:Number= verts[p2 + 0] - verts[p1 + 0];
		var v1:Number= verts[p2 + 2] - verts[p1 + 2];
		var u2:Number= verts[p3 + 0] - verts[p1 + 0];
		var v2:Number= verts[p3 + 2] - verts[p1 + 2];
		return u1 * v2 - v1 * u2;
	}

	private static function vcross22(p1:Array, p2:Array, p3:Array):Number {
		var u1:Number= p2[0] - p1[0];
		var v1:Number= p2[2] - p1[2];
		var u2:Number= p3[0] - p1[0];
		var v2:Number= p3[2] - p1[2];
		return u1 * v2 - v1 * u2;
	}

	private static function circumCircle(verts:Array, p1:int, p2:int, p3:int, c:Array,  r:Array):Boolean {
		var EPS:Number= 1e-6;
		// Calculate the circle relative to p1, to avoid some precision issues.
		var v1:Array = [];
		var v2:Array = [];
		var v3:Array = [];
		RecastVectors.sub(v2, verts, p2, p1);
		RecastVectors.sub(v3, verts, p3, p1);

		var cp:Number= vcross22(v1, v2, v3);
		if (Math.abs(cp) > EPS) {
			var v1Sq:Number= vdot2(v1, v1);
			var v2Sq:Number= vdot2(v2, v2);
			var v3Sq:Number= vdot2(v3, v3);
			c[0] = (v1Sq * (v2[2] - v3[2]) + v2Sq * (v3[2] - v1[2]) + v3Sq * (v1[2] - v2[2])) / (2* cp);
			c[1] = 0;
			c[2] = (v1Sq * (v3[0] - v2[0]) + v2Sq * (v1[0] - v3[0]) + v3Sq * (v2[0] - v1[0])) / (2* cp);
			r.set(vdist22(c, v1));
			RecastVectors.add(c, c, verts, p1);
			return true;
		}
		RecastVectors.copy(c, verts, p1);
		r.set(0);
		return false;
	}

	private static function distPtTri(p:Array, verts:Array, a:int, b:int, c:int):Number {
		var v0:Array= [];
		var v1:Array= [];
		var v2:Array= [];
		RecastVectors.sub(v0, verts, c, a);
		RecastVectors.sub(v1, verts, b, a);
		RecastVectors.sub2(v2, p, verts, a);

		var dot00:Number= vdot2(v0, v0);
		var dot01:Number= vdot2(v0, v1);
		var dot02:Number= vdot2(v0, v2);
		var dot11:Number= vdot2(v1, v1);
		var dot12:Number= vdot2(v1, v2);

		// Compute barycentric coordinates
		var invDenom:Number= 1.0/ (dot00 * dot11 - dot01 * dot01);
		var u:Number= (dot11 * dot02 - dot01 * dot12) * invDenom;
		var v:Number= (dot00 * dot12 - dot01 * dot02) * invDenom;

		// If point lies inside the triangle, return interpolated y-coord.
		var EPS:Number= 1e-4;
		if (u >= -EPS && v >= -EPS && (u + v) <= 1+ EPS) {
			var y:Number= verts[a + 1] + v0[1] * u + v1[1] * v;
			return Math.abs(y - p[1]);
		}
		return Number.MAX_VALUE;
	}

	private static function distancePtSeg(verts:Array, pt:int, p:int, q:int):Number {
		var pqx:Number= verts[q + 0] - verts[p + 0];
		var pqy:Number= verts[q + 1] - verts[p + 1];
		var pqz:Number= verts[q + 2] - verts[p + 2];
		var dx:Number= verts[pt + 0] - verts[p + 0];
		var dy:Number= verts[pt + 1] - verts[p + 1];
		var dz:Number= verts[pt + 2] - verts[p + 2];
		var d:Number= pqx * pqx + pqy * pqy + pqz * pqz;
		var t:Number= pqx * dx + pqy * dy + pqz * dz;
		if (d > 0)
			t /= d;
		if (t < 0)
			t = 0;
		else if (t > 1)
			t = 1;

		dx = verts[p + 0] + t * pqx - verts[pt + 0];
		dy = verts[p + 1] + t * pqy - verts[pt + 1];
		dz = verts[p + 2] + t * pqz - verts[pt + 2];

		return dx * dx + dy * dy + dz * dz;
	}

	private static function distancePtSeg2d(verts:Array, pt:int, poly:Array, p:int, q:int):Number {
		var pqx:Number= poly[q + 0] - poly[p + 0];
		var pqz:Number= poly[q + 2] - poly[p + 2];
		var dx:Number= verts[pt + 0] - poly[p + 0];
		var dz:Number= verts[pt + 2] - poly[p + 2];
		var d:Number= pqx * pqx + pqz * pqz;
		var t:Number= pqx * dx + pqz * dz;
		if (d > 0)
			t /= d;
		if (t < 0)
			t = 0;
		else if (t > 1)
			t = 1;

		dx = poly[p + 0] + t * pqx - verts[pt + 0];
		dz = poly[p + 2] + t * pqz - verts[pt + 2];

		return dx * dx + dz * dz;
	}

	private static function distToTriMesh(p:Array, verts:Array, nverts:int,  tris:Array, ntris:int):Number {
		var dmin:Number= Number.MAX_VALUE;
		for (var i:int= 0; i < ntris; ++i) {
			var va:int= tris.get(i * 4+ 0) * 3;
			var vb:int= tris.get(i * 4+ 1) * 3;
			var vc:int= tris.get(i * 4+ 2) * 3;
			var d:Number= distPtTri(p, verts, va, vb, vc);
			if (d < dmin)
				dmin = d;
		}
		if (dmin == Number.MAX_VALUE)
			return -1;
		return dmin;
	}

	private static function distToPoly(nvert:int, verts:Array, p:Array):Number {

		var dmin:Number= Number.MAX_VALUE;
		var i:int, j:int;
		var c:Boolean= false;
		for (i = 0, j = nvert - 1; i < nvert; j = i++) {
			var vi:int= i * 3;
			var vj:int= j * 3;
			if (((verts[vi + 2] > p[2]) != (verts[vj + 2] > p[2])) && (p[0] < (verts[vj + 0] - verts[vi + 0])
					* (p[2] - verts[vi + 2]) / (verts[vj + 2] - verts[vi + 2]) + verts[vi + 0]))
				c = !c;
			dmin = Math.min(dmin, distancePtSeg2d(p, 0, verts, vj, vi));
		}
		return c ? -dmin : dmin;
	}

	private static function getHeight(fx:Number, fy:Number, fz:Number, cs:Number, ics:Number, ch:Number, hp:HeightPatch):int {
		var ix:int= int(Math.floor(fx * ics + 0.01));
		var iz:int= int(Math.floor(fz * ics + 0.01));
		ix = RecastCommon.clamp(ix - hp.xmin, 0, hp.width - 1);
		iz = RecastCommon.clamp(iz - hp.ymin, 0, hp.height - 1);
		var h:int= hp.data[ix + iz * hp.width];
		if (h == RC_UNSET_HEIGHT) {
			// Special case when data might be bad.
			// Find nearest neighbour pixel which has valid height.
			var off:Array = [ -1, 0, -1, -1, 0, -1, 1, -1, 1, 0, 1, 1, 0, 1, -1, 1];
			var dmin:Number= Number.MAX_VALUE;
			for (var i:int= 0; i < 8; ++i) {
				var nx:int= ix + off[i * 2+ 0];
				var nz:int= iz + off[i * 2+ 1];
				if (nx < 0|| nz < 0|| nx >= hp.width || nz >= hp.height)
					continue;
				var nh:int= hp.data[nx + nz * hp.width];
				if (nh == RC_UNSET_HEIGHT)
					continue;

				var d:Number= Math.abs(nh * ch - fy);
				if (d < dmin) {
					h = nh;
					dmin = d;
				}
			}
		}
		return h;
	}

	private static function findEdge( edges:Array, s:int, t:int):int {
		for (var i:int= 0; i < edges.length / 4; i++) {
			var e:int= i * 4;
			if ((edges.get(e + 0) == s && edges.get(e + 1) == t) || (edges.get(e + 0) == t && edges.get(e + 1) == s))
				return i;
		}
		return EV_UNDEF;
	}

	private static function addEdge(ctx:Context,  edges:Array, maxEdges:int, s:int, t:int, l:int, r:int):void {
		if (edges.length / 4>= maxEdges) {
			throw ("addEdge: Too many edges (" + edges.length / 4+ "/" + maxEdges + ").");
		}

		// Add edge if not already in the triangulation.
		var e:int= findEdge(edges, s, t);
		if (e == EV_UNDEF) {
			edges.push(s);
			edges.push(t);
			edges.push(l);
			edges.push(r);
		}
	}

	private static function updateLeftFace(edges:Array, e:int, s:int, t:int, f:int):void {
		if (edges.get(e + 0) == s && edges.get(e + 1) == t && edges.get(e + 2) == EV_UNDEF)
			edges.set(e + 2, f);
		else if (edges.get(e + 1) == s && edges.get(e + 0) == t && edges.get(e + 3) == EV_UNDEF)
			edges.set(e + 3, f);
	}

	private static function overlapSegSeg2d(verts:Array, a:int, b:int, c:int, d:int):Boolean {
		var a1:Number= vcross2(verts, a, b, d);
		var a2:Number= vcross2(verts, a, b, c);
		if (a1 * a2 < 0.0) {
			var a3:Number= vcross2(verts, c, d, a);
			var a4:Number= a3 + a2 - a1;
			if (a3 * a4 < 0.0)
				return true;
		}
		return false;
	}

	private static function overlapEdges(pts:Array, edges:Array,  s1:int, t1:int):Boolean {
		for (var i:int= 0; i < edges.length / 4; ++i) {
			var s0:int= edges.get(i * 4+ 0);
			var t0:int= edges.get(i * 4+ 1);
			// Same or connected edges do not overlap.
			if (s0 == s1 || s0 == t1 || t0 == s1 || t0 == t1)
				continue;
			if (overlapSegSeg2d(pts, s0 * 3, t0 * 3, s1 * 3, t1 * 3))
				return true;
		}
		return false;
	}

	public static function completeFacet(ctx:Context, pts:Array, npts:int, edges:Array, maxEdges:int,
			nfaces:int, e:int):int {
		var EPS:Number= 1e-5;

		var edge:int= e * 4;

		// Cache s and t.
		var s:int, t:int;
		if (edges.get(edge + 2) == EV_UNDEF) {
			s = edges.get(edge + 0);
			t = edges.get(edge + 1);
		} else if (edges.get(edge + 3) == EV_UNDEF) {
			s = edges.get(edge + 1);
			t = edges.get(edge + 0);
		} else {
			// Edge already completed.
			return nfaces;
		}

		// Find best point on left of edge.
		var pt:int= npts;
		var c:Array = [];
		var r:Array = [];
		for (var u:int= 0; u < npts; ++u) {
			if (u == s || u == t)
				continue;
			if (vcross2(pts, s * 3, t * 3, u * 3) > EPS) {
				if (r.get() < 0) {
					// The circle is not updated yet, do it now.
					pt = u;
					circumCircle(pts, s * 3, t * 3, u * 3, c, r);
					continue;
				}
				var d:Number= vdist23(c, pts, u * 3);
				var tol:Number= 0.001;
				if (d > r.get() * (1+ tol)) {
					// Outside current circumcircle, skip.
					continue;
				} else if (d < r.get() * (1- tol)) {
					// Inside safe circumcircle, update circle.
					pt = u;
					circumCircle(pts, s * 3, t * 3, u * 3, c, r);
				} else {
					// Inside epsilon circum circle, do extra tests to make sure the edge is valid.
					// s-u and t-u cannot overlap with s-pt nor t-pt if they exists.
					if (overlapEdges(pts, edges, s, u))
						continue;
					if (overlapEdges(pts, edges, t, u))
						continue;
					// Edge is valid.
					pt = u;
					circumCircle(pts, s * 3, t * 3, u * 3, c, r);
				}
			}
		}

		// Add new triangle or update edge info if s-t is on hull.
		if (pt < npts) {
			// Update face information of edge being completed.
			updateLeftFace(edges, e * 4, s, t, nfaces);

			// Add new edge or update face info of old edge.
			e = findEdge(edges, pt, s);
			if (e == EV_UNDEF)
				addEdge(ctx, edges, maxEdges, pt, s, nfaces, EV_UNDEF);
			else
				updateLeftFace(edges, e * 4, pt, s, nfaces);

			// Add new edge or update face info of old edge.
			e = findEdge(edges, t, pt);
			if (e == EV_UNDEF)
				addEdge(ctx, edges, maxEdges, t, pt, nfaces, EV_UNDEF);
			else
				updateLeftFace(edges, e * 4, t, pt, nfaces);

			nfaces++;
		} else {
			updateLeftFace(edges, e * 4, s, t, EV_HULL);
		}
		return nfaces;
	}

	private static function delaunayHull(ctx:Context, npts:int, pts:Array, nhull:int, hull:Array,  tris:Array):void {
		var nfaces:int= 0;
		var maxEdges:int= npts * 10;
		var edges:Array = [];
		for (var i:int= 0, j:int = nhull - 1; i < nhull; j = i++)
			addEdge(ctx, edges, maxEdges, hull[j], hull[i], EV_HULL, EV_UNDEF);
		var currentEdge:int= 0;
		while (currentEdge < edges.length / 4) {
			if (edges.get(currentEdge * 4+ 2) == EV_UNDEF) {
				nfaces = completeFacet(ctx, pts, npts, edges, maxEdges, nfaces, currentEdge);
			}
			if (edges.get(currentEdge * 4+ 3) == EV_UNDEF) {
				nfaces = completeFacet(ctx, pts, npts, edges, maxEdges, nfaces, currentEdge);
			}
			currentEdge++;
		}
		// Create tris
		tris.clear();
		for (i= 0; i < nfaces * 4; ++i)
			tris.push(-1);

		for (i= 0; i < edges.length / 4; ++i) {
			var e:int= i * 4;
			if (edges.get(e + 3) >= 0) {
				// Left face
				var t:int= edges.get(e + 3) * 4;
				if (tris.get(t + 0) == -1) {
					tris.set(t + 0, edges.get(e + 0));
					tris.set(t + 1, edges.get(e + 1));
				} else if (tris.get(t + 0) == edges.get(e + 1))
					tris.set(t + 2, edges.get(e + 0));
				else if (tris.get(t + 1) == edges.get(e + 0))
					tris.set(t + 2, edges.get(e + 1));
			}
			if (edges.get(e + 2) >= 0) {
				// Right
				t= edges.get(e + 2) * 4;
				if (tris.get(t + 0) == -1) {
					tris.set(t + 0, edges.get(e + 1));
					tris.set(t + 1, edges.get(e + 0));
				} else if (tris.get(t + 0) == edges.get(e + 0))
					tris.set(t + 2, edges.get(e + 1));
				else if (tris.get(t + 1) == edges.get(e + 1))
					tris.set(t + 2, edges.get(e + 0));
			}
		}

		for (i= 0; i < tris.length / 4; ++i) {
			t= i * 4;
			if (tris.get(t + 0) == -1|| tris.get(t + 1) == -1|| tris.get(t + 2) == -1) {
				trace("Dangling! " + tris.get(t) + " " + tris.get(t + 1) + "  " + tris.get(t + 2));
				//ctx.log(RC_LOG_WARNING, "delaunayHull: Removing dangling face %d [%d,%d,%d].", i, t[0],t[1],t[2]);
				tris.set(t + 0, tris.get(tris.length - 4));
				tris.set(t + 1, tris.get(tris.length - 3));
				tris.set(t + 2, tris.get(tris.length - 2));
				tris.set(t + 3, tris.get(tris.length - 1));
				tris.remove(tris.length - 1);
				tris.remove(tris.length - 1);
				tris.remove(tris.length - 1);
				tris.remove(tris.length - 1);
				--i;
			}
		}
	}

	// Calculate minimum extend of the polygon.
	private static function polyMinExtent(verts:Array, nverts:int):Number {
		var minDist:Number= Number.MAX_VALUE;
		for (var i:int= 0; i < nverts; i++) {
			var ni:int= (i + 1) % nverts;
			var p1:int= i * 3;
			var p2:int= ni * 3;
			var maxEdgeDist:Number= 0;
			for (var j:int= 0; j < nverts; j++) {
				if (j == i || j == ni)
					continue;
				var d:Number= distancePtSeg2d(verts, j * 3, verts, p1, p2);
				maxEdgeDist = Math.max(maxEdgeDist, d);
			}
			minDist = Math.min(minDist, maxEdgeDist);
		}
		return (Math.sqrt(minDist));
	}

	private static function triangulateHull(nverts:int, verts:Array, nhull:int, hull:Array,  tris:Array):void {
		var start:int= 0, left:int = 1, right:int = nhull - 1;

		// Start from an ear with shortest perimeter.
		// This tends to favor well formed triangles as starting point.
		var dmin:Number= 0;
		for (var i:int= 0; i < nhull; i++) {
			var pi:int= RecastMesh.prev(i, nhull);
			var ni:int= RecastMesh.next(i, nhull);
			var pv:int= hull[pi] * 3;
			var cv:int= hull[i] * 3;
			var nv:int= hull[ni] * 3;
			var d:Number= vdist2(verts, pv, cv) + vdist2(verts, cv, nv) + vdist2(verts, nv, pv);
			if (d < dmin) {
				start = i;
				left = ni;
				right = pi;
				dmin = d;
			}
		}

		// Add first triangle
		tris.push(hull[start]);
		tris.push(hull[left]);
		tris.push(hull[right]);
		tris.push(0);

		// Triangulate the polygon by moving left or right,
		// depending on which triangle has shorter perimeter.
		// This heuristic was chose emprically, since it seems
		// handle tesselated straight edges well.
		while (RecastMesh.next(left, nhull) != right) {
			// Check to see if se should advance left or right.
			var nleft:int= RecastMesh.next(left, nhull);
			var nright:int= RecastMesh.prev(right, nhull);

			var cvleft:int= hull[left] * 3;
			var nvleft:int= hull[nleft] * 3;
			var cvright:int= hull[right] * 3;
			var nvright:int= hull[nright] * 3;
			var dleft:Number= vdist2(verts, cvleft, nvleft) + vdist2(verts, nvleft, cvright);
			var dright:Number= vdist2(verts, cvright, nvright) + vdist2(verts, cvleft, nvright);

			if (dleft < dright) {
				tris.push(hull[left]);
				tris.push(hull[nleft]);
				tris.push(hull[right]);
				tris.push(0);
				left = nleft;
			} else {
				tris.push(hull[left]);
				tris.push(hull[nright]);
				tris.push(hull[right]);
				tris.push(0);
				right = nright;
			}
		}
	}

	private static function getJitterX(i:int):Number {
		return (((i * 0x8da6b343) & 0) / 65535.0* 2.0) - 1.0;
	}

	private static function getJitterY(i:int):Number {
		return (((i * 0xd8163841) & 0) / 65535.0* 2.0) - 1.0;
	}

	public static function buildPolyDetail(ctx:Context, in_:Array, nin:int, sampleDist:Number, sampleMaxError:Number,
			chf:CompactHeightfield, hp:HeightPatch, verts:Array,  tris:Array):int {

		var samples:Array = [];

		var nverts:int= 0;
		var edge:Array= []//new [(MAX_VERTS_PER_EDGE + 1) * 3];
		var hull:Array= []//[]//MAX_VERTS];
		var nhull:int= 0;

		nverts = 0;

		for (var i:int= 0; i < nin; ++i)
			RecastVectors.copy2(verts, i * 3, in_, i * 3);
		nverts = nin;
		tris.clear();

		var cs:Number= chf.cs;
		var ics:Number= 1.0/ cs;

		// Calculate minimum extents of the polygon based on input data.
		var minExtent:Number= polyMinExtent(verts, nverts);

		// Tessellate outlines.
		// This is done in separate pass in order to ensure
		// seamless height values across the ply boundaries.
		if (sampleDist > 0) {
			var j:int;
			for (i= 0, j = nin - 1; i < nin; j = i++) {
				var vj:int= j * 3;
				var vi:int= i * 3;
				var swapped:Boolean= false;
				// Make sure the segments are always handled in same order
				// using lexological sort or else there will be seams.
				if (Math.abs(in_[vj + 0] - in_[vi + 0]) < 1e-6) {
					if (in_[vj + 2] > in_[vi + 2]) {
						var temp:int= vi;
						vi = vj;
						vj = temp;
						swapped = true;
					}
				} else {
					if (in_[vj + 0] > in_[vi + 0]) {
						 temp= vi;
						vi = vj;
						vj = temp;
						swapped = true;
					}
				}
				// Create samples along the edge.
				var dx:Number= in_[vi + 0] - in_[vj + 0];
				var dy:Number= in_[vi + 1] - in_[vj + 1];
				var dz:Number= in_[vi + 2] - in_[vj + 2];
				var d:Number= (Math.sqrt(dx * dx + dz * dz));
				var nn:int= 1+ int(Math.floor(d / sampleDist));
				if (nn >= MAX_VERTS_PER_EDGE)
					nn = MAX_VERTS_PER_EDGE - 1;
				if (nverts + nn >= MAX_VERTS)
					nn = MAX_VERTS - 1- nverts;

				for (var k:int= 0; k <= nn; ++k) {
					var u:Number= (k )/ (nn);
					var pos:int= k * 3;
					edge[pos + 0] = in_[vj + 0] + dx * u;
					edge[pos + 1] = in_[vj + 1] + dy * u;
					edge[pos + 2] = in_[vj + 2] + dz * u;
					edge[pos + 1] = getHeight(edge[pos + 0], edge[pos + 1], edge[pos + 2], cs, ics, chf.ch, hp)
							* chf.ch;
				}
				// Simplify samples.
				var idx:Array= []//[]//MAX_VERTS_PER_EDGE];
				idx[0] = 0;
				idx[1] = nn;
				var nidx:int= 2;
				for (k= 0; k < nidx - 1;) {
					var a:int= idx[k];
					var b:int= idx[k + 1];
					var va:int= a * 3;
					var vb:int= b * 3;
					// Find maximum deviation along the segment.
					var maxd:Number= 0;
					var maxi:int= -1;
					for (var m:int= a + 1; m < b; ++m) {
						var dev:Number= distancePtSeg(edge, m * 3, va, vb);
						if (dev > maxd) {
							maxd = dev;
							maxi = m;
						}
					}
					// If the max deviation is larger than accepted error,
					// add new point, else continue to next segment.
					if (maxi != -1&& maxd > sampleMaxError * sampleMaxError) {
						for ( m= nidx; m > k; --m)
							idx[m] = idx[m - 1];
						idx[k + 1] = maxi;
						nidx++;
					} else {
						++k;
					}
				}

				hull[nhull++] = j;
				// Add new vertices.
				if (swapped) {
					for ( k= nidx - 2; k > 0; --k) {
						RecastVectors.copy2(verts, nverts * 3, edge, idx[k] * 3);
						hull[nhull++] = nverts;
						nverts++;
					}
				} else {
					for ( k= 1; k < nidx - 1; ++k) {
						RecastVectors.copy2(verts, nverts * 3, edge, idx[k] * 3);
						hull[nhull++] = nverts;
						nverts++;
					}
				}
			}
		}

		// If the polygon minimum extent is small (sliver or small triangle), do not try to add internal points.
		if (minExtent < sampleDist * 2) {
			triangulateHull(nverts, verts, nhull, hull, tris);
			return nverts;
		}

		// Tessellate the base mesh.
		// We're using the triangulateHull instead of delaunayHull as it tends to
		// create a bit better triangulation for long thing triangles when there
		// are no internal points.
		triangulateHull(nverts, verts, nhull, hull, tris);

		if (tris.length == 0) {
			// Could not triangulate the poly, make sure there is some valid data there.
			throw ("buildPolyDetail: Could not triangulate polygon (" + nverts + ") verts).");
		}

		if (sampleDist > 0) {
			// Create sample locations in a grid.
			var bmin:Array= []//new float[3];
			var bmax:Array= []//new float[3];
			RecastVectors.copy(bmin, in_, 0);
			RecastVectors.copy(bmax, in_, 0);
			for (i= 1; i < nin; ++i) {
				RecastVectors.min(bmin, in_, i * 3);
				RecastVectors.max(bmax, in_, i * 3);
			}
			var x0:int= int(Math.floor(bmin[0] / sampleDist));
			var x1:int= int(Math.ceil(bmax[0] / sampleDist));
			var z0:int= int(Math.floor(bmin[2] / sampleDist));
			var z1:int= int(Math.ceil(bmax[2] / sampleDist));
			samples.clear();
			for (var z:int= z0; z < z1; ++z) {
				for (var x:int= x0; x < x1; ++x) {
					var pt:Array= []//new float[3];
					pt[0] = x * sampleDist;
					pt[1] = (bmax[1] + bmin[1]) * 0.5;
					pt[2] = z * sampleDist;
					// Make sure the samples are not too close to the edges.
					if (distToPoly(nin, in_, pt) > -sampleDist / 2)
						continue;
					samples.push(x);
					samples.push(getHeight(pt[0], pt[1], pt[2], cs, ics, chf.ch, hp));
					samples.push(z);
					samples.push(0); // Not added
				}
			}

			// Add the samples starting from the one that has the most
			// error. The procedure stops when all samples are added
			// or when the max error is within treshold.
			var nsamples:int= samples.length / 4;
			for (var iter:int= 0; iter < nsamples; ++iter) {
				if (nverts >= MAX_VERTS)
					break;

				// Find sample with most error.
				var bestpt:Array= []//new float[3];
				var bestd:Number= 0;
				var besti:int= -1;
				for ( i= 0; i < nsamples; ++i) {
					var s:int= i * 4;
					if (samples.get(s + 3) != 0)
						continue; // skip added.
					 pt= []//new float[3];
					// The sample location is jittered to get rid of some bad triangulations
					// which are cause by symmetrical data from the grid structure.
					pt[0] = samples.get(s + 0) * sampleDist + getJitterX(i) * cs * 0.1;
					pt[1] = samples.get(s + 1) * chf.ch;
					pt[2] = samples.get(s + 2) * sampleDist + getJitterY(i) * cs * 0.1;
					 d= distToTriMesh(pt, verts, nverts, tris, tris.length / 4);
					if (d < 0)
						continue; // did not hit the mesh.
					if (d > bestd) {
						bestd = d;
						besti = i;
						bestpt = pt;
					}
				}
				// If the max error is within accepted threshold, stop tesselating.
				if (bestd <= sampleMaxError || besti == -1)
					break;
				// Mark sample as added.
				samples.set(besti * 4+ 3, 1);
				// Add the new sample point.
				RecastVectors.copy2(verts, nverts * 3, bestpt, 0);
				nverts++;

				// Create new triangulation.
				// TODO: Incremental add instead of full rebuild.
				delaunayHull(ctx, nverts, verts, nhull, hull, tris);
			}
		}

		var ntris:int= tris.length / 4;
		if (ntris > MAX_TRIS) {
			var subList:Array =tris.slice(0, MAX_TRIS * 4);
			tris.clear();
			tris.addAll(subList);
			throw (
					"rcBuildPolyMeshDetail: Shrinking triangle count from " + ntris + " to max " + MAX_TRIS);
		}
		return nverts;
	}

	public static function getHeightDataSeedsFromVertices(chf:CompactHeightfield, meshpoly:Array, poly:int, npoly:int, verts:Array,
			bs:int, hp:HeightPatch,  stack:Array):void {
		// Floodfill the heightfield to get 2D height data,
		// starting at vertex locations as seeds.

		// Note: Reads to the compact heightfield are offset by border size (bs)
		// since border size offset is already removed from the polymesh vertices.

		Arrays.fill(hp.data, 0, hp.width * hp.height, 0);
		stack.clear();

		var offset:Array = [ 0, 0, -1, -1, 0, -1, 1, -1, 1, 0, 1, 1, 0, 1, -1, 1, -1, 0];

		// Use poly vertices as seed points for the flood fill.
		for (var j:int= 0; j < npoly; ++j) {
			var cx:int= 0, cz:int = 0, ci:int = -1;
			var dmin:int= RC_UNSET_HEIGHT;
			for (var k:int= 0; k < 9; ++k) {
				var ax:int= verts[meshpoly[poly + j] * 3+ 0] + offset[k * 2+ 0];
				var ay:int= verts[meshpoly[poly + j] * 3+ 1];
				var az:int= verts[meshpoly[poly + j] * 3+ 2] + offset[k * 2+ 1];
				if (ax < hp.xmin || ax >= hp.xmin + hp.width || az < hp.ymin || az >= hp.ymin + hp.height)
					continue;

				var c:CompactCell= chf.cells[(ax + bs) + (az + bs) * chf.width];
				var ni:int
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					var s:CompactSpan= chf.spans[i];
					var d:int= Math.abs(ay - s.y);
					if (d < dmin) {
						cx = ax;
						cz = az;
						ci = i;
						dmin = d;
					}
				}
			}
			if (ci != -1) {
				stack.push(cx);
				stack.push(cz);
				stack.push(ci);
			}
		}

		// Find center of the polygon using flood fill.
		var pcx:int= 0, pcz:int = 0;
		for (j= 0; j < npoly; ++j) {
			pcx += verts[meshpoly[poly + j] * 3+ 0];
			pcz += verts[meshpoly[poly + j] * 3+ 2];
		}
		pcx /= npoly;
		pcz /= npoly;

		for (var i:int= 0; i < stack.length; i += 3) {
			cx= stack.get(i + 0);
			var cy:int= stack.get(i + 1);
			var idx:int= cx - hp.xmin + (cy - hp.ymin) * hp.width;
			hp.data[idx] = 1;
		}

		while (stack.length > 0) {
			 ci= stack.remove(stack.length - 1);
			 cy= stack.remove(stack.length - 1);
			 cx= stack.remove(stack.length - 1);

			// Check if close to center of the polygon.
			if (Math.abs(cx - pcx) <= 1&& Math.abs(cy - pcz) <= 1) {
				stack.clear();
				stack.push(cx);
				stack.push(cy);
				stack.push(ci);
				break;
			}

			var cs:CompactSpan= chf.spans[ci];

			for (var dir:int= 0; dir < 4; ++dir) {
				if (RecastCommon.GetCon(cs, dir) == RecastConstants.RC_NOT_CONNECTED)
					continue;

				ax= cx + RecastCommon.GetDirOffsetX(dir);
				ay= cy + RecastCommon.GetDirOffsetY(dir);

				if (ax < hp.xmin || ax >= (hp.xmin + hp.width) || ay < hp.ymin || ay >= (hp.ymin + hp.height))
					continue;

				if (hp.data[ax - hp.xmin + (ay - hp.ymin) * hp.width] != 0)
					continue;

				var ai:int= chf.cells[(ax + bs) + (ay + bs) * chf.width].index + RecastCommon.GetCon(cs, dir);

				idx= ax - hp.xmin + (ay - hp.ymin) * hp.width;
				hp.data[idx] = 1;

				stack.push(ax);
				stack.push(ay);
				stack.push(ai);
			}
		}

		Arrays.fill(hp.data, 0, hp.width * hp.height, RC_UNSET_HEIGHT);

		// Mark start locations.
		for ( i= 0; i < stack.length; i += 3) {
			 cx= stack.get(i + 0);
			 cy= stack.get(i + 1);
			ci= stack.get(i + 2);
			 idx= cx - hp.xmin + (cy - hp.ymin) * hp.width;
			 cs= chf.spans[ci];
			hp.data[idx] = cs.y;

			// getHeightData seeds are given in coordinates with borders
			stack.set(i + 0, stack.get(i + 0) + bs);
			stack.set(i + 1, stack.get(i + 1) + bs);
		}

	}

	public static const RETRACT_SIZE:int= 256;

	public static function getHeightData(chf:CompactHeightfield, meshpolys:Array, poly:int, npoly:int, verts:Array, bs:int,
			hp:HeightPatch, region:int):void {
		// Note: Reads to the compact heightfield are offset by border size (bs)
		// since border size offset is already removed from the polymesh vertices.

		var stack:Array = [];
		Arrays.fill(hp.data, 0, hp.width * hp.height, RC_UNSET_HEIGHT);

		var empty:Boolean= true;

		// Copy the height from the same region, and mark region borders
		// as seed points to fill the rest.
		for (var hy:int= 0; hy < hp.height; hy++) {
			var y:int= hp.ymin + hy + bs;
			for (var hx:int= 0; hx < hp.width; hx++) {
				var x:int= hp.xmin + hx + bs;
				var c:CompactCell= chf.cells[x + y * chf.width];
				for (var i:int= c.index, ni:int = c.index + c.count; i < ni; ++i) {
					var s:CompactSpan= chf.spans[i];
					if (s.reg == region) {
						// Store height
						hp.data[hx + hy * hp.width] = s.y;
						empty = false;

						// If any of the neighbours is not in same region,
						// add the current location as flood fill start
						var border:Boolean= false;
						for (var dir:int= 0; dir < 4; ++dir) {
							if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
								var ax:int= x + RecastCommon.GetDirOffsetX(dir);
								var ay:int= y + RecastCommon.GetDirOffsetY(dir);
								var ai:int= chf.cells[ax + ay * chf.width].index + RecastCommon.GetCon(s, dir);
								var as_:CompactSpan= chf.spans[ai];
								if (as_.reg != region) {
									border = true;
									break;
								}
							}
						}
						if (border) {
							stack.push(x);
							stack.push(y);
							stack.push(i);
						}
						break;
					}
				}
			}
		}

		// if the polygon does not contian any points from the current region (rare, but happens)
		// then use the cells closest to the polygon vertices as seeds to fill the height field
		if (empty)
			getHeightDataSeedsFromVertices(chf, meshpolys, poly, npoly, verts, bs, hp, stack);

		var head:int= 0;

		while (head * 3< stack.length) {
			var cx:int= stack.get(head * 3+ 0);
			var cy:int= stack.get(head * 3+ 1);
			var ci:int= stack.get(head * 3+ 2);
			head++;
			if (head >= RETRACT_SIZE) {
				head = 0;
				stack = stack.subList(RETRACT_SIZE * 3, stack.length);
			}

			var cs:CompactSpan= chf.spans[ci];
			for ( dir= 0; dir < 4; ++dir) {
				if (RecastCommon.GetCon(cs, dir) == RecastConstants.RC_NOT_CONNECTED)
					continue;

				 ax= cx + RecastCommon.GetDirOffsetX(dir);
				 ay= cy + RecastCommon.GetDirOffsetY(dir);
				 hx= ax - hp.xmin - bs;
				 hy= ay - hp.ymin - bs;

				if (hx < 0|| hx >= hp.width || hy < 0|| hy >= hp.height)
					continue;

				if (hp.data[hx + hy * hp.width] != RC_UNSET_HEIGHT)
					continue;

				 ai= chf.cells[ax + ay * chf.width].index + RecastCommon.GetCon(cs, dir);
				 as_= chf.spans[ai];

				hp.data[hx + hy * hp.width] = as_.y;

				stack.push(ax);
				stack.push(ay);
				stack.push(ai);
			}
		}
	}

	public static function getEdgeFlags(verts:Array, va:int, vb:int, vpoly:Array, npoly:int):int {
		// Return true if edge (va,vb) is part of the polygon.
		var thrSqr:Number= 0.001* 0.001;
		for (var i:int= 0, j:int = npoly - 1; i < npoly; j = i++) {
			if (distancePtSeg2d(verts, va, vpoly, j * 3, i * 3) < thrSqr
					&& distancePtSeg2d(verts, vb, vpoly, j * 3, i * 3) < thrSqr)
				return 1;
		}
		return 0;
	}

	public static function getTriFlags(verts:Array, va:int, vb:int, vc:int, vpoly:Array, npoly:int):int {
		var flags:int= 0;
		flags |= getEdgeFlags(verts, va, vb, vpoly, npoly) << 0;
		flags |= getEdgeFlags(verts, vb, vc, vpoly, npoly) << 2;
		flags |= getEdgeFlags(verts, vc, va, vpoly, npoly) << 4;
		return flags;
	}

	/// @par
	///
	/// See the #rcConfig documentation for more information on the configuration parameters.
	///
	/// @see rcAllocPolyMeshDetail, rcPolyMesh, rcCompactHeightfield, rcPolyMeshDetail, rcConfig
	public static function buildPolyMeshDetail(ctx:Context, mesh:PolyMesh, chf:CompactHeightfield, sampleDist:Number,
			sampleMaxError:Number):PolyMeshDetail {

		ctx.startTimer("BUILD_POLYMESHDETAIL");
		if (mesh.nverts == 0|| mesh.npolys == 0)
			return null;

		var dmesh:PolyMeshDetail= new PolyMeshDetail();
		var nvp:int= mesh.nvp;
		var cs:Number= mesh.cs;
		var ch:Number= mesh.ch;
		var orig:Array= mesh.bmin;
		var borderSize:int= mesh.borderSize;

		var tris:Array = [];
		var verts:Array = [];
		var hp:HeightPatch= new HeightPatch();
		var nPolyVerts:int= 0;
		var maxhw:int= 0, maxhh:int = 0;

		var bounds:Array= []//mesh.npolys * 4];
		var poly:Array= []//new float[nvp * 3];

		// Find max size for a polygon area.
		for (var i:int= 0; i < mesh.npolys; ++i) {
			var p:int= i * nvp * 2;
			bounds[i * 4+ 0] = chf.width;
			bounds[i * 4+ 1] = 0;
			bounds[i * 4+ 2] = chf.height;
			bounds[i * 4+ 3] = 0;
			for (var j:int= 0; j < nvp; ++j) {
				if (mesh.polys[p + j] == RecastConstants.RC_MESH_NULL_IDX)
					break;
				var v:int= mesh.polys[p + j] * 3;
				bounds[i * 4+ 0] = Math.min(bounds[i * 4+ 0], mesh.verts[v + 0]);
				bounds[i * 4+ 1] = Math.max(bounds[i * 4+ 1], mesh.verts[v + 0]);
				bounds[i * 4+ 2] = Math.min(bounds[i * 4+ 2], mesh.verts[v + 2]);
				bounds[i * 4+ 3] = Math.max(bounds[i * 4+ 3], mesh.verts[v + 2]);
				nPolyVerts++;
			}
			bounds[i * 4+ 0] = Math.max(0, bounds[i * 4+ 0] - 1);
			bounds[i * 4+ 1] = Math.min(chf.width, bounds[i * 4+ 1] + 1);
			bounds[i * 4+ 2] = Math.max(0, bounds[i * 4+ 2] - 1);
			bounds[i * 4+ 3] = Math.min(chf.height, bounds[i * 4+ 3] + 1);
			if (bounds[i * 4+ 0] >= bounds[i * 4+ 1] || bounds[i * 4+ 2] >= bounds[i * 4+ 3])
				continue;
			maxhw = Math.max(maxhw, bounds[i * 4+ 1] - bounds[i * 4+ 0]);
			maxhh = Math.max(maxhh, bounds[i * 4+ 3] - bounds[i * 4+ 2]);
		}
		hp.data = []//maxhw * maxhh];

		dmesh.nmeshes = mesh.npolys;
		dmesh.nverts = 0;
		dmesh.ntris = 0;
		dmesh.meshes = []//dmesh.nmeshes * 4];

		var vcap:int= nPolyVerts + nPolyVerts / 2;
		var tcap:int= vcap * 2;

		dmesh.nverts = 0;
		dmesh.verts = []//new float[vcap * 3];
		dmesh.ntris = 0;
		dmesh.tris = []//tcap * 4];

		for ( i= 0; i < mesh.npolys; ++i) {
			 p= i * nvp * 2;

			// Store polygon vertices for processing.
			var npoly:int= 0;
			for ( j= 0; j < nvp; ++j) {
				if (mesh.polys[p + j] == RecastConstants.RC_MESH_NULL_IDX)
					break;
				 v= mesh.polys[p + j] * 3;
				poly[j * 3+ 0] = mesh.verts[v + 0] * cs;
				poly[j * 3+ 1] = mesh.verts[v + 1] * ch;
				poly[j * 3+ 2] = mesh.verts[v + 2] * cs;
				npoly++;
			}

			// Get the height data from the area of the polygon.
			hp.xmin = bounds[i * 4+ 0];
			hp.ymin = bounds[i * 4+ 2];
			hp.width = bounds[i * 4+ 1] - bounds[i * 4+ 0];
			hp.height = bounds[i * 4+ 3] - bounds[i * 4+ 2];
			getHeightData(chf, mesh.polys, p, npoly, mesh.verts, borderSize, hp, mesh.regs[i]);

			// Build detail mesh.
			var nverts:int= buildPolyDetail(ctx, poly, npoly, sampleDist, sampleMaxError, chf, hp, verts, tris);

			// Move detail verts to world space.
			for ( j= 0; j < nverts; ++j) {
				verts[j * 3+ 0] += orig[0];
				verts[j * 3+ 1] += orig[1] + chf.ch; // Is this offset necessary?
				verts[j * 3+ 2] += orig[2];
			}
			// Offset poly too, will be used to flag checking.
			for ( j= 0; j < npoly; ++j) {
				poly[j * 3+ 0] += orig[0];
				poly[j * 3+ 1] += orig[1];
				poly[j * 3+ 2] += orig[2];
			}

			// Store detail submesh.
			var ntris:int= tris.length / 4;

			dmesh.meshes[i * 4+ 0] = dmesh.nverts;
			dmesh.meshes[i * 4+ 1] = nverts;
			dmesh.meshes[i * 4+ 2] = dmesh.ntris;
			dmesh.meshes[i * 4+ 3] = ntris;

			// Store vertices, allocate more memory if necessary.
			if (dmesh.nverts + nverts > vcap) {
				while (dmesh.nverts + nverts > vcap)
					vcap += 256;

				var newv:Array= []//new float[vcap * 3];
				if (dmesh.nverts != 0)
					System.arraycopy(dmesh.verts, 0, newv, 0, 3* dmesh.nverts);
				dmesh.verts = newv;
			}
			for ( j= 0; j < nverts; ++j) {
				dmesh.verts[dmesh.nverts * 3+ 0] = verts[j * 3+ 0];
				dmesh.verts[dmesh.nverts * 3+ 1] = verts[j * 3+ 1];
				dmesh.verts[dmesh.nverts * 3+ 2] = verts[j * 3+ 2];
				dmesh.nverts++;
			}

			// Store triangles, allocate more memory if necessary.
			if (dmesh.ntris + ntris > tcap) {
				while (dmesh.ntris + ntris > tcap)
					tcap += 256;
				var newt:Array= []//tcap * 4];
				if (dmesh.ntris != 0)
					System.arraycopy(dmesh.tris, 0, newt, 0, 4* dmesh.ntris);
				dmesh.tris = newt;
			}
			for ( j= 0; j < ntris; ++j) {
				var t:int= j * 4;
				dmesh.tris[dmesh.ntris * 4+ 0] = tris.get(t + 0);
				dmesh.tris[dmesh.ntris * 4+ 1] = tris.get(t + 1);
				dmesh.tris[dmesh.ntris * 4+ 2] = tris.get(t + 2);
				dmesh.tris[dmesh.ntris * 4+ 3] = getTriFlags(verts, tris.get(t + 0) * 3, tris.get(t + 1) * 3,
						tris.get(t + 2) * 3, poly, npoly);
				dmesh.ntris++;
			}
		}

		ctx.stopTimer("BUILD_POLYMESHDETAIL");
		return dmesh;

	}

	/// @see rcAllocPolyMeshDetail, rcPolyMeshDetail
	public function mergePolyMeshDetails(ctx:Context, meshes:Array, nmeshes:int):PolyMeshDetail {
		var mesh:PolyMeshDetail= new PolyMeshDetail();

		ctx.startTimer("MERGE_POLYMESHDETAIL");

		var maxVerts:int= 0;
		var maxTris:int= 0;
		var maxMeshes:int= 0;

		for (var i:int= 0; i < nmeshes; ++i) {
			if (meshes[i] == null)
				continue;
			maxVerts += meshes[i].nverts;
			maxTris += meshes[i].ntris;
			maxMeshes += meshes[i].nmeshes;
		}

		mesh.nmeshes = 0;
		mesh.meshes = []//maxMeshes * 4];
		mesh.ntris = 0;
		mesh.tris = []//maxTris * 4];
		mesh.nverts = 0;
		mesh.verts = []//new float[maxVerts * 3];

		// Merge datas.
		for ( i= 0; i < nmeshes; ++i) {
			var dm:PolyMeshDetail= meshes[i];
			if (dm == null)
				continue;
			for (var j:int= 0; j < dm.nmeshes; ++j) {
				var dst:int= mesh.nmeshes * 4;
				var src:int= j * 4;
				mesh.meshes[dst + 0] = mesh.nverts + dm.meshes[src + 0];
				mesh.meshes[dst + 1] = dm.meshes[src + 1];
				mesh.meshes[dst + 2] = mesh.ntris + dm.meshes[src + 2];
				mesh.meshes[dst + 3] = dm.meshes[src + 3];
				mesh.nmeshes++;
			}

			for (var k:int= 0; k < dm.nverts; ++k) {
				RecastVectors.copy2(mesh.verts, mesh.nverts * 3, dm.verts, k * 3);
				mesh.nverts++;
			}
			for ( k= 0; k < dm.ntris; ++k) {
				mesh.tris[mesh.ntris * 4+ 0] = dm.tris[k * 4+ 0];
				mesh.tris[mesh.ntris * 4+ 1] = dm.tris[k * 4+ 1];
				mesh.tris[mesh.ntris * 4+ 2] = dm.tris[k * 4+ 2];
				mesh.tris[mesh.ntris * 4+ 3] = dm.tris[k * 4+ 3];
				mesh.ntris++;
			}
		}
		ctx.stopTimer("MERGE_POLYMESHDETAIL");
		return mesh;
	}

}
}

 class HeightPatch {
		public var xmin:int;
		public var ymin:int;
		public var width:int;
		public var height:int;
		public var data:Array;
	}
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

public class RecastMesh {

	public static const VERTEX_BUCKET_COUNT:int= (1<< 12);

	

	private static function buildMeshAdjacency(polys:Array, npolys:int, nverts:int, vertsPerPoly:int):void {
		// Based on code by Eric Lengyel from:
		// http://www.terathon.com/code/edges.php

		var maxEdgeCount:int= npolys * vertsPerPoly;
		var firstEdge:Array= []//nverts + maxEdgeCount];
		var nextEdge:int= nverts;
		var edgeCount:int= 0;

		var edges:Array= []//new Edge[maxEdgeCount];

		for (var i:int= 0; i < nverts; i++)
			firstEdge[i] = RecastConstants.RC_MESH_NULL_IDX;

		for (i= 0; i < npolys; ++i) {
			var t:int= i * vertsPerPoly * 2;
			for (var j:int= 0; j < vertsPerPoly; ++j) {
				if (polys[t + j] == RecastConstants.RC_MESH_NULL_IDX)
					break;
				var v0:int= polys[t + j];
				var v1:int= (j + 1>= vertsPerPoly || polys[t + j + 1] == RecastConstants.RC_MESH_NULL_IDX) ? polys[t + 0]
						: polys[t + j + 1];
				if (v0 < v1) {
					var edge:Edge= new Edge();
					edges[edgeCount] = edge;
					edge.vert[0] = v0;
					edge.vert[1] = v1;
					edge.poly[0] = i;
					edge.polyEdge[0] = j;
					edge.poly[1] = i;
					edge.polyEdge[1] = 0;
					// Insert edge
					firstEdge[nextEdge + edgeCount] = firstEdge[v0];
					firstEdge[v0] = edgeCount;
					edgeCount++;
				}
			}
		}

		for (i= 0; i < npolys; ++i) {
			t= i * vertsPerPoly * 2;
			for (j= 0; j < vertsPerPoly; ++j) {
				if (polys[t + j] == RecastConstants.RC_MESH_NULL_IDX)
					break;
				v0= polys[t + j];
				v1= (j + 1>= vertsPerPoly || polys[t + j + 1] == RecastConstants.RC_MESH_NULL_IDX) ? polys[t + 0]
						: polys[t + j + 1];
				if (v0 > v1) {
					for (var e:int= firstEdge[v1]; e != RecastConstants.RC_MESH_NULL_IDX; e = firstEdge[nextEdge + e]) {
						edge= edges[e];
						if (edge.vert[1] == v0 && edge.poly[0] == edge.poly[1]) {
							edge.poly[1] = i;
							edge.polyEdge[1] = j;
							break;
						}
					}
				}
			}
		}

		// Store adjacency
		for (i= 0; i < edgeCount; ++i) {
			var e2:Edge= edges[i];
			if (e2.poly[0] != e2.poly[1]) {
				var p0:int= e2.poly[0] * vertsPerPoly * 2;
				var p1:int= e2.poly[1] * vertsPerPoly * 2;
				polys[p0 + vertsPerPoly + e2.polyEdge[0]] = e2.poly[1];
				polys[p1 + vertsPerPoly + e2.polyEdge[1]] = e2.poly[0];
			}
		}

	}

	private static function computeVertexHash(x:int, y:int, z:int):int {
		var h1:int= 0x8da6b343; // Large multiplicative constants;
		var h2:int= 0xd8163841; // here arbitrarily chosen primes
		var h3:int= 0xcb1ab31;
		var n:int= h1 * x + h2 * y + h3 * z;
		return n & (VERTEX_BUCKET_COUNT - 1);
	}

	private static function addVertex( x:int,  y:int,  z:int,  verts:Array,  firstVert:Array,  nextVert:Array,  nv:int):Array {
		var bucket:int= computeVertexHash(x, 0, z);
		var i:int= firstVert[bucket];

		while (i != -1) {
			v= i * 3;
			if (verts[v + 0] == x && (Math.abs(verts[v + 1] - y) <= 2) && verts[v + 2] == z)
				return [ i, nv ];
			i = nextVert[i]; // next
		}

		// Could not find, create new.
		i = nv;
		nv++;
		var v:int= i * 3;
		verts[v + 0] = x;
		verts[v + 1] = y;
		verts[v + 2] = z;
		nextVert[i] = firstVert[bucket];
		firstVert[bucket] = i;

		return [ i, nv ];
	}

	public static function prev(i:int, n:int):int {
		return i - 1>= 0? i - 1: n - 1;
	}

	public static function next(i:int, n:int):int {
		return i + 1< n ? i + 1: 0;
	}

	private static function area2(verts:Array, a:int, b:int, c:int):int {
		return (verts[b + 0] - verts[a + 0]) * (verts[c + 2] - verts[a + 2])
				- (verts[c + 0] - verts[a + 0]) * (verts[b + 2] - verts[a + 2]);
	}

	// Returns true iff c is strictly to the left of the directed
	// line through a to b.
	public static function left(verts:Array, a:int, b:int, c:int):Boolean {
		return area2(verts, a, b, c) < 0;
	}

	public static function leftOn(verts:Array, a:int, b:int, c:int):Boolean {
		return area2(verts, a, b, c) <= 0;
	}

	private static function collinear(verts:Array, a:int, b:int, c:int):Boolean {
		return area2(verts, a, b, c) == 0;
	}

	// Returns true iff ab properly intersects cd: they share
	// a point interior to both segments. The properness of the
	// intersection is ensured by using strict leftness.
	private static function intersectProp(verts:Array, a:int, b:int, c:int, d:int):Boolean {
		// Eliminate improper cases.
		if (collinear(verts, a, b, c) || collinear(verts, a, b, d) || collinear(verts, c, d, a)
				|| collinear(verts, c, d, b))
			return false;

		return Boolean((int(left(verts, a, b, c)) ^ int(left(verts, a, b, d))) && (int(left(verts, c, d, a)) ^ int(left(verts, c, d, b))));
	}

	// Returns T iff (a,b,c) are collinear and point c lies
	// on the closed segement ab.
	private static function between(verts:Array, a:int, b:int, c:int):Boolean {
		if (!collinear(verts, a, b, c))
			return false;
		// If ab not vertical, check betweenness on x; else on y.
		if (verts[a + 0] != verts[b + 0])
			return ((verts[a + 0] <= verts[c + 0]) && (verts[c + 0] <= verts[b + 0]))
					|| ((verts[a + 0] >= verts[c + 0]) && (verts[c + 0] >= verts[b + 0]));
		else
			return ((verts[a + 2] <= verts[c + 2]) && (verts[c + 2] <= verts[b + 2]))
					|| ((verts[a + 2] >= verts[c + 2]) && (verts[c + 2] >= verts[b + 2]));
	}

	// Returns true iff segments ab and cd intersect, properly or improperly.
	public static function intersect(verts:Array, a:int, b:int, c:int, d:int):Boolean {
		if (intersectProp(verts, a, b, c, d))
			return true;
		else if (between(verts, a, b, c) || between(verts, a, b, d) || between(verts, c, d, a)
				|| between(verts, c, d, b))
			return true;
		else
			return false;
	}

	public static function vequal(verts:Array, a:int, b:int):Boolean {
		return verts[a + 0] == verts[b + 0] && verts[a + 2] == verts[b + 2];
	}

	// Returns T iff (v_i, v_j) is a proper internal *or* external
	// diagonal of P, *ignoring edges incident to v_i and v_j*.
	private static function diagonalie(i:int, j:int, n:int, verts:Array, indices:Array):Boolean {
		var d0:int= (indices[i] & 0x0) * 4;
		var d1:int= (indices[j] & 0x0) * 4;

		// For each edge (k,k+1) of P
		for (var k:int= 0; k < n; k++) {
			var k1:int= next(k, n);
			// Skip edges incident to i or j
			if (!((k == i) || (k1 == i) || (k == j) || (k1 == j))) {
				var p0:int= (indices[k] & 0x0) * 4;
				var p1:int= (indices[k1] & 0x0) * 4;

				if (vequal(verts, d0, p0) || vequal(verts, d1, p0) || vequal(verts, d0, p1) || vequal(verts, d1, p1))
					continue;

				if (intersect(verts, d0, d1, p0, p1))
					return false;
			}
		}
		return true;
	}

	// Returns true iff the diagonal (i,j) is strictly internal to the
	// polygon P in the neighborhood of the i endpoint.
	private static function inCone(i:int, j:int, n:int, verts:Array, indices:Array):Boolean {
		var pi:int= (indices[i] & 0x0) * 4;
		var pj:int= (indices[j] & 0x0) * 4;
		var pi1:int= (indices[next(i, n)] & 0x0) * 4;
		var pin1:int= (indices[prev(i, n)] & 0x0) * 4;
		// If P[i] is a convex vertex [ i+1 left or on (i-1,i) ].
		if (leftOn(verts, pin1, pi, pi1)) {
			return left(verts, pi, pj, pin1) && left(verts, pj, pi, pi1);
		}
		// Assume (i-1,i,i+1) not collinear.
		// else P[i] is reflex.
		return !(leftOn(verts, pi, pj, pi1) && leftOn(verts, pj, pi, pin1));
	}

	// Returns T iff (v_i, v_j) is a proper internal
	// diagonal of P.
	private static function diagonal(i:int, j:int, n:int, verts:Array, indices:Array):Boolean {
		return inCone(i, j, n, verts, indices) && diagonalie(i, j, n, verts, indices);
	}

	private static function diagonalieLoose(i:int, j:int, n:int, verts:Array, indices:Array):Boolean {
		var d0:int= (indices[i] & 0x0) * 4;
		var d1:int= (indices[j] & 0x0) * 4;

		// For each edge (k,k+1) of P
		for (var k:int= 0; k < n; k++) {
			var k1:int= next(k, n);
			// Skip edges incident to i or j
			if (!((k == i) || (k1 == i) || (k == j) || (k1 == j))) {
				var p0:int= (indices[k] & 0x0) * 4;
				var p1:int= (indices[k1] & 0x0) * 4;

				if (vequal(verts, d0, p0) || vequal(verts, d1, p0) || vequal(verts, d0, p1) || vequal(verts, d1, p1))
					continue;

				if (intersectProp(verts, d0, d1, p0, p1))
					return false;
			}
		}
		return true;
	}

	private static function inConeLoose(i:int, j:int, n:int, verts:Array, indices:Array):Boolean {
		var pi:int= (indices[i] & 0x0) * 4;
		var pj:int= (indices[j] & 0x0) * 4;
		var pi1:int= (indices[next(i, n)] & 0x0) * 4;
		var pin1:int= (indices[prev(i, n)] & 0x0) * 4;

		// If P[i] is a convex vertex [ i+1 left or on (i-1,i) ].
		if (leftOn(verts, pin1, pi, pi1))
			return leftOn(verts, pi, pj, pin1) && leftOn(verts, pj, pi, pi1);
		// Assume (i-1,i,i+1) not collinear.
		// else P[i] is reflex.
		return !(leftOn(verts, pi, pj, pi1) && leftOn(verts, pj, pi, pin1));
	}

	private static function diagonalLoose(i:int, j:int, n:int, verts:Array, indices:Array):Boolean {
		return inConeLoose(i, j, n, verts, indices) && diagonalieLoose(i, j, n, verts, indices);
	}

	private static function triangulate(n:int, verts:Array, indices:Array, tris:Array):int {
		var ntris:int= 0;

		// The last bit of the index is used to indicate if the vertex can be removed.
		for (var i:int= 0; i < n; i++) {
			var i1:int= next(i, n);
			var i2:int= next(i1, n);
			if (diagonal(i, i2, n, verts, indices)) {
				indices[i1] |= 0x80000000;
			}
		}

		while (n > 3) {
			var minLen:int= -1;
			var mini:int= -1;
			for (i= 0; i < n; i++) {
				i1= next(i, n);
				if ((indices[i1] & 0x80000000) != 0) {
					var p0:int= (indices[i] & 0x0) * 4;
					var p2:int= (indices[next(i1, n)] & 0x0) * 4;

					var dx:int= verts[p2 + 0] - verts[p0 + 0];
					var dy:int= verts[p2 + 2] - verts[p0 + 2];
					var len:int= dx * dx + dy * dy;

					if (minLen < 0|| len < minLen) {
						minLen = len;
						mini = i;
					}
				}
			}

			if (mini == -1) {
				// We might get here because the contour has overlapping segments, like this:
				//
				// A o-o=====o---o B
				// / |C D| \
				// o o o o
				// : : : :
				// We'll try to recover by loosing up the inCone test a bit so that a diagonal
				// like A-B or C-D can be found and we can continue.
				minLen = -1;
				mini = -1;
				for (i= 0; i < n; i++) {
					i1= next(i, n);
					i2= next(i1, n);
					if (diagonalLoose(i, i2, n, verts, indices)) {
						p0= (indices[i] & 0x0) * 4;
						p2= (indices[next(i2, n)] & 0x0) * 4;
						dx= verts[p2 + 0] - verts[p0 + 0];
						dy= verts[p2 + 2] - verts[p0 + 2];
						len= dx * dx + dy * dy;

						if (minLen < 0|| len < minLen) {
							minLen = len;
							mini = i;
						}
					}
				}
				if (mini == -1) {
					// The contour is messed up. This sometimes happens
					// if the contour simplification is too aggressive.
					return -ntris;
				}
			}

			i= mini;
			i1= next(i, n);
			i2= next(i1, n);

			tris[ntris * 3] = indices[i] & 0x0;
			tris[ntris * 3+ 1] = indices[i1] & 0x0;
			tris[ntris * 3+ 2] = indices[i2] & 0x0;
			ntris++;

			// Removes P[i1] by copying P[i+1]...P[n-1] left one index.
			n--;
			for (var k:int= i1; k < n; k++)
				indices[k] = indices[k + 1];

			if (i1 >= n)
				i1 = 0;
			i = prev(i1, n);
			// Update diagonal flags.
			if (diagonal(prev(i, n), i1, n, verts, indices))
				indices[i] |= 0x80000000;
			else
				indices[i] &= 0x0;

			if (diagonal(i, next(i1, n), n, verts, indices))
				indices[i1] |= 0x80000000;
			else
				indices[i1] &= 0x0;
		}

		// Append the remaining triangle.
		tris[ntris * 3] = indices[0] & 0x0;
		tris[ntris * 3+ 1] = indices[1] & 0x0;
		tris[ntris * 3+ 2] = indices[2] & 0x0;
		ntris++;

		return ntris;
	}

	private static function countPolyVerts(p:Array, j:int, nvp:int):int {
		for (var i:int= 0; i < nvp; ++i)
			if (p[i + j] == RecastConstants.RC_MESH_NULL_IDX)
				return i;
		return nvp;
	}

	private static function uleft(verts:Array, a:int, b:int, c:int):Boolean {
		return (verts[b + 0] - verts[a + 0]) * (verts[c + 2] - verts[a + 2])
				- (verts[c + 0] - verts[a + 0]) * (verts[b + 2] - verts[a + 2]) < 0;
	}

	private static function getPolyMergeValue( polys:Array,  pa:int,  pb:int,  verts:Array,  nvp:int):Array {
		var ea:int= -1;
		var eb:int= -1;
		var na:int= countPolyVerts(polys, pa, nvp);
		var nb:int= countPolyVerts(polys, pb, nvp);

		// If the merged polygon would be too big, do not merge.
		if (na + nb - 2> nvp)
			return new [ -1, ea, eb ];

		// Check if the polygons share an edge.

		for (var i:int= 0; i < na; ++i) {
			var va0:int= polys[pa + i];
			var va1:int= polys[pa + (i + 1) % na];
			if (va0 > va1) {
				var temp:int= va0;
				va0 = va1;
				va1 = temp;
			}
			for (var j:int= 0; j < nb; ++j) {
				var vb0:int= polys[pb + j];
				var vb1:int= polys[pb + (j + 1) % nb];
				if (vb0 > vb1) {
					temp= vb0;
					vb0 = vb1;
					vb1 = temp;
				}
				if (va0 == vb0 && va1 == vb1) {
					ea = i;
					eb = j;
					break;
				}
			}
		}

		// No common edge, cannot merge.
		if (ea == -1|| eb == -1)
			return [ -1, ea, eb ];

		// Check to see if the merged polygon would be convex.
		var va:int, vb:int, vc:int;

		va = polys[pa + (ea + na - 1) % na];
		vb = polys[pa + ea];
		vc = polys[pb + (eb + 2) % nb];
		if (!uleft(verts, va * 3, vb * 3, vc * 3))
			return [ -1, ea, eb ];

		va = polys[pb + (eb + nb - 1) % nb];
		vb = polys[pb + eb];
		vc = polys[pa + (ea + 2) % na];
		if (!uleft(verts, va * 3, vb * 3, vc * 3))
			return [ -1, ea, eb ];

		va = polys[pa + ea];
		vb = polys[pa + (ea + 1) % na];

		var dx:int= verts[va * 3+ 0] - verts[vb * 3+ 0];
		var dy:int= verts[va * 3+ 2] - verts[vb * 3+ 2];

		return [ dx * dx + dy * dy, ea, eb ];
	}

	private static function mergePolys(polys:Array, pa:int, pb:int, ea:int, eb:int, tmp:int, nvp:int):void {
		var na:int= countPolyVerts(polys, pa, nvp);
		var nb:int= countPolyVerts(polys, pb, nvp);

		// Merge polygons.
		Arrays.fill(polys, tmp, tmp + nvp, RecastConstants.RC_MESH_NULL_IDX);
		var n:int= 0;
		// Add pa
		for (var i:int= 0; i < na - 1; ++i) {
			polys[tmp + n] = polys[pa + (ea + 1+ i) % na];
			n++;
		}
		// Add pb
		for (i= 0; i < nb - 1; ++i) {
			polys[tmp + n] = polys[pb + (eb + 1+ i) % nb];
			n++;
		}
		System.arraycopy(polys, tmp, polys, pa, nvp);
	}

	private static function pushFront(v:int, arr:Array, an:int):int {
		an++;
		for (var i:int= an - 1; i > 0; --i)
			arr[i] = arr[i - 1];
		arr[0] = v;
		return an;
	}

	private static function pushBack(v:int, arr:Array, an:int):int {
		arr[an] = v;
		an++;
		return an;
	}

	private static function canRemoveVertex(ctx:Context, mesh:PolyMesh, rem:int):Boolean {
		var nvp:int= mesh.nvp;

		// Count number of polygons to remove.
		var numTouchedVerts:int= 0;
		var numRemainingEdges:int= 0;
		for (var i:int= 0; i < mesh.npolys; ++i) {
			var p:int= i * nvp * 2;
			var nv:int= countPolyVerts(mesh.polys, p, nvp);
			var numRemoved:int= 0;
			var numVerts:int= 0;
			for (var j:int= 0; j < nv; ++j) {
				if (mesh.polys[p + j] == rem) {
					numTouchedVerts++;
					numRemoved++;
				}
				numVerts++;
			}
			if (numRemoved != 0) {
				numRemainingEdges += numVerts - (numRemoved + 1);
			}
		}
		// There would be too few edges remaining to create a polygon.
		// This can happen for example when a tip of a triangle is marked
		// as deletion, but there are no other polys that share the vertex.
		// In this case, the vertex should not be removed.
		if (numRemainingEdges <= 2)
			return false;

		// Find edges which share the removed vertex.
		var maxEdges:int= numTouchedVerts * 2;
		var nedges:int= 0;
		var edges:Array= []//maxEdges * 3];

		for (i= 0; i < mesh.npolys; ++i) {
			p= i * nvp * 2;
			nv= countPolyVerts(mesh.polys, p, nvp);

			// Collect edges which touches the removed vertex.
			var k:int;
			for (j= 0, k = nv - 1; j < nv; k = j++) {
				if (mesh.polys[p + j] == rem || mesh.polys[p + k] == rem) {
					// Arrange edge so that a=rem.
					var a:int= mesh.polys[p + j], b:int = mesh.polys[p + k];
					if (b == rem) {
						var temp:int= a;
						a = b;
						b = temp;
					}
					// Check if the edge exists
					var exists:Boolean= false;
					for (var m:int= 0; m < nedges; ++m) {
						var e:int= m * 3;
						if (edges[e + 1] == b) {
							// Exists, increment vertex share count.
							edges[e + 2]++;
							exists = true;
						}
					}
					// Add new edge.
					if (!exists) {
						e= nedges * 3;
						edges[e + 0] = a;
						edges[e + 1] = b;
						edges[e + 2] = 1;
						nedges++;
					}
				}
			}
		}

		// There should be no more than 2 open edges.
		// This catches the case that two non-adjacent polygons
		// share the removed vertex. In that case, do not remove the vertex.
		var numOpenEdges:int= 0;
		for (i= 0; i < nedges; ++i) {
			if (edges[i * 3+ 2] < 2)
				numOpenEdges++;
		}
		if (numOpenEdges > 2)
			return false;

		return true;
	}

	private static function removeVertex(ctx:Context, mesh:PolyMesh, rem:int, maxTris:int):void {
		var nvp:int= mesh.nvp;

		// Count number of polygons to remove.
		var numRemovedVerts:int= 0;
		for (var i:int= 0; i < mesh.npolys; ++i) {
			var p:int= i * nvp * 2;
			var nv:int= countPolyVerts(mesh.polys, p, nvp);
			for (j= 0; j < nv; ++j) {
				if (mesh.polys[p + j] == rem)
					numRemovedVerts++;
			}
		}

		var nedges:int= 0;
		var edges:Array= []//numRemovedVerts * nvp * 4];

		var nhole:int= 0;
		var hole:Array= []//numRemovedVerts * nvp];

		var nhreg:int= 0;
		var hreg:Array= []//numRemovedVerts * nvp];

		var nharea:int= 0;
		var harea:Array= []//numRemovedVerts * nvp];

		for (i= 0; i < mesh.npolys; ++i) {
			p= i * nvp * 2;
			nv= countPolyVerts(mesh.polys, p, nvp);
			var hasRem:Boolean= false;
			for (j= 0; j < nv; ++j)
				if (mesh.polys[p + j] == rem)
					hasRem = true;
			if (hasRem) {
				// Collect edges which does not touch the removed vertex.
				for (j= 0, k = nv - 1; j < nv; k = j++) {
					if (mesh.polys[p + j] != rem && mesh.polys[p + k] != rem) {
						var e:int= nedges * 4;
						edges[e + 0] = mesh.polys[p + k];
						edges[e + 1] = mesh.polys[p + j];
						edges[e + 2] = mesh.regs[i];
						edges[e + 3] = mesh.areas[i];
						nedges++;
					}
				}
				// Remove the polygon.
				var p2:int= (mesh.npolys - 1) * nvp * 2;
				if (p != p2) {
					System.arraycopy(mesh.polys, p2, mesh.polys, p, nvp);
				}
				Arrays.fill(mesh.polys, p + nvp, p + nvp + nvp, RecastConstants.RC_MESH_NULL_IDX);
				mesh.regs[i] = mesh.regs[mesh.npolys - 1];
				mesh.areas[i] = mesh.areas[mesh.npolys - 1];
				mesh.npolys--;
				--i;
			}
		}

		// Remove vertex.
		for (i= rem; i < mesh.nverts - 1; ++i) {
			mesh.verts[i * 3+ 0] = mesh.verts[(i + 1) * 3+ 0];
			mesh.verts[i * 3+ 1] = mesh.verts[(i + 1) * 3+ 1];
			mesh.verts[i * 3+ 2] = mesh.verts[(i + 1) * 3+ 2];
		}
		mesh.nverts--;

		// Adjust indices to match the removed vertex layout.
		for (i= 0; i < mesh.npolys; ++i) {
			p= i * nvp * 2;
			nv= countPolyVerts(mesh.polys, p, nvp);
			for (j= 0; j < nv; ++j)
				if (mesh.polys[p + j] > rem)
					mesh.polys[p + j]--;
		}
		for (i= 0; i < nedges; ++i) {
			if (edges[i * 4+ 0] > rem)
				edges[i * 4+ 0]--;
			if (edges[i * 4+ 1] > rem)
				edges[i * 4+ 1]--;
		}

		if (nedges == 0)
			return;

		// Start with one vertex, keep appending connected
		// segments to the start and end of the hole.
		pushBack(edges[0], hole, nhole);
		pushBack(edges[2], hreg, nhreg);
		pushBack(edges[3], harea, nharea);

		while (nedges != 0) {
			var match:Boolean= false;

			for (i= 0; i < nedges; ++i) {
				var ea:int= edges[i * 4+ 0];
				var eb:int= edges[i * 4+ 1];
				var r:int= edges[i * 4+ 2];
				var a:int= edges[i * 4+ 3];
				var add:Boolean= false;
				if (hole[0] == eb) {
					// The segment matches the beginning of the hole boundary.
					pushFront(ea, hole, nhole);
					pushFront(r, hreg, nhreg);
					pushFront(a, harea, nharea);
					add = true;
				} else if (hole[nhole - 1] == ea) {
					// The segment matches the end of the hole boundary.
					nhole = pushBack(eb, hole, nhole);
					nhreg = pushBack(r, hreg, nhreg);
					nharea = pushBack(a, harea, nharea);
					add = true;
				}
				if (add) {
					// The edge segment was added, remove it.
					edges[i * 4+ 0] = edges[(nedges - 1) * 4+ 0];
					edges[i * 4+ 1] = edges[(nedges - 1) * 4+ 1];
					edges[i * 4+ 2] = edges[(nedges - 1) * 4+ 2];
					edges[i * 4+ 3] = edges[(nedges - 1) * 4+ 3];
					--nedges;
					match = true;
					--i;
				}
			}

			if (!match)
				break;
		}

		var tris:Array= []//nhole * 3];

		var tverts:Array= []//nhole * 4];

		var thole:Array= []//nhole];

		// Generate temp vertex array for triangulation.
		for (i= 0; i < nhole; ++i) {
			var pi:int= hole[i];
			tverts[i * 4+ 0] = mesh.verts[pi * 3+ 0];
			tverts[i * 4+ 1] = mesh.verts[pi * 3+ 1];
			tverts[i * 4+ 2] = mesh.verts[pi * 3+ 2];
			tverts[i * 4+ 3] = 0;
			thole[i] = i;
		}

		// Triangulate the hole.
		var ntris:int= triangulate(nhole, tverts, thole, tris);
		if (ntris < 0) {
			ntris = -ntris;
			ctx.warn("removeVertex: triangulate() returned bad results.");
		}

		// Merge the hole triangles back to polygons.
		var polys:Array= []//(ntris + 1) * nvp];
		var pregs:Array= []//ntris];
		var pareas:Array= []//ntris];

		var tmpPoly:int= ntris * nvp;

		// Build initial polygons.
		var npolys:int= 0;
		Arrays.fill(polys, 0, ntris * nvp, RecastConstants.RC_MESH_NULL_IDX);
		for (var j:int= 0; j < ntris; ++j) {
			var t:int= j * 3;
			if (tris[t + 0] != tris[t + 1] && tris[t + 0] != tris[t + 2] && tris[t + 1] != tris[t + 2]) {
				polys[npolys * nvp + 0] = hole[tris[t + 0]];
				polys[npolys * nvp + 1] = hole[tris[t + 1]];
				polys[npolys * nvp + 2] = hole[tris[t + 2]];
				pregs[npolys] = hreg[tris[t + 0]];
				pareas[npolys] = harea[tris[t + 0]];
				npolys++;
			}
		}
		if (npolys == 0)
			return;

		// Merge polygons.
		if (nvp > 3) {
			for (;;) {
				// Find best polygons to merge.
				var bestMergeVal:int= 0;
				var bestPa:int= 0, bestPb:int = 0, bestEa:int = 0, bestEb:int = 0;

				for (j= 0; j < npolys - 1; ++j) {
					var pj:int= j * nvp;
					for (var k:int= j + 1; k < npolys; ++k) {
						var pk:int= k * nvp;
						var veaeb:Array= getPolyMergeValue(polys, pj, pk, mesh.verts, nvp);
						var v:int= veaeb[0];
						ea= veaeb[1];
						eb= veaeb[2];
						if (v > bestMergeVal) {
							bestMergeVal = v;
							bestPa = j;
							bestPb = k;
							bestEa = ea;
							bestEb = eb;
						}
					}
				}

				if (bestMergeVal > 0) {
					// Found best, merge.
					var pa:int= bestPa * nvp;
					var pb:int= bestPb * nvp;
					mergePolys(polys, pa, pb, bestEa, bestEb, tmpPoly, nvp);
					var last:int= (npolys - 1) * nvp;
					if (pb != last) {
						System.arraycopy(polys, last, polys, pb, nvp);
					}
					pregs[bestPb] = pregs[npolys - 1];
					pareas[bestPb] = pareas[npolys - 1];
					npolys--;
				} else {
					// Could not merge any polygons, stop.
					break;
				}
			}
		}

		// Store polygons.
		for (i= 0; i < npolys; ++i) {
			if (mesh.npolys >= maxTris)
				break;
			p= mesh.npolys * nvp * 2;
			Arrays.fill(mesh.polys, p, p + nvp * 2, RecastConstants.RC_MESH_NULL_IDX);
			for (j= 0; j < nvp; ++j)
				mesh.polys[p + j] = polys[i * nvp + j];
			mesh.regs[mesh.npolys] = pregs[i];
			mesh.areas[mesh.npolys] = pareas[i];
			mesh.npolys++;
			if (mesh.npolys > maxTris) {
				throw ("removeVertex: Too many polygons " + mesh.npolys + " (max:" + maxTris + ".");
			}
		}

	}

	/// @par
	///
	/// @note If the mesh data is to be used to construct a Detour navigation mesh, then the upper
	/// limit must be retricted to <= #DT_VERTS_PER_POLYGON.
	///
	/// @see rcAllocPolyMesh, rcContourSet, rcPolyMesh, rcConfig
	public static function buildPolyMesh(ctx:Context, cset:ContourSet, nvp:int):PolyMesh {
		ctx.startTimer("BUILD_POLYMESH");
		var mesh:PolyMesh= new PolyMesh();
		RecastVectors.copy(mesh.bmin, cset.bmin, 0);
		RecastVectors.copy(mesh.bmax, cset.bmax, 0);
		mesh.cs = cset.cs;
		mesh.ch = cset.ch;
		mesh.borderSize = cset.borderSize;

		var maxVertices:int= 0;
		var maxTris:int= 0;
		var maxVertsPerCont:int= 0;
		for (var i:int= 0; i < cset.conts.length; ++i) {
			// Skip null contours.
			if (cset.conts[i].nverts < 3)
				continue;
			maxVertices += cset.conts[i].nverts;
			maxTris += cset.conts[i].nverts - 2;
			maxVertsPerCont = Math.max(maxVertsPerCont, cset.conts[i].nverts);
		}
		if (maxVertices >= 0xe) {
			throw ("rcBuildPolyMesh: Too many vertices " + maxVertices);
		}
		var vflags:Array = [];// []//maxVertices];

		mesh.verts = [];// []//maxVertices * 3];
		mesh.polys = [];// []//maxTris * nvp * 2];
		Arrays.fill2(mesh.polys, RecastConstants.RC_MESH_NULL_IDX);
		mesh.regs = [];// []//maxTris];
		mesh.areas = [];// []//maxTris];

		mesh.nverts = 0;
		mesh.npolys = 0;
		mesh.nvp = nvp;
		mesh.maxpolys = maxTris;

		var nextVert:Array= []//[]//maxVertices];

		var firstVert:Array= []//[]//VERTEX_BUCKET_COUNT];
		for (i= 0; i < VERTEX_BUCKET_COUNT; ++i)
			firstVert[i] = -1;

		var indices:Array= []//maxVertsPerCont];
		var tris:Array= []//maxVertsPerCont * 3];
		var polys:Array= []//(maxVertsPerCont + 1) * nvp];

		var tmpPoly:int= maxVertsPerCont * nvp;

		for (i= 0; i < cset.conts.length; ++i) {
			var cont:Contour= cset.conts[i];

			// Skip null contours.
			if (cont.nverts < 3)
				continue;

			// Triangulate contour
			for (var j:int= 0; j < cont.nverts; ++j)
				indices[j] = j;
			var ntris:int= triangulate(cont.nverts, cont.verts, indices, tris);
			if (ntris <= 0) {
				// Bad triangulation, should not happen.
				ctx.warn("buildPolyMesh: Bad triangulation Contour " + i + ".");
				ntris = -ntris;
			}

			// Add and merge vertices.
			for (j= 0; j < cont.nverts; ++j) {
				var v:int= j * 4;
				var inv:Array= addVertex(cont.verts[v + 0], cont.verts[v + 1], cont.verts[v + 2], mesh.verts, firstVert,
						nextVert, mesh.nverts);
				indices[j] = inv[0];
				mesh.nverts = inv[1];
				if ((cont.verts[v + 3] & RecastConstants.RC_BORDER_VERTEX) != 0) {
					// This vertex should be removed.
					vflags[indices[j]] = 1;
				}
			}

			// Build initial polygons.
			var npolys:int= 0;
			Arrays.fill2(polys, RecastConstants.RC_MESH_NULL_IDX);
			for (j= 0; j < ntris; ++j) {
				var t:int= j * 3;
				if (tris[t + 0] != tris[t + 1] && tris[t + 0] != tris[t + 2] && tris[t + 1] != tris[t + 2]) {
					polys[npolys * nvp + 0] = indices[tris[t + 0]];
					polys[npolys * nvp + 1] = indices[tris[t + 1]];
					polys[npolys * nvp + 2] = indices[tris[t + 2]];
					npolys++;
				}
			}
			if (npolys == 0)
				continue;

			// Merge polygons.
			if (nvp > 3) {
				for (;;) {
					// Find best polygons to merge.
					var bestMergeVal:int= 0;
					var bestPa:int= 0, bestPb:int = 0, bestEa:int = 0, bestEb:int = 0;

					for (j= 0; j < npolys - 1; ++j) {
						var pj:int= j * nvp;
						for (var k:int= j + 1; k < npolys; ++k) {
							var pk:int= k * nvp;
							var veaeb:Array= getPolyMergeValue(polys, pj, pk, mesh.verts, nvp);
							v= veaeb[0];
							var ea:int= veaeb[1];
							var eb:int= veaeb[2];
							if (v > bestMergeVal) {
								bestMergeVal = v;
								bestPa = j;
								bestPb = k;
								bestEa = ea;
								bestEb = eb;
							}
						}
					}

					if (bestMergeVal > 0) {
						// Found best, merge.
						var pa:int= bestPa * nvp;
						var pb:int= bestPb * nvp;
						mergePolys(polys, pa, pb, bestEa, bestEb, tmpPoly, nvp);
						var lastPoly:int= (npolys - 1) * nvp;
						if (pb != lastPoly) {
							System.arraycopy(polys, lastPoly, polys, pb, nvp);
						}
						npolys--;
					} else {
						// Could not merge any polygons, stop.
						break;
					}
				}
			}

			// Store polygons.
			for (j= 0; j < npolys; ++j) {
				var p:int= mesh.npolys * nvp * 2;
				var q:int= j * nvp;
				for (k= 0; k < nvp; ++k)
					mesh.polys[p + k] = polys[q + k];
				mesh.regs[mesh.npolys] = cont.reg;
				mesh.areas[mesh.npolys] = cont.area;
				mesh.npolys++;
				if (mesh.npolys > maxTris) {
					throw (
							"rcBuildPolyMesh: Too many polygons " + mesh.npolys + " (max:" + maxTris + ").");
				}
			}
		}

		// Remove edge vertices.
		for (i= 0; i < mesh.nverts; ++i) {
			if (vflags[i] != 0) {
				if (!canRemoveVertex(ctx, mesh, i))
					continue;
				removeVertex(ctx, mesh, i, maxTris);
				// Remove vertex
				// Note: mesh.nverts is already decremented inside removeVertex()!
				// Fixup vertex flags
				for (j= i; j < mesh.nverts; ++j)
					vflags[j] = vflags[j + 1];
				--i;
			}
		}

		// Calculate adjacency.
		buildMeshAdjacency(mesh.polys, mesh.npolys, mesh.nverts, nvp);

		// Find portal edges
		if (mesh.borderSize > 0) {
			var w:int= cset.width;
			var h:int= cset.height;
			for (i= 0; i < mesh.npolys; ++i) {
				p= i * 2* nvp;
				for (j= 0; j < nvp; ++j) {
					if (mesh.polys[p + j] == RecastConstants.RC_MESH_NULL_IDX)
						break;
					// Skip connected edges.
					if (mesh.polys[p + nvp + j] != RecastConstants.RC_MESH_NULL_IDX)
						continue;
					var nj:int= j + 1;
					if (nj >= nvp || mesh.polys[p + nj] == RecastConstants.RC_MESH_NULL_IDX)
						nj = 0;
					var va:int= mesh.polys[p + j] * 3;
					var vb:int= mesh.polys[p + nj] * 3;

					if (mesh.verts[va + 0] == 0&& mesh.verts[vb + 0] == 0)
						mesh.polys[p + nvp + j] = 0x8000| 0;
					else if (mesh.verts[va + 2] == h && mesh.verts[vb + 2] == h)
						mesh.polys[p + nvp + j] = 0x8000| 1;
					else if (mesh.verts[va + 0] == w && mesh.verts[vb + 0] == w)
						mesh.polys[p + nvp + j] = 0x8000| 2;
					else if (mesh.verts[va + 2] == 0&& mesh.verts[vb + 2] == 0)
						mesh.polys[p + nvp + j] = 0x8000| 3;
				}
			}
		}

		// Just allocate the mesh flags array. The user is resposible to fill it.
		mesh.flags = []//mesh.npolys];

		if (mesh.nverts > 0) {
			throw ("rcBuildPolyMesh: The resulting mesh has too many vertices " + mesh.nverts
					+ " (max " + 0+ "). Data can be corrupted.");
		}
		if (mesh.npolys > 0) {
			throw ("rcBuildPolyMesh: The resulting mesh has too many polygons " + mesh.npolys
					+ " (max " + 0+ "). Data can be corrupted.");
		}

		ctx.stopTimer("BUILD_POLYMESH");
		return mesh;

	}

	/// @see rcAllocPolyMesh, rcPolyMesh
	public static function mergePolyMeshes(ctx:Context, meshes:Array, nmeshes:int):PolyMesh {

		if (nmeshes == 0|| meshes == null)
			return null;

		ctx.startTimer("MERGE_POLYMESH");
		var mesh:PolyMesh= new PolyMesh();
		mesh.nvp = meshes[0].nvp;
		mesh.cs = meshes[0].cs;
		mesh.ch = meshes[0].ch;
		RecastVectors.copy(mesh.bmin, meshes[0].bmin, 0);
		RecastVectors.copy(mesh.bmax, meshes[0].bmax, 0);

		var maxVerts:int= 0;
		var maxPolys:int= 0;
		var maxVertsPerMesh:int= 0;
		for (var i:int= 0; i < nmeshes; ++i) {
			RecastVectors.min(mesh.bmin, meshes[i].bmin, 0);
			RecastVectors.max(mesh.bmax, meshes[i].bmax, 0);
			maxVertsPerMesh = Math.max(maxVertsPerMesh, meshes[i].nverts);
			maxVerts += meshes[i].nverts;
			maxPolys += meshes[i].npolys;
		}

		mesh.nverts = 0;
		mesh.verts = []//maxVerts * 3];

		mesh.npolys = 0;
		mesh.polys = []//maxPolys * 2* mesh.nvp];
		Arrays.fill(mesh.polys, 0, mesh.polys.length, RecastConstants.RC_MESH_NULL_IDX);
		mesh.regs = []//maxPolys];
		mesh.areas = []//maxPolys];
		mesh.flags = []//maxPolys];

		var nextVert:Array= []//maxVerts];

		var firstVert:Array= []//VERTEX_BUCKET_COUNT];
		for (i= 0; i < VERTEX_BUCKET_COUNT; ++i)
			firstVert[i] = -1;

		var vremap:Array= []//maxVertsPerMesh];

		for (i= 0; i < nmeshes; ++i) {
			var pmesh:PolyMesh= meshes[i];

			var ox:int= int(Math.floor((pmesh.bmin[0] - mesh.bmin[0]) / mesh.cs + 0.5));
			var oz:int= int(Math.floor((pmesh.bmin[2] - mesh.bmin[2]) / mesh.cs + 0.5));

			var isMinX:Boolean= (ox == 0);
			var isMinZ:Boolean= (oz == 0);
			var isMaxX:Boolean= (Math.floor((mesh.bmax[0] - pmesh.bmax[0]) / mesh.cs + 0.5)) == 0;
			var isMaxZ:Boolean= (Math.floor((mesh.bmax[2] - pmesh.bmax[2]) / mesh.cs + 0.5)) == 0;
			var isOnBorder:Boolean= (isMinX || isMinZ || isMaxX || isMaxZ);

			for (var j:int= 0; j < pmesh.nverts; ++j) {
				var v:int= j * 3;
				var inv:Array= addVertex(pmesh.verts[v + 0] + ox, pmesh.verts[v + 1], pmesh.verts[v + 2] + oz, mesh.verts,
						firstVert, nextVert, mesh.nverts);

				vremap[j] = inv[0];
				mesh.nverts = inv[1];
			}

			for (j= 0; j < pmesh.npolys; ++j) {
				var tgt:int= mesh.npolys * 2* mesh.nvp;
				var src:int= j * 2* mesh.nvp;
				mesh.regs[mesh.npolys] = pmesh.regs[j];
				mesh.areas[mesh.npolys] = pmesh.areas[j];
				mesh.flags[mesh.npolys] = pmesh.flags[j];
				mesh.npolys++;
				for (var k:int= 0; k < mesh.nvp; ++k) {
					if (pmesh.polys[src + k] == RecastConstants.RC_MESH_NULL_IDX)
						break;
					mesh.polys[tgt + k] = vremap[pmesh.polys[src + k]];
				}

				if (isOnBorder) {
					for (k= mesh.nvp; k < mesh.nvp * 2; ++k) {
						if ((pmesh.polys[src + k] & 0x8000) != 0&& pmesh.polys[src + k] != 0) {
							var dir:int= pmesh.polys[src + k] & 0;
							switch (dir) {
							case 0: // Portal x-
								if (isMinX)
									mesh.polys[tgt + k] = pmesh.polys[src + k];
								break;
							case 1: // Portal z+
								if (isMaxZ)
									mesh.polys[tgt + k] = pmesh.polys[src + k];
								break;
							case 2: // Portal x+
								if (isMaxX)
									mesh.polys[tgt + k] = pmesh.polys[src + k];
								break;
							case 3: // Portal z-
								if (isMinZ)
									mesh.polys[tgt + k] = pmesh.polys[src + k];
								break;
							}
						}
					}
				}
			}
		}

		// Calculate adjacency.
		buildMeshAdjacency(mesh.polys, mesh.npolys, mesh.nverts, mesh.nvp);
		if (mesh.nverts > 0) {
			throw ("rcBuildPolyMesh: The resulting mesh has too many vertices " + mesh.nverts
					+ " (max " + 0+ "). Data can be corrupted.");
		}
		if (mesh.npolys > 0) {
			throw ("rcBuildPolyMesh: The resulting mesh has too many polygons " + mesh.npolys
					+ " (max " + 0+ "). Data can be corrupted.");
		}

		ctx.stopTimer("MERGE_POLYMESH");

		return mesh;
	}

	public static function copyPolyMesh(ctx:Context, src:PolyMesh):PolyMesh {
		var dst:PolyMesh= new PolyMesh();

		dst.nverts = src.nverts;
		dst.npolys = src.npolys;
		dst.maxpolys = src.npolys;
		dst.nvp = src.nvp;
		RecastVectors.copy(dst.bmin, src.bmin, 0);
		RecastVectors.copy(dst.bmax, src.bmax, 0);
		dst.cs = src.cs;
		dst.ch = src.ch;
		dst.borderSize = src.borderSize;

		dst.verts = []//src.nverts * 3];
		System.arraycopy(src.verts, 0, dst.verts, 0, dst.verts.length);
		dst.polys = []//src.npolys * 2* src.nvp];
		System.arraycopy(src.polys, 0, dst.polys, 0, dst.polys.length);
		dst.regs = []//src.npolys];
		System.arraycopy(src.regs, 0, dst.regs, 0, dst.regs.length);
		dst.areas = []//src.npolys];
		System.arraycopy(src.areas, 0, dst.areas, 0, dst.areas.length);
		dst.flags = []//src.npolys];
		System.arraycopy(src.flags, 0, dst.flags, 0, dst.flags.length);
		return dst;
	}
}
}

 class Edge {
	 public var vert:Array = [];
	 public var polyEdge:Array = [];
	 public var poly:Array = [];

	}
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

public class RecastContour {
	private static function getCornerHeight(x:int, y:int, i:int, dir:int, chf:CompactHeightfield, isBorderVertex:Boolean):int {
		var s:CompactSpan= chf.spans[i];
		var ch:int= s.y;
		var dirp:int= (dir + 1) & 0x3;

		var regs:Array = [ 0, 0, 0, 0];

		// Combine region and area codes in order to prevent
		// border vertices which are in between two areas to be removed.
		regs[0] = chf.spans[i].reg | (chf.areas[i] << 16);

		if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
			var ax:int= x + RecastCommon.GetDirOffsetX(dir);
			var ay:int= y + RecastCommon.GetDirOffsetY(dir);
			var ai:int= chf.cells[ax + ay * chf.width].index + RecastCommon.GetCon(s, dir);
			var as_:CompactSpan= chf.spans[ai];
			ch = Math.max(ch, as_.y);
			regs[1] = chf.spans[ai].reg | (chf.areas[ai] << 16);
			if (RecastCommon.GetCon(as_, dirp) != RecastConstants.RC_NOT_CONNECTED) {
				var ax2:int= ax + RecastCommon.GetDirOffsetX(dirp);
				var ay2:int= ay + RecastCommon.GetDirOffsetY(dirp);
				var ai2:int= chf.cells[ax2 + ay2 * chf.width].index + RecastCommon.GetCon(as_, dirp);
				var as2:CompactSpan= chf.spans[ai2];
				ch = Math.max(ch, as2.y);
				regs[2] = chf.spans[ai2].reg | (chf.areas[ai2] << 16);
			}
		}
		if (RecastCommon.GetCon(s, dirp) != RecastConstants.RC_NOT_CONNECTED) {
			ax= x + RecastCommon.GetDirOffsetX(dirp);
			ay= y + RecastCommon.GetDirOffsetY(dirp);
			ai= chf.cells[ax + ay * chf.width].index + RecastCommon.GetCon(s, dirp);
			as_= chf.spans[ai];
			ch = Math.max(ch, as_.y);
			regs[3] = chf.spans[ai].reg | (chf.areas[ai] << 16);
			if (RecastCommon.GetCon(as_, dir) != RecastConstants.RC_NOT_CONNECTED) {
				ax2= ax + RecastCommon.GetDirOffsetX(dir);
				ay2= ay + RecastCommon.GetDirOffsetY(dir);
				ai2= chf.cells[ax2 + ay2 * chf.width].index + RecastCommon.GetCon(as_, dir);
				as2= chf.spans[ai2];
				ch = Math.max(ch, as2.y);
				regs[2] = chf.spans[ai2].reg | (chf.areas[ai2] << 16);
			}
		}

		// Check if the vertex is special edge vertex, these vertices will be removed later.
		for (var j:int= 0; j < 4; ++j) {
			var a:int= j;
			var b:int= (j + 1) & 0x3;
			var c:int= (j + 2) & 0x3;
			var d:int= (j + 3) & 0x3;

			// The vertex is a border vertex there are two same exterior cells in a row,
			// followed by two interior cells and none of the regions are out of bounds.
			var twoSameExts:Boolean= (regs[a] & regs[b] & RecastConstants.RC_BORDER_REG) != 0&& regs[a] == regs[b];
			var twoInts:Boolean= ((regs[c] | regs[d]) & RecastConstants.RC_BORDER_REG) == 0;
			var intsSameArea:Boolean= (regs[c] >> 16) == (regs[d] >> 16);
			var noZeros:Boolean= regs[a] != 0&& regs[b] != 0&& regs[c] != 0&& regs[d] != 0;
			if (twoSameExts && twoInts && intsSameArea && noZeros) {
				isBorderVertex = true;
				break;
			}
		}

		return ch;
	}

	private static function walkContour(x:int, y:int, i:int, chf:CompactHeightfield, flags:Array, points:Array):void {
		// Choose the first non-connected edge
		var dir:int= 0;
		while ((flags[i] & (1<< dir)) == 0)
			dir++;

		var startDir:int= dir;
		var starti:int= i;

		var area:int= chf.areas[i];

		var iter:int= 0;
		while (++iter < 40000) {
			if ((flags[i] & (1<< dir)) != 0) {
				// Choose the edge corner
				var isBorderVertex:Boolean= false;
				var isAreaBorder:Boolean= false;
				var px:int= x;
				var py:int= getCornerHeight(x, y, i, dir, chf, isBorderVertex);
				var pz:int= y;
				switch (dir) {
				case 0:
					pz++;
					break;
				case 1:
					px++;
					pz++;
					break;
				case 2:
					px++;
					break;
				}
				var r:int= 0;
				var s:CompactSpan= chf.spans[i];
				if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
					var ax:int= x + RecastCommon.GetDirOffsetX(dir);
					var ay:int= y + RecastCommon.GetDirOffsetY(dir);
					var ai:int= chf.cells[ax + ay * chf.width].index + RecastCommon.GetCon(s, dir);
					r = chf.spans[ai].reg;
					if (area != chf.areas[ai])
						isAreaBorder = true;
				}
				if (isBorderVertex)
					r |= RecastConstants.RC_BORDER_VERTEX;
				if (isAreaBorder)
					r |= RecastConstants.RC_AREA_BORDER;
				points.push(px);
				points.push(py);
				points.push(pz);
				points.push(r);

				flags[i] &= ~(1<< dir); // Remove visited edges
				dir = (dir + 1) & 0x3; // Rotate CW
			} else {
				var ni:int= -1;
				var nx:int= x + RecastCommon.GetDirOffsetX(dir);
				var ny:int= y + RecastCommon.GetDirOffsetY(dir);
				s= chf.spans[i];
				if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
					var nc:CompactCell= chf.cells[nx + ny * chf.width];
					ni = nc.index + RecastCommon.GetCon(s, dir);
				}
				if (ni == -1) {
					// Should not happen.
					return;
				}
				x = nx;
				y = ny;
				i = ni;
				dir = (dir + 3) & 0x3; // Rotate CCW
			}

			if (starti == i && startDir == dir) {
				break;
			}
		}
	}

	private static function distancePtSeg(x:int, z:int, px:int, pz:int, qx:int, qz:int):Number {
		var pqx:Number= qx - px;
		var pqz:Number= qz - pz;
		var dx:Number= x - px;
		var dz:Number= z - pz;
		var d:Number= pqx * pqx + pqz * pqz;
		var t:Number= pqx * dx + pqz * dz;
		if (d > 0)
			t /= d;
		if (t < 0)
			t = 0;
		else if (t > 1)
			t = 1;

		dx = px + t * pqx - x;
		dz = pz + t * pqz - z;

		return dx * dx + dz * dz;
	}

	private static function simplifyContour(points:Array,simplified:Array, maxError:Number, maxEdgeLen:int,
			buildFlags:int):void {
		// Add initial points.
		var hasConnections:Boolean= false;
		for (var i:int= 0; i < points.length; i += 4) {
			if ((points[i + 3] & RecastConstants.RC_CONTOUR_REG_MASK) != 0) {
				hasConnections = true;
				break;
			}
		}

		if (hasConnections) {
			// The contour has some portals to other regions.
			// Add a new point to every location where the region changes.
			var ni:int;
			for (i= 0, ni = points.length / 4; i < ni; ++i) {
				var ii:int= (i + 1) % ni;
				var differentRegs:Boolean= (points[i * 4+ 3]
						& RecastConstants.RC_CONTOUR_REG_MASK) != (points[ii * 4+ 3]
								& RecastConstants.RC_CONTOUR_REG_MASK);
				var areaBorders:Boolean= (points[i * 4+ 3]
						& RecastConstants.RC_AREA_BORDER) != (points[ii * 4+ 3] & RecastConstants.RC_AREA_BORDER);
				if (differentRegs || areaBorders) {
					simplified.push(points[i * 4+ 0]);
					simplified.push(points[i * 4+ 1]);
					simplified.push(points[i * 4+ 2]);
					simplified.push(i);
				}
			}
		}

		if (simplified.length == 0) {
			// If there is no connections at all,
			// create some initial points for the simplification process.
			// Find lower-left and upper-right vertices of the contour.
			var llx:int= points[0];
			var lly:int= points[1];
			var llz:int= points[2];
			var lli:int= 0;
			var urx:int= points[0];
			var ury:int= points[1];
			var urz:int= points[2];
			var uri:int= 0;
			for (i= 0; i < points.length; i += 4) {
				var x:int= points[i + 0];
				var y:int= points[i + 1];
				var z:int= points[i + 2];
				if (x < llx || (x == llx && z < llz)) {
					llx = x;
					lly = y;
					llz = z;
					lli = i / 4;
				}
				if (x > urx || (x == urx && z > urz)) {
					urx = x;
					ury = y;
					urz = z;
					uri = i / 4;
				}
			}
			simplified.push(llx);
			simplified.push(lly);
			simplified.push(llz);
			simplified.push(lli);

			simplified.push(urx);
			simplified.push(ury);
			simplified.push(urz);
			simplified.push(uri);
		}
		// Add points until all raw points are within
		// error tolerance to the simplified shape.
		var pn:int= points.length / 4;
		for (i= 0; i < simplified.length / 4;) {
			ii= (i + 1) % (simplified.length / 4);

			var ax:int= simplified[i * 4+ 0];
			var az:int= simplified[i * 4+ 2];
			var ai:int= simplified[i * 4+ 3];

			var bx:int= simplified[ii * 4+ 0];
			var bz:int= simplified[ii * 4+ 2];
			var bi:int= simplified[ii * 4+ 3];

			// Find maximum deviation from the segment.
			var maxd:Number= 0;
			var maxi:int= -1;
			var ci:int, cinc:int, endi:int;

			// Traverse the segment in lexilogical order so that the
			// max deviation is calculated similarly when traversing
			// opposite segments.
			if (bx > ax || (bx == ax && bz > az)) {
				cinc = 1;
				ci = (ai + cinc) % pn;
				endi = bi;
			} else {
				cinc = pn - 1;
				ci = (bi + cinc) % pn;
				endi = ai;
				var temp:int= ax;
				ax = bx;
				bx = temp;
				temp = az;
				az = bz;
				bz = temp;
			}
			// Tessellate only outer edges or edges between areas.
			if ((points[ci * 4+ 3] & RecastConstants.RC_CONTOUR_REG_MASK) == 0|| (points[ci * 4+ 3] & RecastConstants.RC_AREA_BORDER) != 0) {
				while (ci != endi) {
					var d:Number= distancePtSeg(points[ci * 4+ 0], points[ci * 4+ 2], ax, az, bx, bz);
					if (d > maxd) {
						maxd = d;
						maxi = ci;
					}
					ci = (ci + cinc) % pn;
				}
			}
			// If the max deviation is larger than accepted error,
			// add new point, else continue to next segment.
			if (maxi != -1&& maxd > (maxError * maxError)) {
				// Add the point.
				simplified.push((i + 1) * 4+ 0, points[maxi * 4+ 0]);
				simplified.push((i + 1) * 4+ 1, points[maxi * 4+ 1]);
				simplified.push((i + 1) * 4+ 2, points[maxi * 4+ 2]);
				simplified.push((i + 1) * 4+ 3, maxi);
			} else {
				++i;
			}
		}
		// Split too long edges.
		if (maxEdgeLen > 0&& (buildFlags
				& (RecastConstants.RC_CONTOUR_TESS_WALL_EDGES | RecastConstants.RC_CONTOUR_TESS_AREA_EDGES)) != 0) {
			for (i= 0; i < simplified.length / 4;) {
				ii= (i + 1) % (simplified.length / 4);

				ax= simplified[i * 4+ 0];
				az= simplified[i * 4+ 2];
				ai= simplified[i * 4+ 3];

				bx= simplified[ii * 4+ 0];
				bz= simplified[ii * 4+ 2];
				bi= simplified[ii * 4+ 3];

				// Find maximum deviation from the segment.
				maxi= -1;
				ci= (ai + 1) % pn;

				// Tessellate only outer edges or edges between areas.
				var tess:Boolean= false;
				// Wall edges.
				if ((buildFlags & RecastConstants.RC_CONTOUR_TESS_WALL_EDGES) != 0&& (points[ci * 4+ 3] & RecastConstants.RC_CONTOUR_REG_MASK) == 0)
					tess = true;
				// Edges between areas.
				if ((buildFlags & RecastConstants.RC_CONTOUR_TESS_AREA_EDGES) != 0&& (points[ci * 4+ 3] & RecastConstants.RC_AREA_BORDER) != 0)
					tess = true;

				if (tess) {
					var dx:int= bx - ax;
					var dz:int= bz - az;
					if (dx * dx + dz * dz > maxEdgeLen * maxEdgeLen) {
						// Round based on the segments in lexilogical order so that the
						// max tesselation is consistent regardles in which direction
						// segments are traversed.
						var n:int= bi < ai ? (bi + pn - ai) : (bi - ai);
						if (n > 1) {
							if (bx > ax || (bx == ax && bz > az))
								maxi = (ai + n / 2) % pn;
							else
								maxi = (ai + (n + 1) / 2) % pn;
						}
					}
				}

				// If the max deviation is larger than accepted error,
				// add new point, else continue to next segment.
				if (maxi != -1) {
					// Add the point.
					simplified.push((i + 1) * 4+ 0, points[maxi * 4+ 0]);
					simplified.push((i + 1) * 4+ 1, points[maxi * 4+ 1]);
					simplified.push((i + 1) * 4+ 2, points[maxi * 4+ 2]);
					simplified.push((i + 1) * 4+ 3, maxi);
				} else {
					++i;
				}
			}
		}
		for (i= 0; i < simplified.length / 4; ++i) {
			// The edge vertex flag is take from the current raw point,
			// and the neighbour region is take from the next raw point.
			ai= (simplified[i * 4+ 3] + 1) % pn;
			bi= simplified[i * 4+ 3];
			simplified
					[i * 4+ 3]=
							(points[ai * 4+ 3]
									& (RecastConstants.RC_CONTOUR_REG_MASK | RecastConstants.RC_AREA_BORDER))
									| (points[bi * 4+ 3] & RecastConstants.RC_BORDER_VERTEX);
		}

	}

	private static function calcAreaOfPolygon2D(verts:Array, nverts:int):int {
		var area:int= 0;
		for (var i:int= 0, j:int = nverts - 1; i < nverts; j = i++) {
			var vi:int= i * 4;
			var vj:int= j * 4;
			area += verts[vi + 0] * verts[vj + 2] - verts[vj + 0] * verts[vi + 2];
		}
		return (area + 1) / 2;
	}

	private static function intersectSegCountour(d0:int, d1:int, i:int, n:int, verts:Array, d0verts:Array,
			d1verts:Array):Boolean {
		// For each edge (k,k+1) of P
		var pverts:Array= []//4* 4];
		for (var g:int= 0; g < 4; g++) {
			pverts[g] = d0verts[d0 + g];
			pverts[4+ g] = d1verts[d1 + g];
		}
		d0 = 0;
		d1 = 4;
		for (var k:int= 0; k < n; k++) {
			var k1:int= RecastMesh.next(k, n);
			// Skip edges incident to i.
			if (i == k || i == k1)
				continue;
			var p0:int= k * 4;
			var p1:int= k1 * 4;
			for (g= 0; g < 4; g++) {
				pverts[8+ g] = verts[p0 + g];
				pverts[12+ g] = verts[p1 + g];
			}
			p0 = 8;
			p1 = 12;
			if (RecastMesh.vequal(pverts, d0, p0) || RecastMesh.vequal(pverts, d1, p0)
					|| RecastMesh.vequal(pverts, d0, p1) || RecastMesh.vequal(pverts, d1, p1))
				continue;

			if (RecastMesh.intersect(pverts, d0, d1, p0, p1))
				return true;
		}
		return false;
	}

	private static function inCone(i:int, n:int, verts:Array, pj:int, vertpj:Array):Boolean {
		var pi:int= i * 4;
		var pi1:int= RecastMesh.next(i, n) * 4;
		var pin1:int= RecastMesh.prev(i, n) * 4;
		var pverts:Array= []//4* 4];
		for (var g:int= 0; g < 4; g++) {
			pverts[g] = verts[pi + g];
			pverts[4+ g] = verts[pi1 + g];
			pverts[8+ g] = verts[pin1 + g];
			pverts[12+ g] = vertpj[pj + g];
		}
		pi = 0;
		pi1 = 4;
		pin1 = 8;
		pj = 12;
		// If P[i] is a convex vertex [ i+1 left or on (i-1,i) ].
		if (RecastMesh.leftOn(pverts, pin1, pi, pi1))
			return RecastMesh.left(pverts, pi, pj, pin1) && RecastMesh.left(pverts, pj, pi, pi1);
		// Assume (i-1,i,i+1) not collinear.
		// else P[i] is reflex.
		return !(RecastMesh.leftOn(pverts, pi, pj, pi1) && RecastMesh.leftOn(pverts, pj, pi, pin1));
	}

	private static function removeDegenerateSegments(simplified:Array):void {
		// Remove adjacent vertices which are equal on xz-plane,
		// or else the triangulator will get confused.
		var npts:int= simplified.length / 4;
		for (var i:int= 0; i < npts; ++i) {
			var ni:int= RecastMesh.next(i, npts);

			//			if (vequal(&simplified[i*4], &simplified[ni*4]))
			if (simplified[i * 4] == simplified[ni * 4]
					&& simplified[i * 4+ 2] == simplified[ni * 4+ 2]) {
				// Degenerate segment, remove.
				simplified.splice(i * 4,1);
				simplified.splice(i * 4,1);
				simplified.splice(i * 4,1);
				simplified.splice(i * 4,1);
				npts--;
			}
		}
	}

	private static function mergeContours(ca:Contour, cb:Contour, ia:int, ib:int):void {
		var maxVerts:int= ca.nverts + cb.nverts + 2;
		var verts:Array= []//maxVerts * 4];

		var nv:int= 0;

		// Copy contour A.
		for (var i:int= 0; i <= ca.nverts; ++i) {
			var dst:int= nv * 4;
			var src:int= ((ia + i) % ca.nverts) * 4;
			verts[dst + 0] = ca.verts[src + 0];
			verts[dst + 1] = ca.verts[src + 1];
			verts[dst + 2] = ca.verts[src + 2];
			verts[dst + 3] = ca.verts[src + 3];
			nv++;
		}

		// Copy contour B
		for (i= 0; i <= cb.nverts; ++i) {
			dst= nv * 4;
			src= ((ib + i) % cb.nverts) * 4;
			verts[dst + 0] = cb.verts[src + 0];
			verts[dst + 1] = cb.verts[src + 1];
			verts[dst + 2] = cb.verts[src + 2];
			verts[dst + 3] = cb.verts[src + 3];
			nv++;
		}

		ca.verts = verts;
		ca.nverts = nv;

		cb.verts = null;
		cb.nverts = 0;

	}

	// Finds the lowest leftmost vertex of a contour.
	private static function findLeftMostVertex(contour:Contour):Array {
		var minx:int= contour.verts[0];
		var minz:int= contour.verts[2];
		var leftmost:int= 0;
		for (var i:int= 1; i < contour.nverts; i++) {
			var x:int= contour.verts[i * 4+ 0];
			var z:int= contour.verts[i * 4+ 2];
			if (x < minx || (x == minx && z < minz)) {
				minx = x;
				minz = z;
				leftmost = i;
			}
		}
		return [ minx, minz, leftmost ];
	}

	

	private static function mergeRegionHoles(ctx:Context, region:ContourRegion):void {
		// Sort holes from left to right.
		for (var i:int= 0; i < region.nholes; i++) {
			var minleft:Array= findLeftMostVertex(region.holes[i].contour);
			region.holes[i].minx = minleft[0];
			region.holes[i].minz = minleft[1];
			region.holes[i].leftmost = minleft[2];
		}
		region.holes.sort(CompareHoles.compare);
		//Arrays.sort(region.holes, new CompareHoles());

		var maxVerts:int= region.outline.nverts;
		for (i= 0; i < region.nholes; i++)
			maxVerts += region.holes[i].contour.nverts;

		var diags:Array= new PotentialDiagonal[maxVerts];
		for (var pd:int= 0; pd < maxVerts; pd++) {
			diags[pd] = new PotentialDiagonal();
		}
		var outline:Contour= region.outline;

		// Merge holes into the outline one by one.
		for (i= 0; i < region.nholes; i++) {
			var hole:Contour= region.holes[i].contour;

			var index:int= -1;
			var bestVertex:int= region.holes[i].leftmost;
			for (var iter:int= 0; iter < hole.nverts; iter++) {
				// Find potential diagonals.
				// The 'best' vertex must be in the cone described by 3 cosequtive vertices of the outline.
				// ..o j-1
				//   |
				//   |   * best
				//   |
				// j o-----o j+1
				//         :
				var ndiags:int= 0;
				var corner:int= bestVertex * 4;
				for (var j:int= 0; j < outline.nverts; j++) {
					if (inCone(j, outline.nverts, outline.verts, corner, hole.verts)) {
						var dx:int= outline.verts[j * 4+ 0] - hole.verts[corner + 0];
						var dz:int= outline.verts[j * 4+ 2] - hole.verts[corner + 2];
						diags[ndiags].vert = j;
						diags[ndiags].dist = dx * dx + dz * dz;
						ndiags++;
					}
				}
				// Sort potential diagonals by distance, we want to make the connection as short as possible.
				Arrays.sort(diags, 0, ndiags, CompareDiagDist.compare);
				
				
				// Find a diagonal that is not intersecting the outline not the remaining holes.
				index = -1;
				for (j= 0; j < ndiags; j++) {
					var pt:int= diags[j].vert * 4;
					var intersect:Boolean= intersectSegCountour(pt, corner, diags[i].vert, outline.nverts, outline.verts,
							outline.verts, hole.verts);
					for (var k:int= i; k < region.nholes && !intersect; k++)
						intersect =Boolean(int(intersect)| int(intersectSegCountour(pt, corner, -1, region.holes[k].contour.nverts,
								region.holes[k].contour.verts, outline.verts, hole.verts)));
					if (!intersect) {
						index = diags[j].vert;
						break;
					}
				}
				// If found non-intersecting diagonal, stop looking.
				if (index != -1)
					break;
				// All the potential diagonals for the current vertex were intersecting, try next vertex.
				bestVertex = (bestVertex + 1) % hole.nverts;
			}

			if (index == -1) {
				ctx.warn("mergeHoles: Failed to find merge points for");
				continue;
			}
			mergeContours(region.outline, hole, index, bestVertex);
		}
	}

	/// @par
	///
	/// The raw contours will match the region outlines exactly. The @p maxError and @p maxEdgeLen
	/// parameters control how closely the simplified contours will match the raw contours.
	///
	/// Simplified contours are generated such that the vertices for portals between areas match up.
	/// (They are considered mandatory vertices.)
	///
	/// Setting @p maxEdgeLength to zero will disabled the edge length feature.
	///
	/// See the #rcConfig documentation for more information on the configuration parameters.
	///
	/// @see rcAllocContourSet, rcCompactHeightfield, rcContourSet, rcConfig
	public static function buildContours(ctx:Context, chf:CompactHeightfield, maxError:Number, maxEdgeLen:int,
			buildFlags:int):ContourSet {

		var w:int= chf.width;
		var h:int= chf.height;
		var borderSize:int= chf.borderSize;
		var cset:ContourSet= new ContourSet();

		ctx.startTimer("BUILD_CONTOURS");
		RecastVectors.copy(cset.bmin, chf.bmin, 0);
		RecastVectors.copy(cset.bmax, chf.bmax, 0);
		if (borderSize > 0) {
			// If the heightfield was build with bordersize, remove the offset.
			var pad:Number= borderSize * chf.cs;
			cset.bmin[0] += pad;
			cset.bmin[2] += pad;
			cset.bmax[0] -= pad;
			cset.bmax[2] -= pad;
		}
		cset.cs = chf.cs;
		cset.ch = chf.ch;
		cset.width = chf.width - chf.borderSize * 2;
		cset.height = chf.height - chf.borderSize * 2;
		cset.borderSize = chf.borderSize;

		var flags:Array = [];//[]//chf.spanCount];

		ctx.startTimer("BUILD_CONTOURS_TRACE");

		// Mark boundaries.
		for (var y:int= 0; y < h; ++y) {
			for (var x:int= 0; x < w; ++x) {
				var c:CompactCell= chf.cells[x + y * w];
				for (var i:int= c.index, ni:int = c.index + c.count; i < ni; ++i) {
					var res:int= 0;
					var s:CompactSpan= chf.spans[i];
					if (chf.spans[i].reg == 0|| (chf.spans[i].reg & RecastConstants.RC_BORDER_REG) != 0) {
						flags[i] = 0;
						continue;
					}
					for (var dir:int= 0; dir < 4; ++dir) {
						var r:int= 0;
						if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
							var ax:int= x + RecastCommon.GetDirOffsetX(dir);
							var ay:int= y + RecastCommon.GetDirOffsetY(dir);
							var ai:int= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, dir);
							r = chf.spans[ai].reg;
						}
						if (r == chf.spans[i].reg)
							res |= (1<< dir);
					}
					flags[i] = res ^ 0xf; // Inverse, mark non connected edges.
				}
			}
		}

		ctx.stopTimer("BUILD_CONTOURS_TRACE");

		var verts:Array = [];
		var simplified:Array = [];

		for (y= 0; y < h; ++y) {
			for (x= 0; x < w; ++x) {
				c= chf.cells[x + y * w];
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					if (flags[i] == 0|| flags[i] == 0xf) {
						flags[i] = 0;
						continue;
					}
					var reg:int= chf.spans[i].reg;
					if (reg == 0|| (reg & RecastConstants.RC_BORDER_REG) != 0)
						continue;
					var area:int= chf.areas[i];

					verts.splice(0, verts.length);// .clear();
					simplified.splice(0,simplified.length);// .clear();

					ctx.startTimer("BUILD_CONTOURS_TRACE");
					walkContour(x, y, i, chf, flags, verts);
					ctx.stopTimer("BUILD_CONTOURS_TRACE");

					ctx.startTimer("BUILD_CONTOURS_SIMPLIFY");
					simplifyContour(verts, simplified, maxError, maxEdgeLen, buildFlags);
					removeDegenerateSegments(simplified);
					ctx.stopTimer("BUILD_CONTOURS_SIMPLIFY");

					// Store region->contour remap info.
					// Create contour.
					if (simplified.length / 4>= 3) {

						var cont:Contour= new Contour();
						cset.conts.push(cont);

						cont.nverts = simplified.length / 4;
						cont.verts = []//simplified.length];
						for (var l:int= 0; l < simplified.length; l++) {
							cont.verts[l] = simplified[l];
						}

						if (borderSize > 0) {
							// If the heightfield was build with bordersize, remove the offset.
							for (var j:int= 0; j < cont.nverts; ++j) {
								cont.verts[j * 4] -= borderSize;
								cont.verts[j * 4+ 2] -= borderSize;
							}
						}

						cont.nrverts = verts.length / 4;
						cont.rverts = []//verts.length];
						for (l= 0; l < verts.length; l++) {
							cont.rverts[l] = verts[l];
						}
						if (borderSize > 0) {
							// If the heightfield was build with bordersize, remove the offset.
							for (j= 0; j < cont.nrverts; ++j) {
								cont.rverts[j * 4] -= borderSize;
								cont.rverts[j * 4+ 2] -= borderSize;
							}
						}

						cont.reg = reg;
						cont.area = area;
					}
				}
			}
		}

		// Merge holes if needed.
		if (cset.conts.length > 0) {
			// Calculate winding of all polygons.
			var winding:Array= []//cset.conts.length];
			var nholes:int= 0;
			for (i= 0; i < cset.conts.length; ++i) {
				cont= cset.conts[i];
				// If the contour is wound backwards, it is a hole.
				winding[i] = calcAreaOfPolygon2D(cont.verts, cont.nverts) < 0? -1: 1;
				if (winding[i] < 0)
					nholes++;
			}

			if (nholes > 0) {
				// Collect outline contour and holes contours per region.
				// We assume that there is one outline and multiple holes.
				var nregions:int= chf.maxRegions + 1;
				var regions:Array= new ContourRegion[nregions];
				for (i= 0; i < nregions; i++) {
					regions[i] = new ContourRegion();
				}

				for (i= 0; i < cset.conts.length; ++i) {
					cont= cset.conts[i];
					// Positively would contours are outlines, negative holes.
					if (winding[i] > 0) {
						if (regions[cont.reg].outline != null) {
							throw (
									"rcBuildContours: Multiple outlines for region " + cont.reg + ".");
						}
						regions[cont.reg].outline = cont;
					} else {
						regions[cont.reg].nholes++;
					}
				}
				for (i= 0; i < nregions; i++) {
					if (regions[i].nholes > 0) {
						regions[i].holes = new ContourHole[regions[i].nholes];
						for (var nh:int= 0; nh < regions[i].nholes; nh++) {
							regions[i].holes[nh] = new ContourHole();
						}
						regions[i].nholes = 0;
					}
				}
				for (i= 0; i < cset.conts.length; ++i) {
					cont= cset.conts[i];
					var reg2:ContourRegion= regions[cont.reg];
					if (winding[i] < 0)
						reg2.holes[reg2.nholes++].contour = cont;
				}

				// Finally merge each regions holes into the outline.
				for (i= 0; i < nregions; i++) {
					reg2= regions[i];
					if (reg2.nholes == 0)
						continue;

					if (reg2.outline != null) {
						mergeRegionHoles(ctx, reg2);
					} else {
						// The region does not have an outline.
						// This can happen if the contour becaomes selfoverlapping because of
						// too aggressive simplification settings.
						throw ("rcBuildContours: Bad outline for region " + i
								+ ", contour simplification is likely too aggressive.");
					}
				}
			}
		}
		ctx.stopTimer("BUILD_CONTOURS");
		return cset;
	}
}
}
import org.recast4j.recast.Contour;

 class ContourRegion {
		public var outline:Contour;
		public var holes:Array;
		public var nholes:int;
	}

	 class ContourHole {
		public var leftmost:int;
		public var minx:int;
		public var minz:int;
		public var contour:Contour;
	}

	 class PotentialDiagonal {
		public var dist:int;
		public var vert:int;
	}
	class CompareHoles {

		
		public static function compare(a:ContourHole, b:ContourHole):int {
			if (a.minx == b.minx) {
				if (a.minz < b.minz)
					return -1;
				if (a.minz > b.minz)
					return 1;
			} else {
				if (a.minx < b.minx)
					return -1;
				if (a.minx > b.minx)
					return 1;
			}
			return 0;
		}

	}

	 class CompareDiagDist {

		
		 public static function compare(va:PotentialDiagonal, vb:PotentialDiagonal):int {
			var a:PotentialDiagonal= va;
			var b:PotentialDiagonal= vb;
			if (a.dist < b.dist)
				return -1;
			if (a.dist > b.dist)
				return 1;
			return 0;
		}
	}
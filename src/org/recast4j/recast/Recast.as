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
public class Recast {

	function calcBounds(verts:Array, nv:int, bmin:Array, bmax:Array):void {
		for (var i:int= 0; i < 3; i++) {
			bmin[i] = verts[i];
			bmax[i] = verts[i];
		}
		for (var i:int= 1; i < nv; ++i) {
			for (var j:int= 0; j < 3; j++) {
				bmin[j] = Math.min(bmin[j], verts[i * 3+ j]);
				bmax[j] = Math.max(bmax[j], verts[i * 3+ j]);
			}
		}
		// Calculate bounding box.
	}

	static function calcGridSize(bmin:Array, bmax:Array, cs:Number):Array {
		return  [ int(((bmax[0] - bmin[0]) / cs + 0.5)), int(((bmax[2] - bmin[2]) / cs + 0.5) )];
	}

	/// @par
	///
	/// Only sets the area id's for the walkable triangles.  Does not alter the
	/// area id's for unwalkable triangles.
	/// 
	/// See the #rcConfig documentation for more information on the configuration parameters.
	/// 
	/// @see rcHeightfield, rcClearUnwalkableTriangles, rcRasterizeTriangles
	static public function markWalkableTriangles( ctx:Context,  walkableSlopeAngle:Number,  verts:Array,  nv:int,  tris:Array,  nt:int):Array {
		var areas:Array= new int[nt];
		var walkableThr:Number= (Math.cos(walkableSlopeAngle / 180.0 * Math.PI));
		var norm:Array = [];
		for (var i:int= 0; i < nt; ++i) {
			var tri:int= i * 3;
			calcTriNormal(verts, tris[tri], tris[tri + 1], tris[tri + 2], norm);
			// Check if the face is walkable.
			if (norm[1] > walkableThr)
				areas[i] = RecastConstants.RC_WALKABLE_AREA;
		}
		return areas;
	}

	static function calcTriNormal(verts:Array, v0:int, v1:int, v2:int, norm:Array):void {
		var e0:Array = [], e1:Array = [];
		RecastVectors.sub(e0, verts, v1 * 3, v0 * 3);
		RecastVectors.sub(e1, verts, v2 * 3, v0 * 3);
		RecastVectors.cross(norm, e0, e1);
		RecastVectors.normalize(norm);
	}

	/// @par
	///
	/// Only sets the area id's for the unwalkable triangles.  Does not alter the
	/// area id's for walkable triangles.
	/// 
	/// See the #rcConfig documentation for more information on the configuration parameters.
	/// 
	/// @see rcHeightfield, rcClearUnwalkableTriangles, rcRasterizeTriangles
	function clearUnwalkableTriangles(ctx:Context, walkableSlopeAngle:Number, verts:Array, nv:int, tris:Array, nt:int,
			areas:Array):void {
		var walkableThr:Number= (Math.cos(walkableSlopeAngle / 180.0 * Math.PI));

		var norm:Array = [];

		for (var i:int= 0; i < nt; ++i) {
			var tri:int= i * 3;
			calcTriNormal(verts, tris[tri], tris[tri + 1], tris[tri + 2], norm);
			// Check if the face is walkable.
			if (norm[1] <= walkableThr)
				areas[i] = RecastConstants.RC_NULL_AREA;
		}
	}

	static function getHeightFieldSpanCount(ctx:Context, hf:Heightfield):int {
		var w:int= hf.width;
		var h:int= hf.height;
		var spanCount:int= 0;
		for (var y:int= 0; y < h; ++y) {
			for (var x:int= 0; x < w; ++x) {
				for (var s:Span= hf.spans[x + y * w]; s != null; s = s.next) {
					if (s.area != RecastConstants.RC_NULL_AREA)
						spanCount++;
				}
			}
		}
		return spanCount;
	}

	/// @par
	///
	/// This is just the beginning of the process of fully building a compact heightfield.
	/// Various filters may be applied, then the distance field and regions built.
	/// E.g: #rcBuildDistanceField and #rcBuildRegions
	///
	/// See the #rcConfig documentation for more information on the configuration parameters.
	///
	/// @see rcAllocCompactHeightfield, rcHeightfield, rcCompactHeightfield, rcConfig

	public static function buildCompactHeightfield(ctx:Context, walkableHeight:int, walkableClimb:int, hf:Heightfield):CompactHeightfield {

		ctx.startTimer("BUILD_COMPACTHEIGHTFIELD");

		var chf:CompactHeightfield= new CompactHeightfield();
		var w:int= hf.width;
		var h:int= hf.height;
		var spanCount:int= getHeightFieldSpanCount(ctx, hf);

		// Fill in header.
		chf.width = w;
		chf.height = h;
		chf.spanCount = spanCount;
		chf.walkableHeight = walkableHeight;
		chf.walkableClimb = walkableClimb;
		chf.maxRegions = 0;
		chf.bmin = hf.bmin;
		chf.bmax = hf.bmax;
		chf.bmax[1] += walkableHeight * hf.ch;
		chf.cs = hf.cs;
		chf.ch = hf.ch;
		chf.cells = new CompactCell[w * h];
		chf.spans = new CompactSpan[spanCount];
		chf.areas = new int[spanCount];
		var MAX_HEIGHT:int= 0;
		for (var i:int= 0; i < chf.cells.length; i++) {
			chf.cells[i] = new CompactCell();
		}
		for (var i:int= 0; i < chf.spans.length; i++) {
			chf.spans[i] = new CompactSpan();
		}
		// Fill in cells and spans.
		var idx:int= 0;
		for (var y:int= 0; y < h; ++y) {
			for (var x:int= 0; x < w; ++x) {
				var s:Span= hf.spans[x + y * w];
				// If there are no spans at this cell, just leave the data to index=0, count=0.
				if (s == null)
					continue;
				var c:CompactCell= chf.cells[x + y * w];
				c.index = idx;
				c.count = 0;
				while (s != null) {
					if (s.area != RecastConstants.RC_NULL_AREA) {
						var bot:int= s.smax;
						var top:int= s.next != null ? int(s.next.smin ): MAX_HEIGHT;
						chf.spans[idx].y = RecastCommon.clamp(bot, 0, 0);
						chf.spans[idx].h = RecastCommon.clamp(top - bot, 0, 0);
						chf.areas[idx] = s.area;
						idx++;
						c.count++;
					}
					s = s.next;
				}
			}
		}

		// Find neighbour connections.
		var MAX_LAYERS:int= RecastConstants.RC_NOT_CONNECTED - 1;
		var tooHighNeighbour:int= 0;
		for (var y:int= 0; y < h; ++y) {
			for (var x:int= 0; x < w; ++x) {
				var c:CompactCell= chf.cells[x + y * w];
				for (var i:int= c.index, ni = c.index + c.count; i < ni; ++i) {
					var s2:CompactSpan= chf.spans[i];

					for (var dir:int= 0; dir < 4; ++dir) {
						RecastCommon.SetCon(s, dir, RecastConstants.RC_NOT_CONNECTED);
						var nx:int= x + RecastCommon.GetDirOffsetX(dir);
						var ny:int= y + RecastCommon.GetDirOffsetY(dir);
						// First check that the neighbour cell is in bounds.
						if (nx < 0|| ny < 0|| nx >= w || ny >= h)
							continue;

						// Iterate over all neighbour spans and check if any of the is
						// accessible from current cell.
						var nc:CompactCell= chf.cells[nx + ny * w];
						for (var k:int= nc.index, nk = nc.index + nc.count; k < nk; ++k) {
							var ns:CompactSpan= chf.spans[k];
							var bot:int= Math.max(s2.y, ns.y);
							var top:int= Math.min(s2.y + s2.h, ns.y + ns.h);

							// Check that the gap between the spans is walkable,
							// and that the climb height between the gaps is not too high.
							if ((top - bot) >= walkableHeight && Math.abs(ns.y - s2.y) <= walkableClimb) {
								// Mark direction as walkable.
								var lidx:int= k - nc.index;
								if (lidx < 0|| lidx > MAX_LAYERS) {
									tooHighNeighbour = Math.max(tooHighNeighbour, lidx);
									continue;
								}
								RecastCommon.SetCon(s2, dir, lidx);
								break;
							}
						}

					}
				}
			}
		}

		if (tooHighNeighbour > MAX_LAYERS) {
			throw ("rcBuildCompactHeightfield: Heightfield has too many layers " + tooHighNeighbour
					+ " (max: " + MAX_LAYERS + ")");
		}
		ctx.stopTimer("BUILD_COMPACTHEIGHTFIELD");
		return chf;
	}
}
}
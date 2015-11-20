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

public class RecastArea {

	/// @par 
	/// 
	/// Basically, any spans that are closer to a boundary or obstruction than the specified radius 
	/// are marked as unwalkable.
	///
	/// This method is usually called immediately after the heightfield has been built.
	///
	/// @see rcCompactHeightfield, rcBuildCompactHeightfield, rcConfig::walkableRadius	
	public static function erodeWalkableArea(ctx:Context, radius:int, chf:CompactHeightfield):void {
		var w:int= chf.width;
		var h:int= chf.height;
		ctx.startTimer("ERODE_AREA");

		var dist:Array = [];////[]//chf.spanCount];
		Arrays.fill2(dist, 255);
		// Mark boundary cells.
		for (var y:int= 0; y < h; ++y) {
			for (var x:int= 0; x < w; ++x) {
				var c:CompactCell= chf.cells[x + y * w];
				var ni:int;
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					if (chf.areas[i] == RecastConstants.RC_NULL_AREA) {
						dist[i] = 0;
					} else {
						var s:CompactSpan= chf.spans[i];
						var nc:int= 0;
						for (var dir:int= 0; dir < 4; ++dir) {
							if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
								var nx:int= x + RecastCommon.GetDirOffsetX(dir);
								var ny:int= y + RecastCommon.GetDirOffsetY(dir);
								var nidx:int= chf.cells[nx + ny * w].index + RecastCommon.GetCon(s, dir);
								if (chf.areas[nidx] != RecastConstants.RC_NULL_AREA) {
									nc++;
								}
							}
						}
						// At least one missing neighbour.
						if (nc != 4)
							dist[i] = 0;
					}
				}
			}
		}

		var nd:int;

		// Pass 1
		for (y= 0; y < h; ++y) {
			for (x= 0; x < w; ++x) {
				c= chf.cells[x + y * w];
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					s= chf.spans[i];

					if (RecastCommon.GetCon(s, 0) != RecastConstants.RC_NOT_CONNECTED) {
						// (-1,0)
						var ax:int= x + RecastCommon.GetDirOffsetX(0);
						var ay:int= y + RecastCommon.GetDirOffsetY(0);
						var ai:int= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, 0);
						var as_:CompactSpan= chf.spans[ai];
						nd = Math.min(dist[ai] + 2, 255);
						if (nd < dist[i])
							dist[i] = nd;

						// (-1,-1)
						if (RecastCommon.GetCon(as_, 3) != RecastConstants.RC_NOT_CONNECTED) {
							var aax:int= ax + RecastCommon.GetDirOffsetX(3);
							var aay:int= ay + RecastCommon.GetDirOffsetY(3);
							var aai:int= chf.cells[aax + aay * w].index + RecastCommon.GetCon(as_, 3);
							nd = Math.min(dist[aai] + 3, 255);
							if (nd < dist[i])
								dist[i] = nd;
						}
					}
					if (RecastCommon.GetCon(s, 3) != RecastConstants.RC_NOT_CONNECTED) {
						// (0,-1)
						ax= x + RecastCommon.GetDirOffsetX(3);
						ay= y + RecastCommon.GetDirOffsetY(3);
						ai= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, 3);
						as_= chf.spans[ai];
						nd = Math.min(dist[ai] + 2, 255);
						if (nd < dist[i])
							dist[i] = nd;

						// (1,-1)
						if (RecastCommon.GetCon(as_, 2) != RecastConstants.RC_NOT_CONNECTED) {
							aax= ax + RecastCommon.GetDirOffsetX(2);
							aay= ay + RecastCommon.GetDirOffsetY(2);
							aai= chf.cells[aax + aay * w].index + RecastCommon.GetCon(as_, 2);
							nd = Math.min(dist[aai] + 3, 255);
							if (nd < dist[i])
								dist[i] = nd;
						}
					}
				}
			}
		}

		// Pass 2
		for (y= h - 1; y >= 0; --y) {
			for (x= w - 1; x >= 0; --x) {
				c= chf.cells[x + y * w];
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					s= chf.spans[i];

					if (RecastCommon.GetCon(s, 2) != RecastConstants.RC_NOT_CONNECTED) {
						// (1,0)
						 ax= x + RecastCommon.GetDirOffsetX(2);
						 ay= y + RecastCommon.GetDirOffsetY(2);
						 ai= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, 2);
						 as_= chf.spans[ai];
						nd = Math.min(dist[ai] + 2, 255);
						if (nd < dist[i])
							dist[i] = nd;

						// (1,1)
						if (RecastCommon.GetCon(as_, 1) != RecastConstants.RC_NOT_CONNECTED) {
							 aax= ax + RecastCommon.GetDirOffsetX(1);
							 aay= ay + RecastCommon.GetDirOffsetY(1);
							 aai= chf.cells[aax + aay * w].index + RecastCommon.GetCon(as_, 1);
							nd = Math.min(dist[aai] + 3, 255);
							if (nd < dist[i])
								dist[i] = nd;
						}
					}
					if (RecastCommon.GetCon(s, 1) != RecastConstants.RC_NOT_CONNECTED) {
						// (0,1)
						ax= x + RecastCommon.GetDirOffsetX(1);
						ay= y + RecastCommon.GetDirOffsetY(1);
						ai= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, 1);
						as_= chf.spans[ai];
						nd = Math.min(dist[ai] + 2, 255);
						if (nd < dist[i])
							dist[i] = nd;

						// (-1,1)
						if (RecastCommon.GetCon(as_, 0) != RecastConstants.RC_NOT_CONNECTED) {
							 aax= ax + RecastCommon.GetDirOffsetX(0);
							 aay= ay + RecastCommon.GetDirOffsetY(0);
							 aai= chf.cells[aax + aay * w].index + RecastCommon.GetCon(as_, 0);
							nd = Math.min(dist[aai] + 3, 255);
							if (nd < dist[i])
								dist[i] = nd;
						}
					}
				}
			}
		}

		var thr:int= radius * 2;
		for (var i:int= 0; i < chf.spanCount; ++i)
			if (dist[i] < thr)
				chf.areas[i] = RecastConstants.RC_NULL_AREA;

		ctx.stopTimer("ERODE_AREA");
	}

	/// @par
	///
	/// This filter is usually applied after applying area id's using functions
	/// such as #rcMarkBoxArea, #rcMarkConvexPolyArea, and #rcMarkCylinderArea.
	/// 
	/// @see rcCompactHeightfield
	public function medianFilterWalkableArea(ctx:Context, chf:CompactHeightfield):Boolean {

		var w:int= chf.width;
		var h:int= chf.height;

		ctx.startTimer("MEDIAN_AREA");

		var areas:Array= []//chf.spanCount];

		for (var y:int= 0; y < h; ++y) {
			for (var x:int= 0; x < w; ++x) {
				var c:CompactCell= chf.cells[x + y * w];
				for (var i:int= c.index, ni:int = c.index + c.count; i < ni; ++i) {
					var s:CompactSpan= chf.spans[i];
					if (chf.areas[i] == RecastConstants.RC_NULL_AREA) {
						areas[i] = chf.areas[i];
						continue;
					}

					var nei:Array = [];
					for (var j:int= 0; j < 9; ++j)
						nei[j] = chf.areas[i];

					for (var dir:int= 0; dir < 4; ++dir) {
						if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
							var ax:int= x + RecastCommon.GetDirOffsetX(dir);
							var ay:int= y + RecastCommon.GetDirOffsetY(dir);
							var ai:int= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, dir);
							if (chf.areas[ai] != RecastConstants.RC_NULL_AREA)
								nei[dir * 2+ 0] = chf.areas[ai];

							var as_:CompactSpan= chf.spans[ai];
							var dir2:int= (dir + 1) & 0x3;
							if (RecastCommon.GetCon(as_, dir2) != RecastConstants.RC_NOT_CONNECTED) {
								var ax2:int= ax + RecastCommon.GetDirOffsetX(dir2);
								var ay2:int= ay + RecastCommon.GetDirOffsetY(dir2);
								var ai2:int= chf.cells[ax2 + ay2 * w].index + RecastCommon.GetCon(as_, dir2);
								if (chf.areas[ai2] != RecastConstants.RC_NULL_AREA)
									nei[dir * 2+ 1] = chf.areas[ai2];
							}
						}
					}
					nei.sort(Array.NUMERIC);
					//Arrays.sort(nei);
					areas[i] = nei[4];
				}
			}
		}
		chf.areas = areas;

		ctx.stopTimer("MEDIAN_AREA");

		return true;
	}

	/// @par
	///
	/// The value of spacial parameters are in world units.
	/// 
	/// @see rcCompactHeightfield, rcMedianFilterWalkableArea
	public function markBoxArea(ctx:Context, bmin:Array, bmax:Array, areaId:int, chf:CompactHeightfield):void {
		ctx.startTimer("MARK_BOX_AREA");

		var minx:int= int(((bmin[0] - chf.bmin[0]) / chf.cs));
		var miny:int= int(((bmin[1] - chf.bmin[1]) / chf.ch));
		var minz:int= int(((bmin[2] - chf.bmin[2]) / chf.cs));
		var maxx:int= int(((bmax[0] - chf.bmin[0]) / chf.cs));
		var maxy:int= int(((bmax[1] - chf.bmin[1]) / chf.ch));
		var maxz:int= int(((bmax[2] - chf.bmin[2]) / chf.cs));

		if (maxx < 0)
			return;
		if (minx >= chf.width)
			return;
		if (maxz < 0)
			return;
		if (minz >= chf.height)
			return;

		if (minx < 0)
			minx = 0;
		if (maxx >= chf.width)
			maxx = chf.width - 1;
		if (minz < 0)
			minz = 0;
		if (maxz >= chf.height)
			maxz = chf.height - 1;

		for (var z:int= minz; z <= maxz; ++z) {
			for (var x:int= minx; x <= maxx; ++x) {
				var c:CompactCell= chf.cells[x + z * chf.width];
				for (var i:int= c.index, ni:int = c.index + c.count; i < ni; ++i) {
					var s:CompactSpan= chf.spans[i];
					if (s.y >= miny && s.y <= maxy) {
						if (chf.areas[i] != RecastConstants.RC_NULL_AREA)
							chf.areas[i] = areaId;
					}
				}
			}
		}

		ctx.stopTimer("MARK_BOX_AREA");

	}

	public static function pointInPoly(nvert:int, verts:Array, p:Array):Boolean {
		var c:Boolean= false;
		var i:int, j:int;
		for (i = 0, j = nvert - 1; i < nvert; j = i++) {
			var vi:int= i * 3;
			var vj:int= j * 3;
			if (((verts[vi + 2] > p[2]) != (verts[vj + 2] > p[2]))
					&& (p[0] < (verts[vj] - verts[vi]) * (p[2] - verts[vi + 2]) / (verts[vj + 2] - verts[vi + 2])
							+ verts[vi]))
				c = !c;
		}
		return c;
	}

	/// @par
	///
	/// The value of spacial parameters are in world units.
	/// 
	/// The y-values of the polygon vertices are ignored. So the polygon is effectively 
	/// projected onto the xz-plane at @p hmin, then extruded to @p hmax.
	/// 
	/// @see rcCompactHeightfield, rcMedianFilterWalkableArea
	public static function markConvexPolyArea(ctx:Context, verts:Array, nverts:int, hmin:Number, hmax:Number, areaId:int,
			chf:CompactHeightfield):void {
		ctx.startTimer("MARK_CONVEXPOLY_AREA");

		var bmin:Array = [], bmax:Array = [];
		RecastVectors.copy(bmin, verts, 0);
		RecastVectors.copy(bmax, verts, 0);
		for (var i:int= 1; i < nverts; ++i) {
			RecastVectors.min(bmin, verts, i * 3);
			RecastVectors.max(bmax, verts, i * 3);
		}
		bmin[1] = hmin;
		bmax[1] = hmax;

		var minx:int= int(((bmin[0] - chf.bmin[0]) / chf.cs));
		var miny:int= int(((bmin[1] - chf.bmin[1]) / chf.ch));
		var minz:int= int(((bmin[2] - chf.bmin[2]) / chf.cs));
		var maxx:int= int(((bmax[0] - chf.bmin[0]) / chf.cs));
		var maxy:int= int(((bmax[1] - chf.bmin[1]) / chf.ch));
		var maxz:int= int(((bmax[2] - chf.bmin[2]) / chf.cs));

		if (maxx < 0)
			return;
		if (minx >= chf.width)
			return;
		if (maxz < 0)
			return;
		if (minz >= chf.height)
			return;

		if (minx < 0)
			minx = 0;
		if (maxx >= chf.width)
			maxx = chf.width - 1;
		if (minz < 0)
			minz = 0;
		if (maxz >= chf.height)
			maxz = chf.height - 1;

		// TODO: Optimize.
		for (var z:int= minz; z <= maxz; ++z) {
			for (var x:int= minx; x <= maxx; ++x) {
				var c:CompactCell = chf.cells[x + z * chf.width];
				var ni:int;
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					var s:CompactSpan= chf.spans[i];
					if (chf.areas[i] == RecastConstants.RC_NULL_AREA)
						continue;
					if (s.y >= miny && s.y <= maxy) {
						var p:Array = [];
						p[0] = chf.bmin[0] + (x + 0.5) * chf.cs;
						p[1] = 0;
						p[2] = chf.bmin[2] + (z + 0.5) * chf.cs;

						if (pointInPoly(nverts, verts, p)) {
							chf.areas[i] = areaId;
						}
					}
				}
			}
		}

		ctx.stopTimer("MARK_CONVEXPOLY_AREA");
	}

	public function offsetPoly(verts:Array, nverts:int, offset:Number, outVerts:Array, maxOutVerts:int):int {
		var MITER_LIMIT:Number= 1.20;

		var n:int= 0;

		for (var i:int= 0; i < nverts; i++) {
			var a:int= (i + nverts - 1) % nverts;
			var b:int= i;
			var c:int= (i + 1) % nverts;
			var va:int= a * 3;
			var vb:int= b * 3;
			var vc:int= c * 3;
			var dx0:Number= verts[vb] - verts[va];
			var dy0:Number= verts[vb + 2] - verts[va + 2];
			var d0:Number= dx0 * dx0 + dy0 * dy0;
			if (d0 > 1e-6) {
				d0 = ((1.0 / Math.sqrt(d0)));
				dx0 *= d0;
				dy0 *= d0;
			}
			var dx1:Number= verts[vc] - verts[vb];
			var dy1:Number= verts[vc + 2] - verts[vb + 2];
			var d1:Number= dx1 * dx1 + dy1 * dy1;
			if (d1 > 1e-6) {
				d1 = ((1.0 / Math.sqrt(d1)));
				dx1 *= d1;
				dy1 *= d1;
			}
			var dlx0:Number= -dy0;
			var dly0:Number= dx0;
			var dlx1:Number= -dy1;
			var dly1:Number= dx1;
			var cross:Number= dx1 * dy0 - dx0 * dy1;
			var dmx:Number= (dlx0 + dlx1) * 0.5;
			var dmy:Number= (dly0 + dly1) * 0.5;
			var dmr2:Number= dmx * dmx + dmy * dmy;
			var bevel:Boolean= dmr2 * MITER_LIMIT * MITER_LIMIT < 1.0;
			if (dmr2 > 1e-6) {
				var scale:Number= 1.0/ dmr2;
				dmx *= scale;
				dmy *= scale;
			}

			if (bevel && cross < 0.0) {
				if (n + 2>= maxOutVerts)
					return 0;
				var d:Number= (1.0- (dx0 * dx1 + dy0 * dy1)) * 0.5;
				outVerts[n * 3+ 0] = verts[vb] + (-dlx0 + dx0 * d) * offset;
				outVerts[n * 3+ 1] = verts[vb + 1];
				outVerts[n * 3+ 2] = verts[vb + 2] + (-dly0 + dy0 * d) * offset;
				n++;
				outVerts[n * 3+ 0] = verts[vb] + (-dlx1 - dx1 * d) * offset;
				outVerts[n * 3+ 1] = verts[vb + 1];
				outVerts[n * 3+ 2] = verts[vb + 2] + (-dly1 - dy1 * d) * offset;
				n++;
			} else {
				if (n + 1>= maxOutVerts)
					return 0;
				outVerts[n * 3+ 0] = verts[vb] - dmx * offset;
				outVerts[n * 3+ 1] = verts[vb + 1];
				outVerts[n * 3+ 2] = verts[vb + 2] - dmy * offset;
				n++;
			}
		}

		return n;
	}

	/// @par
	///
	/// The value of spacial parameters are in world units.
	/// 
	/// @see rcCompactHeightfield, rcMedianFilterWalkableArea
	public function markCylinderArea(ctx:Context, pos:Array, r:Number, h:Number, areaId:int, chf:CompactHeightfield):void {

		ctx.startTimer("MARK_CYLINDER_AREA");

		var bmin:Array = [], bmax:Array = [];
		bmin[0] = pos[0] - r;
		bmin[1] = pos[1];
		bmin[2] = pos[2] - r;
		bmax[0] = pos[0] + r;
		bmax[1] = pos[1] + h;
		bmax[2] = pos[2] + r;
		var r2:Number= r * r;

		var minx:int= int(((bmin[0] - chf.bmin[0]) / chf.cs));
		var miny:int= int(((bmin[1] - chf.bmin[1]) / chf.ch));
		var minz:int= int(((bmin[2] - chf.bmin[2]) / chf.cs));
		var maxx:int= int(((bmax[0] - chf.bmin[0]) / chf.cs));
		var maxy:int= int(((bmax[1] - chf.bmin[1]) / chf.ch));
		var maxz:int= int(((bmax[2] - chf.bmin[2]) / chf.cs));

		if (maxx < 0)
			return;
		if (minx >= chf.width)
			return;
		if (maxz < 0)
			return;
		if (minz >= chf.height)
			return;

		if (minx < 0)
			minx = 0;
		if (maxx >= chf.width)
			maxx = chf.width - 1;
		if (minz < 0)
			minz = 0;
		if (maxz >= chf.height)
			maxz = chf.height - 1;

		for (var z:int= minz; z <= maxz; ++z) {
			for (var x:int= minx; x <= maxx; ++x) {
				var c:CompactCell= chf.cells[x + z * chf.width];
				for (var i:int= c.index, ni:int = c.index + c.count; i < ni; ++i) {
					var s:CompactSpan= chf.spans[i];

					if (chf.areas[i] == RecastConstants.RC_NULL_AREA)
						continue;

					if (s.y >= miny && s.y <= maxy) {
						var sx:Number= chf.bmin[0] + (x + 0.5) * chf.cs;
						var sz:Number= chf.bmin[2] + (z + 0.5) * chf.cs;
						var dx:Number= sx - pos[0];
						var dz:Number= sz - pos[2];

						if (dx * dx + dz * dz < r2) {
							chf.areas[i] = areaId;
						}
					}
				}
			}
		}
		ctx.stopTimer("MARK_CYLINDER_AREA");
	}

}
}
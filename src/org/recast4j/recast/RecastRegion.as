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

public class RecastRegion {

	public static const RC_NULL_NEI:int= 0xffff;

	

	public static function calculateDistanceField(chf:CompactHeightfield, src:Array):int {
		var maxDist:int;
		var w:int= chf.width;
		var h:int= chf.height;

		// Init distance and points.
		for (var i:int= 0; i < chf.spanCount; ++i)
			src[i] = 0xffff;

		// Mark boundary cells.
		for (var y:int= 0; y < h; ++y) {
			for (var x:int= 0; x < w; ++x) {
				var c:CompactCell= chf.cells[x + y * w];
				var ni:int;
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					var s:CompactSpan= chf.spans[i];
					var area:int= chf.areas[i];

					var nc:int= 0;
					for (var dir:int= 0; dir < 4; ++dir) {
						if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
							var ax:int= x + RecastCommon.GetDirOffsetX(dir);
							var ay:int= y + RecastCommon.GetDirOffsetY(dir);
							var ai:int= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, dir);
							if (area == chf.areas[ai])
								nc++;
						}
					}
					if (nc != 4)
						src[i] = 0;
				}
			}
		}

		// Pass 1
		for (y= 0; y < h; ++y) {
			for (x= 0; x < w; ++x) {
				c= chf.cells[x + y * w];
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					s= chf.spans[i];

					if (RecastCommon.GetCon(s, 0) != RecastConstants.RC_NOT_CONNECTED) {
						// (-1,0)
						ax= x + RecastCommon.GetDirOffsetX(0);
						ay= y + RecastCommon.GetDirOffsetY(0);
						ai= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, 0);
						var as_:CompactSpan= chf.spans[ai];
						if (src[ai] + 2< src[i])
							src[i] = src[ai] + 2;

						// (-1,-1)
						if (RecastCommon.GetCon(as_, 3) != RecastConstants.RC_NOT_CONNECTED) {
							var aax:int= ax + RecastCommon.GetDirOffsetX(3);
							var aay:int= ay + RecastCommon.GetDirOffsetY(3);
							var aai:int= chf.cells[aax + aay * w].index + RecastCommon.GetCon(as_, 3);
							if (src[aai] + 3< src[i])
								src[i] = src[aai] + 3;
						}
					}
					if (RecastCommon.GetCon(s, 3) != RecastConstants.RC_NOT_CONNECTED) {
						// (0,-1)
						ax= x + RecastCommon.GetDirOffsetX(3);
						ay= y + RecastCommon.GetDirOffsetY(3);
						ai= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, 3);
						as_= chf.spans[ai];
						if (src[ai] + 2< src[i])
							src[i] = src[ai] + 2;

						// (1,-1)
						if (RecastCommon.GetCon(as_, 2) != RecastConstants.RC_NOT_CONNECTED) {
							aax= ax + RecastCommon.GetDirOffsetX(2);
							aay= ay + RecastCommon.GetDirOffsetY(2);
							aai= chf.cells[aax + aay * w].index + RecastCommon.GetCon(as_, 2);
							if (src[aai] + 3< src[i])
								src[i] = src[aai] + 3;
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
						if (src[ai] + 2< src[i])
							src[i] = src[ai] + 2;

						// (1,1)
						if (RecastCommon.GetCon(as_, 1) != RecastConstants.RC_NOT_CONNECTED) {
							aax= ax + RecastCommon.GetDirOffsetX(1);
							aay= ay + RecastCommon.GetDirOffsetY(1);
							aai= chf.cells[aax + aay * w].index + RecastCommon.GetCon(as_, 1);
							if (src[aai] + 3< src[i])
								src[i] = src[aai] + 3;
						}
					}
					if (RecastCommon.GetCon(s, 1) != RecastConstants.RC_NOT_CONNECTED) {
						// (0,1)
						ax= x + RecastCommon.GetDirOffsetX(1);
						ay= y + RecastCommon.GetDirOffsetY(1);
						ai= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, 1);
						as_= chf.spans[ai] as CompactSpan;
						if (src[ai] + 2< src[i])
							src[i] = src[ai] + 2;

						// (-1,1)
						if (RecastCommon.GetCon(as_, 0) != RecastConstants.RC_NOT_CONNECTED) {
							aax= ax + RecastCommon.GetDirOffsetX(0);
							aay= ay + RecastCommon.GetDirOffsetY(0);
							aai= chf.cells[aax + aay * w].index + RecastCommon.GetCon(as_, 0);
							if (src[aai] + 3< src[i])
								src[i] = src[aai] + 3;
						}
					}
				}
			}
		}

		maxDist = 0;
		for (i= 0; i < chf.spanCount; ++i)
			maxDist = Math.max(src[i], maxDist);

		return maxDist;
	}

	private static function boxBlur(chf:CompactHeightfield, thr:int, src:Array):Array {
		var w:int= chf.width;
		var h:int= chf.height;
		var dst:Array= []//[]//chf.spanCount];

		thr *= 2;

		for (var y:int= 0; y < h; ++y) {
			for (var x:int= 0; x < w; ++x) {
				var c:CompactCell= chf.cells[x + y * w];
				for (var i:int= c.index, ni:int = c.index + c.count; i < ni; ++i) {
					var s:CompactSpan= chf.spans[i];
					var cd:int= src[i];
					if (cd <= thr) {
						dst[i] = cd;
						continue;
					}

					var d:int= cd;
					for (var dir:int= 0; dir < 4; ++dir) {
						if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
							var ax:int= x + RecastCommon.GetDirOffsetX(dir);
							var ay:int= y + RecastCommon.GetDirOffsetY(dir);
							var ai:int= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, dir);
							d += src[ai];

							var as_:CompactSpan= chf.spans[ai];
							var dir2:int= (dir + 1) & 0x3;
							if (RecastCommon.GetCon(as_, dir2) != RecastConstants.RC_NOT_CONNECTED) {
								var ax2:int= ax + RecastCommon.GetDirOffsetX(dir2);
								var ay2:int= ay + RecastCommon.GetDirOffsetY(dir2);
								var ai2:int= chf.cells[ax2 + ay2 * w].index + RecastCommon.GetCon(as_, dir2);
								d += src[ai2];
							} else {
								d += cd;
							}
						} else {
							d += cd * 2;
						}
					}
					dst[i] = ((d + 5) / 9);
				}
			}
		}
		return dst;
	}

	private static function floodRegion(x:int, y:int, i:int, level:int, r:int, chf:CompactHeightfield, srcReg:Array,
			srcDist:Array, stack:Array):Boolean {
		var w:int= chf.width;

		var area:int= chf.areas[i];

		// Flood fill mark region.
		stack.splice(0, stack.length);//.clear();
		stack.push(x);
		stack.push(y);
		stack.push(i);
		srcReg[i] = r;
		srcDist[i] = 0;

		var lev:int= level >= 2? level - 2: 0;
		var count:int= 0;

		while (stack.length > 0) {
			var ci:int= stack.pop();//.remove(stack.length - 1);
			var cy:int= stack.pop();//.remove(stack.length - 1);
			var cx:int= stack.pop();//.remove(stack.length - 1);

			var cs:CompactSpan= chf.spans[ci];

			// Check if any of the neighbours already have a valid region set.
			var ar:int= 0;
			for (var dir:int= 0; dir < 4; ++dir) {
				// 8 connected
				if (RecastCommon.GetCon(cs, dir) != RecastConstants.RC_NOT_CONNECTED) {
					var ax:int= cx + RecastCommon.GetDirOffsetX(dir);
					var ay:int= cy + RecastCommon.GetDirOffsetY(dir);
					var ai:int= chf.cells[ax + ay * w].index + RecastCommon.GetCon(cs, dir);
					if (chf.areas[ai] != area)
						continue;
					var nr:int= srcReg[ai];
					if ((nr & RecastConstants.RC_BORDER_REG) != 0) // Do not take borders into account.
						continue;
					if (nr != 0&& nr != r) {
						ar = nr;
						break;
					}

					var as_:CompactSpan= chf.spans[ai];

					var dir2:int= (dir + 1) & 0x3;
					if (RecastCommon.GetCon(as_, dir2) != RecastConstants.RC_NOT_CONNECTED) {
						var ax2:int= ax + RecastCommon.GetDirOffsetX(dir2);
						var ay2:int= ay + RecastCommon.GetDirOffsetY(dir2);
						var ai2:int= chf.cells[ax2 + ay2 * w].index + RecastCommon.GetCon(as_, dir2);
						if (chf.areas[ai2] != area)
							continue;
						var nr2:int= srcReg[ai2];
						if (nr2 != 0&& nr2 != r) {
							ar = nr2;
							break;
						}
					}
				}
			}
			if (ar != 0) {
				srcReg[ci] = 0;
				continue;
			}

			count++;

			// Expand neighbours.
			for (dir= 0; dir < 4; ++dir) {
				if (RecastCommon.GetCon(cs, dir) != RecastConstants.RC_NOT_CONNECTED) {
					ax= cx + RecastCommon.GetDirOffsetX(dir);
					ay= cy + RecastCommon.GetDirOffsetY(dir);
					ai= chf.cells[ax + ay * w].index + RecastCommon.GetCon(cs, dir);
					if (chf.areas[ai] != area)
						continue;
					if (chf.dist[ai] >= lev && srcReg[ai] == 0) {
						srcReg[ai] = r;
						srcDist[ai] = 0;
						stack.push(ax);
						stack.push(ay);
						stack.push(ai);
					}
				}
			}
		}

		return count > 0;
	}

	private static function expandRegions(maxIter:int, level:int, chf:CompactHeightfield, srcReg:Array, srcDist:Array,
			dstReg:Array, dstDist:Array, stack:Array, fillStack:Boolean):Array {
		var w:int= chf.width;
		var h:int= chf.height;

		if (fillStack) {
			// Find cells revealed by the raised level.
			stack.splice(0, stack.length);// .clear();
			for (var y:int= 0; y < h; ++y) {
				for (var x:int= 0; x < w; ++x) {
					var c:CompactCell= chf.cells[x + y * w];
					for (var i:int= c.index, ni:int = c.index + c.count; i < ni; ++i) {
						if (chf.dist[i] >= level && srcReg[i] == 0&& chf.areas[i] != RecastConstants.RC_NULL_AREA) {
							stack.push(x);
							stack.push(y);
							stack.push(i);
						}
					}
				}
			}
		} else // use cells in the input stack
		{
			// mark all cells which already have a region
			for (var j:int= 0; j < stack.length; j += 3) {
				i= stack[j + 2];
				if (srcReg[i] != 0)
					stack[j + 2]= -1;
			}
		}

		var iter:int= 0;
		while (stack.length > 0) {
			var failed:int = 0;
			System.arraycopy(srcReg, 0, dstReg, 0, chf.spanCount);
			System.arraycopy(srcDist, 0, dstDist, 0, chf.spanCount);

			for (j= 0; j < stack.length; j += 3) {
				x= stack[j + 0];
				y= stack[j + 1];
				i= stack[j + 2];
				if (i < 0) {
					failed++;
					continue;
				}

				var r:int= srcReg[i];
				var d2:int= 0xffff;
				var area:int= chf.areas[i];
				var s:CompactSpan= chf.spans[i];
				for (var dir:int= 0; dir < 4; ++dir) {
					if (RecastCommon.GetCon(s, dir) == RecastConstants.RC_NOT_CONNECTED)
						continue;
					var ax:int= x + RecastCommon.GetDirOffsetX(dir);
					var ay:int= y + RecastCommon.GetDirOffsetY(dir);
					var ai:int= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, dir);
					if (chf.areas[ai] != area)
						continue;
					if (srcReg[ai] > 0&& (srcReg[ai] & RecastConstants.RC_BORDER_REG) == 0) {
						if (srcDist[ai] + 2< d2) {
							r = srcReg[ai];
							d2 = srcDist[ai] + 2;
						}
					}
				}
				if (r != 0) {
					stack[j + 2]= -1; // mark as used
					dstReg[i] = r;
					dstDist[i] = d2;
				} else {
					failed++;
				}
			}

			// rcSwap source and dest.
			var temp:Array= srcReg;
			srcReg = dstReg;
			dstReg = temp;
			temp = srcDist;
			srcDist = dstDist;
			dstDist = temp;

			if (failed * 3== stack.length)
				break;

			if (level > 0) {
				++iter;
				if (iter >= maxIter)
					break;
			}
		}

		return srcReg;
	}

	private static function sortCellsByLevel(startLevel:int, chf:CompactHeightfield, srcReg:Array, nbStacks:int,
			stacks:Array, loglevelsPerStack:int):void // the levels per stack (2 in our case) as a bit shift
	{
		var w:int= chf.width;
		var h:int= chf.height;
		startLevel = startLevel >> loglevelsPerStack;

		for (var j:int= 0; j < nbStacks; ++j){
			(stacks[j] as Array).splice(0,(stacks[j] as Array).length );// .clear();
		}

		// put all cells in the level range into the appropriate stacks
		for (var y:int= 0; y < h; ++y) {
			for (var x:int= 0; x < w; ++x) {
				var c:CompactCell= chf.cells[x + y * w];
				for (var i:int= c.index, ni:int = c.index + c.count; i < ni; ++i) {
					if (chf.areas[i] == RecastConstants.RC_NULL_AREA || srcReg[i] != 0)
						continue;

					var level:int= chf.dist[i] >> loglevelsPerStack;
					var sId:int= startLevel - level;
					if (sId >= nbStacks)
						continue;
					if (sId < 0)
						sId = 0;

					stacks[sId].push(x);
					stacks[sId].push(y);
					stacks[sId].push(i);
				}
			}
		}
	}

	private static function appendStacks(srcStack:Array, dstStack:Array, srcReg:Array):void {
		for (var j:int= 0; j < srcStack.length; j += 3) {
			var i:int= srcStack[j + 2];
			if ((i < 0) || (srcReg[i] != 0))
				continue;
			dstStack.push(srcStack[j]);
			dstStack.push(srcStack[j + 1]);
			dstStack.push(srcStack[j + 2]);
		}
	}

	 

	private static function removeAdjacentNeighbours(reg:Region):void {
		// Remove adjacent duplicates.
		for (var i:int= 0; i < reg.connections.length && reg.connections.length > 1;) {
			var ni:int= (i + 1) % reg.connections.length;
			if (reg.connections[i] == reg.connections[ni]) {
				reg.connections.splice(i, 1);// .remove(i);
			} else
				++i;
		}
	}

	private static function replaceNeighbour(reg:Region, oldId:int, newId:int):void {
		var neiChanged:Boolean= false;
		for (var i:int= 0; i < reg.connections.length; ++i) {
			if (reg.connections[i] == oldId) {
				reg.connections[i]= newId;
				neiChanged = true;
			}
		}
		for (i= 0; i < reg.floors.length; ++i) {
			if (reg.floors[i] == oldId)
				reg.floors[i]= newId;
		}
		if (neiChanged)
			removeAdjacentNeighbours(reg);
	}

	private static function canMergeWithRegion(rega:Region, regb:Region):Boolean {
		if (rega.areaType != regb.areaType)
			return false;
		var n:int= 0;
		for (var i:int= 0; i < rega.connections.length; ++i) {
			if (rega.connections[i] == regb.id)
				n++;
		}
		if (n > 1)
			return false;
		for (i= 0; i < rega.floors.length; ++i) {
			if (rega.floors[i] == regb.id)
				return false;
		}
		return true;
	}

	private static function addUniqueFloorRegion(reg:Region, n:int):void {
		if (reg.floors.indexOf(n)==-1) {
			reg.floors.push(n);
		}
	}

	private static function mergeRegions(rega:Region, regb:Region):Boolean {
		var aid:int= rega.id;
		var bid:int= regb.id;

		// Duplicate current neighbourhood.
		var acon:Array = rega.connections;
		//rega.connections();
		var bcon:Array = regb.connections;

		// Find insertion point on A.
		var insa:int= -1;
		for (var i:int= 0; i < acon.length; ++i) {
			if (acon[i] == bid) {
				insa = i;
				break;
			}
		}
		if (insa == -1)
			return false;

		// Find insertion point on B.
		var insb:int= -1;
		for (i= 0; i < bcon.length; ++i) {
			if (bcon[i] == aid) {
				insb = i;
				break;
			}
		}
		if (insb == -1)
			return false;

		// Merge neighbours.
		var ni:int;
		rega.connections.splice(0, rega.connections.length);//.clear();
		for (i= 0, ni = acon.length; i < ni - 1; ++i)
			rega.connections.push(acon[(insa + 1+ i) % ni]);

		for (i= 0, ni = bcon.length; i < ni - 1; ++i)
			rega.connections.push(bcon[(insb + 1+ i) % ni]);

		removeAdjacentNeighbours(rega);

		for (var j:int= 0; j < regb.floors.length; ++j)
			addUniqueFloorRegion(rega, regb.floors[j]);
		rega.spanCount += regb.spanCount;
		regb.spanCount = 0;
		regb.connections.splice(0, regb.connections.length);//.clear();

		return true;
	}

	private static function isRegionConnectedToBorder(reg:Region):Boolean {
		// Region is connected to border if
		// one of the neighbours is null id.
		return reg.connections.indexOf(0)!=-1;
	}

	private static function isSolidEdge(chf:CompactHeightfield, srcReg:Array, x:int, y:int, i:int, dir:int):Boolean {
		var s:CompactSpan= chf.spans[i];
		var r:int= 0;
		if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
			var ax:int= x + RecastCommon.GetDirOffsetX(dir);
			var ay:int= y + RecastCommon.GetDirOffsetY(dir);
			var ai:int= chf.cells[ax + ay * chf.width].index + RecastCommon.GetCon(s, dir);
			r = srcReg[ai];
		}
		if (r == srcReg[i])
			return false;
		return true;
	}

	private static function walkContour(x:int, y:int, i:int, dir:int, chf:CompactHeightfield, srcReg:Array,
			cont:Array):void {
		var startDir:int= dir;
		var starti:int= i;

		var ss:CompactSpan= chf.spans[i];
		var curReg:int= 0;
		if (RecastCommon.GetCon(ss, dir) != RecastConstants.RC_NOT_CONNECTED) {
			var ax:int= x + RecastCommon.GetDirOffsetX(dir);
			var ay:int= y + RecastCommon.GetDirOffsetY(dir);
			var ai:int= chf.cells[ax + ay * chf.width].index + RecastCommon.GetCon(ss, dir);
			curReg = srcReg[ai];
		}
		cont.push(curReg);

		var iter:int= 0;
		while (++iter < 40000) {
			var s:CompactSpan= chf.spans[i];

			if (isSolidEdge(chf, srcReg, x, y, i, dir)) {
				// Choose the edge corner
				var r:int= 0;
				if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
					ax= x + RecastCommon.GetDirOffsetX(dir);
					ay= y + RecastCommon.GetDirOffsetY(dir);
					ai= chf.cells[ax + ay * chf.width].index + RecastCommon.GetCon(s, dir);
					r = srcReg[ai];
				}
				if (r != curReg) {
					curReg = r;
					cont.push(curReg);
				}

				dir = (dir + 1) & 0x3; // Rotate CW
			} else {
				var ni:int= -1;
				var nx:int= x + RecastCommon.GetDirOffsetX(dir);
				var ny:int= y + RecastCommon.GetDirOffsetY(dir);
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

		// Remove adjacent duplicates.
		if (cont.length > 1) {
			for (var j:int= 0; j < cont.length;) {
				var nj:int= (j + 1) % cont.length;
				if (cont[j] == cont[nj]) {
					cont.splice(j, 1);//.remove(j);
				} else
					++j;
			}
		}
	}

	private static function mergeAndFilterRegions(ctx:Context, minRegionArea:int, mergeRegionSize:int, maxRegionId:int,
			chf:CompactHeightfield, srcReg:Array, overlaps:Array):int {
		var w:int= chf.width;
		var h:int= chf.height;

		var nreg:int= maxRegionId + 1;
		var regions:Array = [];////new Region[nreg];

		// Construct regions
		for (var i:int= 0; i < nreg; ++i)
			regions[i] = new Region(i);

		// Find edge of a region and find connections around the contour.
		for (var y:int= 0; y < h; ++y) {
			for (var x:int= 0; x < w; ++x) {
				var c:CompactCell = chf.cells[x + y * w];
				var ni:int;
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					var r:int= srcReg[i];
					if (r == 0|| r >= nreg)
						continue;

					var reg:Region= regions[r];
					reg.spanCount++;

					// Update floors.
					for (var j:int= c.index; j < ni; ++j) {
						if (i == j)
							continue;
						var floorId:int= srcReg[j];
						if (floorId == 0|| floorId >= nreg)
							continue;
						if (floorId == r)
							reg.overlap = true;
						addUniqueFloorRegion(reg, floorId);
					}

					// Have found contour
					if (reg.connections.length > 0)
						continue;

					reg.areaType = chf.areas[i];

					// Check if this cell is next to a border.
					var ndir:int= -1;
					for (var dir:int= 0; dir < 4; ++dir) {
						if (isSolidEdge(chf, srcReg, x, y, i, dir)) {
							ndir = dir;
							break;
						}
					}

					if (ndir != -1) {
						// The cell is at border.
						// Walk around the contour to find all the neighbours.
						walkContour(x, y, i, ndir, chf, srcReg, reg.connections);
					}
				}
			}
		}

		// Remove too small regions.
		var stack:Array = [];
		var trace:Array = [];
		for (i= 0; i < nreg; ++i) {
			reg= regions[i];
			if (reg.id == 0|| (reg.id & RecastConstants.RC_BORDER_REG) != 0)
				continue;
			if (reg.spanCount == 0)
				continue;
			if (reg.visited)
				continue;

			// Count the total size of all the connected regions.
			// Also keep track of the regions connects to a tile border.
			var connectsToBorder:Boolean= false;
			var spanCount:int= 0;
			stack.splice(0, stack.length);//.clear();
			trace.splice(0, trace.length);//.clear();

			reg.visited = true;
			stack.push(i);

			while (stack.length > 0) {
				// Pop
				var ri:int = stack.pop();// .remove(stack.length - 1);

				var creg:Region= regions[ri];

				spanCount += creg.spanCount;
				trace.push(ri);

				for (j= 0; j < creg.connections.length; ++j) {
					if ((creg.connections[j] & RecastConstants.RC_BORDER_REG) != 0) {
						connectsToBorder = true;
						continue;
					}
					var neireg:Region= regions[creg.connections[j]];
					if (neireg.visited)
						continue;
					if (neireg.id == 0|| (neireg.id & RecastConstants.RC_BORDER_REG) != 0)
						continue;
					// Visit
					stack.push(neireg.id);
					neireg.visited = true;
				}
			}

			// If the accumulated regions size is too small, remove it.
			// Do not remove areas which connect to tile borders
			// as their size cannot be estimated correctly and removing them
			// can potentially remove necessary areas.
			if (spanCount < minRegionArea && !connectsToBorder) {
				// Kill all visited regions.
				for (j= 0; j < trace.length; ++j) {
					regions[trace[j]].spanCount = 0;
					regions[trace[j]].id = 0;
				}
			}
		}

		// Merge too small regions to neighbour regions.
		var mergeCount:int= 0;
		do {
			mergeCount = 0;
			for (i= 0; i < nreg; ++i) {
				reg= regions[i];
				if (reg.id == 0|| (reg.id & RecastConstants.RC_BORDER_REG) != 0)
					continue;
				if (reg.overlap)
					continue;
				if (reg.spanCount == 0)
					continue;

				// Check to see if the region should be merged.
				if (reg.spanCount > mergeRegionSize && isRegionConnectedToBorder(reg))
					continue;

				// Small region with more than 1 connection.
				// Or region which is not connected to a border at all.
				// Find smallest neighbour region that connects to this one.
				var smallest:int= 0xfffffff;
				var mergeId:int= reg.id;
				for (j= 0; j < reg.connections.length; ++j) {
					if ((reg.connections[j] & RecastConstants.RC_BORDER_REG) != 0)
						continue;
					var mreg:Region= regions[reg.connections[j]];
					if (mreg.id == 0|| (mreg.id & RecastConstants.RC_BORDER_REG) != 0|| mreg.overlap)
						continue;
					if (mreg.spanCount < smallest && canMergeWithRegion(reg, mreg) && canMergeWithRegion(mreg, reg)) {
						smallest = mreg.spanCount;
						mergeId = mreg.id;
					}
				}
				// Found new id.
				if (mergeId != reg.id) {
					var oldId:int= reg.id;
					var target:Region= regions[mergeId];

					// Merge neighbours.
					if (mergeRegions(target, reg)) {
						// Fixup regions pointing to current region.
						for (j= 0; j < nreg; ++j) {
							if (regions[j].id == 0|| (regions[j].id & RecastConstants.RC_BORDER_REG) != 0)
								continue;
							// If another region was already merged into current region
							// change the nid of the previous region too.
							if (regions[j].id == oldId)
								regions[j].id = mergeId;
							// Replace the current region with the new one if the
							// current regions is neighbour.
							replaceNeighbour(regions[j], oldId, mergeId);
						}
						mergeCount++;
					}
				}
			}
		} while (mergeCount > 0);

		// Compress region Ids.
		for (i= 0; i < nreg; ++i) {
			regions[i].remap = false;
			if (regions[i].id == 0)
				continue; // Skip nil regions.
			if ((regions[i].id & RecastConstants.RC_BORDER_REG) != 0)
				continue; // Skip external regions.
			regions[i].remap = true;
		}

		var regIdGen:int= 0;
		for (i= 0; i < nreg; ++i) {
			if (!regions[i].remap)
				continue;
			oldId= regions[i].id;
			var newId:int= ++regIdGen;
			for (j= i; j < nreg; ++j) {
				if (regions[j].id == oldId) {
					regions[j].id = newId;
					regions[j].remap = false;
				}
			}
		}
		maxRegionId = regIdGen;

		// Remap regions.
		for (i= 0; i < chf.spanCount; ++i) {
			if ((srcReg[i] & RecastConstants.RC_BORDER_REG) == 0)
				srcReg[i] = regions[srcReg[i]].id;
		}

		// Return regions that we found to be overlapping.
		for (i= 0; i < nreg; ++i)
			if (regions[i].overlap)
				overlaps.push(regions[i].id);

		return maxRegionId;
	}

	private static function addUniqueConnection(reg:Region, n:int):void {
		if (reg.connections.indexOf(n)==-1) {
			reg.connections.push(n);
		}
	}

	private static function mergeAndFilterLayerRegions(ctx:Context, minRegionArea:int, maxRegionId:int,
			chf:CompactHeightfield, srcReg:Array, overlaps:Array):int {
		var w:int= chf.width;
		var h:int= chf.height;

		var nreg:int= maxRegionId + 1;
		var regions:Array= new Region[nreg];

		// Construct regions
		for (var i:int= 0; i < nreg; ++i)
			regions[i] = new Region(i);

		// Find region neighbours and overlapping regions.
		var lregs:Array = [];
		for (var y:int= 0; y < h; ++y) {
			for (var x:int= 0; x < w; ++x) {
				var c:CompactCell= chf.cells[x + y * w];

				lregs.splice(0, lregs.length);//.clear();
				var ni:int;
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					var s:CompactSpan= chf.spans[i];
					var ri:int= srcReg[i];
					if (ri == 0|| ri >= nreg)
						continue;
					var reg:Region= regions[ri];

					reg.spanCount++;

					reg.ymin = Math.min(reg.ymin, s.y);
					reg.ymax = Math.max(reg.ymax, s.y);
					// Collect all region layers.
					lregs.push(ri);

					// Update neighbours
					for (var dir:int= 0; dir < 4; ++dir) {
						if (RecastCommon.GetCon(s, dir) != RecastConstants.RC_NOT_CONNECTED) {
							var ax:int= x + RecastCommon.GetDirOffsetX(dir);
							var ay:int= y + RecastCommon.GetDirOffsetY(dir);
							var ai:int= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, dir);
							var rai:int= srcReg[ai];
							if (rai > 0&& rai < nreg && rai != ri)
								addUniqueConnection(reg, rai);
							if ((rai & RecastConstants.RC_BORDER_REG) != 0)
								reg.connectsToBorder = true;
						}
					}

				}

				// Update overlapping regions.
				for (i= 0; i < lregs.length - 1; ++i) {
					for (var j:int= i + 1; j < lregs.length; ++j) {
						if (lregs[i] != lregs[j]) {
							var ri2:Region= regions[lregs[i]];
							var rj:Region= regions[lregs[j]];
							addUniqueFloorRegion(ri2, lregs[j]);
							addUniqueFloorRegion(rj, lregs[i]);
						}
					}
				}

			}
		}

		// Create 2D layers from regions.
		var layerId:int= 1;

		for (i= 0; i < nreg; ++i)
			regions[i].id = 0;

		// Merge montone regions to create non-overlapping areas.
		var stack:Array = [];
		for (i= 1; i < nreg; ++i) {
			var root:Region= regions[i];
			// Skip already visited.
			if (root.id != 0)
				continue;

			// Start search.
			root.id = layerId;

			stack.splice(0, stack.length);//.clear();
			stack.push(i);

			while (stack.length > 0) {
				// Pop front
				reg= regions[stack.shift()/*.remove(0)*/];

				var ncons:int= reg.connections.length;
				for (j= 0; j < ncons; ++j) {
					var nei:int= reg.connections[j];
					var regn:Region= regions[nei];
					// Skip already visited.
					if (regn.id != 0)
						continue;
					// Skip if the neighbour is overlapping root region.
					var overlap:Boolean= false;
					for (var k:int= 0; k < root.floors.length; k++) {
						if (root.floors[k] == nei) {
							overlap = true;
							break;
						}
					}
					if (overlap)
						continue;

					// Deepen
					stack.push(nei);

					// Mark layer id
					regn.id = layerId;
					// Merge current layers to root.
					for (k= 0; k < regn.floors.length; ++k)
						addUniqueFloorRegion(root, regn.floors[k]);
					root.ymin = Math.min(root.ymin, regn.ymin);
					root.ymax = Math.max(root.ymax, regn.ymax);
					root.spanCount += regn.spanCount;
					regn.spanCount = 0;
					root.connectsToBorder = root.connectsToBorder || regn.connectsToBorder;
				}
			}

			layerId++;
		}

		// Remove small regions
		for (i= 0; i < nreg; ++i) {
			if (regions[i].spanCount > 0&& regions[i].spanCount < minRegionArea && !regions[i].connectsToBorder) {
				var reg2:int= regions[i].id;
				for (j= 0; j < nreg; ++j)
					if (regions[j].id == reg2)
						regions[j].id = 0;
			}
		}

		// Compress region Ids.
		for (i= 0; i < nreg; ++i) {
			regions[i].remap = false;
			if (regions[i].id == 0)
				continue; // Skip nil regions.
			if ((regions[i].id & RecastConstants.RC_BORDER_REG) != 0)
				continue; // Skip external regions.
			regions[i].remap = true;
		}

		var regIdGen:int= 0;
		for (i= 0; i < nreg; ++i) {
			if (!regions[i].remap)
				continue;
			var oldId:int= regions[i].id;
			var newId:int= ++regIdGen;
			for (j= i; j < nreg; ++j) {
				if (regions[j].id == oldId) {
					regions[j].id = newId;
					regions[j].remap = false;
				}
			}
		}
		maxRegionId = regIdGen;

		// Remap regions.
		for (i= 0; i < chf.spanCount; ++i) {
			if ((srcReg[i] & RecastConstants.RC_BORDER_REG) == 0)
				srcReg[i] = regions[srcReg[i]].id;
		}

		return maxRegionId;
	}

	/// @par
	/// 
	/// This is usually the second to the last step in creating a fully built
	/// compact heightfield.  This step is required before regions are built
	/// using #rcBuildRegions or #rcBuildRegionsMonotone.
	/// 
	/// After this step, the distance data is available via the rcCompactHeightfield::maxDistance
	/// and rcCompactHeightfield::dist fields.
	///
	/// @see rcCompactHeightfield, rcBuildRegions, rcBuildRegionsMonotone
	public static function buildDistanceField(ctx:Context, chf:CompactHeightfield):void {

		ctx.startTimer("BUILD_DISTANCEFIELD");
		var src:Array= []//[]//chf.spanCount];
		ctx.startTimer("DISTANCEFIELD_DIST");

		var maxDist:int= calculateDistanceField(chf, src);
		chf.maxDistance = maxDist;

		ctx.stopTimer("DISTANCEFIELD_DIST");

		ctx.startTimer("DISTANCEFIELD_BLUR");

		// Blur
		src = boxBlur(chf, 1, src);

		// Store distance.
		chf.dist = src;

		ctx.stopTimer("DISTANCEFIELD_BLUR");

		ctx.stopTimer("BUILD_DISTANCEFIELD");

	}

	private static function paintRectRegion(minx:int, maxx:int, miny:int, maxy:int, regId:int, chf:CompactHeightfield,
			srcReg:Array):void {
		var w:int= chf.width;
		for (var y:int= miny; y < maxy; ++y) {
			for (var x:int= minx; x < maxx; ++x) {
				var c:CompactCell= chf.cells[x + y * w];
				for (var i:int= c.index, ni:int = c.index + c.count; i < ni; ++i) {
					if (chf.areas[i] != RecastConstants.RC_NULL_AREA)
						srcReg[i] = regId;
				}
			}
		}
	}

	/// @par
	/// 
	/// Non-null regions will consist of connected, non-overlapping walkable spans that form a single contour.
	/// Contours will form simple polygons.
	/// 
	/// If multiple regions form an area that is smaller than @p minRegionArea, then all spans will be
	/// re-assigned to the zero (null) region.
	/// 
	/// Partitioning can result in smaller than necessary regions. @p mergeRegionArea helps 
	/// reduce unecessarily small regions.
	/// 
	/// See the #rcConfig documentation for more information on the configuration parameters.
	/// 
	/// The region data will be available via the rcCompactHeightfield::maxRegions
	/// and rcCompactSpan::reg fields.
	/// 
	/// @warning The distance field must be created using #rcBuildDistanceField before attempting to build regions.
	/// 
	/// @see rcCompactHeightfield, rcCompactSpan, rcBuildDistanceField, rcBuildRegionsMonotone, rcConfig
	public static function buildRegionsMonotone(ctx:Context, chf:CompactHeightfield, borderSize:int, minRegionArea:int,
			mergeRegionArea:int):void {
		ctx.startTimer("BUILD_REGIONS");

		var w:int= chf.width;
		var h:int= chf.height;
		var id:int= 1;

		var srcReg:Array= []//chf.spanCount];

		var nsweeps:int= Math.max(chf.width, chf.height);
		var sweeps:Array= new SweepSpan[nsweeps];
		for (var i:int= 0; i < sweeps.length; i++) {
			sweeps[i] = new SweepSpan();
		}

		// Mark border regions.
		if (borderSize > 0) {
			// Make sure border will not overflow.
			var bw:int= Math.min(w, borderSize);
			var bh:int= Math.min(h, borderSize);
			// Paint regions
			paintRectRegion(0, bw, 0, h, id | RecastConstants.RC_BORDER_REG, chf, srcReg);
			id++;
			paintRectRegion(w - bw, w, 0, h, id | RecastConstants.RC_BORDER_REG, chf, srcReg);
			id++;
			paintRectRegion(0, w, 0, bh, id | RecastConstants.RC_BORDER_REG, chf, srcReg);
			id++;
			paintRectRegion(0, w, h - bh, h, id | RecastConstants.RC_BORDER_REG, chf, srcReg);
			id++;

			chf.borderSize = borderSize;
		}

		var prev:Array= []//256];

		// Sweep one line at a time.
		for (var y:int= borderSize; y < h - borderSize; ++y) {
			// Collect spans from this row.
			Arrays.fill(prev, 0, id, 0);
			var rid:int= 1;

			for (var x:int= borderSize; x < w - borderSize; ++x) {
				var c:CompactCell= chf.cells[x + y * w];
				var ni:int;
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					var s:CompactSpan= chf.spans[i];
					if (chf.areas[i] == RecastConstants.RC_NULL_AREA)
						continue;

					// -x
					var previd:int= 0;
					if (RecastCommon.GetCon(s, 0) != RecastConstants.RC_NOT_CONNECTED) {
						var ax:int= x + RecastCommon.GetDirOffsetX(0);
						var ay:int= y + RecastCommon.GetDirOffsetY(0);
						var ai:int= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, 0);
						if ((srcReg[ai] & RecastConstants.RC_BORDER_REG) == 0&& chf.areas[i] == chf.areas[ai])
							previd = srcReg[ai];
					}

					if (previd == 0) {
						previd = rid++;
						sweeps[previd].rid = previd;
						sweeps[previd].ns = 0;
						sweeps[previd].nei = 0;
					}

					// -y
					if (RecastCommon.GetCon(s, 3) != RecastConstants.RC_NOT_CONNECTED) {
						 ax= x + RecastCommon.GetDirOffsetX(3);
						 ay= y + RecastCommon.GetDirOffsetY(3);
						ai= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, 3);
						if (srcReg[ai] != 0&& (srcReg[ai] & RecastConstants.RC_BORDER_REG) == 0&& chf.areas[i] == chf.areas[ai]) {
							var nr:int= srcReg[ai];
							if (sweeps[previd].nei == 0|| sweeps[previd].nei == nr) {
								sweeps[previd].nei = nr;
								sweeps[previd].ns++;
								prev[nr]++;
							} else {
								sweeps[previd].nei = RC_NULL_NEI;
							}
						}
					}

					srcReg[i] = previd;
				}
			}

			// Create unique ID.
			for (i= 1; i < rid; ++i) {
				if (sweeps[i].nei != RC_NULL_NEI && sweeps[i].nei != 0&& prev[sweeps[i].nei] == sweeps[i].ns) {
					sweeps[i].id = sweeps[i].nei;
				} else {
					sweeps[i].id = id++;
				}
			}

			// Remap IDs
			for (x= borderSize; x < w - borderSize; ++x) {
				c= chf.cells[x + y * w];
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					if (srcReg[i] > 0&& srcReg[i] < rid)
						srcReg[i] = sweeps[srcReg[i]].id;
				}
			}
		}

		ctx.startTimer("BUILD_REGIONS_FILTER");

		// Merge regions and filter out small regions.
		var overlaps:Array = [];
		chf.maxRegions = mergeAndFilterRegions(ctx, minRegionArea, mergeRegionArea, id, chf, srcReg, overlaps);

		// Monotone partitioning does not generate overlapping regions.

		ctx.stopTimer("BUILD_REGIONS_FILTER");

		// Store the result out.
		for (i= 0; i < chf.spanCount; ++i)
			chf.spans[i].reg = srcReg[i];

		ctx.stopTimer("BUILD_REGIONS");

	}

	/// @par
	/// 
	/// Non-null regions will consist of connected, non-overlapping walkable spans that form a single contour.
	/// Contours will form simple polygons.
	/// 
	/// If multiple regions form an area that is smaller than @p minRegionArea, then all spans will be
	/// re-assigned to the zero (null) region.
	/// 
	/// Watershed partitioning can result in smaller than necessary regions, especially in diagonal corridors. 
	/// @p mergeRegionArea helps reduce unecessarily small regions.
	/// 
	/// See the #rcConfig documentation for more information on the configuration parameters.
	/// 
	/// The region data will be available via the rcCompactHeightfield::maxRegions
	/// and rcCompactSpan::reg fields.
	/// 
	/// @warning The distance field must be created using #rcBuildDistanceField before attempting to build regions.
	/// 
	/// @see rcCompactHeightfield, rcCompactSpan, rcBuildDistanceField, rcBuildRegionsMonotone, rcConfig
	public static function buildRegions(ctx:Context, chf:CompactHeightfield, borderSize:int, minRegionArea:int,
			mergeRegionArea:int):void {
		ctx.startTimer("BUILD_REGIONS");

		var w:int= chf.width;
		var h:int= chf.height;

		ctx.startTimer("REGIONS_WATERSHED");

		var LOG_NB_STACKS:int= 3;
		var NB_STACKS:int= 1<< LOG_NB_STACKS;
		var lvlStacks:Array = [];
		for (var i:int= 0; i < NB_STACKS; ++i)
			lvlStacks.push([]);

		var stack:Array = [];

		var srcReg:Array= []//[]//chf.spanCount];
		var srcDist:Array= []//[]//chf.spanCount];
		var dstReg:Array= []//[]//chf.spanCount];
		var dstDist:Array = []//[]//chf.spanCount];
		Arrays.fill(srcReg, 0,chf.spanCount,0);
		Arrays.fill(srcDist, 0,chf.spanCount,0);
		Arrays.fill(dstReg, 0,chf.spanCount,0);
		Arrays.fill(dstDist, 0,chf.spanCount,0);

		var regionId:int= 1;
		var level:int= (chf.maxDistance + 1) & ~1;

		// TODO: Figure better formula, expandIters defines how much the 
		// watershed "overflows" and simplifies the regions. Tying it to
		// agent radius was usually good indication how greedy it could be.
		//		const int expandIters = 4 + walkableRadius * 2;
		var expandIters:int= 8;

		if (borderSize > 0) {
			// Make sure border will not overflow.
			var bw:int= Math.min(w, borderSize);
			var bh:int= Math.min(h, borderSize);
			// Paint regions
			paintRectRegion(0, bw, 0, h, regionId | RecastConstants.RC_BORDER_REG, chf, srcReg);
			regionId++;
			paintRectRegion(w - bw, w, 0, h, regionId | RecastConstants.RC_BORDER_REG, chf, srcReg);
			regionId++;
			paintRectRegion(0, w, 0, bh, regionId | RecastConstants.RC_BORDER_REG, chf, srcReg);
			regionId++;
			paintRectRegion(0, w, h - bh, h, regionId | RecastConstants.RC_BORDER_REG, chf, srcReg);
			regionId++;

			chf.borderSize = borderSize;
		}

		var sId:int= -1;
		while (level > 0) {
			level = level >= 2? level - 2: 0;
			sId = (sId + 1) & (NB_STACKS - 1);

			//			ctx->startTimer(RC_TIMER_DIVIDE_TO_LEVELS);

			if (sId == 0)
				sortCellsByLevel(level, chf, srcReg, NB_STACKS, lvlStacks, 1);
			else
				appendStacks(lvlStacks[sId - 1], lvlStacks[sId], srcReg); // copy left overs from last level

			//			ctx->stopTimer(RC_TIMER_DIVIDE_TO_LEVELS);

			ctx.startTimer("BUILD_REGIONS_EXPAND");

			// Expand current regions until no empty connected cells found.
			if (expandRegions(expandIters, level, chf, srcReg, srcDist, dstReg, dstDist, lvlStacks[sId],
					false) != srcReg) {
				var temp:Array= srcReg;
				srcReg = dstReg;
				dstReg = temp;
				temp = srcDist;
				srcDist = dstDist;
				dstDist = temp;
			}

			ctx.stopTimer("BUILD_REGIONS_EXPAND");

			ctx.startTimer("BUILD_REGIONS_FLOOD");

			// Mark new regions with IDs.
			for (var j:int= 0; j < lvlStacks[sId].length; j += 3) {
				var x:int= lvlStacks[sId][j];
				var y:int= lvlStacks[sId][j + 1];
				i= lvlStacks[sId][j + 2];
				if (i >= 0&& srcReg[i] == 0) {
					if (floodRegion(x, y, i, level, regionId, chf, srcReg, srcDist, stack))
						regionId++;
				}
			}

			ctx.stopTimer("BUILD_REGIONS_FLOOD");
		}

		// Expand current regions until no empty connected cells found.
		if (expandRegions(expandIters * 8, 0, chf, srcReg, srcDist, dstReg, dstDist, stack, true) != srcReg) {
			temp= srcReg;
			srcReg = dstReg;
			dstReg = temp;
			temp = srcDist;
			srcDist = dstDist;
			dstDist = temp;
		}

		ctx.stopTimer("BUILD_REGIONS_WATERSHED");

		ctx.startTimer("BUILD_REGIONS_FILTER");

		// Merge regions and filter out smalle regions.
		var overlaps:Array = [];
		chf.maxRegions = mergeAndFilterRegions(ctx, minRegionArea, mergeRegionArea, regionId, chf, srcReg, overlaps);

		// If overlapping regions were found during merging, split those regions.
		if (overlaps.length > 0) {
			("rcBuildRegions: " + overlaps.length + " overlapping regions.");
		}

		ctx.stopTimer("BUILD_REGIONS_FILTER");

		// Write the result out.
		for (i= 0; i < chf.spanCount; ++i)
			chf.spans[i].reg = srcReg[i];

		ctx.stopTimer("BUILD_REGIONS");

	}

	public static function buildLayerRegions(ctx:Context, chf:CompactHeightfield, borderSize:int, minRegionArea:int):void {

		ctx.startTimer("BUILD_REGIONS");

		var w:int= chf.width;
		var h:int= chf.height;
		var id:int= 1;

		var srcReg:Array= []//chf.spanCount];
		var nsweeps:int= Math.max(chf.width, chf.height);
		var sweeps:Array= new SweepSpan[nsweeps];
		for (var i:int= 0; i < sweeps.length; i++) {
			sweeps[i] = new SweepSpan();
		}

		// Mark border regions.
		if (borderSize > 0) {
			// Make sure border will not overflow.
			var bw:int= Math.min(w, borderSize);
			var bh:int= Math.min(h, borderSize);
			// Paint regions
			paintRectRegion(0, bw, 0, h, id | RecastConstants.RC_BORDER_REG, chf, srcReg);
			id++;
			paintRectRegion(w - bw, w, 0, h, id | RecastConstants.RC_BORDER_REG, chf, srcReg);
			id++;
			paintRectRegion(0, w, 0, bh, id | RecastConstants.RC_BORDER_REG, chf, srcReg);
			id++;
			paintRectRegion(0, w, h - bh, h, id | RecastConstants.RC_BORDER_REG, chf, srcReg);
			id++;

			chf.borderSize = borderSize;
		}

		var prev:Array= []//256];

		// Sweep one line at a time.
		for (var y:int= borderSize; y < h - borderSize; ++y) {
			// Collect spans from this row.
			Arrays.fill(prev, 0, id, 0);
			var rid:int= 1;

			for (var x:int= borderSize; x < w - borderSize; ++x) {
				var c:CompactCell= chf.cells[x + y * w];
				var ni:int;
				for (i= c.index, ni = c.index + c.count; i < ni; ++i) {
					var s:CompactSpan= chf.spans[i];
					if (chf.areas[i] == RecastConstants.RC_NULL_AREA)
						continue;

					// -x
					var previd:int= 0;
					if (RecastCommon.GetCon(s, 0) != RecastConstants.RC_NOT_CONNECTED) {
						var ax:int= x + RecastCommon.GetDirOffsetX(0);
						var ay:int= y + RecastCommon.GetDirOffsetY(0);
						var ai:int= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, 0);
						if ((srcReg[ai] & RecastConstants.RC_BORDER_REG) == 0&& chf.areas[i] == chf.areas[ai])
							previd = srcReg[ai];
					}

					if (previd == 0) {
						previd = rid++;
						sweeps[previd].rid = previd;
						sweeps[previd].ns = 0;
						sweeps[previd].nei = 0;
					}

					// -y
					if (RecastCommon.GetCon(s, 3) != RecastConstants.RC_NOT_CONNECTED) {
						ax= x + RecastCommon.GetDirOffsetX(3);
						ay= y + RecastCommon.GetDirOffsetY(3);
						ai= chf.cells[ax + ay * w].index + RecastCommon.GetCon(s, 3);
						if (srcReg[ai] != 0&& (srcReg[ai] & RecastConstants.RC_BORDER_REG) == 0&& chf.areas[i] == chf.areas[ai]) {
							var nr:int= srcReg[ai];
							if (sweeps[previd].nei == 0|| sweeps[previd].nei == nr) {
								sweeps[previd].nei = nr;
								sweeps[previd].ns++;
								prev[nr]++;
							} else {
								sweeps[previd].nei = RC_NULL_NEI;
							}
						}
					}

					srcReg[i] = previd;
				}
			}

			// Create unique ID.
			for (i= 1; i < rid; ++i) {
				if (sweeps[i].nei != RC_NULL_NEI && sweeps[i].nei != 0&& prev[sweeps[i].nei] == sweeps[i].ns) {
					sweeps[i].id = sweeps[i].nei;
				} else {
					sweeps[i].id = id++;
				}
			}

			// Remap IDs
			for (x= borderSize; x < w - borderSize; ++x) {
				 c= chf.cells[x + y * w];

				for ( i= c.index, ni = c.index + c.count; i < ni; ++i) {
					if (srcReg[i] > 0&& srcReg[i] < rid)
						srcReg[i] = sweeps[srcReg[i]].id;
				}
			}
		}

		ctx.startTimer("BUILD_REGIONS_FILTER");

		// Merge monotone regions to layers and remove small regions.
		var overlaps:Array = [];
		chf.maxRegions = mergeAndFilterLayerRegions(ctx, minRegionArea, id, chf, srcReg, overlaps);

		ctx.stopTimer("BUILD_REGIONS_FILTER");

		// Store the result out.
		for ( i= 0; i < chf.spanCount; ++i)
			chf.spans[i].reg = srcReg[i];

		ctx.stopTimer("BUILD_REGIONS");

	}
}
}

class SweepSpan {
	public	var rid:int; // row id
	public	var id:int; // region id
	public	var ns:int; // number samples
	public	var nei:int; // neighbour id
	}
	class Region {
	public	var spanCount:int; // Number of spans belonging to this region
	public	var id:int; // ID of the region
	public	var areaType:int; // Are type.
	public	var remap:Boolean;
	public	var visited:Boolean;
	public	var overlap:Boolean;
	public	var connectsToBorder:Boolean;
	public	var ymin:int, ymax:int;
	public	var connections:Array;
	public	var floors:Array;

		public function Region(i:int) {
			this.id = i;
			this.ymin = 0xFFFF;
			connections = [];
			floors = [];
		}

	}
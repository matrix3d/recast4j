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
import org.recast4j.System;



public class NavMeshQuery {

	public static const DT_FINDPATH_LOW_QUALITY_FAR:int= 0x01; /// < [provisional] trade quality for performance far
																/// from the origin. The idea is that by then a new
																/// query will be issued
	public static const DT_FINDPATH_ANY_ANGLE:int= 0x02; /// < use raycasts during pathfind to "shortcut" (raycast
															/// still consider costs)

	/** Raycast should calculate movement cost along the ray and fill RaycastHit::cost */
	public static const DT_RAYCAST_USE_COSTS:int= 0x01;

	/// Vertex flags returned by findStraightPath.
	/** The vertex is the start position in the path. */
	public static const DT_STRAIGHTPATH_START:int= 0x01; 
	/** The vertex is the end position in the path. */
	public static const DT_STRAIGHTPATH_END:int= 0x02;
	/** The vertex is the start of an off-mesh connection. */
	public static const DT_STRAIGHTPATH_OFFMESH_CONNECTION:int= 0x04; 

	/// Options for findStraightPath.
	public static const DT_STRAIGHTPATH_AREA_CROSSINGS:int= 0x01; ///< Add a vertex at every polygon edge crossing where area changes.
	public static const DT_STRAIGHTPATH_ALL_CROSSINGS:int= 0x02; ///< Add a vertex at every polygon edge crossing.

	public static var H_SCALE:Number= 0.999; // Search heuristic scale.

	private var m_nav:NavMesh;
	private var m_nodePool:NodePool;
	private var m_tinyNodePool:NodePool;
	private var m_openList:NodeQueue;
	private var m_query:QueryData; /// < Sliced query state.

	public function NavMeshQuery(nav:NavMesh) {
		m_nav = nav;
		m_nodePool = new NodePool();
		m_tinyNodePool = new NodePool();
		m_openList = new NodeQueue();
	}
	
	/**
	 * Returns random location on navmesh.
	 * Polygons are chosen weighted by area. The search runs in linear related to number of polygon.
	 * @param filter The polygon filter to apply to the query.
	 * @param frand Function returning a random number [0..1).
	 * @return Random location
	 */
	public function findRandomPoint(filter:QueryFilter, frand:FRand):FindRandomPointResult {
		// Randomly pick one tile. Assume that all tiles cover roughly the same area.
		var tile:MeshTile= null;
		var tsum:Number= 0.0;
		for (var i:int= 0; i < m_nav.getMaxTiles(); i++) {
			var t:MeshTile= m_nav.getTile(i);
			if (t == null || t.data == null || t.data.header == null)
				continue;

			// Choose random tile using reservoi sampling.
			var area:Number= 1.0; // Could be tile area too.
			tsum += area;
			var u:Number= frand.frand();
			if (u * tsum <= area)
				tile = t;
		}
		if (tile == null)
			return new FindRandomPointResult(Status.FAILURE, 0, null);

		// Randomly pick one polygon weighted by polygon area.
		var poly:Poly= null;
		var polyRef:Number= 0;
		var base:Number= m_nav.getPolyRefBase(tile);

		var areaSum:Number= 0.0;
		for (i= 0; i < tile.data.header.polyCount; ++i) {
			var p:Poly= tile.data.polys[i];
			// Do not return off-mesh connection polygons.
			if (p.getType() != Poly.DT_POLYTYPE_GROUND)
				continue;
			// Must pass filter
			var ref:Number= base | i;
			if (!filter.passFilter(ref, tile, p))
				continue;

			// Calc area of the polygon.
			var polyArea:Number= 0.0;
			for (j= 2; j < p.vertCount; ++j) {
				var va:int= p.verts[0] * 3;
				var vb:int= p.verts[j - 1] * 3;
				var vc:int= p.verts[j] * 3;
				polyArea += DetourCommon.triArea2D(tile.data.verts, va, vb, vc);
			}

			// Choose random polygon weighted by area, using reservoi sampling.
			areaSum += polyArea;
			u= frand.frand();
			if (u * areaSum <= polyArea) {
				poly = p;
				polyRef = ref;
			}
		}

		if (poly == null)
			return new FindRandomPointResult(Status.FAILURE, 0, null);

		// Randomly pick point on polygon.
		var verts:Array= []//new float[3* NavMesh.DT_VERTS_PER_POLYGON];
		var areas:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON];
		System.arraycopy(tile.data.verts, poly.verts[0] * 3, verts, 0, 3);
		for (var j:int= 1; j < poly.vertCount; ++j) {
			System.arraycopy(tile.data.verts, poly.verts[j] * 3, verts, j * 3, 3);
		}

		var s:Number= frand.frand();
		var t2:Number= frand.frand();

		var pt:Array= DetourCommon.randomPointInConvexPoly(verts, poly.vertCount, areas, s, t2);

		pt[1] = getPolyHeight(polyRef, new VectorPtr(pt, 0));

		return new FindRandomPointResult(Status.SUCCSESS, polyRef, pt);
	}

	/**
	 * Returns random location on navmesh within the reach of specified location.
	 * Polygons are chosen weighted by area. The search runs in linear related to number of polygon.
	 * The location is not exactly constrained by the circle, but it limits the visited polygons.
	 * 
	 * @param startRef The reference id of the polygon where the search starts.
	 * @param centerPos The center of the search circle. [(x, y, z)]
	 * @param maxRadius 
	 * @param filter The polygon filter to apply to the query.
	 * @param frand Function returning a random number [0..1).
	 * @return Random location
	 */
	public function findRandomPointAroundCircle(startRef:Number, centerPos:Array, maxRadius:Number,
			filter:QueryFilter, frand:FRand):FindRandomPointResult {

		// Validate input
		if (startRef == 0|| !m_nav.isValidPolyRef(startRef))
			throw ("Invalid start ref");

		var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(startRef);
		var startTile:MeshTile= tileAndPoly.first as MeshTile;
		var startPoly:Poly= tileAndPoly.second as Poly;
		if (!filter.passFilter(startRef, startTile, startPoly))
			throw ("Invalid start");

		m_nodePool.clear();
		m_openList.clear();

		var startNode:Node= m_nodePool.getNode(startRef);
		DetourCommon.vCopy2(startNode.pos, centerPos);
		startNode.pidx = 0;
		startNode.cost = 0;
		startNode.total = 0;
		startNode.id = startRef;
		startNode.flags = Node.DT_NODE_OPEN;
		m_openList.push(startNode);

		var radiusSqr:Number= maxRadius * maxRadius;
		var areaSum:Number= 0.0;

		var randomTile:MeshTile= null;
		var randomPoly:Poly= null;
		var randomPolyRef:Number= 0;

		while (!m_openList.isEmpty()) {
			var bestNode:Node= m_openList.pop();
			bestNode.flags &= ~Node.DT_NODE_OPEN;
			bestNode.flags |= Node.DT_NODE_CLOSED;
			// Get poly and tile.
			// The API input has been cheked already, skip checking internal data.
			var bestRef:Number= bestNode.id;
			var bestTilePoly:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(bestRef);
			var bestTile:MeshTile= bestTilePoly.first as MeshTile;
			var bestPoly:Poly= bestTilePoly.second as Poly;

			// Place random locations on on ground.
			if (bestPoly.getType() == Poly.DT_POLYTYPE_GROUND) {
				// Calc area of the polygon.
				var polyArea:Number= 0.0;
				for (j= 2; j < bestPoly.vertCount; ++j) {
					var va2:int= bestPoly.verts[0] * 3;
					var vb2:int= bestPoly.verts[j - 1] * 3;
					var vc:int= bestPoly.verts[j] * 3;
					polyArea += DetourCommon.triArea2D(bestTile.data.verts, va2, vb2, vc);
				}
				// Choose random polygon weighted by area, using reservoi sampling.
				areaSum += polyArea;
				var u:Number= frand.frand();
				if (u * areaSum <= polyArea) {
					randomTile = bestTile;
					randomPoly = bestPoly;
					randomPolyRef = bestRef;
				}
			}

			// Get parent poly and tile.
			var parentRef:Number= 0;
			if (bestNode.pidx != 0)
				parentRef = m_nodePool.getNodeAtIdx(bestNode.pidx).id;
			if (parentRef != 0) {
				var parentTilePoly:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(parentRef);
				var parentTile:MeshTile= parentTilePoly.first as MeshTile;
				var parentPoly:Poly= parentTilePoly.second as Poly;
			}

			for (var i:int= bestPoly.firstLink; i != NavMesh.DT_NULL_LINK; i = bestTile.links[i].next) {
				var link:Link= bestTile.links[i];
				var neighbourRef:Number= link.ref;
				// Skip invalid neighbours and do not follow back to parent.
				if (neighbourRef == 0|| neighbourRef == parentRef)
					continue;

				// Expand to neighbour
				var neighbourTilePoly:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(neighbourRef);
				var neighbourTile:MeshTile= neighbourTilePoly.first as MeshTile;
				var neighbourPoly:Poly= neighbourTilePoly.second as Poly;

				// Do not advance if the polygon is excluded by the filter.
				if (!filter.passFilter(neighbourRef, neighbourTile, neighbourPoly))
					continue;

				// Find edge and calc distance to the edge.
				var portalpoints:PortalResult= getPortalPoints2(bestRef, bestPoly, bestTile, neighbourRef, neighbourPoly,
						neighbourTile, 0, 0);
				var va:Array= portalpoints.left;
				var vb:Array= portalpoints.right;

				// If the circle is not touching the next polygon, skip it.
				var distseg:Tupple2 = DetourCommon.distancePtSegSqr2D(centerPos, va, vb);
				var distSqr:Number= distseg.first as Number;
				var tseg:Number= distseg.second as Number;
				if (distSqr > radiusSqr)
					continue;

				var neighbourNode:Node= m_nodePool.getNode(neighbourRef);

				if ((neighbourNode.flags & Node.DT_NODE_CLOSED) != 0)
					continue;

				// Cost
				if (neighbourNode.flags == 0)
					neighbourNode.pos = DetourCommon.vLerp3(va, vb, 0.5);

				var total:Number= bestNode.total + DetourCommon.vDist(bestNode.pos, neighbourNode.pos);

				// The node is already in open list and the new result is worse, skip.
				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0&& total >= neighbourNode.total)
					continue;

				neighbourNode.id = neighbourRef;
				neighbourNode.flags = (neighbourNode.flags & ~Node.DT_NODE_CLOSED);
				neighbourNode.pidx = m_nodePool.getNodeIdx(bestNode);
				neighbourNode.total = total;

				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0) {
					m_openList.modify(neighbourNode);
				} else {
					neighbourNode.flags = Node.DT_NODE_OPEN;
					m_openList.push(neighbourNode);
				}
			}
		}

		if (randomPoly == null)
			return new FindRandomPointResult(Status.FAILURE, 0, null);

		// Randomly pick point on polygon.
		var verts:Array= []//new float[3* NavMesh.DT_VERTS_PER_POLYGON];
		var areas:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON];
		System.arraycopy(randomTile.data.verts, randomPoly.verts[0] * 3, verts, 0, 3);
		for (var j:int= 1; j < randomPoly.vertCount; ++j) {
			System.arraycopy(randomTile.data.verts, randomPoly.verts[j] * 3, verts, j * 3, 3);
		}

		var s:Number= frand.frand();
		var t:Number= frand.frand();

		var pt:Array= DetourCommon.randomPointInConvexPoly(verts, randomPoly.vertCount, areas, s, t);

		pt[1] = getPolyHeight(randomPolyRef, new VectorPtr(pt, 0));

		return new FindRandomPointResult(Status.SUCCSESS, randomPolyRef, pt);
	}

	//////////////////////////////////////////////////////////////////////////////////////////
	/// @par
	///
	/// Uses the detail polygons to find the surface height. (Most accurate.)
	///
	/// @p pos does not have to be within the bounds of the polygon or navigation mesh.
	///
	/// See closestPointOnPolyBoundary() for a limited but faster option.
	///
	/// Finds the closest point on the specified polygon.
	///  @param[in]		ref			The reference id of the polygon.
	///  @param[in]		pos			The position to check. [(x, y, z)]
	///  @param[out]	closest		
	///  @param[out]	posOverPoly	
	/// @returns The status flags for the query.
	public function closestPointOnPoly(ref:Number, pos:Array):ClosesPointOnPolyResult {
		var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRef(ref);
		var tile:MeshTile= tileAndPoly.first as MeshTile;
		var poly:Poly= tileAndPoly.second as Poly;

		// Off-mesh connections don't have detail polygons.
		if (poly.getType() == Poly.DT_POLYTYPE_OFFMESH_CONNECTION) {
			var v0:int= poly.verts[0] * 3;
			var v1:int= poly.verts[1] * 3;
			var d0:Number= DetourCommon.vDist2(pos, tile.data.verts, v0);
			var d1:Number= DetourCommon.vDist2(pos, tile.data.verts, v1);
			var u:Number= d0 / (d0 + d1);
			var closest:Array= DetourCommon.vLerp2(tile.data.verts, v0, v1, u);
			return new ClosesPointOnPolyResult(false, closest);
		}

		// Clamp point to be inside the polygon.
		var verts:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON * 3];
		var edged:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON];
		var edget:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON];
		var nv:int= poly.vertCount;
		for (var i:int= 0; i < nv; ++i)
			System.arraycopy(tile.data.verts, poly.verts[i] * 3, verts, i * 3, 3);

		var posOverPoly:Boolean= false;
		closest= []//new float[3];
		DetourCommon.vCopy2(closest, pos);
		if (!DetourCommon.distancePtPolyEdgesSqr(pos, verts, nv, edged, edget)) {
			// Point is outside the polygon, dtClamp to nearest edge.
			var dmin:Number= Number.MAX_VALUE;
			var imin:int= -1;
			for (i= 0; i < nv; ++i) {
				if (edged[i] < dmin) {
					dmin = edged[i];
					imin = i;
				}
			}
			var va2:int= imin * 3;
			var vb2:int= ((imin + 1) % nv) * 3;
			closest = DetourCommon.vLerp2(verts, va2, vb2, edget[imin]);
			posOverPoly = false;
		} else {
			posOverPoly = true;
		}
		var ip:int= poly.index;
		if (tile.data.detailMeshes != null && tile.data.detailMeshes.length > ip) {
			var pd:PolyDetail= tile.data.detailMeshes[ip];
			var posV:VectorPtr= new VectorPtr(pos);
			// Find height at the location.
			for (var j:int= 0; j < pd.triCount; ++j) {
				var t:int= (pd.triBase + j) * 4;
				var v:Array= new VectorPtr[3];
				for (var k:int= 0; k < 3; ++k) {
					if (tile.data.detailTris[t + k] < poly.vertCount)
						v[k] = new VectorPtr(tile.data.verts, poly.verts[tile.data.detailTris[t + k]] * 3);
					else
						v[k] = new VectorPtr(tile.data.detailVerts,
								(pd.vertBase + (tile.data.detailTris[t + k] - poly.vertCount)) * 3);
				}
				var clp:Tupple2 = DetourCommon.closestHeightPointTriangle(posV, v[0], v[1], v[2]);
				if (clp.first) {
					closest[1] = clp.second;
					break;
				}
			}
		}
		return new ClosesPointOnPolyResult(posOverPoly, closest);
	}

	/// @par
	///
	/// Much faster than closestPointOnPoly().
	///
	/// If the provided position lies within the polygon's xz-bounds (above or below),
	/// then @p pos and @p closest will be equal.
	///
	/// The height of @p closest will be the polygon boundary. The height detail is not used.
	///
	/// @p pos does not have to be within the bounds of the polybon or the navigation mesh.
	///
	/// Returns a point on the boundary closest to the source point if the source point is outside the 
	/// polygon's xz-bounds.
	///  @param[in]		ref			The reference id to the polygon.
	///  @param[in]		pos			The position to check. [(x, y, z)]
	///  @param[out]	closest		The closest point. [(x, y, z)]
	/// @returns The status flags for the query.
	public function closestPointOnPolyBoundary(ref:Number,pos:Array):Array {

		var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRef(ref);
		var tile:MeshTile= tileAndPoly.first as MeshTile;
		var poly:Poly= tileAndPoly.second as Poly;

		// Collect vertices.
		var verts:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON * 3];
		var edged:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON];
		var edget:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON];
		var nv:int= poly.vertCount;
		for (var i:int= 0; i < nv; ++i)
			System.arraycopy(tile.data.verts, poly.verts[i] * 3, verts, i * 3, 3);

		var closest:Array;
		if (DetourCommon.distancePtPolyEdgesSqr(pos, verts, nv, edged, edget)) {
			closest = DetourCommon.vCopy(pos);
		} else {
			// Point is outside the polygon, dtClamp to nearest edge.
			var dmin:Number= Number.MAX_VALUE;
			var imin:int= -1;
			for (i= 0; i < nv; ++i) {
				if (edged[i] < dmin) {
					dmin = edged[i];
					imin = i;
				}
			}
			var va:int= imin * 3;
			var vb:int= ((imin + 1) % nv) * 3;
			closest = DetourCommon.vLerp2(verts, va, vb, edget[imin]);
		}
		return closest;
	}

	/// @par
	///
	/// Will return #DT_FAILURE if the provided position is outside the xz-bounds
	/// of the polygon.
	///
	/// Gets the height of the polygon at the provided position using the height detail. (Most accurate.)
	///  @param[in]		ref			The reference id of the polygon.
	///  @param[in]		pos			A position within the xz-bounds of the polygon. [(x, y, z)]
	///  @param[out]	height		The height at the surface of the polygon.
	/// @returns The status flags for the query.
	public function getPolyHeight(ref:Number, pos:VectorPtr):Number {
		var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRef(ref);
		var tile:MeshTile= tileAndPoly.first as MeshTile;
		var poly:Poly= tileAndPoly.second as Poly;
		if (poly.getType() == Poly.DT_POLYTYPE_OFFMESH_CONNECTION) {
			var v0:VectorPtr= new VectorPtr(tile.data.verts, poly.verts[0] * 3);
			var v1:VectorPtr= new VectorPtr(tile.data.verts, poly.verts[1] * 3);
			var d0:Number= DetourCommon.vDist2D(pos, v0);
			var d1:Number= DetourCommon.vDist2D(pos, v1);
			var u:Number= d0 / (d0 + d1);
			return v0[1] + (v1[1] - v0[1]) * u;
		} else {
			var ip:int= poly.index;
			var pd:PolyDetail= tile.data.detailMeshes[ip];
			for (var j:int= 0; j < pd.triCount; ++j) {
				var t:int= (pd.triBase + j) * 4;
				var v:Array= new VectorPtr[3];
				for (var k:int= 0; k < 3; ++k) {
					if (tile.data.detailTris[t + k] < poly.vertCount)
						v[k] = new VectorPtr(tile.data.verts, poly.verts[tile.data.detailTris[t + k]] * 3);
					else
						v[k] = new VectorPtr(tile.data.detailVerts,
								(pd.vertBase + (tile.data.detailTris[t + k] - poly.vertCount)) * 3);
				}
				var heightResult:Tupple2 = DetourCommon.closestHeightPointTriangle(pos, v[0], v[1], v[2]);
				if (heightResult.first) {
					return heightResult.second as Number;
				}
			}
		}
		throw ("Invalid ref");
	}

	/// @par
	///
	/// @note If the search box does not intersect any polygons the search will
	/// return #DT_SUCCESS, but @p nearestRef will be zero. So if in doubt, check
	/// @p nearestRef before using @p nearestPt.
	///
	/// @warning This function is not suitable for large area searches. If the search
	/// extents overlaps more than MAX_SEARCH (128) polygons it may return an invalid result.
	///
	/// @}
	/// @name Local Query Functions
	///@{

	/// Finds the polygon nearest to the specified center point.
	///  @param[in]		center		The center of the search box. [(x, y, z)]
	///  @param[in]		extents		The search distance along each axis. [(x, y, z)]
	///  @param[in]		filter		The polygon filter to apply to the query.
	/// @returns The status flags for the query.
	public function findNearestPoly(center:Array, extents:Array, filter:QueryFilter):FindNearestPolyResult {

		var nearestPt:Array= null;

		// Get nearby polygons from proximity grid.
		var polys:Array = queryPolygons(center, extents, filter);

		// Find nearest polygon amongst the nearby polygons.
		var nearest:Number= 0;
		var nearestDistanceSqr:Number= Number.MAX_VALUE;
		for (var i:int= 0; i < polys.length; ++i) {
			var ref:Number= polys[i];
			var closest:ClosesPointOnPolyResult= closestPointOnPoly(ref, center);
			var posOverPoly:Boolean= closest.isPosOverPoly();
			var closestPtPoly:Array= closest.getClosest();

			// If a point is directly over a polygon and closer than
			// climb height, favor that instead of straight line nearest point.
			var d:Number= 0;
			var diff:Array= DetourCommon.vSub2(center, closestPtPoly);
			if (posOverPoly) {
				var tilaAndPoly:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(polys[i]);
				var tile:MeshTile= tilaAndPoly.first as MeshTile;
				d = Math.abs(diff[1]) - tile.data.header.walkableClimb;
				d = d > 0? d * d : 0;
			} else {
				d = DetourCommon.vLenSqr(diff);
			}

			if (d < nearestDistanceSqr) {
				nearestPt = closestPtPoly;
				nearestDistanceSqr = d;
				nearest = ref;
			}
		}

		return new FindNearestPolyResult(nearest, nearestPt);
	}

	// FIXME: (PP) duplicate?
	protected function queryPolygonsInTile(tile:MeshTile, qmin:Array, qmax:Array,  filter:QueryFilter):Array {
		var polys:Array = [];
		if (tile.data.bvTree != null) {
			var nodeIndex:int= 0;
			var tbmin:Array= tile.data.header.bmin;
			var tbmax:Array= tile.data.header.bmax;
			var qfac:Number= tile.data.header.bvQuantFactor;
			// Calculate quantized box
			var bmin:Array= []//3];
			var bmax:Array= []//3];
			// dtClamp query box to world box.
			var minx:Number= DetourCommon.clamp(qmin[0], tbmin[0], tbmax[0]) - tbmin[0];
			var miny:Number= DetourCommon.clamp(qmin[1], tbmin[1], tbmax[1]) - tbmin[1];
			var minz:Number= DetourCommon.clamp(qmin[2], tbmin[2], tbmax[2]) - tbmin[2];
			var maxx:Number= DetourCommon.clamp(qmax[0], tbmin[0], tbmax[0]) - tbmin[0];
			var maxy:Number= DetourCommon.clamp(qmax[1], tbmin[1], tbmax[1]) - tbmin[1];
			var maxz:Number= DetourCommon.clamp(qmax[2], tbmin[2], tbmax[2]) - tbmin[2];
			// Quantize
			bmin[0] = int((qfac * minx) )& 0xfffe;
			bmin[1] = int((qfac * miny) )& 0xfffe;
			bmin[2] = int((qfac * minz) )& 0xfffe;
			bmax[0] = int((qfac * maxx + 1) )| 1;
			bmax[1] = int((qfac * maxy + 1) )| 1;
			bmax[2] = int((qfac * maxz + 1) )| 1;

			// Traverse tree
			var base:Number= m_nav.getPolyRefBase(tile);
			var end:int= tile.data.header.bvNodeCount;
			while (nodeIndex < end) {
				var node:BVNode= tile.data.bvTree[nodeIndex];
				var overlap:Boolean= DetourCommon.overlapQuantBounds(bmin, bmax, node.bmin, node.bmax);
				var isLeafNode:Boolean= node.i >= 0;

				if (isLeafNode && overlap) {
					var ref:Number= base | node.i;
					if (filter.passFilter(ref, tile, tile.data.polys[node.i])) {
						polys.push(ref);
					}
				}

				if (overlap || isLeafNode)
					nodeIndex++;
				else {
					var escapeIndex:int= -node.i;
					nodeIndex += escapeIndex;
				}
			}
			return polys;
		} else {
			bmin= []//new float[3];
			bmax= []//new float[3];
			base= m_nav.getPolyRefBase(tile);
			for (var i:int= 0; i < tile.data.header.polyCount; ++i) {
				var p:Poly= tile.data.polys[i];
				// Do not return off-mesh connection polygons.
				if (p.getType() == Poly.DT_POLYTYPE_OFFMESH_CONNECTION)
					continue;
				ref= base | i;
				if (!filter.passFilter(ref, tile, p))
					continue;
				// Calc polygon bounds.
				var v:int= p.verts[0] * 3;
				DetourCommon.vCopy3(bmin, tile.data.verts, v);
				DetourCommon.vCopy3(bmax, tile.data.verts, v);
				for (var j:int= 1; j < p.vertCount; ++j) {
					v = p.verts[j] * 3;
					DetourCommon.vMin(bmin, tile.data.verts, v);
					DetourCommon.vMax(bmax, tile.data.verts, v);
				}
				if (DetourCommon.overlapBounds(qmin, qmax, bmin, bmax)) {
					polys.push(ref);
				}
			}
			return polys;
		}
	}

	/**
	 * Finds polygons that overlap the search box.
	 * 
	 * If no polygons are found, the function will return with a polyCount of zero.
	 * 
	 * @param center
	 *            The center of the search box. [(x, y, z)]
	 * @param extents
	 *            The search distance along each axis. [(x, y, z)]
	 * @param filter
	 *            The polygon filter to apply to the query.
	 * @return The reference ids of the polygons that overlap the query box.
	 */
	public function queryPolygons(center:Array, extents:Array, filter:QueryFilter):Array {
		var bmin:Array= DetourCommon.vSub2(center, extents);
		var bmax:Array= DetourCommon.vAdd2(center, extents);
		// Find tiles the query touches.
		var minxy:Array= m_nav.calcTileLoc(bmin);
		var minx:int= minxy[0];
		var miny:int= minxy[1];
		var maxxy:Array= m_nav.calcTileLoc(bmax);
		var maxx:int= maxxy[0];
		var maxy:int= maxxy[1];
		var polys:Array = [];
		for (var y:int= miny; y <= maxy; ++y) {
			for (var x:int= minx; x <= maxx; ++x) {
				var neis:Array = m_nav.getTilesAt(x, y);
				for (var j:int= 0; j < neis.length; ++j) {
					var polysInTile:Array = queryPolygonsInTile(neis[j], bmin, bmax, filter);
					polys.push.apply(null,polysInTile);
				}
			}
		}
		return polys;
	}
	
	/**
	 * Finds a path from the start polygon to the end polygon.
	 * 
	 * If the end polygon cannot be reached through the navigation graph, the last polygon in the path will be the
	 * nearest the end polygon.
	 * 
	 * The start and end positions are used to calculate traversal costs. (The y-values impact the result.)
	 * 
	 * @param startRef
	 *            The refrence id of the start polygon.
	 * @param endRef
	 *            The reference id of the end polygon.
	 * @param startPos
	 *            A position within the start polygon. [(x, y, z)]
	 * @param endPos
	 *            A position within the end polygon. [(x, y, z)]
	 * @param filter
	 *            The polygon filter to apply to the query.
	 * @return Found path
	 */
	public function findPath(startRef:Number, endRef:Number, startPos:Array, endPos:Array,
			filter:QueryFilter):FindPathResult {
		if (startRef == 0|| endRef == 0)
			throw ("Start or end ref = 0");

		// Validate input
		if (!m_nav.isValidPolyRef(startRef) || !m_nav.isValidPolyRef(endRef))
			throw ("Invalid start or end ref");

		var path:Array = [];
		if (startRef == endRef) {
			path.push(startRef);
			return new FindPathResult(Status.SUCCSESS, path);
		}

		m_nodePool.clear();
		m_openList.clear();

		var startNode:Node= m_nodePool.getNode(startRef);
		DetourCommon.vCopy2(startNode.pos, startPos);
		startNode.pidx = 0;
		startNode.cost = 0;
		startNode.total = DetourCommon.vDist(startPos, endPos) * H_SCALE;
		startNode.id = startRef;
		startNode.flags = Node.DT_NODE_OPEN;
		m_openList.push(startNode);

		var lastBestNode:Node= startNode;
		var lastBestNodeCost:Number= startNode.total;

		var status:int= Status.SUCCSESS;

		while (!m_openList.isEmpty()) {
			// Remove node from open list and put it in closed list.
			var bestNode:Node= m_openList.pop();
			bestNode.flags &= ~Node.DT_NODE_OPEN;
			bestNode.flags |= Node.DT_NODE_CLOSED;

			// Reached the goal, stop searching.
			if (bestNode.id == endRef) {
				lastBestNode = bestNode;
				break;
			}

			// Get current poly and tile.
			// The API input has been cheked already, skip checking internal data.
			var bestRef:Number= bestNode.id;
			var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(bestRef);
			var bestTile:MeshTile= tileAndPoly.first as MeshTile;
			var bestPoly:Poly= tileAndPoly.second as Poly;

			// Get parent poly and tile.
			var parentRef:Number= 0;
			var parentTile:MeshTile= null;
			var parentPoly:Poly= null;
			if (bestNode.pidx != 0)
				parentRef = m_nodePool.getNodeAtIdx(bestNode.pidx).id;
			if (parentRef != 0) {
				tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(parentRef);
				parentTile = tileAndPoly.first as MeshTile;
				parentPoly = tileAndPoly.second as Poly;
			}

			for (var i:int= bestPoly.firstLink; i != NavMesh.DT_NULL_LINK; i = bestTile.links[i].next) {
				var neighbourRef:Number= bestTile.links[i].ref;

				// Skip invalid ids and do not expand back to where we came from.
				if (neighbourRef == 0|| neighbourRef == parentRef)
					continue;

				// Get neighbour poly and tile.
				// The API input has been cheked already, skip checking internal data.
				tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(neighbourRef);
				var neighbourTile:MeshTile= tileAndPoly.first as MeshTile;
				var neighbourPoly:Poly= tileAndPoly.second as Poly;

				if (!filter.passFilter(neighbourRef, neighbourTile, neighbourPoly))
					continue;

				// deal explicitly with crossing tile boundaries
				var crossSide:int= 0;
				if (bestTile.links[i].side != 0xff)
					crossSide = bestTile.links[i].side >> 1;

				// get the node
				var neighbourNode:Node= m_nodePool.getNode(neighbourRef, crossSide);

				// If the node is visited the first time, calculate node position.
				if (neighbourNode.flags == 0) {
					neighbourNode.pos = getEdgeMidPoint2(bestRef, bestPoly, bestTile, neighbourRef,
							neighbourPoly, neighbourTile);
				}

				// Calculate cost and heuristic.
				var cost:Number= 0;
				var heuristic:Number= 0;

				// Special case for last node.
				if (neighbourRef == endRef) {
					// Cost
					var curCost:Number= filter.getCost(bestNode.pos, neighbourNode.pos, parentRef, parentTile, parentPoly,
							bestRef, bestTile, bestPoly, neighbourRef, neighbourTile, neighbourPoly);
					var endCost:Number= filter.getCost(neighbourNode.pos, endPos, bestRef, bestTile, bestPoly, neighbourRef,
							neighbourTile, neighbourPoly, 0, null, null);

					cost = bestNode.cost + curCost + endCost;
					heuristic = 0;
				} else {
					// Cost
					curCost= filter.getCost(bestNode.pos, neighbourNode.pos, parentRef, parentTile, parentPoly,
							bestRef, bestTile, bestPoly, neighbourRef, neighbourTile, neighbourPoly);
					cost = bestNode.cost + curCost;
					heuristic = DetourCommon.vDist(neighbourNode.pos, endPos) * H_SCALE;
				}

				var total:Number= cost + heuristic;

				// The node is already in open list and the new result is worse, skip.
				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0&& total >= neighbourNode.total)
					continue;
				// The node is already visited and process, and the new result is worse, skip.
				if ((neighbourNode.flags & Node.DT_NODE_CLOSED) != 0&& total >= neighbourNode.total)
					continue;

				// Add or update the node.
				neighbourNode.pidx = m_nodePool.getNodeIdx(bestNode);
				neighbourNode.id = neighbourRef;
				neighbourNode.flags = (neighbourNode.flags & ~Node.DT_NODE_CLOSED);
				neighbourNode.cost = cost;
				neighbourNode.total = total;

				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0) {
					// Already in open, update node location.
					m_openList.modify(neighbourNode);
				} else {
					// Put the node in open list.
					neighbourNode.flags |= Node.DT_NODE_OPEN;
					m_openList.push(neighbourNode);
				}

				// Update nearest node to target so far.
				if (heuristic < lastBestNodeCost) {
					lastBestNodeCost = heuristic;
					lastBestNode = neighbourNode;
				}
			}
		}

		if (lastBestNode.id != endRef)
			status = Status.PARTIAL_RESULT;

		// Reverse the path.
		var prev:Node= null;
		var node:Node= lastBestNode;
		do {
			var next:Node= m_nodePool.getNodeAtIdx(node.pidx);
			node.pidx = m_nodePool.getNodeIdx(prev);
			prev = node;
			node = next;
		} while (node != null);

		// Store path
		node = prev;
		do {
			path.push(node.id);
			node = m_nodePool.getNodeAtIdx(node.pidx);
		} while (node != null);

		return new FindPathResult(status, path);
	}

	/**
	 * Intializes a sliced path query.
	 * 
	 * Common use case: -# Call initSlicedFindPath() to initialize the sliced path query. -# Call updateSlicedFindPath()
	 * until it returns complete. -# Call finalizeSlicedFindPath() to get the path.
	 * 
	 * @param startRef
	 *            The reference id of the start polygon.
	 * @param endRef
	 *            The reference id of the end polygon.
	 * @param startPos
	 *            A position within the start polygon. [(x, y, z)]
	 * @param endPos
	 *            A position within the end polygon. [(x, y, z)]
	 * @param filter
	 *            The polygon filter to apply to the query.
	 * @param options
	 *            query options (see: #FindPathOptions)
	 * @return
	 */
	public function initSlicedFindPath(startRef:Number, endRef:Number, startPos:Array, endPos:Array, filter:QueryFilter,
			options:int):int {
		// Init path state.
		m_query = new QueryData();
		m_query.status = Status.FAILURE;
		m_query.startRef = startRef;
		m_query.endRef = endRef;
		DetourCommon.vCopy2(m_query.startPos, startPos);
		DetourCommon.vCopy2(m_query.endPos, endPos);
		m_query.filter = filter;
		m_query.options = options;
		m_query.raycastLimitSqr = Number.MAX_VALUE;

		if (startRef == 0|| endRef == 0)
			throw ("Start or end ref = 0");

		// Validate input
		if (!m_nav.isValidPolyRef(startRef) || !m_nav.isValidPolyRef(endRef))
			throw ("Invalid start or end ref");

		// trade quality with performance?
		if ((options & DT_FINDPATH_ANY_ANGLE) != 0) {
			// limiting to several times the character radius yields nice results. It is not sensitive
			// so it is enough to compute it from the first tile.
			var tile:MeshTile= m_nav.getTileByRef(startRef);
			var agentRadius:Number= tile.data.header.walkableRadius;
			m_query.raycastLimitSqr = DetourCommon.sqr(agentRadius * NavMesh.DT_RAY_CAST_LIMIT_PROPORTIONS);
		}

		if (startRef == endRef) {
			m_query.status = Status.SUCCSESS;
			return Status.SUCCSESS;
		}

		m_nodePool.clear();
		m_openList.clear();

		var startNode:Node= m_nodePool.getNode(startRef);
		DetourCommon.vCopy2(startNode.pos, startPos);
		startNode.pidx = 0;
		startNode.cost = 0;
		startNode.total = DetourCommon.vDist(startPos, endPos) * H_SCALE;
		startNode.id = startRef;
		startNode.flags = Node.DT_NODE_OPEN;
		m_openList.push(startNode);

		m_query.status = Status.IN_PROGRESS;
		m_query.lastBestNode = startNode;
		m_query.lastBestNodeCost = startNode.total;

		return m_query.status;
	}

	/**
	 * Updates an in-progress sliced path query.
	 * 
	 * @param maxIter
	 *            The maximum number of iterations to perform.
	 * @return The status flags for the query.
	 */
	public function updateSlicedFindPath(maxIter:int):UpdateSlicedPathResult {
		if (!Status.isInProgress(m_query.status))
			return new UpdateSlicedPathResult(m_query.status, 0);

		// Make sure the request is still valid.
		if (!m_nav.isValidPolyRef(m_query.startRef) || !m_nav.isValidPolyRef(m_query.endRef)) {
			m_query.status = Status.FAILURE;
			return new UpdateSlicedPathResult(m_query.status, 0);
		}

		var iter:int= 0;
		while (iter < maxIter && !m_openList.isEmpty()) {
			iter++;

			// Remove node from open list and put it in closed list.
			var bestNode:Node= m_openList.pop();
			bestNode.flags &= ~Node.DT_NODE_OPEN;
			bestNode.flags |= Node.DT_NODE_CLOSED;

			// Reached the goal, stop searching.
			if (bestNode.id == m_query.endRef) {
				m_query.lastBestNode = bestNode;
				m_query.status = Status.SUCCSESS;
				return new UpdateSlicedPathResult(m_query.status, iter);
			}

			// Get current poly and tile.
			// The API input has been cheked already, skip checking internal
			// data.
			var bestRef:Number= bestNode.id;
			var tileAndPoly:Tupple2;
			try {
				tileAndPoly = m_nav.getTileAndPolyByRef(bestRef);
			} catch (e:Error) {
				m_query.status = Status.FAILURE;
				// The polygon has disappeared during the sliced query, fail.
				return new UpdateSlicedPathResult(m_query.status, iter);
			}
			var bestTile:MeshTile= tileAndPoly.first as MeshTile;
			var bestPoly:Poly= tileAndPoly.second as Poly;
			// Get parent and grand parent poly and tile.
			var parentRef:Number= 0, grandpaRef:Number = 0;
			var parentTile:MeshTile= null;
			var parentPoly:Poly= null;
			var parentNode:Node= null;
			if (bestNode.pidx != 0) {
				parentNode = m_nodePool.getNodeAtIdx(bestNode.pidx);
				parentRef = parentNode.id;
				if (parentNode.pidx != 0)
					grandpaRef = m_nodePool.getNodeAtIdx(parentNode.pidx).id;
			}
			if (parentRef != 0) {
				var invalidParent:Boolean= false;
				try {
					tileAndPoly = m_nav.getTileAndPolyByRef(parentRef);
					parentTile = tileAndPoly.first as MeshTile;
					parentPoly = tileAndPoly.second as Poly;
				} catch (e:Error) {
					invalidParent = true;
				}
				if (invalidParent || (grandpaRef != 0&& !m_nav.isValidPolyRef(grandpaRef))) {
					// The polygon has disappeared during the sliced query,
					// fail.
					m_query.status = Status.FAILURE;
					return new UpdateSlicedPathResult(m_query.status, iter);
				}
			}

			// decide whether to test raycast to previous nodes
			var tryLOS:Boolean= false;
			if ((m_query.options & DT_FINDPATH_ANY_ANGLE) != 0) {
				if ((parentRef != 0) && (DetourCommon.vDistSqr(parentNode.pos, bestNode.pos) < m_query.raycastLimitSqr))
					tryLOS = true;
			}

			for (var i:int= bestPoly.firstLink; i != NavMesh.DT_NULL_LINK; i = bestTile.links[i].next) {
				var neighbourRef:Number= bestTile.links[i].ref;

				// Skip invalid ids and do not expand back to where we came
				// from.
				if (neighbourRef == 0|| neighbourRef == parentRef)
					continue;

				// Get neighbour poly and tile.
				// The API input has been cheked already, skip checking internal
				// data.
				var tileAndPolyUns:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(neighbourRef);
				var neighbourTile:MeshTile= tileAndPolyUns.first as MeshTile;
				var neighbourPoly:Poly= tileAndPolyUns.second as Poly;

				if (!m_query.filter.passFilter(neighbourRef, neighbourTile, neighbourPoly))
					continue;

				// get the neighbor node
				var neighbourNode:Node= m_nodePool.getNode(neighbourRef, 0);

				// do not expand to nodes that were already visited from the
				// same parent
				if (neighbourNode.pidx != 0&& neighbourNode.pidx == bestNode.pidx)
					continue;

				// If the node is visited the first time, calculate node
				// position.
				if (neighbourNode.flags == 0) {
					neighbourNode.pos = getEdgeMidPoint2(bestRef, bestPoly, bestTile, neighbourRef,
							neighbourPoly, neighbourTile);
				}

				// Calculate cost and heuristic.
				var cost:Number= 0;
				var heuristic:Number= 0;

				// raycast parent
				var foundShortCut:Boolean= false;
				if (tryLOS) {
					var rayHit:RaycastHit= raycast(parentRef, parentNode.pos, neighbourNode.pos, m_query.filter,
							DT_RAYCAST_USE_COSTS, grandpaRef);
					foundShortCut = rayHit.t >= 1.0;
					if (foundShortCut) {
						// shortcut found using raycast. Using shorter cost
						// instead
						cost = parentNode.cost + rayHit.pathCost;
					}
				}

				// update move cost
				if (!foundShortCut) {
					// No shortcut found.
					var curCost:Number= m_query.filter.getCost(bestNode.pos, neighbourNode.pos, parentRef, parentTile,
							parentPoly, bestRef, bestTile, bestPoly, neighbourRef, neighbourTile, neighbourPoly);
					cost = bestNode.cost + curCost;
				}

				// Special case for last node.
				if (neighbourRef == m_query.endRef) {
					var endCost:Number= m_query.filter.getCost(neighbourNode.pos, m_query.endPos, bestRef, bestTile,
							bestPoly, neighbourRef, neighbourTile, neighbourPoly, 0, null, null);

					cost = cost + endCost;
					heuristic = 0;
				} else {
					heuristic = DetourCommon.vDist(neighbourNode.pos, m_query.endPos) * H_SCALE;
				}

				var total:Number= cost + heuristic;

				// The node is already in open list and the new result is worse,
				// skip.
				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0&& total >= neighbourNode.total)
					continue;
				// The node is already visited and process, and the new result
				// is worse, skip.
				if ((neighbourNode.flags & Node.DT_NODE_CLOSED) != 0&& total >= neighbourNode.total)
					continue;

				// Add or update the node.
				neighbourNode.pidx = foundShortCut ? bestNode.pidx : m_nodePool.getNodeIdx(bestNode);
				neighbourNode.id = neighbourRef;
				neighbourNode.flags = (neighbourNode.flags & ~(Node.DT_NODE_CLOSED | Node.DT_NODE_PARENT_DETACHED));
				neighbourNode.cost = cost;
				neighbourNode.total = total;
				if (foundShortCut)
					neighbourNode.flags = (neighbourNode.flags | Node.DT_NODE_PARENT_DETACHED);

				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0) {
					// Already in open, update node location.
					m_openList.modify(neighbourNode);
				} else {
					// Put the node in open list.
					neighbourNode.flags |= Node.DT_NODE_OPEN;
					m_openList.push(neighbourNode);
				}

				// Update nearest node to target so far.
				if (heuristic < m_query.lastBestNodeCost) {
					m_query.lastBestNodeCost = heuristic;
					m_query.lastBestNode = neighbourNode;
				}
			}
		}

		// Exhausted all nodes, but could not find path.
		if (m_openList.isEmpty()) {
			m_query.status = Status.PARTIAL_RESULT;
		}

		return new UpdateSlicedPathResult(m_query.status, iter);
	}
	
	/// Finalizes and returns the results of a sliced path query.
	///  @param[out]	path		An ordered list of polygon references representing the path. (Start to end.) 
	///  							[(polyRef) * @p pathCount]
	///  @param[out]	pathCount	The number of polygons returned in the @p path array.
	///  @param[in]		maxPath		The max number of polygons the path array can hold. [Limit: >= 1]
	/// @returns The status flags for the query.
	public function finalizeSlicedFindPath():FindPathResult {

		var path:Array = [];
		if (Status.isFailed(m_query.status)) {
			// Reset query.
			m_query = new QueryData();
			return new FindPathResult(Status.FAILURE, path);
		}

		if (m_query.startRef == m_query.endRef) {
			// Special case: the search starts and ends at same poly.
			path.push(m_query.startRef);
		} else {
			// Reverse the path.
			if (m_query.lastBestNode.id != m_query.endRef)
				m_query.status = Status.PARTIAL_RESULT;

			var prev:Node= null;
			var node:Node= m_query.lastBestNode;
			var prevRay:int= 0;
			do {
				var next:Node= m_nodePool.getNodeAtIdx(node.pidx);
				node.pidx = m_nodePool.getNodeIdx(prev);
				prev = node;
				var nextRay:int= node.flags & Node.DT_NODE_PARENT_DETACHED; // keep track of whether parent is not adjacent (i.e. due to raycast shortcut)
				node.flags = (node.flags & ~Node.DT_NODE_PARENT_DETACHED) | prevRay; // and store it in the reversed path's node
				prevRay = nextRay;
				node = next;
			} while (node != null);

			// Store path
			node = prev;
			do {
				next= m_nodePool.getNodeAtIdx(node.pidx);
				if ((node.flags & Node.DT_NODE_PARENT_DETACHED) != 0) {
					var iresult:RaycastHit= raycast(node.id, node.pos, next.pos, m_query.filter, 0, 0);
					path.addAll(iresult.path);
					// raycast ends on poly boundary and the path might include the next poly boundary.
					if (path[path.length - 1] == next.id)
						path.pop();//.remove(path.length - 1); // remove to avoid duplicates
				} else {
					path.push(node.id);
				}

				node = next;
			} while (node != null);
		}

		var status:int= m_query.status;
		// Reset query.
		m_query = new QueryData();

		return new FindPathResult(status, path);
	}

	/// Finalizes and returns the results of an incomplete sliced path query, returning the path to the furthest
	/// polygon on the existing path that was visited during the search.
	///  @param[in]		existing		An array of polygon references for the existing path.
	///  @param[in]		existingSize	The number of polygon in the @p existing array.
	///  @param[out]	path			An ordered list of polygon references representing the path. (Start to end.) 
	///  								[(polyRef) * @p pathCount]
	///  @param[out]	pathCount		The number of polygons returned in the @p path array.
	///  @param[in]		maxPath			The max number of polygons the @p path array can hold. [Limit: >= 1]
	/// @returns The status flags for the query.
	public function finalizeSlicedFindPathPartial(existing:Array):FindPathResult {

		var path:Array = [];
		if (existing.length == 0) {
			return new FindPathResult(Status.FAILURE, path);
		}
		if (Status.isFailed(m_query.status)) {
			// Reset query.
			m_query = new QueryData();
			return new FindPathResult(Status.FAILURE, path);
		}
		if (m_query.startRef == m_query.endRef) {
			// Special case: the search starts and ends at same poly.
			path.push(m_query.startRef);
		} else {
			// Find furthest existing node that was visited.
			var prev:Node= null;
			var node:Node= null;
			for (var i:int= existing.length-1; i >= 0; --i)
			{
				node = m_nodePool.findNode(existing[i]);
				if (node != null)
					break;
			}
				
			if (node == null)
			{
				m_query.status = Status.PARTIAL_RESULT;
				node = m_query.lastBestNode;
			}
				
			// Reverse the path.
			var prevRay:int= 0;
			do {
				var next:Node= m_nodePool.getNodeAtIdx(node.pidx);
				node.pidx = m_nodePool.getNodeIdx(prev);
				prev = node;
				var nextRay:int= node.flags & Node.DT_NODE_PARENT_DETACHED; // keep track of whether parent is not adjacent (i.e. due to raycast shortcut)
				node.flags = (node.flags & ~Node.DT_NODE_PARENT_DETACHED) | prevRay; // and store it in the reversed path's node
				prevRay = nextRay;
				node = next;
			} while (node != null);
				
			// Store path
			node = prev;
			do {
				next= m_nodePool.getNodeAtIdx(node.pidx);
				if ((node.flags & Node.DT_NODE_PARENT_DETACHED) != 0) {
					var iresult:RaycastHit= raycast(node.id, node.pos, next.pos, m_query.filter, 0, 0);
					path.addAll(iresult.path);
					// raycast ends on poly boundary and the path might include the next poly boundary.
					if (path[path.length - 1] == next.id)
						path.pop();//.remove(path.length - 1); // remove to avoid duplicates
				} else {
					path.push(node.id);
				}

				node = next;
			} while (node != null);
		}
		var status:int= m_query.status;
		// Reset query.
		m_query = new QueryData();

		return new FindPathResult(status, path);
	}	
	
	protected function appendVertex(pos:Array, flags:int, ref:Number, straightPath:Array):int {
		if (straightPath.length > 0&& DetourCommon.vEqual(straightPath[straightPath.length - 1].pos, pos)) {
			// The vertices are equal, update flags and poly.
			straightPath[straightPath.length - 1].flags = flags;
			straightPath[straightPath.length - 1].ref = ref;
		} else {
			// Append new vertex.
			straightPath.push(new StraightPathItem(pos, flags, ref));
			// If reached end of path or there is no space to append more vertices, return.
			if (flags == DT_STRAIGHTPATH_END) {
				return Status.SUCCSESS;
			}
		}
		return Status.IN_PROGRESS;
	}

	protected function appendPortals(startIdx:int, endIdx:int, endPos:Array, path:Array, straightPath:Array,
			options:int):int {
		var startPos:Array= straightPath[straightPath.length - 1].pos;
		// Append or update last vertex
		var stat:int= -1;
		for (var i:int= startIdx; i < endIdx; i++) {
			// Calculate portal
			var from:Number= path[i];
			var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRef(from);
			var fromTile:MeshTile= tileAndPoly.first as MeshTile;
			var fromPoly:Poly= tileAndPoly.second as Poly;

			var to:Number= path[i + 1];
			tileAndPoly = m_nav.getTileAndPolyByRef(to);
			var toTile:MeshTile= tileAndPoly.first as MeshTile;
			var toPoly:Poly= tileAndPoly.second as Poly;

			var portals:PortalResult= getPortalPoints2(from, fromPoly, fromTile, to, toPoly, toTile, 0, 0);
			var left:Array= portals.left;
			var right:Array= portals.right;

			if ((options & DT_STRAIGHTPATH_AREA_CROSSINGS) != 0) {
				// Skip intersection if only area crossings are requested.
				if (fromPoly.getArea() == toPoly.getArea())
					continue;
			}

			// Append intersection
			var interect:Tupple3 = DetourCommon.intersectSegSeg2D(startPos, endPos, left, right);
			if (interect.first) {
				var t:Number= interect.third as Number;
				var pt:Array= DetourCommon.vLerp3(left, right, t);
				stat = appendVertex(pt, 0, path[i + 1], straightPath);
				if (stat != Status.IN_PROGRESS)
					return stat;
			}
		}
		return Status.IN_PROGRESS;
	}

	/// @par
	/// Finds the straight path from the start to the end position within the polygon corridor.
	/// 
	/// This method peforms what is often called 'string pulling'.
	///
	/// The start position is clamped to the first polygon in the path, and the 
	/// end position is clamped to the last. So the start and end positions should 
	/// normally be within or very near the first and last polygons respectively.
	///
	/// The returned polygon references represent the reference id of the polygon 
	/// that is entered at the associated path position. The reference id associated 
	/// with the end point will always be zero.  This allows, for example, matching 
	/// off-mesh link points to their representative polygons.
	///
	/// If the provided result buffers are too small for the entire result set, 
	/// they will be filled as far as possible from the start toward the end 
	/// position.
	///
	///  @param[in]		startPos			Path start position. [(x, y, z)]
	///  @param[in]		endPos				Path end position. [(x, y, z)]
	///  @param[in]		path				An array of polygon references that represent the path corridor.
	///  @param[in]		pathSize			The number of polygons in the @p path array.
	///  @param[out]	straightPath		Points describing the straight path. [(x, y, z) * @p straightPathCount].
	///  @param[out]	straightPathFlags	Flags describing each point. (See: #dtStraightPathFlags) [opt]
	///  @param[out]	straightPathRefs	The reference id of the polygon that is being entered at each point. [opt]
	///  @param[out]	straightPathCount	The number of points in the straight path.
	///  @param[in]		maxStraightPath		The maximum number of points the straight path arrays can hold.  [Limit: > 0]
	///  @param[in]		options				Query options. (see: #dtStraightPathOptions)
	/// @returns The status flags for the query.
	public function findStraightPath(startPos:Array, endPos:Array, path:Array, options:int):Array {
		if (path.length==0) {
			throw ("Empty path");
		}

		// TODO: Should this be callers responsibility?
		var closestStartPos:Array= closestPointOnPolyBoundary(path[0], startPos);
		var closestEndPos:Array= closestPointOnPolyBoundary(path[path.length - 1], endPos);
		var straightPath:Array = [];
		// Add start point.
		var stat:int= appendVertex(closestStartPos, DT_STRAIGHTPATH_START, path[0], straightPath);
		if (stat != Status.IN_PROGRESS)
			return straightPath;

		if (path.length > 1) {
			var portalApex:Array= DetourCommon.vCopy(closestStartPos);
			var portalLeft:Array= DetourCommon.vCopy(portalApex);
			var portalRight:Array= DetourCommon.vCopy(portalApex);
			var apexIndex:int= 0;
			var leftIndex:int= 0;
			var rightIndex:int= 0;

			var leftPolyType:int= 0;
			var rightPolyType:int= 0;

			var leftPolyRef:Number= path[0];
			var rightPolyRef:Number= path[0];

			for (var i:int= 0; i < path.length; ++i) {
				var left:Array;
				var right:Array;
				var fromType:int;
				var toType:int;

				if (i + 1< path.length) {
					// Next portal.
					try {
						var portalPoints:PortalResult= getPortalPoints(path[i], path[i + 1]);
						left = portalPoints.left;
						right = portalPoints.right;
						fromType = portalPoints.fromType;
						toType = portalPoints.toType;
					} catch (e:Error) {
						closestEndPos = closestPointOnPolyBoundary(path[i], endPos);
						// Append portals along the current straight path segment.
						if ((options & (DT_STRAIGHTPATH_AREA_CROSSINGS | DT_STRAIGHTPATH_ALL_CROSSINGS)) != 0) {
							appendPortals(apexIndex, i, closestEndPos, path, straightPath, options);
						}
						appendVertex(closestEndPos, 0, path[i], straightPath);
						return straightPath;
					}

					// If starting really close the portal, advance.
					if (i == 0) {
						var dt:Tupple2 = DetourCommon.distancePtSegSqr2D(portalApex, left, right);
						if (dt.second < DetourCommon.sqr(0.001))
							continue;
					}
				} else {
					// End of the path.
					left = DetourCommon.vCopy(closestEndPos);
					right = DetourCommon.vCopy(closestEndPos);
					fromType = toType = Poly.DT_POLYTYPE_GROUND;
				}

				// Right vertex.
				if (DetourCommon.triArea2D2(portalApex, portalRight, right) <= 0.0) {
					if (DetourCommon.vEqual(portalApex, portalRight) || DetourCommon.triArea2D2(portalApex, portalLeft, right) > 0.0) {
						portalRight = DetourCommon.vCopy(right);
						rightPolyRef = (i + 1< path.length) ? path[i + 1] : 0;
						rightPolyType = toType;
						rightIndex = i;
					} else {
						// Append portals along the current straight path segment.
						if ((options & (DT_STRAIGHTPATH_AREA_CROSSINGS | DT_STRAIGHTPATH_ALL_CROSSINGS)) != 0) {
							stat = appendPortals(apexIndex, leftIndex, portalLeft, path, straightPath, options);
							if (stat != Status.IN_PROGRESS)
								return straightPath;
						}

						portalApex = DetourCommon.vCopy(portalLeft);
						apexIndex = leftIndex;

						var flags:int= 0;
						if (leftPolyRef == 0)
							flags = DT_STRAIGHTPATH_END;
						else if (leftPolyType == Poly.DT_POLYTYPE_OFFMESH_CONNECTION)
							flags = DT_STRAIGHTPATH_OFFMESH_CONNECTION;
						var ref:Number= leftPolyRef;

						// Append or update vertex
						stat = appendVertex(portalApex, flags, ref, straightPath);
						if (stat != Status.IN_PROGRESS)
							return straightPath;

						portalLeft = DetourCommon.vCopy(portalApex);
						portalRight = DetourCommon.vCopy(portalApex);
						leftIndex = apexIndex;
						rightIndex = apexIndex;

						// Restart
						i = apexIndex;

						continue;
					}
				}

				// Left vertex.
				if (DetourCommon.triArea2D2(portalApex, portalLeft, left) >= 0.0) {
					if (DetourCommon.vEqual(portalApex, portalLeft) || DetourCommon.triArea2D2(portalApex, portalRight, left) < 0.0) {
						portalLeft = DetourCommon.vCopy(left);
						leftPolyRef = (i + 1< path.length) ? path[i + 1] : 0;
						leftPolyType = toType;
						leftIndex = i;
					} else {
						// Append portals along the current straight path segment.
						if ((options & (DT_STRAIGHTPATH_AREA_CROSSINGS | DT_STRAIGHTPATH_ALL_CROSSINGS)) != 0) {
							stat = appendPortals(apexIndex, rightIndex, portalRight, path, straightPath, options);
							if (stat != Status.IN_PROGRESS)
								return straightPath;
						}

						portalApex = DetourCommon.vCopy(portalRight);
						apexIndex = rightIndex;

						flags= 0;
						if (rightPolyRef == 0)
							flags = DT_STRAIGHTPATH_END;
						else if (rightPolyType == Poly.DT_POLYTYPE_OFFMESH_CONNECTION)
							flags = DT_STRAIGHTPATH_OFFMESH_CONNECTION;
						ref= rightPolyRef;

						// Append or update vertex
						stat = appendVertex(portalApex, flags, ref, straightPath);
						if (stat != Status.IN_PROGRESS)
							return straightPath;

						portalLeft = DetourCommon.vCopy(portalApex);
						portalRight = DetourCommon.vCopy(portalApex);
						leftIndex = apexIndex;
						rightIndex = apexIndex;

						// Restart
						i = apexIndex;

						continue;
					}
				}
			}

			// Append portals along the current straight path segment.
			if ((options & (DT_STRAIGHTPATH_AREA_CROSSINGS | DT_STRAIGHTPATH_ALL_CROSSINGS)) != 0) {
				stat = appendPortals(apexIndex, path.length - 1, closestEndPos, path, straightPath, options);
				if (stat != Status.IN_PROGRESS)
					return straightPath;
			}
		}

		appendVertex(closestEndPos, DT_STRAIGHTPATH_END, 0, straightPath);

		return straightPath;
	}

	/// @par
	///
	/// This method is optimized for small delta movement and a small number of 
	/// polygons. If used for too great a distance, the result set will form an 
	/// incomplete path.
	///
	/// @p resultPos will equal the @p endPos if the end is reached. 
	/// Otherwise the closest reachable position will be returned.
	/// 
	/// @p resultPos is not projected onto the surface of the navigation 
	/// mesh. Use #getPolyHeight if this is needed.
	///
	/// This method treats the end position in the same manner as 
	/// the #raycast method. (As a 2D point.) See that method's documentation 
	/// for details.
	/// 
	/// If the @p visited array is too small to hold the entire result set, it will 
	/// be filled as far as possible from the start position toward the end 
	/// position.
	///
	/// Moves from the start to the end position constrained to the navigation mesh.
	///  @param[in]		startRef		The reference id of the start polygon.
	///  @param[in]		startPos		A position of the mover within the start polygon. [(x, y, x)]
	///  @param[in]		endPos			The desired end position of the mover. [(x, y, z)]
	///  @param[in]		filter			The polygon filter to apply to the query.
	/// @returns Path
	public function moveAlongSurface(startRef:Number, startPos:Array, endPos:Array, filter:QueryFilter):MoveAlongSurfaceResult {

		// Validate input
		if (startRef == 0)
			throw ("Start ref = 0");
		if (!m_nav.isValidPolyRef(startRef))
			throw ("Invalid start ref");


		m_tinyNodePool.clear();

		var startNode:Node= m_tinyNodePool.getNode(startRef);
		startNode.pidx = 0;
		startNode.cost = 0;
		startNode.total = 0;
		startNode.id = startRef;
		startNode.flags = Node.DT_NODE_CLOSED;
		var stack:Array = [];
		stack.push(startNode);

		var bestPos:Array= []//new float[3];
		var bestDist:Number= Number.MAX_VALUE;
		var bestNode:Node= null;
		DetourCommon.vCopy2(bestPos, startPos);

		// Search constraints
		var searchPos:Array= DetourCommon.vLerp3(startPos, endPos, 0.5);
		var searchRadSqr:Number= DetourCommon.sqr(DetourCommon.vDist(startPos, endPos) / 2.0+ 0.001);

		var verts:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON * 3];

		while (stack.length!=0) {
			// Pop front.
			var curNode:Node= stack.pop();

			// Get poly and tile.
			// The API input has been cheked already, skip checking internal data.
			var curRef:Number= curNode.id;
			var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(curRef);
			var curTile:MeshTile= tileAndPoly.first as MeshTile;
			var curPoly:Poly= tileAndPoly.second as Poly;

			// Collect vertices.
			var nverts:int= curPoly.vertCount;
			for (var i:int= 0; i < nverts; ++i)
				System.arraycopy(curTile.data.verts, curPoly.verts[i] * 3, verts, i * 3, 3);

			// If target is inside the poly, stop search.
			if (DetourCommon.pointInPolygon(endPos, verts, nverts)) {
				bestNode = curNode;
				DetourCommon.vCopy2(bestPos, endPos);
				break;
			}
			
			var j:int;
			// Find wall edges and find nearest point inside the walls.
			for (i = 0, j = curPoly.vertCount - 1; i < curPoly.vertCount; j = i++) {
				// Find links to neighbours.
				var MAX_NEIS:int= 8;
				var nneis:int= 0;
				var neis:Array = [];//new long[MAX_NEIS];

				if ((curPoly.neis[j] & NavMesh.DT_EXT_LINK) != 0) {
					// Tile border.
					for (var k:int= curPoly.firstLink; k != NavMesh.DT_NULL_LINK; k = curTile.links[k].next) {
						var link:Link= curTile.links[k];
						if (link.edge == j) {
							if (link.ref != 0) {
								tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(link.ref);
								var neiTile:MeshTile= tileAndPoly.first as MeshTile;
								var neiPoly:Poly= tileAndPoly.second as Poly;
								if (filter.passFilter(link.ref, neiTile, neiPoly)) {
									if (nneis < MAX_NEIS)
										neis[nneis++] = link.ref;
								}
							}
						}
					}
				} else if (curPoly.neis[j] != 0) {
					var idx:int= curPoly.neis[j] - 1;
					var ref:Number= m_nav.getPolyRefBase(curTile) | idx;
					if (filter.passFilter(ref, curTile, curTile.data.polys[idx])) {
						// Internal edge, encode id.
						neis[nneis++] = ref;
					}
				}

				if (nneis == 0) {
					// Wall edge, calc distance.
					var vj:int= j * 3;
					var vi:int= i * 3;
					var distSeg:Tupple2 = DetourCommon.distancePtSegSqr2D2(endPos, verts, vj, vi);
					var distSqr:Number= distSeg.first as Number;
					var tseg:Number= distSeg.second as Number;
					if (distSqr < bestDist) {
						// Update nearest distance.
						bestPos = DetourCommon.vLerp2(verts, vj, vi, tseg);
						bestDist = distSqr;
						bestNode = curNode;
					}
				} else {
					for (k= 0; k < nneis; ++k) {
						// Skip if no node can be allocated.
						var neighbourNode:Node= m_tinyNodePool.getNode(neis[k]);
						if (neighbourNode == null)
							continue;
						// Skip if already visited.
						if ((neighbourNode.flags & Node.DT_NODE_CLOSED) != 0)
							continue;

						// Skip the link if it is too far from search constraint.
						// TODO: Maybe should use getPortalPoints(), but this one is way faster.
						vj= j * 3;
						vi= i * 3;
						var distseg:Tupple2 = DetourCommon.distancePtSegSqr2D2(searchPos, verts, vj, vi);
						distSqr= distseg.first as Number;
						if (distSqr > searchRadSqr)
							continue;

						// Mark as the node as visited and push to queue.
						neighbourNode.pidx = m_tinyNodePool.getNodeIdx(curNode);
						neighbourNode.flags |= Node.DT_NODE_CLOSED;
						stack.push(neighbourNode);
					}
				}
			}
		}

		var visited:Array = [];
		if (bestNode != null) {
			// Reverse the path.
			var prev:Node= null;
			var node:Node= bestNode;
			do {
				var next:Node= m_tinyNodePool.getNodeAtIdx(node.pidx);
				node.pidx = m_tinyNodePool.getNodeIdx(prev);
				prev = node;
				node = next;
			} while (node != null);

			// Store result
			node = prev;
			do {
				visited.push(node.id);
				node = m_tinyNodePool.getNodeAtIdx(node.pidx);
			} while (node != null);
		}
		return new MoveAlongSurfaceResult(bestPos, visited);
	}

	protected function getPortalPoints(from:Number, to:Number):PortalResult {
		var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRef(from);
		var fromTile:MeshTile= tileAndPoly.first as MeshTile;
		var fromPoly:Poly= tileAndPoly.second as Poly;
		var fromType:int= fromPoly.getType();

		tileAndPoly = m_nav.getTileAndPolyByRef(to);
		var toTile:MeshTile= tileAndPoly.first as MeshTile;
		var toPoly:Poly= tileAndPoly.second as Poly;
		var toType:int= toPoly.getType();

		return getPortalPoints2(from, fromPoly, fromTile, to, toPoly, toTile, fromType, toType);
	}

	// Returns portal points between two polygons.
	protected function getPortalPoints2(from:Number, fromPoly:Poly, fromTile:MeshTile, to:Number, toPoly:Poly, toTile:MeshTile,
			fromType:int, toType:int):PortalResult {
		var left:Array= []//new float[3];
		var right:Array= []//new float[3];
		// Find the link that points to the 'to' polygon.
		var link:Link= null;
		for (var i:int= fromPoly.firstLink; i != NavMesh.DT_NULL_LINK; i = fromTile.links[i].next) {
			if (fromTile.links[i].ref == to) {
				link = fromTile.links[i];
				break;
			}
		}
		if (link == null)
			throw ("Null link");

		// Handle off-mesh connections.
		if (fromPoly.getType() == Poly.DT_POLYTYPE_OFFMESH_CONNECTION) {
			// Find link that points to first vertex.
			for (i= fromPoly.firstLink; i != NavMesh.DT_NULL_LINK; i = fromTile.links[i].next) {
				if (fromTile.links[i].ref == to) {
					var v:int= fromTile.links[i].edge;
					System.arraycopy(fromTile.data.verts, fromPoly.verts[v] * 3, left, 0, 3);
					System.arraycopy(fromTile.data.verts, fromPoly.verts[v] * 3, right, 0, 3);
					return new PortalResult(left, right, fromType, toType);
				}
			}
			throw ("Invalid offmesh from connection");
		}

		if (toPoly.getType() == Poly.DT_POLYTYPE_OFFMESH_CONNECTION) {
			for (i= toPoly.firstLink; i != NavMesh.DT_NULL_LINK; i = toTile.links[i].next) {
				if (toTile.links[i].ref == from) {
					v= toTile.links[i].edge;
					System.arraycopy(toTile.data.verts, toPoly.verts[v] * 3, left, 0, 3);
					System.arraycopy(toTile.data.verts, toPoly.verts[v] * 3, right, 0, 3);
					return new PortalResult(left, right, fromType, toType);
				}
			}
			throw ("Invalid offmesh to connection");
		}

		// Find portal vertices.
		var v0:int= fromPoly.verts[link.edge];
		var v1:int= fromPoly.verts[(link.edge + 1) % int(fromPoly.vertCount)];
		System.arraycopy(fromTile.data.verts, v0 * 3, left, 0, 3);
		System.arraycopy(fromTile.data.verts, v1 * 3, right, 0, 3);

		// If the link is at tile boundary, dtClamp the vertices to
		// the link width.
		if (link.side != 0xff) {
			// Unpack portal limits.
			if (link.bmin != 0|| link.bmax != 255) {
				var s:Number= 1.0/ 255.0;
				var tmin:Number= link.bmin * s;
				var tmax:Number= link.bmax * s;
				left = DetourCommon.vLerp2(fromTile.data.verts, v0 * 3, v1 * 3, tmin);
				right = DetourCommon.vLerp2(fromTile.data.verts, v0 * 3, v1 * 3, tmax);
			}
		}

		return new PortalResult(left, right, fromType, toType);
	}

	// Returns edge mid point between two polygons.
	protected function getEdgeMidPoint(from:Number, to:Number):Array {
		var ppoints:PortalResult= getPortalPoints(from, to);
		var left:Array= ppoints.left;
		var right:Array= ppoints.right;
		var mid:Array= []//new float[3];
		mid[0] = (left[0] + right[0]) * 0.5;
		mid[1] = (left[1] + right[1]) * 0.5;
		mid[2] = (left[2] + right[2]) * 0.5;
		return mid;
	}

	protected function getEdgeMidPoint2(from:Number,fromPoly:Poly,fromTile:MeshTile, to:Number, toPoly:Poly,
			toTile:MeshTile):Array {
		var ppoints:PortalResult= getPortalPoints2(from, fromPoly, fromTile, to, toPoly, toTile, 0, 0);
		var left:Array= ppoints.left;
		var right:Array= ppoints.right;
		var mid:Array= []//new float[3];
		mid[0] = (left[0] + right[0]) * 0.5;
		mid[1] = (left[1] + right[1]) * 0.5;
		mid[2] = (left[2] + right[2]) * 0.5;
		return mid;
	}

	private static var s:Number= 1.0/255.0;

	/// @par
	///
	/// This method is meant to be used for quick, short distance checks.
	///
	/// If the path array is too small to hold the result, it will be filled as 
	/// far as possible from the start postion toward the end position.
	///
	/// <b>Using the Hit Parameter t of RaycastHit</b>
	/// 
	/// If the hit parameter is a very high value (FLT_MAX), then the ray has hit 
	/// the end position. In this case the path represents a valid corridor to the 
	/// end position and the value of @p hitNormal is undefined.
	///
	/// If the hit parameter is zero, then the start position is on the wall that 
	/// was hit and the value of @p hitNormal is undefined.
	///
	/// If 0 < t < 1.0 then the following applies:
	///
	/// @code
	/// distanceToHitBorder = distanceToEndPosition * t
	/// hitPoint = startPos + (endPos - startPos) * t
	/// @endcode
	///
	/// <b>Use Case Restriction</b>
	///
	/// The raycast ignores the y-value of the end position. (2D check.) This 
	/// places significant limits on how it can be used. For example:
	///
	/// Consider a scene where there is a main floor with a second floor balcony 
	/// that hangs over the main floor. So the first floor mesh extends below the 
	/// balcony mesh. The start position is somewhere on the first floor. The end 
	/// position is on the balcony.
	///
	/// The raycast will search toward the end position along the first floor mesh. 
	/// If it reaches the end position's xz-coordinates it will indicate FLT_MAX
	/// (no wall hit), meaning it reached the end position. This is one example of why
	/// this method is meant for short distance checks.
	///
	/// Casts a 'walkability' ray along the surface of the navigation mesh from 
	/// the start position toward the end position.
	/// @note A wrapper around raycast(..., RaycastHit*). Retained for backward compatibility.
	///  @param[in]		startRef	The reference id of the start polygon.
	///  @param[in]		startPos	A position within the start polygon representing 
	///  							the start of the ray. [(x, y, z)]
	///  @param[in]		endPos		The position to cast the ray toward. [(x, y, z)]
	///  @param[out]	t			The hit parameter. (FLT_MAX if no wall hit.)
	///  @param[out]	hitNormal	The normal of the nearest wall hit. [(x, y, z)]
	///  @param[in]		filter		The polygon filter to apply to the query.
	///  @param[out]	path		The reference ids of the visited polygons. [opt]
	///  @param[out]	pathCount	The number of visited polygons. [opt]
	///  @param[in]		maxPath		The maximum number of polygons the @p path array can hold.
	/// @returns The status flags for the query.
	public function raycast(startRef:Number, startPos:Array, endPos:Array, filter:QueryFilter, options:int, prevRef:Number):RaycastHit {
		// Validate input
		if (startRef == 0|| !m_nav.isValidPolyRef(startRef))
			throw ("Invalid start ref");
		if (prevRef != 0&& !m_nav.isValidPolyRef(prevRef))
			throw ("Invalid pref ref");

		var hit:RaycastHit= new RaycastHit();

		var verts:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON * 3+ 3];

		var curPos:Array = []//new float[3], 
		var lastPos:Array = []//new float[3];
		var curPosV:VectorPtr= new VectorPtr(curPos);

		DetourCommon.vCopy2(curPos, startPos);
		var dir:Array= DetourCommon.vSub2(endPos, startPos);

		var prevTile:MeshTile, tile:MeshTile, nextTile:MeshTile;
		var prevPoly:Poly, poly:Poly, nextPoly:Poly;

		// The API input has been checked already, skip checking internal data.
		var curRef:Number= startRef;
		var tileAndPolyUns:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(curRef);
		tile = tileAndPolyUns.first as MeshTile;
		poly = tileAndPolyUns.second as Poly;
		nextTile = prevTile = tile;
		nextPoly = prevPoly = poly;
		if (prevRef != 0) {
			tileAndPolyUns = m_nav.getTileAndPolyByRefUnsafe(prevRef);
			prevTile = tileAndPolyUns.first as MeshTile;
			prevPoly = tileAndPolyUns.second as Poly;
		}
		while (curRef != 0) {
			// Cast ray against current polygon.

			// Collect vertices.
			var nv:int= 0;
			for (var i:int= 0; i < int(poly.vertCount); ++i) {
				System.arraycopy(tile.data.verts, poly.verts[i] * 3, verts, nv * 3, 3);
				nv++;
			}

			var iresult:IntersectResult= DetourCommon.intersectSegmentPoly2D(startPos, endPos, verts, nv);
			if (!iresult.intersects) {
				// Could not hit the polygon, keep the old t and report hit.
				return hit;
			}
			// Keep track of furthest t so far.
			if (iresult.tmax > hit.t)
				hit.t = iresult.tmax;

			// Store visited polygons.
			hit.path.push(curRef);

			// Ray end is completely inside the polygon.
			if (iresult.segMax == -1) {
				hit.t = Number.MAX_VALUE;

				// add the cost
				if ((options & DT_RAYCAST_USE_COSTS) != 0)
					hit.pathCost += filter.getCost(curPos, endPos, prevRef, prevTile, prevPoly, curRef, tile, poly,
							curRef, tile, poly);
				return hit;
			}

			// Follow neighbours.
			var nextRef:Number= 0;

			for (i= poly.firstLink; i != NavMesh.DT_NULL_LINK; i = tile.links[i].next) {
				var link:Link= tile.links[i];

				// Find link which contains this edge.
				if (link.edge != iresult.segMax)
					continue;

				// Get pointer to the next polygon.
				tileAndPolyUns = m_nav.getTileAndPolyByRefUnsafe(link.ref);
				nextTile = tileAndPolyUns.first as MeshTile;
				nextPoly = tileAndPolyUns.second as Poly;
				// Skip off-mesh connections.
				if (nextPoly.getType() == Poly.DT_POLYTYPE_OFFMESH_CONNECTION)
					continue;

				// Skip links based on filter.
				if (!filter.passFilter(link.ref, nextTile, nextPoly))
					continue;

				// If the link is internal, just return the ref.
				if (link.side == 0xff) {
					nextRef = link.ref;
					break;
				}

				// If the link is at tile boundary,

				// Check if the link spans the whole edge, and accept.
				if (link.bmin == 0&& link.bmax == 255) {
					nextRef = link.ref;
					break;
				}

				// Check for partial edge links.
				var v0:int= poly.verts[link.edge];
				var v1:int= poly.verts[(link.edge + 1) % poly.vertCount];
				var left:int= v0 * 3;
				var right:int= v1 * 3;

				// Check that the intersection lies inside the link portal.
				if (link.side == 0|| link.side == 4) {
					// Calculate link size.
					var lmin:Number= tile.data.verts[left + 2]
							+ (tile.data.verts[right + 2] - tile.data.verts[left + 2]) * (link.bmin * s);
					var lmax:Number= tile.data.verts[left + 2]
							+ (tile.data.verts[right + 2] - tile.data.verts[left + 2]) * (link.bmax * s);
					if (lmin > lmax) {
						var temp:Number= lmin;
						lmin = lmax;
						lmax = temp;
					}

					// Find Z intersection.
					var z:Number= startPos[2] + (endPos[2] - startPos[2]) * iresult.tmax;
					if (z >= lmin && z <= lmax) {
						nextRef = link.ref;
						break;
					}
				} else if (link.side == 2|| link.side == 6) {
					// Calculate link size.
					lmin= tile.data.verts[left] + (tile.data.verts[right] - tile.data.verts[left]) * (link.bmin * s);
					lmax= tile.data.verts[left] + (tile.data.verts[right] - tile.data.verts[left]) * (link.bmax * s);
					if (lmin > lmax) {
						temp= lmin;
						lmin = lmax;
						lmax = temp;
					}

					// Find X intersection.
					var x:Number= startPos[0] + (endPos[0] - startPos[0]) * iresult.tmax;
					if (x >= lmin && x <= lmax) {
						nextRef = link.ref;
						break;
					}
				}
			}

			// add the cost
			if ((options & DT_RAYCAST_USE_COSTS) != 0) {
				// compute the intersection point at the furthest end of the polygon
				// and correct the height (since the raycast moves in 2d)
				DetourCommon.vCopy2(lastPos, curPos);
				curPos = DetourCommon.vMad(startPos, dir, hit.t);
				var e1:VectorPtr= new VectorPtr(verts, iresult.segMax * 3);
				var e2:VectorPtr= new VectorPtr(verts, ((iresult.segMax + 1) % nv) * 3);
				var eDir:Array= DetourCommon.vSub(e2, e1);
				var diff:Array= DetourCommon.vSub(curPosV, e1);
				var s:Number= DetourCommon.sqr(eDir[0]) > DetourCommon.sqr(eDir[2]) ? diff[0] / eDir[0] : diff[2] / eDir[2];
				curPos[1] = e1[1] + eDir[1] * s;

				hit.pathCost += filter.getCost(lastPos, curPos, prevRef, prevTile, prevPoly, curRef, tile, poly,
						nextRef, nextTile, nextPoly);
			}

			if (nextRef == 0) {
				// No neighbour, we hit a wall.

				// Calculate hit normal.
				var a:int= iresult.segMax;
				var b:int= iresult.segMax + 1< nv ? iresult.segMax + 1: 0;
				var va:int= a * 3;
				var vb:int= b * 3;
				var dx:Number= verts[vb] - verts[va];
				var dz:Number= verts[vb + 2] - verts[va + 2];
				hit.hitNormal[0] = dz;
				hit.hitNormal[1] = 0;
				hit.hitNormal[2] = -dx;
				DetourCommon.vNormalize(hit.hitNormal);
				return hit;
			}

			// No hit, advance to neighbour polygon.
			prevRef = curRef;
			curRef = nextRef;
			prevTile = tile;
			tile = nextTile;
			prevPoly = poly;
			poly = nextPoly;
		}

		return hit;
	}

	/// @par
	///
	/// At least one result array must be provided.
	///
	/// The order of the result set is from least to highest cost to reach the polygon.
	///
	/// A common use case for this method is to perform Dijkstra searches. 
	/// Candidate polygons are found by searching the graph beginning at the start polygon.
	///
	/// If a polygon is not found via the graph search, even if it intersects the 
	/// search circle, it will not be included in the result set. For example:
	///
	/// polyA is the start polygon.
	/// polyB shares an edge with polyA. (Is adjacent.)
	/// polyC shares an edge with polyB, but not with polyA
	/// Even if the search circle overlaps polyC, it will not be included in the 
	/// result set unless polyB is also in the set.
	/// 
	/// The value of the center point is used as the start position for cost 
	/// calculations. It is not projected onto the surface of the mesh, so its 
	/// y-value will effect the costs.
	///
	/// Intersection tests occur in 2D. All polygons and the search circle are 
	/// projected onto the xz-plane. So the y-value of the center point does not 
	/// effect intersection tests.
	///
	/// If the result arrays are to small to hold the entire result set, they will be 
	/// filled to capacity.
	/// 
	///@}
	/// @name Dijkstra Search Functions
	/// @{ 

	/// Finds the polygons along the navigation graph that touch the specified circle.
	///  @param[in]		startRef		The reference id of the polygon where the search starts.
	///  @param[in]		centerPos		The center of the search circle. [(x, y, z)]
	///  @param[in]		radius			The radius of the search circle.
	///  @param[in]		filter			The polygon filter to apply to the query.
	///  @param[out]	resultRef		The reference ids of the polygons touched by the circle. [opt]
	///  @param[out]	resultParent	The reference ids of the parent polygons for each result. 
	///  								Zero if a result polygon has no parent. [opt]
	///  @param[out]	resultCost		The search cost from @p centerPos to the polygon. [opt]
	///  @param[out]	resultCount		The number of polygons found. [opt]
	///  @param[in]		maxResult		The maximum number of polygons the result arrays can hold.
	/// @returns The status flags for the query.
	public function findPolysAroundCircle(startRef:Number, centerPos:Array, radius:Number,
			filter:QueryFilter):FindPolysAroundResult {

		// Validate input
		if (startRef == 0|| !m_nav.isValidPolyRef(startRef))
			throw ("Invalid start ref");

		var resultRef:Array = [];
		var resultParent:Array = [];
		var resultCost:Array = [];

		m_nodePool.clear();
		m_openList.clear();

		var startNode:Node= m_nodePool.getNode(startRef);
		DetourCommon.vCopy2(startNode.pos, centerPos);
		startNode.pidx = 0;
		startNode.cost = 0;
		startNode.total = 0;
		startNode.id = startRef;
		startNode.flags = Node.DT_NODE_OPEN;
		m_openList.push(startNode);

		resultRef.push(startNode.id);
		resultParent.push(0);
		resultCost.push(0);

		var radiusSqr:Number= DetourCommon.sqr(radius);

		while (!m_openList.isEmpty()) {
			var bestNode:Node= m_openList.pop();
			bestNode.flags &= ~Node.DT_NODE_OPEN;
			bestNode.flags |= Node.DT_NODE_CLOSED;

			// Get poly and tile.
			// The API input has been cheked already, skip checking internal data.
			var bestRef:Number= bestNode.id;
			var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(bestRef);
			var bestTile:MeshTile= tileAndPoly.first as MeshTile;
			var bestPoly:Poly= tileAndPoly.second as Poly;

			// Get parent poly and tile.
			var parentRef:Number= 0;
			var parentTile:MeshTile= null;
			var parentPoly:Poly= null;
			if (bestNode.pidx != 0)
				parentRef = m_nodePool.getNodeAtIdx(bestNode.pidx).id;
			if (parentRef != 0) {
				tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(parentRef);
				parentTile = tileAndPoly.first as MeshTile;
				parentPoly = tileAndPoly.second as Poly;
			}

			for (var i:int= bestPoly.firstLink; i != NavMesh.DT_NULL_LINK; i = bestTile.links[i].next) {
				var link:Link= bestTile.links[i];
				var neighbourRef:Number= link.ref;
				// Skip invalid neighbours and do not follow back to parent.
				if (neighbourRef == 0|| neighbourRef == parentRef)
					continue;

				// Expand to neighbour
				tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(neighbourRef);
				var neighbourTile:MeshTile= tileAndPoly.first as MeshTile;
				var neighbourPoly:Poly= tileAndPoly.second as Poly;

				// Do not advance if the polygon is excluded by the filter.
				if (!filter.passFilter(neighbourRef, neighbourTile, neighbourPoly))
					continue;

				// Find edge and calc distance to the edge.
				var pp:PortalResult= getPortalPoints2(bestRef, bestPoly, bestTile, neighbourRef, neighbourPoly,
						neighbourTile, 0, 0);
				var va:Array= pp.left;
				var vb:Array= pp.right;

				// If the circle is not touching the next polygon, skip it.
				var distseg:Tupple2 = DetourCommon.distancePtSegSqr2D(centerPos, va, vb);
				var distSqr:Number= distseg.first as Number;
				if (distSqr > radiusSqr)
					continue;

				var neighbourNode:Node= m_nodePool.getNode(neighbourRef); 

				if ((neighbourNode.flags & Node.DT_NODE_CLOSED) != 0)// TODO: (PP) move it higher?
					continue;

				// Cost
				if (neighbourNode.flags == 0)
					neighbourNode.pos = DetourCommon.vLerp3(va, vb, 0.5);

				var total:Number= bestNode.total + DetourCommon.vDist(bestNode.pos, neighbourNode.pos);

				// The node is already in open list and the new result is worse, skip.
				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0&& total >= neighbourNode.total)
					continue;

				neighbourNode.id = neighbourRef;
				neighbourNode.flags = (neighbourNode.flags & ~Node.DT_NODE_CLOSED);
				neighbourNode.pidx = m_nodePool.getNodeIdx(bestNode);
				neighbourNode.total = total;

				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0) {
					m_openList.modify(neighbourNode);
				} else {
					resultRef.push(neighbourNode.id);
					resultParent.push(m_nodePool.getNodeAtIdx(neighbourNode.pidx).id);
					resultCost.push(neighbourNode.total);
					neighbourNode.flags = Node.DT_NODE_OPEN;
					m_openList.push(neighbourNode);
				}
			}
		}

		return new FindPolysAroundResult(resultRef, resultParent, resultCost);
	}

	/// @par
	///
	/// The order of the result set is from least to highest cost.
	/// 
	/// At least one result array must be provided.
	///
	/// A common use case for this method is to perform Dijkstra searches. 
	/// Candidate polygons are found by searching the graph beginning at the start 
	/// polygon.
	/// 
	/// The same intersection test restrictions that apply to findPolysAroundCircle()
	/// method apply to this method.
	/// 
	/// The 3D centroid of the search polygon is used as the start position for cost 
	/// calculations.
	/// 
	/// Intersection tests occur in 2D. All polygons are projected onto the 
	/// xz-plane. So the y-values of the vertices do not effect intersection tests.
	/// 
	/// If the result arrays are is too small to hold the entire result set, they will 
	/// be filled to capacity.
	///
	/// Finds the polygons along the naviation graph that touch the specified convex polygon.
	///  @param[in]		startRef		The reference id of the polygon where the search starts.
	///  @param[in]		verts			The vertices describing the convex polygon. (CCW) 
	///  								[(x, y, z) * @p nverts]
	///  @param[in]		nverts			The number of vertices in the polygon.
	///  @param[in]		filter			The polygon filter to apply to the query.
	///  @param[out]	resultRef		The reference ids of the polygons touched by the search polygon. [opt]
	///  @param[out]	resultParent	The reference ids of the parent polygons for each result. Zero if a 
	///  								result polygon has no parent. [opt]
	///  @param[out]	resultCost		The search cost from the centroid point to the polygon. [opt]
	///  @param[out]	resultCount		The number of polygons found.
	///  @param[in]		maxResult		The maximum number of polygons the result arrays can hold.
	/// @returns The status flags for the query.
	public function findPolysAroundShape(startRef:Number, verts:Array, nverts:int,
			filter:QueryFilter):FindPolysAroundResult {
		// Validate input
		if (startRef == 0|| !m_nav.isValidPolyRef(startRef))
			throw ("Invalid start ref");

		var resultRef:Array = [];
		var resultParent:Array = [];
		var resultCost:Array = [];

		m_nodePool.clear();
		m_openList.clear();

		var centerPos:Array= [ 0, 0, 0];
		for (var i:int= 0; i < nverts; ++i) {
			centerPos[0] += verts[i * 3];
			centerPos[1] += verts[i * 3+ 1];
			centerPos[2] += verts[i * 3+ 2];
		}
		var scale:Number= 1.0/ nverts;
		centerPos[0] *= scale;
		centerPos[1] *= scale;
		centerPos[2] *= scale;

		var startNode:Node= m_nodePool.getNode(startRef);
		DetourCommon.vCopy2(startNode.pos, centerPos);
		startNode.pidx = 0;
		startNode.cost = 0;
		startNode.total = 0;
		startNode.id = startRef;
		startNode.flags = Node.DT_NODE_OPEN;
		m_openList.push(startNode);

		resultRef.push(startNode.id);
		resultParent.push(0);
		resultCost.push(0);

		while (!m_openList.isEmpty()) {
			var bestNode:Node= m_openList.pop();
			bestNode.flags &= ~Node.DT_NODE_OPEN;
			bestNode.flags |= Node.DT_NODE_CLOSED;

			// Get poly and tile.
			// The API input has been cheked already, skip checking internal data.
			var bestRef:Number= bestNode.id;
			var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(bestRef);
			var bestTile:MeshTile= tileAndPoly.first as MeshTile;
			var bestPoly:Poly= tileAndPoly.second as Poly;

			// Get parent poly and tile.
			var parentRef:Number= 0;
			var parentTile:MeshTile= null;
			var parentPoly:Poly= null;
			if (bestNode.pidx != 0)
				parentRef = m_nodePool.getNodeAtIdx(bestNode.pidx).id;
			if (parentRef != 0) {
				tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(parentRef);
				parentTile = tileAndPoly.first as MeshTile;
				parentPoly = tileAndPoly.second as Poly;
			}

			for (i= bestPoly.firstLink; i != NavMesh.DT_NULL_LINK; i = bestTile.links[i].next) {
				var link:Link= bestTile.links[i];
				var neighbourRef:Number= link.ref;
				// Skip invalid neighbours and do not follow back to parent.
				if (neighbourRef == 0|| neighbourRef == parentRef)
					continue;

				// Expand to neighbour
				tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(neighbourRef);
				var neighbourTile:MeshTile= tileAndPoly.first as MeshTile;
				var neighbourPoly:Poly= tileAndPoly.second as Poly;

				// Do not advance if the polygon is excluded by the filter.
				if (!filter.passFilter(neighbourRef, neighbourTile, neighbourPoly))
					continue;

				// Find edge and calc distance to the edge.
				var pp:PortalResult= getPortalPoints2(bestRef, bestPoly, bestTile, neighbourRef, neighbourPoly,
						neighbourTile, 0, 0);
				var va:Array= pp.left;
				var vb:Array= pp.right;

				// If the poly is not touching the edge to the next polygon, skip the connection it.
				var ir:IntersectResult= DetourCommon.intersectSegmentPoly2D(va, vb, verts, nverts);
				if (!ir.intersects)
					continue;
				if (ir.tmin > 1.0|| ir.tmax < 0.0)
					continue;

				var neighbourNode:Node= m_nodePool.getNode(neighbourRef);

				if ((neighbourNode.flags & Node.DT_NODE_CLOSED) != 0) // TODO: (PP) move it higer?
					continue;

				// Cost
				if (neighbourNode.flags == 0)
					neighbourNode.pos = DetourCommon.vLerp3(va, vb, 0.5);

				var total:Number= bestNode.total + DetourCommon.vDist(bestNode.pos, neighbourNode.pos);

				// The node is already in open list and the new result is worse, skip.
				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0&& total >= neighbourNode.total)
					continue;

				neighbourNode.id = neighbourRef;
				neighbourNode.flags = (neighbourNode.flags & ~Node.DT_NODE_CLOSED);
				neighbourNode.pidx = m_nodePool.getNodeIdx(bestNode);
				neighbourNode.total = total;

				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0) {
					m_openList.modify(neighbourNode);
				} else {
					resultRef.push(neighbourNode.id);
					resultParent.push(m_nodePool.getNodeAtIdx(neighbourNode.pidx).id);
					resultCost.push(neighbourNode.total);
					neighbourNode.flags = Node.DT_NODE_OPEN;
					m_openList.push(neighbourNode);
				}

			}
		}

		return new FindPolysAroundResult(resultRef, resultParent, resultCost);
	}

	/// @par
	///
	/// This method is optimized for a small search radius and small number of result 
	/// polygons.
	///
	/// Candidate polygons are found by searching the navigation graph beginning at 
	/// the start polygon.
	///
	/// The same intersection test restrictions that apply to the findPolysAroundCircle 
	/// mehtod applies to this method.
	///
	/// The value of the center point is used as the start point for cost calculations. 
	/// It is not projected onto the surface of the mesh, so its y-value will effect 
	/// the costs.
	/// 
	/// Intersection tests occur in 2D. All polygons and the search circle are 
	/// projected onto the xz-plane. So the y-value of the center point does not 
	/// effect intersection tests.
	/// 
	/// If the result arrays are is too small to hold the entire result set, they will 
	/// be filled to capacity.
	/// 
	/// Finds the non-overlapping navigation polygons in the local neighbourhood around the center position.
	///  @param[in]		startRef		The reference id of the polygon where the search starts.
	///  @param[in]		centerPos		The center of the query circle. [(x, y, z)]
	///  @param[in]		radius			The radius of the query circle.
	///  @param[in]		filter			The polygon filter to apply to the query.
	///  @param[out]	resultRef		The reference ids of the polygons touched by the circle.
	///  @param[out]	resultParent	The reference ids of the parent polygons for each result. 
	///  								Zero if a result polygon has no parent. [opt]
	///  @param[out]	resultCount		The number of polygons found.
	///  @param[in]		maxResult		The maximum number of polygons the result arrays can hold.
	/// @returns The status flags for the query.
	public function findLocalNeighbourhood(startRef:Number, centerPos:Array, radius:Number,
			filter:QueryFilter):FindLocalNeighbourhoodResult {

		// Validate input
		if (startRef == 0|| !m_nav.isValidPolyRef(startRef))
			throw ("Invalid start ref");

		var resultRef:Array = [];
		var resultParent:Array = [];

		m_tinyNodePool.clear();

		var startNode:Node= m_tinyNodePool.getNode(startRef);
		startNode.pidx = 0;
		startNode.id = startRef;
		startNode.flags = Node.DT_NODE_CLOSED;
		var stack:Array = [];
		stack.push(startNode);

		resultRef.push(startNode.id);
		resultParent.push(0);

		var radiusSqr:Number= DetourCommon.sqr(radius);

		var pa:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON * 3];
		var pb:Array= []//new float[NavMesh.DT_VERTS_PER_POLYGON * 3];

		while (stack.length!=0) {
			// Pop front.
			var curNode:Node= stack.pop();

			// Get poly and tile.
			// The API input has been cheked already, skip checking internal data.
			var curRef:Number= curNode.id;
			var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(curRef);
			var curTile:MeshTile= tileAndPoly.first as MeshTile;
			var curPoly:Poly= tileAndPoly.second as Poly;

			for (var i:int= curPoly.firstLink; i != NavMesh.DT_NULL_LINK; i = curTile.links[i].next) {
				var link:Link= curTile.links[i];
				var neighbourRef:Number= link.ref;
				// Skip invalid neighbours.
				if (neighbourRef == 0)
					continue;

				// Skip if cannot alloca more nodes.
				var neighbourNode:Node= m_tinyNodePool.getNode(neighbourRef);
				if (neighbourNode == null)
					continue;
				// Skip visited.
				if ((neighbourNode.flags & Node.DT_NODE_CLOSED) != 0)
					continue;

				// Expand to neighbour
				tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(neighbourRef);
				var neighbourTile:MeshTile= tileAndPoly.first as MeshTile;
				var neighbourPoly:Poly= tileAndPoly.second as Poly;

				// Skip off-mesh connections.
				if (neighbourPoly.getType() == Poly.DT_POLYTYPE_OFFMESH_CONNECTION)
					continue;

				// Do not advance if the polygon is excluded by the filter.
				if (!filter.passFilter(neighbourRef, neighbourTile, neighbourPoly))
					continue;

				// Find edge and calc distance to the edge.
				var pp:PortalResult= getPortalPoints2(curRef, curPoly, curTile, neighbourRef, neighbourPoly, neighbourTile,
						0, 0);
				var va:Array= pp.left;
				var vb:Array= pp.right;

				// If the circle is not touching the next polygon, skip it.
				var distseg:Tupple2 = DetourCommon.distancePtSegSqr2D(centerPos, va, vb);
				var distSqr:Number= distseg.first as Number;
				if (distSqr > radiusSqr)
					continue;

				// Mark node visited, this is done before the overlap test so that
				// we will not visit the poly again if the test fails.
				neighbourNode.flags |= Node.DT_NODE_CLOSED;
				neighbourNode.pidx = m_tinyNodePool.getNodeIdx(curNode);

				// Check that the polygon does not collide with existing polygons.

				// Collect vertices of the neighbour poly.
				var npa:int= neighbourPoly.vertCount;
				for (var k:int= 0; k < npa; ++k)
					System.arraycopy(neighbourTile.data.verts, neighbourPoly.verts[k] * 3, pa, k * 3, 3);

				var overlap:Boolean= false;
				for (var j:int= 0; j < resultRef.length; ++j) {
					var pastRef:Number= resultRef[j];

					// Connected polys do not overlap.
					var connected:Boolean= false;
					for (k= curPoly.firstLink; k != NavMesh.DT_NULL_LINK; k = curTile.links[k].next) {
						if (curTile.links[k].ref == pastRef) {
							connected = true;
							break;
						}
					}
					if (connected)
						continue;

					// Potentially overlapping.
					tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(pastRef);
					var pastTile:MeshTile= tileAndPoly.first as MeshTile;
					var pastPoly:Poly= tileAndPoly.second as Poly;

					// Get vertices and test overlap
					var npb:int= pastPoly.vertCount;
					for (k= 0; k < npb; ++k)
						System.arraycopy(pastTile.data.verts, pastPoly.verts[k] * 3, pb, k * 3, 3);

					if (DetourCommon.overlapPolyPoly2D(pa, npa, pb, npb)) {
						overlap = true;
						break;
					}
				}
				if (overlap)
					continue;

				resultRef.push(neighbourRef);
				resultParent.push(curRef);
				stack.push(neighbourNode);
			}
		}

		return new FindLocalNeighbourhoodResult(resultRef, resultParent);
	}



	protected function insertInterval(ints:Array, tmin:int, tmax:int, ref:Number):void {
		// Find insertion point.
		var idx:int= 0;
		while (idx < ints.length) {
			if (tmax <= ints[idx].tmin)
				break;
			idx++;
		}
		// Store
		ints.push(idx, new SegInterval(ref, tmin, tmax));
	}
	
	/// @par
	///
	/// If the @p segmentRefs parameter is provided, then all polygon segments will be returned. 
	/// Otherwise only the wall segments are returned.
	/// 
	/// A segment that is normally a portal will be included in the result set as a 
	/// wall if the @p filter results in the neighbor polygon becoomming impassable.
	/// 
	/// The @p segmentVerts and @p segmentRefs buffers should normally be sized for the 
	/// maximum segments per polygon of the source navigation mesh.
	/// 
	/// Returns the segments for the specified polygon, optionally including portals.
	///  @param[in]		ref				The reference id of the polygon.
	///  @param[in]		filter			The polygon filter to apply to the query.
	///  @param[out]	segmentVerts	The segments. [(ax, ay, az, bx, by, bz) * segmentCount]
	///  @param[out]	segmentRefs		The reference ids of each segment's neighbor polygon. 
	///  								Or zero if the segment is a wall. [opt] [(parentRef) * @p segmentCount] 
	///  @param[out]	segmentCount	The number of segments returned.
	///  @param[in]		maxSegments		The maximum number of segments the result arrays can hold.
	/// @returns The status flags for the query.
	public function getPolyWallSegments(ref:Number, filter:QueryFilter):GetPolyWallSegmentsResult {
		var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRef(ref);
		var tile:MeshTile= tileAndPoly.first as MeshTile;
		var poly:Poly= tileAndPoly.second as Poly;

		var segmentRefs:Array = [];
		var segmentVerts:Array = [];
		var ints:Array = [];

		for (var i:int= 0, j:int = poly.vertCount - 1; i < poly.vertCount; j = i++) {
			// Skip non-solid edges.
			ints.splice(0, ints.length);//.clear();
			if ((poly.neis[j] & NavMesh.DT_EXT_LINK) != 0) {
				// Tile border.
				for (k= poly.firstLink; k != NavMesh.DT_NULL_LINK; k = tile.links[k].next) {
					var link:Link= tile.links[k];
					if (link.edge == j) {
						if (link.ref != 0) {
							tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(link.ref);
							var neiTile:MeshTile= tileAndPoly.first as MeshTile;
							var neiPoly:Poly= tileAndPoly.second as Poly;
							if (filter.passFilter(link.ref, neiTile, neiPoly)) {
								insertInterval(ints, link.bmin, link.bmax, link.ref);
							}
						}
					}
				}
			} else {
				// Internal edge
				var neiRef:Number= 0;
				if (poly.neis[j] != 0) {
					var idx:int= (poly.neis[j] - 1);
					neiRef = m_nav.getPolyRefBase(tile) | idx;
					if (!filter.passFilter(neiRef, tile, tile.data.polys[idx]))
						neiRef = 0;
				}

				vj= poly.verts[j] * 3;
				vi= poly.verts[i] * 3;
				var seg:Array= []//new float[6];
				System.arraycopy(tile.data.verts, vj, seg, 0, 3);
				System.arraycopy(tile.data.verts, vi, seg, 3, 3);
				segmentVerts.push(seg);
				segmentRefs.push(neiRef);
				continue;
			}

			// Add sentinels
			insertInterval(ints, -1, 0, 0);
			insertInterval(ints, 255, 256, 0);

			// Store segments.
			var vj:int= poly.verts[j] * 3;
			var vi:int= poly.verts[i] * 3;
			for (var k:int= 1; k < ints.length; ++k) {
				// Portal segment.
				if (ints[k].ref != 0) {
					var tmin:Number= ints[k].tmin / 255.0;
					var tmax:Number= ints[k].tmax / 255.0;
					seg= []//new float[6];
					System.arraycopy(DetourCommon.vLerp2(tile.data.verts, vj, vi, tmin), 0, seg, 0, 3);
					System.arraycopy(DetourCommon.vLerp2(tile.data.verts, vj, vi, tmax), 0, seg, 3, 3);
					segmentVerts.push(seg);
					segmentRefs.push(ints[k].ref);
				}

				// Wall segment.
				var imin:int= ints[k - 1].tmax;
				var imax:int= ints[k].tmin;
				if (imin != imax) {
					tmin= imin / 255.0;
					tmax= imax / 255.0;
					seg= []//new float[6];
					System.arraycopy(DetourCommon.vLerp2(tile.data.verts, vj, vi, tmin), 0, seg, 0, 3);
					System.arraycopy(DetourCommon.vLerp2(tile.data.verts, vj, vi, tmax), 0, seg, 3, 3);
					segmentVerts.push(seg);
					segmentRefs.push(0);
				}
			}
		}

		return new GetPolyWallSegmentsResult(segmentVerts, segmentRefs);
	}
	
	/// @par
	///
	/// @p hitPos is not adjusted using the height detail data.
	///
	/// @p hitDist will equal the search radius if there is no wall within the 
	/// radius. In this case the values of @p hitPos and @p hitNormal are
	/// undefined.
	///
	/// The normal will become unpredicable if @p hitDist is a very small number.
	///
	/// Finds the distance from the specified position to the nearest polygon wall.
	///  @param[in]		startRef		The reference id of the polygon containing @p centerPos.
	///  @param[in]		centerPos		The center of the search circle. [(x, y, z)]
	///  @param[in]		maxRadius		The radius of the search circle.
	///  @param[in]		filter			The polygon filter to apply to the query.
	///  @param[out]	hitDist			The distance to the nearest wall from @p centerPos.
	///  @param[out]	hitPos			The nearest position on the wall that was hit. [(x, y, z)]
	///  @param[out]	hitNormal		The normalized ray formed from the wall point to the 
	///  								source point. [(x, y, z)]
	/// @returns The status flags for the query.
	public function findDistanceToWall(startRef:Number, centerPos:Array, maxRadius:Number,
			filter:QueryFilter):FindDistanceToWallResult {

		// Validate input
		if (startRef == 0|| !m_nav.isValidPolyRef(startRef))
			throw ("Invalid start ref");

		m_nodePool.clear();
		m_openList.clear();

		var startNode:Node= m_nodePool.getNode(startRef);
		DetourCommon.vCopy2(startNode.pos, centerPos);
		startNode.pidx = 0;
		startNode.cost = 0;
		startNode.total = 0;
		startNode.id = startRef;
		startNode.flags = Node.DT_NODE_OPEN;
		m_openList.push(startNode);

		var radiusSqr:Number= DetourCommon.sqr(maxRadius);
		var hitPos:Array= []//new float[3];
		while (!m_openList.isEmpty()) {
			var bestNode:Node= m_openList.pop();
			bestNode.flags &= ~Node.DT_NODE_OPEN;
			bestNode.flags |= Node.DT_NODE_CLOSED;

			// Get poly and tile.
			// The API input has been cheked already, skip checking internal data.
			var bestRef:Number= bestNode.id;
			var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRefUnsafe(bestRef);
			var bestTile:MeshTile= tileAndPoly.first as MeshTile;
			var bestPoly:Poly= tileAndPoly.second as Poly;

			// Get parent poly and tile.
			var parentRef:Number= 0;
			var parentTile:MeshTile= null;
			var parentPoly:Poly= null;
			if (bestNode.pidx != 0)
				parentRef = m_nodePool.getNodeAtIdx(bestNode.pidx).id;
			if (parentRef != 0) {
				tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(parentRef);
				parentTile = tileAndPoly.first as MeshTile;
				parentPoly = tileAndPoly.second as Poly;
			}

			// Hit test walls.
			for (var i:int= 0, j:int = int(bestPoly.vertCount )- 1; i < int(bestPoly.vertCount); j = i++) {
				// Skip non-solid edges.
				if ((bestPoly.neis[j] & NavMesh.DT_EXT_LINK) != 0) {
					// Tile border.
					var solid:Boolean= true;
					for (var k:int= bestPoly.firstLink; k != NavMesh.DT_NULL_LINK; k = bestTile.links[k].next) {
						var link:Link= bestTile.links[k];
						if (link.edge == j) {
							if (link.ref != 0) {
								tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(link.ref);
								var neiTile:MeshTile= tileAndPoly.first as MeshTile;
								var neiPoly:Poly= tileAndPoly.second as Poly;
								if (filter.passFilter(link.ref, neiTile, neiPoly))
									solid = false;
							}
							break;
						}
					}
					if (!solid)
						continue;
				} else if (bestPoly.neis[j] != 0) {
					// Internal edge
					var idx:int= (bestPoly.neis[j] - 1);
					var ref:Number= m_nav.getPolyRefBase(bestTile) | idx;
					if (filter.passFilter(ref, bestTile, bestTile.data.polys[idx]))
						continue;
				}

				// Calc distance to the edge.
				var vj:int= bestPoly.verts[j] * 3;
				var vi:int= bestPoly.verts[i] * 3;
				var distseg:Tupple2 = DetourCommon.distancePtSegSqr2D2(centerPos, bestTile.data.verts, vj, vi);
				var distSqr:Number= distseg.first as Number;
				var tseg:Number= distseg.second as Number;

				// Edge is too far, skip.
				if (distSqr > radiusSqr)
					continue;

				// Hit wall, update radius.
				radiusSqr = distSqr;
				// Calculate hit pos.
				hitPos[0] = bestTile.data.verts[vj] + (bestTile.data.verts[vi] - bestTile.data.verts[vj]) * tseg;
				hitPos[1] = bestTile.data.verts[vj + 1] + (bestTile.data.verts[vi + 1] - bestTile.data.verts[vj + 1]) * tseg;
				hitPos[2] = bestTile.data.verts[vj + 2] + (bestTile.data.verts[vi + 2] - bestTile.data.verts[vj + 2]) * tseg;
			}

			for (i= bestPoly.firstLink; i != NavMesh.DT_NULL_LINK; i = bestTile.links[i].next) {
				link= bestTile.links[i];
				var neighbourRef:Number= link.ref;
				// Skip invalid neighbours and do not follow back to parent.
				if (neighbourRef == 0|| neighbourRef == parentRef)
					continue;

				// Expand to neighbour.
				tileAndPoly = m_nav.getTileAndPolyByRefUnsafe(neighbourRef);
				var neighbourTile:MeshTile= tileAndPoly.first as MeshTile;
				var neighbourPoly:Poly= tileAndPoly.second as Poly;

				// Skip off-mesh connections.
				if (neighbourPoly.getType() == Poly.DT_POLYTYPE_OFFMESH_CONNECTION)
					continue;

				// Calc distance to the edge.
				var va:int= bestPoly.verts[link.edge] * 3;
				var vb:int= bestPoly.verts[(link.edge + 1) % bestPoly.vertCount] * 3;
				distseg = DetourCommon.distancePtSegSqr2D2(centerPos, bestTile.data.verts, va, vb);
				distSqr= distseg.first as Number;
				// If the circle is not touching the next polygon, skip it.
				if (distSqr > radiusSqr)
					continue;

				if (!filter.passFilter(neighbourRef, neighbourTile, neighbourPoly))
					continue;

				var neighbourNode:Node= m_nodePool.getNode(neighbourRef);

				if ((neighbourNode.flags & Node.DT_NODE_CLOSED) != 0)
					continue;

				// Cost
				if (neighbourNode.flags == 0) {
					neighbourNode.pos = getEdgeMidPoint2(bestRef, bestPoly, bestTile, neighbourRef, neighbourPoly,
							neighbourTile);
				}

				var total:Number= bestNode.total + DetourCommon.vDist(bestNode.pos, neighbourNode.pos);

				// The node is already in open list and the new result is worse, skip.
				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0&& total >= neighbourNode.total)
					continue;

				neighbourNode.id = neighbourRef;
				neighbourNode.flags = (neighbourNode.flags & ~Node.DT_NODE_CLOSED);
				neighbourNode.pidx = m_nodePool.getNodeIdx(bestNode);
				neighbourNode.total = total;

				if ((neighbourNode.flags & Node.DT_NODE_OPEN) != 0) {
					m_openList.modify(neighbourNode);
				} else {
					neighbourNode.flags |= Node.DT_NODE_OPEN;
					m_openList.push(neighbourNode);
				}
			}
		}

		// Calc hit normal.
		var hitNormal:Array= DetourCommon.vSub2(centerPos, hitPos);
		DetourCommon.vNormalize(hitNormal);

		return new FindDistanceToWallResult((Math.sqrt(radiusSqr)), hitPos, hitNormal);
	}
	
	/// Returns true if the polygon reference is valid and passes the filter restrictions.
	///  @param[in]		ref			The polygon reference to check.
	///  @param[in]		filter		The filter to apply.
	public function isValidPolyRef(ref:Number, filter:QueryFilter):Boolean {
		try {
			var tileAndPoly:Tupple2 = m_nav.getTileAndPolyByRef(ref);
			// If cannot pass filter, assume flags has changed and boundary is invalid.
			if (filter.passFilter(ref, tileAndPoly.first as MeshTile, tileAndPoly.second as Poly))
				return true;
		} catch (e:Error) {
			// If cannot get polygon, assume it does not exists and boundary is invalid.
		}
		return false;
	}

	/// Gets the navigation mesh the query object is using.
	/// @return The navigation mesh the query object is using.
	public function getAttachedNavMesh():NavMesh {
		return m_nav;
	}
	
	/*
	/// @par
	///
	/// The closed list is the list of polygons that were fully evaluated during 
	/// the last navigation graph search. (A* or Dijkstra)
	/// 
	/// Returns true if the polygon reference is in the closed list. 
	///  @param[in]		ref		The reference id of the polygon to check.
	/// @returns True if the polygon is in closed list.
	public boolean isInClosedList(long ref)
	{
		if (m_nodePool == null) return false;
		
		Node nodes[DT_MAX_STATES_PER_NODE];
		int n= m_nodePool->findNodes(ref, nodes, DT_MAX_STATES_PER_NODE);
	
		for (int i=0; i<n; i++)
		{
			if (nodes[i]->flags & DT_NODE_CLOSED)
				return true;
		}		
	
		return false;
	}
	
	
	*/
}
}


	 
	

	
 class PortalResult {
	 public var left:Array;
	public 	var right:Array;
	public 	var fromType:int;
	public 	var toType:int;

		public function PortalResult(left:Array, right:Array, fromType:int, toType:int) {
			this.left = left;
			this.right = right;
			this.fromType = fromType;
			this.toType = toType;
		}

	}


	 class SegInterval {
		public var ref:Number;
		public var tmin:int, tmax:int;

		public function SegInterval(ref:Number, tmin:int, tmax:int) {
			this.ref = ref;
			this.tmin = tmin;
			this.tmax = tmax;
		}

	}

	


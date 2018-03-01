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

public class NavMesh {

	public var DT_SALT_BITS:int= 16;
	public var DT_TILE_BITS:int= 28;
	public var DT_POLY_BITS:int= 20;

	/** The maximum number of vertices per navigation polygon. */
	public static const DT_VERTS_PER_POLYGON:int= 6;

	/// A flag that indicates that an entity links to an external entity.
	/// (E.g. A polygon edge is a portal that links to another polygon.)
	public static const DT_EXT_LINK:int= 0x8000;

	/// A value that indicates the entity does not link to anything.
	public static const DT_NULL_LINK:int= 0xffffffff;

	/// A flag that indicates that an off-mesh connection can be traversed in both directions. (Is bidirectional.)
	public static const DT_OFFMESH_CON_BIDIR:int= 1;

	/// The maximum number of user defined area ids.
	public static const DT_MAX_AREAS:int= 64;

	/// Limit raycasting during any angle pahfinding
	/// The limit is given as a multiple of the character radius
	public static const DT_RAY_CAST_LIMIT_PROPORTIONS:Number= 50.0;

	public var m_params:NavMeshParams; /// < Current initialization params. TODO: do not store this info twice.
	private var m_orig:Array; /// < Origin of the tile (0,0)
	// float m_orig[3]; ///< Origin of the tile (0,0)
	public var m_tileWidth:Number, m_tileHeight:Number; /// < Dimensions of each tile.
	public var m_maxTiles:int; /// < Max number of tiles.
	public var m_tileLutSize:int; /// < Tile hash lookup size (must be pot).
	public var m_tileLutMask:int; /// < Tile hash lookup mask.

	// MeshTile** m_posLookup; ///< Tile hash lookup.
	// MeshTile[] m_nextFree; ///< Freelist of tiles.
	public var m_posLookup:Array; /// < Tile hash lookup.
	public var m_nextFree:MeshTile; /// < Freelist of tiles.
	public var m_tiles:Array; /// < List of tiles.

	/**
	 *  The maximum number of tiles supported by the navigation mesh.
	 * @return The maximum number of tiles supported by the navigation mesh.
	 */
	public function getMaxTiles():int {
		return m_maxTiles;
	}

	/**
	 * Returns tile in the tile array. 
	 */
	public function getTile(i:int):MeshTile {
		return m_tiles[i];
	}

	/**
	 * Gets the polygon reference for the tile's base polygon.
	 * @param tile The tile.
	 * @return The polygon reference for the base polygon in the specified tile.
	 */
	public function getPolyRefBase(tile:MeshTile):Number {
		if (tile == null)
			return 0;
		var it:int= tile.index;
		return encodePolyId(tile.salt, it, 0);
	}

	/**
	 * Derives a standard polygon reference.
	 * @note This function is generally meant for internal use only.
	 * @param salt The tile's salt value.
	 * @param it The index of the tile.
	 * @param ip The index of the polygon within the tile.
	 * @return encoded polygon reference
	 */
	public function encodePolyId(salt:int, it:int, ip:int):Number {
		return ((salt) << (DT_POLY_BITS + DT_TILE_BITS)) | ((it )<< DT_POLY_BITS) | (ip);
	}

	/// Decodes a standard polygon reference.
	/// @note This function is generally meant for internal use only.
	/// @param[in] ref The polygon reference to decode.
	/// @param[out] salt The tile's salt value.
	/// @param[out] it The index of the tile.
	/// @param[out] ip The index of the polygon within the tile.
	/// @see #encodePolyId
	public function decodePolyId(ref:Number):Array {
		var salt:int;
		var it:int;
		var ip:int;
		var saltMask:Number= (1<< DT_SALT_BITS) - 1;
		var tileMask:Number= (1<< DT_TILE_BITS) - 1;
		var polyMask:Number= (1<< DT_POLY_BITS) - 1;
		//salt = int(((ref >> (DT_POLY_BITS + DT_TILE_BITS)) & saltMask));
		//it = int(((ref >> DT_POLY_BITS) & tileMask));
		salt = int(ref >>(DT_POLY_BITS + DT_TILE_BITS)) & saltMask;
		it = int(ref >>(DT_POLY_BITS)) & tileMask;
		ip = ref & polyMask;
		return [ salt, it, ip ];
	}

	/// Extracts a tile's salt value from the specified polygon reference.
	/// @note This function is generally meant for internal use only.
	/// @param[in] ref The polygon reference.
	/// @see #encodePolyId
	public function decodePolyIdSalt(ref:Number):int {
		var saltMask:Number= (1<< DT_SALT_BITS) - 1;
		return int(ref >>(DT_POLY_BITS + DT_TILE_BITS)) & saltMask;
	}

	/// Extracts the tile's index from the specified polygon reference.
	/// @note This function is generally meant for internal use only.
	/// @param[in] ref The polygon reference.
	/// @see #encodePolyId
	public function decodePolyIdTile(ref:Number):int {
		var tileMask:Number= (1<< DT_TILE_BITS) - 1;
		return int(ref >>(DT_POLY_BITS)) & tileMask;
	}

	/// Extracts the polygon's index (within its tile) from the specified polygon reference.
	/// @note This function is generally meant for internal use only.
	/// @param[in] ref The polygon reference.
	/// @see #encodePolyId
	public function decodePolyIdPoly(ref:Number):int {
		var polyMask:Number= (1<< DT_POLY_BITS) - 1;
		return ref & polyMask;
	}

	public function allocLink(tile:MeshTile):int {
		var link:Link= new Link();
		link.next = DT_NULL_LINK;
		tile.links.push(link);
		return tile.links.length - 1;
	}

	/**
	 * Calculates the tile grid location for the specified world position.
	 * @param	pos  The world position for the query. [(x, y, z)]
	 * @return  2-element int array with (tx,ty) tile location  
	 */
	public function calcTileLoc(pos:Array):Array {
		var tx:int= int(Math.floor((pos[0] - m_orig[0]) / m_tileWidth));
		var ty:int= int(Math.floor((pos[2] - m_orig[2]) / m_tileHeight));
		return [ tx, ty ];
	}

	public function getTileAndPolyByRef(ref:Number):Tupple2 {
		if (ref == 0) {
			throw "ref = 0";
		}
		var saltitip:Array= decodePolyId(ref);
		var salt:int= saltitip[0];
		var it:int= saltitip[1];
		var ip:int= saltitip[2];
		if (it >= m_maxTiles)
			throw "tile > m_maxTiles";
		if (m_tiles[it].salt != salt || m_tiles[it].data.header == null)
			throw "Invalid salt or header";
		if (ip >= m_tiles[it].data.header.polyCount)
			throw "poly > polyCount";
		return new Tupple2(m_tiles[it], m_tiles[it].data.polys[ip]);
	}

	/// @par
	///
	/// @warning Only use this function if it is known that the provided polygon
	/// reference is valid. This function is faster than #getTileAndPolyByRef, but
	/// it does not validate the reference.
	public function  getTileAndPolyByRefUnsafe(ref:Number):Tupple2 {
		var saltitip:Array= decodePolyId(ref);
		var it:int= saltitip[1];
		var ip:int= saltitip[2];
		return new Tupple2(m_tiles[it], m_tiles[it].data.polys[ip]);
	}

	public function isValidPolyRef(ref:Number):Boolean {
		if (ref == 0)
			return false;
		var saltitip:Array= decodePolyId(ref);
		var salt:int= saltitip[0];
		var it:int= saltitip[1];
		var ip:int= saltitip[2];
		if (it >= m_maxTiles)
			return false;
		if (m_tiles[it].salt != salt || m_tiles[it].data.header == null)
			return false;
		if (ip >= m_tiles[it].data.header.polyCount)
			return false;
		return true;
	}

	public function init(params:NavMeshParams):void {
		this.m_params = params;
		m_orig = params.orig;
		m_tileWidth = params.tileWidth;
		m_tileHeight = params.tileHeight;
		// Init tiles
		m_maxTiles = params.maxTiles;
		m_tileLutSize = DetourCommon.nextPow2(params.maxTiles / 4);
		if (m_tileLutSize == 0)
			m_tileLutSize = 1;
		m_tileLutMask = m_tileLutSize - 1;
		m_tiles = [];//new MeshTile[m_maxTiles];
		m_posLookup = [];//new MeshTile[m_tileLutSize];
		m_nextFree = null;
		for (var i:int= m_maxTiles - 1; i >= 0; --i) {
			m_tiles[i] = new MeshTile(i);
			m_tiles[i].salt = 1;
			m_tiles[i].next = m_nextFree;
			m_nextFree = m_tiles[i];
		}

		DT_TILE_BITS = DetourCommon.ilog2(DetourCommon.nextPow2(params.maxTiles));
		DT_POLY_BITS= DetourCommon.ilog2(DetourCommon.nextPow2(params.maxPolys));
		DT_SALT_BITS = Math.min(31, 32- DT_TILE_BITS - DT_POLY_BITS);
	}

	public function init2(data:MeshData, flags:int):void {
		init(getNavMeshParams(data));
		addTile(data, flags, 0);
	}

	private static function getNavMeshParams(data:MeshData):NavMeshParams {
		var params:NavMeshParams= new NavMeshParams();
		params.orig = data.header.bmin;
		params.tileWidth = data.header.bmax[0] - data.header.bmin[0];
		params.tileHeight = data.header.bmax[2] - data.header.bmin[2];
		params.maxTiles = 1;
		params.maxPolys = data.header.polyCount;
		return params;
	}

	// TODO: These methods are duplicates from dtNavMeshQuery, but are needed for off-mesh connection finding.

	public function queryPolygonsInTile(tile:MeshTile, qmin:Array, qmax:Array):Array {
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
			var base:Number= getPolyRefBase(tile);
			var end:int= tile.data.header.bvNodeCount;
			while (nodeIndex < end) {
				var node:BVNode= tile.data.bvTree[nodeIndex];
				var overlap:Boolean= DetourCommon.overlapQuantBounds(bmin, bmax, node.bmin, node.bmax);
				var isLeafNode:Boolean= node.i >= 0;

				if (isLeafNode && overlap) {
					polys.push(base | node.i);
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
			bmin= [];
			bmax= [];
			base= getPolyRefBase(tile);
			for (var i:int= 0; i < tile.data.header.polyCount; ++i) {
				var p:Poly= tile.data.polys[i];
				// Do not return off-mesh connection polygons.
				if (p.getType() == Poly.DT_POLYTYPE_OFFMESH_CONNECTION)
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
					polys.push(base | i);
				}
			}
			return polys;
		}
	}

	/// Adds a tile to the navigation mesh.
	///  @param[in]		data		Data for the new tile mesh. (See: #dtCreateNavMeshData)
	///  @param[in]		dataSize	Data size of the new tile mesh.
	///  @param[in]		flags		Tile flags. (See: #dtTileFlags)
	///  @param[in]		lastRef		The desired reference for the tile. (When reloading a tile.) [opt] [Default: 0]
	///  @param[out]	result		The tile reference. (If the tile was succesfully added.) [opt]
	/// @return The status flags for the operation.
	/// @par
	///
	/// The add operation will fail if the data is in the wrong format, the allocated tile
	/// space is full, or there is a tile already at the specified reference.
	///
	/// The lastRef parameter is used to restore a tile with the same tile
	/// reference it had previously used. In this case the #dtPolyRef's for the
	/// tile will be restored to the same values they were before the tile was
	/// removed.
	///
	/// @see dtCreateNavMeshData, #removeTile
	public function addTile(data:MeshData, flags:int, lastRef:Number):Number {
		// Make sure the data is in right format.
		var header:MeshHeader= data.header;

		// Make sure the location is free.
		if (getTileAt(header.x, header.y, header.layer) != null)
			throw ("Tile already exists");

		// Allocate a tile.
		var tile:MeshTile= null;
		if (lastRef == 0) {
			if (m_nextFree != null) {
				tile = m_nextFree;
				m_nextFree = tile.next;
				tile.next = null;
			}
		} else {
			// Try to relocate the tile to specific index with same salt.
			var tileIndex:int= decodePolyIdTile(lastRef);
			if (tileIndex >= m_maxTiles)
				throw ("Tile index too high");
			// Try to find the specific tile id from the free list.
			var target:MeshTile= m_tiles[tileIndex];
			var prev:MeshTile= null;
			tile = m_nextFree;
			while (tile != null && tile != target) {
				prev = tile;
				tile = tile.next;
			}
			// Could not find the correct location.
			if (tile != target)
				throw ("Could not find tile");
			// Remove from freelist
			if (prev == null)
				m_nextFree = tile.next;
			else
				prev.next = tile.next;

			// Restore salt.
			tile.salt = decodePolyIdSalt(lastRef);
		}

		// Make sure we could allocate a tile.
		if (tile == null)
			throw ("Could not allocate a tile");

		tile.data = data;
		tile.flags = flags;
		if(data.links){
			tile.links = data.links;
		}
		
		// Insert tile into the position lut.
		var h:Number= computeTileHash(header.x, header.y, m_tileLutMask);
		tile.next = m_posLookup[h];
		m_posLookup[h] = tile;

		// Patch header pointers.

		// If there are no items in the bvtree, reset the tree pointer.
		if (tile.data.bvTree != null && tile.data.bvTree.length == 0)
			tile.data.bvTree = null;

		// Init tile.
		
		connectIntLinks(tile);
		baseOffMeshLinks(tile);

		// Connect with layers in current tile.
		var neis:Array = getTilesAt(header.x, header.y);
		for (var j:int= 0; j < neis.length; ++j) {
			if (neis[j] != tile) {
				connectExtLinks(tile, neis[j], -1);
				connectExtLinks(neis[j], tile, -1);
			}
			connectExtOffMeshLinks(tile, neis[j], -1);
			connectExtOffMeshLinks(neis[j], tile, -1);
		}

		// Connect with neighbour tiles.
		for (var i:int= 0; i < 8; ++i) {
			neis = getNeighbourTilesAt(header.x, header.y, i);
			for (j= 0; j < neis.length; ++j) {
				connectExtLinks(tile, neis[j], i);
				connectExtLinks(neis[j], tile, DetourCommon.oppositeTile(i));
				connectExtOffMeshLinks(tile, neis[j], i);
				connectExtOffMeshLinks(neis[j], tile, DetourCommon.oppositeTile(i));
			}
		}

		return getTileRef(tile);
	}

	// FIXME: Implement
	/// Removes the specified tile from the navigation mesh.
	///  @param[in]		ref			The reference of the tile to remove.
	///  @param[out]	data		Data associated with deleted tile.
	///  @param[out]	dataSize	Size of the data associated with deleted tile.
	/// @return The status flags for the operation.
	//dtStatus removeTile(dtTileRef ref, unsigned char** data, int* dataSize);
	
	/// Builds internal polygons links for a tile.
	public function connectIntLinks(tile:MeshTile):void {
		if (tile == null)
			return;

		var base:Number= getPolyRefBase(tile);

		for (var i:int= 0; i < tile.data.header.polyCount; ++i) {
			var poly:Poly= tile.data.polys[i];
			poly.firstLink = DT_NULL_LINK;

			if (poly.getType() == Poly.DT_POLYTYPE_OFFMESH_CONNECTION)
				continue;

			// Build edge links backwards so that the links will be
			// in the linked list from lowest index to highest.
			for (var j:int= poly.vertCount - 1; j >= 0; --j) {
				// Skip hard and non-internal edges.
				if (poly.neis[j] == 0|| (poly.neis[j] & DT_EXT_LINK) != 0)
					continue;

				var idx:int= allocLink(tile);
				var link:Link= tile.links[idx];
				link.ref = base | (poly.neis[j] - 1);
				link.edge = j;
				link.side = 0xff;
				link.bmin = link.bmax = 0;
				// Add to linked list.
				link.next = poly.firstLink;
				poly.firstLink = idx;
			}
		}
	}

	public function connectExtLinks(tile:MeshTile, target:MeshTile, side:int):void {
		if (tile == null)
			return;

		// Connect border links.
		for (var i:int= 0; i < tile.data.header.polyCount; ++i) {
			var poly:Poly= tile.data.polys[i];

			// Create new links.
			// unsigned short m = DT_EXT_LINK | (unsigned short)side;

			var nv:int= poly.vertCount;
			for (var j:int= 0; j < nv; ++j) {
				// Skip non-portal edges.
				if ((poly.neis[j] & DT_EXT_LINK) == 0)
					continue;

				var dir:int= int((poly.neis[j] & 0xff));
				if (side != -1&& dir != side)
					continue;

				// Create new links
				var va:int= poly.verts[j] * 3;
				var vb:int= poly.verts[(j + 1) % nv] * 3;
				var connectedPolys:Tupple3 = findConnectingPolys(tile.data.verts, va, vb, target,
						DetourCommon.oppositeTile(dir), 4);
				var nei:Array= connectedPolys.first as Array;
				var neia:Array= connectedPolys.second as Array;
				var nnei:int= connectedPolys.third as int;
				for (var k:int= 0; k < nnei; ++k) {
					var idx:int= allocLink(tile);
					var link:Link= tile.links[idx];
					link.ref = nei[k];
					link.edge = j;
					link.side = dir;

					link.next = poly.firstLink;
					poly.firstLink = idx;

					// Compress portal limits to a byte value.
					if (dir == 0|| dir == 4) {
						var tmin:Number= (neia[k * 2+ 0] - tile.data.verts[va + 2])
								/ (tile.data.verts[vb + 2] - tile.data.verts[va + 2]);
						var tmax:Number= (neia[k * 2+ 1] - tile.data.verts[va + 2])
								/ (tile.data.verts[vb + 2] - tile.data.verts[va + 2]);
						if (tmin > tmax) {
							var temp:Number= tmin;
							tmin = tmax;
							tmax = temp;
						}
						link.bmin = int((DetourCommon.clamp(tmin, 0.0, 1.0) * 255.0));
						link.bmax = int((DetourCommon.clamp(tmax, 0.0, 1.0) * 255.0));
					} else if (dir == 2|| dir == 6) {
						tmin= (neia[k * 2+ 0] - tile.data.verts[va]) / (tile.data.verts[vb] - tile.data.verts[va]);
						tmax= (neia[k * 2+ 1] - tile.data.verts[va]) / (tile.data.verts[vb] - tile.data.verts[va]);
						if (tmin > tmax) {
							temp= tmin;
							tmin = tmax;
							tmax = temp;
						}
						link.bmin = int((DetourCommon.clamp(tmin, 0.0, 1.0) * 255.0));
						link.bmax = int((DetourCommon.clamp(tmax, 0.0, 1.0) * 255.0));
					}
				}
			}
		}
	}

	public function connectExtOffMeshLinks(tile:MeshTile, target:MeshTile, side:int):void {
		if (tile == null)
			return;

		// Connect off-mesh links.
		// We are interested on links which land from target tile to this tile.
		var oppositeSide:int= (side == -1) ? 0xff: DetourCommon.oppositeTile(side);

		for (var i:int= 0; i < target.data.header.offMeshConCount; ++i) {
			var targetCon:OffMeshConnection= target.data.offMeshCons[i];
			if (targetCon.side != oppositeSide)
				continue;

			var targetPoly:Poly= target.data.polys[targetCon.poly];
			// Skip off-mesh connections which start location could not be connected at all.
			if (targetPoly.firstLink == DT_NULL_LINK)
				continue;

			var ext:Array= [ targetCon.rad, target.data.header.walkableClimb, targetCon.rad ];

			// Find polygon to connect to.
			var p:Array= [];
			p[0] = targetCon.pos[3];
			p[1] = targetCon.pos[4];
			p[2] = targetCon.pos[5];
			var nearest:Tupple2 = findNearestPolyInTile(tile, p, ext);
			var ref:Number= nearest.first as Number;
			if (ref == 0)
				continue;
			var nearestPt:Array= nearest.second as Array;
			// findNearestPoly may return too optimistic results, further check to make sure.

			if (DetourCommon.sqr(nearestPt[0] - p[0]) + DetourCommon.sqr(nearestPt[2] - p[2]) > DetourCommon.sqr(targetCon.rad))
				continue;
			// Make sure the location is on current mesh.
			target.data.verts[targetPoly.verts[1] * 3] = nearestPt[0];
			target.data.verts[targetPoly.verts[1] * 3+ 1] = nearestPt[1];
			target.data.verts[targetPoly.verts[1] * 3+ 2] = nearestPt[2];

			// Link off-mesh connection to target poly.
			var idx:int= allocLink(target);
			var link:Link= target.links[idx];
			link.ref = ref;
			link.edge = 1;
			link.side = oppositeSide;
			link.bmin = link.bmax = 0;
			// Add to linked list.
			link.next = targetPoly.firstLink;
			targetPoly.firstLink = idx;

			// Link target poly to off-mesh connection.
			if ((targetCon.flags & DT_OFFMESH_CON_BIDIR) != 0) {
				var tidx:int= allocLink(tile);
				var landPolyIdx:int= decodePolyIdPoly(ref);
				var landPoly:Poly= tile.data.polys[landPolyIdx];
				link = tile.links[tidx];
				link.ref = getPolyRefBase(target) | targetCon.poly;
				link.edge = 0xff;
				link.side = (side == -1? 0xff: side);
				link.bmin = link.bmax = 0;
				// Add to linked list.
				link.next = landPoly.firstLink;
				landPoly.firstLink = tidx;
			}
		}
	}

	public function  findConnectingPolys(verts:Array, va:int, vb:int, tile:MeshTile, side:int,
			maxcon:int):Tupple3 {
		if (tile == null)
			return new Tupple3(null, null, 0);
		var con:Array = [];
		var conarea:Array= []//new float[maxcon * 2];
		var amin:Array= []//new float[2];
		var amax:Array= []//new float[2];
		calcSlabEndPoints(verts, va, vb, amin, amax, side);
		var apos:Number= getSlabCoord(verts, va, side);

		// Remove links pointing to 'side' and compact the links array.
		var bmin:Array= []//new float[2];
		var bmax:Array= []//new float[2];
		var m:int= DT_EXT_LINK | side;
		var n:int= 0;
		var base:Number= getPolyRefBase(tile);

		for (var i:int= 0; i < tile.data.header.polyCount; ++i) {
			var poly:Poly= tile.data.polys[i];
			var nv:int= poly.vertCount;
			for (var j:int= 0; j < nv; ++j) {
				// Skip edges which do not point to the right side.
				if (poly.neis[j] != m)
					continue;
				var vc:int= poly.verts[j] * 3;
				var vd:int= poly.verts[(j + 1) % nv] * 3;
				var bpos:Number= getSlabCoord(tile.data.verts, vc, side);
				// Segments are not close enough.
				if (Math.abs(apos - bpos) > 0.01)
					continue;

				// Check if the segments touch.
				calcSlabEndPoints(tile.data.verts, vc, vd, bmin, bmax, side);

				if (!overlapSlabs(amin, amax, bmin, bmax, 0.01, tile.data.header.walkableClimb))
					continue;

				// Add return value.
				if (n < maxcon) {
					conarea[n * 2+ 0] = Math.max(amin[0], bmin[0]);
					conarea[n * 2+ 1] = Math.min(amax[0], bmax[0]);
					con[n] = base | i;
					n++;
				}
				break;
			}
		}
		return new Tupple3(con, conarea, n);
	}

	public static function getSlabCoord(verts:Array, va:int, side:int):Number {
		if (side == 0|| side == 4)
			return verts[va];
		else if (side == 2|| side == 6)
			return verts[va + 2];
		return 0;
	}

	public static function calcSlabEndPoints(verts:Array, va:int, vb:int, bmin:Array, bmax:Array, side:int):void {
		if (side == 0|| side == 4) {
			if (verts[va + 2] < verts[vb + 2]) {
				bmin[0] = verts[va + 2];
				bmin[1] = verts[va + 1];
				bmax[0] = verts[vb + 2];
				bmax[1] = verts[vb + 1];
			} else {
				bmin[0] = verts[vb + 2];
				bmin[1] = verts[vb + 1];
				bmax[0] = verts[va + 2];
				bmax[1] = verts[va + 1];
			}
		} else if (side == 2|| side == 6) {
			if (verts[va + 0] < verts[vb + 0]) {
				bmin[0] = verts[va + 0];
				bmin[1] = verts[va + 1];
				bmax[0] = verts[vb + 0];
				bmax[1] = verts[vb + 1];
			} else {
				bmin[0] = verts[vb + 0];
				bmin[1] = verts[vb + 1];
				bmax[0] = verts[va + 0];
				bmax[1] = verts[va + 1];
			}
		}
	}

	public function overlapSlabs(amin:Array, amax:Array, bmin:Array, bmax:Array, px:Number, py:Number):Boolean {
		// Check for horizontal overlap.
		// The segment is shrunken a little so that slabs which touch
		// at end points are not connected.
		var minx:Number= Math.max(amin[0] + px, bmin[0] + px);
		var maxx:Number= Math.min(amax[0] - px, bmax[0] - px);
		if (minx > maxx)
			return false;

		// Check vertical overlap.
		var ad:Number= (amax[1] - amin[1]) / (amax[0] - amin[0]);
		var ak:Number= amin[1] - ad * amin[0];
		var bd:Number= (bmax[1] - bmin[1]) / (bmax[0] - bmin[0]);
		var bk:Number= bmin[1] - bd * bmin[0];
		var aminy:Number= ad * minx + ak;
		var amaxy:Number= ad * maxx + ak;
		var bminy:Number= bd * minx + bk;
		var bmaxy:Number= bd * maxx + bk;
		var dmin:Number= bminy - aminy;
		var dmax:Number= bmaxy - amaxy;

		// Crossing segments always overlap.
		if (dmin * dmax < 0)
			return true;

		// Check for overlap at endpoints.
		var thr:Number= (py * 2) * (py * 2);
		if (dmin * dmin <= thr || dmax * dmax <= thr)
			return true;

		return false;
	}

	/**
	 * Builds internal polygons links for a tile.
	 * @param tile
	 */
	public function baseOffMeshLinks(tile:MeshTile):void {
		if (tile == null)
			return;

		var base:Number= getPolyRefBase(tile);

		// Base off-mesh connection start points.
		for (var i:int= 0; i < tile.data.header.offMeshConCount; ++i) {
			var con:OffMeshConnection= tile.data.offMeshCons[i];
			var poly:Poly= tile.data.polys[con.poly];

			var ext:Array= [ con.rad, tile.data.header.walkableClimb, con.rad ];

			// Find polygon to connect to.
			var nearestPoly:Tupple2 = findNearestPolyInTile(tile, con.pos, ext);
			var ref:Number= nearestPoly.first as Number;
			if (ref == 0)
				continue;
			var p:Array= con.pos; // First vertex
			var nearestPt:Array= nearestPoly.second as Array;
			// findNearestPoly may return too optimistic results, further check to make sure.
			var dx:Number= nearestPt[0] - p[0];
			var dz:Number= nearestPt[2] - p[2];
			var dr:Number= con.rad;
			if (dx * dx + dz * dz > dr * dr)
				continue;
			// Make sure the location is on current mesh.
			System.arraycopy2(nearestPoly, 0, tile.data.verts, poly.verts[0] * 3, 3);

			// Link off-mesh connection to target poly.
			var idx:int= allocLink(tile);
			var link:Link= tile.links[idx];
			link.ref = ref;
			link.edge = 0;
			link.side = 0xff;
			link.bmin = link.bmax = 0;
			// Add to linked list.
			link.next = poly.firstLink;
			poly.firstLink = idx;

			// Start end-point is always connect back to off-mesh connection.
			var tidx:int= allocLink(tile);
			var landPolyIdx:int= decodePolyIdPoly(ref);
			var landPoly:Poly= tile.data.polys[landPolyIdx];
			link = tile.links[tidx];
			link.ref = base | con.poly;
			link.edge = 0xff;
			link.side = 0xff;
			link.bmin = link.bmax = 0;
			// Add to linked list.
			link.next = landPoly.firstLink;
			landPoly.firstLink = tidx;
		}
	}

	/**
	 * Returns closest point on polygon.
	 * @param ref
	 * @param pos
	 * @return
	 */
	public function closestPointOnPoly(ref:Number, pos:Array):Tupple2 {
		var tileAndPoly:Tupple2 = getTileAndPolyByRefUnsafe(ref);
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
			return new Tupple2(false, closest);
		}

		// Clamp point to be inside the polygon.
		var verts:Array= []//new float[DT_VERTS_PER_POLYGON * 3];
		var edged:Array= []//new float[DT_VERTS_PER_POLYGON];
		var edget:Array= []//new float[DT_VERTS_PER_POLYGON];
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
			var va:int= imin * 3;
			var vb:int= ((imin + 1) % nv) * 3;
			closest = DetourCommon.vLerp2(verts, va, vb, edget[imin]);
			posOverPoly = false;
		} else {
			posOverPoly = true;
		}

		// Find height at the location.
		var ip:int= poly.index;
		if (tile.data.detailMeshes != null && tile.data.detailMeshes.length > ip) {
			var pd:PolyDetail= tile.data.detailMeshes[ip];
			var posV:VectorPtr= new VectorPtr(pos);
			for (var j:int= 0; j < pd.triCount; ++j) {
				var t:int= (pd.triBase + j) * 4;
				var v:Array = [];// new VectorPtr[3];
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
		return new Tupple2(posOverPoly, closest);
	}

	public function findNearestPolyInTile(tile:MeshTile, center:Array, extents:Array):Tupple2 {
		var nearestPt:Array= null;
		var bmin:Array= DetourCommon.vSub2(center, extents);
		var bmax:Array= DetourCommon.vAdd2(center, extents);

		// Get nearby polygons from proximity grid.
		var polys:Array = queryPolygonsInTile(tile, bmin, bmax);

		// Find nearest polygon amongst the nearby polygons.
		var nearest:Number= 0;
		var nearestDistanceSqr:Number= Number.MAX_VALUE;
		for (var i:int= 0; i < polys.length; ++i) {
			var ref:Number= polys[i];
			var d:Number;
			var cpp:Tupple2 = closestPointOnPoly(ref, center);
			var posOverPoly:Boolean= cpp.first as Boolean;
			var closestPtPoly:Array= cpp.second as Array;

			// If a point is directly over a polygon and closer than
			// climb height, favor that instead of straight line nearest point.
			var diff:Array= DetourCommon.vSub2(center, closestPtPoly);
			if (posOverPoly) {
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
		return new Tupple2(nearest, nearestPt);
	}

	public function getTileAt(x:int, y:int, layer:int):MeshTile {
		// Find tile based on hash.
		var h:Number= computeTileHash(x, y, m_tileLutMask);
		var tile:MeshTile= m_posLookup[h];
		while (tile != null) {
			if (tile.data.header != null && tile.data.header.x == x && tile.data.header.y == y && tile.data.header.layer == layer) {
				return tile;
			}
			tile = tile.next;
		}
		return null;
	}

	public function getNeighbourTilesAt(x:int, y:int, side:int):Array {
		var nx:int= x, ny:int = y;
		switch (side) {
		case 0:
			nx++;
			break;
		case 1:
			nx++;
			ny++;
			break;
		case 2:
			ny++;
			break;
		case 3:
			nx--;
			ny++;
			break;
		case 4:
			nx--;
			break;
		case 5:
			nx--;
			ny--;
			break;
		case 6:
			ny--;
			break;
		case 7:
			nx++;
			ny--;
			break;
		}
		return getTilesAt(nx, ny);
	}

	public function getTilesAt(x:int, y:int):Array {
		var tiles:Array = [];
		// Find tile based on hash.
		var h:Number= computeTileHash(x, y, m_tileLutMask);
		var tile:MeshTile= m_posLookup[h];
		while (tile != null) {
			if (tile.data.header != null && tile.data.header.x == x && tile.data.header.y == y) {
				tiles.push(tile);
			}
			tile = tile.next;
		}
		return tiles;
	}

	public function getTileByRef(ref:Number):MeshTile {
		if (ref == 0)
			return null;
		var tileIndex:int= decodePolyIdTile(ref);
		var tileSalt:int= decodePolyIdSalt(ref);
		if (int(tileIndex )>= m_maxTiles)
			return null;
		var tile:MeshTile= m_tiles[tileIndex];
		if (tile.salt != tileSalt)
			return null;
		return tile;
	}

	public function getTileRef(tile:MeshTile):Number {
		if (tile == null)
			return 0;
		var it:int= tile.index;
		return encodePolyId(tile.salt, it, 0);
	}

	public static function computeTileHash(x:int, y:int, mask:int):Number {
		var h1:uint= 0x8da6b343; // Large multiplicative constants;
		var h2:uint= 0xd8163841; // here arbitrarily chosen primes
		var n:Number= h1 * x + h2 * y;
		return ((n & mask));
	}

	/// @par
	///
	/// Off-mesh connections are stored in the navigation mesh as special 2-vertex 
	/// polygons with a single edge. At least one of the vertices is expected to be 
	/// inside a normal polygon. So an off-mesh connection is "entered" from a 
	/// normal polygon at one of its endpoints. This is the polygon identified by 
	/// the prevRef parameter.
	public function getOffMeshConnectionPolyEndPoints( prevRef:Number, polyRef:Number):Tupple2 {
		if (polyRef == 0)
			throw ("polyRef = 0");

		// Get current polygon
		var saltitip:Array= decodePolyId(polyRef);
		var salt:int= saltitip[0];
		var it:int= saltitip[1];
		var ip:int= saltitip[2];
		if (it >= m_maxTiles) {
			throw ("Invalid tile ID > max tiles");
		}
		if (m_tiles[it].salt != salt || m_tiles[it].data.header == null) {
			throw ("Invalid salt or missing tile header");
		}
		var tile:MeshTile= m_tiles[it];
		if (ip >= tile.data.header.polyCount) {
			throw ("Invalid poly ID > poly count");
		}
		var poly:Poly= tile.data.polys[ip];

		// Make sure that the current poly is indeed off-mesh link.
		if (poly.getType() != Poly.DT_POLYTYPE_OFFMESH_CONNECTION)
			throw ("Invalid poly type");

		// Figure out which way to hand out the vertices.
		var idx0:int= 0, idx1:int = 1;

		// Find link that points to first vertex.
		for (var i:int= poly.firstLink; i != DT_NULL_LINK; i = tile.links[i].next) {
			if (tile.links[i].edge == 0) {
				if (tile.links[i].ref != prevRef) {
					idx0 = 1;
					idx1 = 0;
				}
				break;
			}
		}
		var startPos:Array= []//new float[3];
		var endPos:Array= []//new float[3];
		DetourCommon.vCopy3(startPos, tile.data.verts, poly.verts[idx0] * 3);
		DetourCommon.vCopy3(endPos, tile.data.verts, poly.verts[idx1] * 3);
		return new Tupple2(startPos, endPos);

	}
	
}
}
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
public class MeshHeader {

	/// A magic number used to detect compatibility of navigation tile data.
	public static var DT_NAVMESH_MAGIC:int= 'D'.charCodeAt(0) << 24| 'N'.charCodeAt(0) << 16| 'A'.charCodeAt(0) << 8| 'V'.charCodeAt(0);

	/// A version number used to detect compatibility of navigation tile data.
	public static var DT_NAVMESH_VERSION:int= 7;

	/// A magic number used to detect the compatibility of navigation tile states.
	public static var DT_NAVMESH_STATE_MAGIC:int= 'D'.charCodeAt(0) << 24| 'N'.charCodeAt(0) << 16| 'M'.charCodeAt(0) << 8| 'S'.charCodeAt(0);

	/// A version number used to detect compatibility of navigation tile states.
	public static var DT_NAVMESH_STATE_VERSION:int= 1;
	
	/// Provides high level information related to a dtMeshTile object.
	/// @ingroup detour
	public var magic:int; /// < Tile magic number. (Used to identify the data format.)
	public var version:int; /// < Tile data format version number.
	public var x:int; /// < The x-position of the tile within the dtNavMesh tile grid. (x, y, layer)
	public var y:int; /// < The y-position of the tile within the dtNavMesh tile grid. (x, y, layer)
	public var layer:int; /// < The layer of the tile within the dtNavMesh tile grid. (x, y, layer)
	public var userId:int; /// < The user defined id of the tile.
	public var polyCount:int; /// < The number of polygons in the tile.
	public var vertCount:int; /// < The number of vertices in the tile.
	public var maxLinkCount:int; /// < The number of allocated links.
	public var detailMeshCount:int; /// < The number of sub-meshes in the detail mesh.

	/// The number of unique vertices in the detail mesh. (In addition to the polygon vertices.)
	public var detailVertCount:int;

	public var detailTriCount:int; /// < The number of triangles in the detail mesh.
	public var bvNodeCount:int; /// < The number of bounding volume nodes. (Zero if bounding volumes are disabled.)
	public var offMeshConCount:int; /// < The number of off-mesh connections.
	public var offMeshBase:int; /// < The index of the first polygon which is an off-mesh connection.
	public var walkableHeight:Number; /// < The height of the agents using the tile.
	public var walkableRadius:Number; /// < The radius of the agents using the tile.
	public var walkableClimb:Number; /// < The maximum climb height of the agents using the tile.
	public var bmin:Array= []; /// < The minimum bounds of the tile's AABB. [(x, y, z)]
	public var bmax:Array= []; /// < The maximum bounds of the tile's AABB. [(x, y, z)]

	/// The bounding volume quantization factor.
	public var bvQuantFactor:Number;
}
}
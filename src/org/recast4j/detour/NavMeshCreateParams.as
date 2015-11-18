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
/// Represents the source data used to build an navigation mesh tile.
public class NavMeshCreateParams {

	/// @name Polygon Mesh Attributes
	/// Used to create the base navigation graph.
	/// See #rcPolyMesh for details related to these attributes.
	/// @{

	public var verts:Array;			///< The polygon mesh vertices. [(x, y, z) * #vertCount] [Unit: vx]
	public var vertCount:int;		///< The number vertices in the polygon mesh. [Limit: >= 3]
	public var polys:Array;			///< The polygon data. [Size: #polyCount * 2 * #nvp]
	public var polyFlags:Array;		///< The user defined flags assigned to each polygon. [Size: #polyCount]
	public var polyAreas:Array;		///< The user defined area ids assigned to each polygon. [Size: #polyCount]
	public var polyCount:int;		///< Number of polygons in the mesh. [Limit: >= 1]
	public var nvp:int;				///< Number maximum number of vertices per polygon. [Limit: >= 3]

	/// @}
	/// @name Height Detail Attributes (Optional)
	/// See #rcPolyMeshDetail for details related to these attributes.
	/// @{

	var detailMeshes:Array;			///< The height detail sub-mesh data. [Size: 4 * #polyCount]
	var detailVerts:Array;		///< The detail mesh vertices. [Size: 3 * #detailVertsCount] [Unit: wu]
	var detailVertsCount:int;		///< The number of vertices in the detail mesh.
	var detailTris:Array;			///< The detail mesh triangles. [Size: 4 * #detailTriCount]
	var detailTriCount:int;			///< The number of triangles in the detail mesh.

	/// @}
	/// @name Off-Mesh Connections Attributes (Optional)
	/// Used to define a custom point-to-point edge within the navigation graph, an 
	/// off-mesh connection is a user defined traversable connection made up to two vertices, 
	/// at least one of which resides within a navigation mesh polygon.
	/// @{

	/// Off-mesh connection vertices. [(ax, ay, az, bx, by, bz) * #offMeshConCount] [Unit: wu]
	var offMeshConVerts:Array;
	/// Off-mesh connection radii. [Size: #offMeshConCount] [Unit: wu]
	var offMeshConRad:Array;
	/// User defined flags assigned to the off-mesh connections. [Size: #offMeshConCount]
	var offMeshConFlags:Array;
	/// User defined area ids assigned to the off-mesh connections. [Size: #offMeshConCount]
	var offMeshConAreas:Array;
	/// The permitted travel direction of the off-mesh connections. [Size: #offMeshConCount]
	///
	/// 0 = Travel only from endpoint A to endpoint B.<br/>
	/// #DT_OFFMESH_CON_BIDIR = Bidirectional travel.
	var offMeshConDir:Array;	
	/// The user defined ids of the off-mesh connection. [Size: #offMeshConCount]
	var offMeshConUserID:Array;
	/// The number of off-mesh connections. [Limit: >= 0]
	var offMeshConCount:int;

	/// @}
	/// @name Tile Attributes
	/// @note The tile grid/layer data can be left at zero if the destination is a single tile mesh.
	/// @{

	var userId:int;	///< The user defined id of the tile.
	var tileX:int;				///< The tile's x-grid location within the multi-tile destination mesh. (Along the x-axis.)
	var tileY:int;				///< The tile's y-grid location within the multi-tile desitation mesh. (Along the z-axis.)
	var tileLayer:int;			///< The tile's layer within the layered destination mesh. [Limit: >= 0] (Along the y-axis.)
	var bmin:Array;			///< The minimum bounds of the tile. [(x, y, z)] [Unit: wu]
	var bmax:Array;			///< The maximum bounds of the tile. [(x, y, z)] [Unit: wu]

	/// @}
	/// @name General Configuration Attributes
	/// @{

	var walkableHeight:Number;	///< The agent height. [Unit: wu]
	var walkableRadius:Number;	///< The agent radius. [Unit: wu]
	var walkableClimb:Number;	///< The agent maximum traversable ledge. (Up/Down) [Unit: wu]
	var cs:Number;				///< The xz-plane cell size of the polygon mesh. [Limit: > 0] [Unit: wu]
	var ch:Number;				///< The y-axis cell height of the polygon mesh. [Limit: > 0] [Unit: wu]

	/// True if a bounding volume tree should be built for the tile.
	/// @note The BVTree is not normally needed for layered navigation meshes.
	var buildBvTree:Boolean;

	/// @}

}
}
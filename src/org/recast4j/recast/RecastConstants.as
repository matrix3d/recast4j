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
public class RecastConstants {

	public static const RC_NULL_AREA:int= 0;
	public static const RC_NOT_CONNECTED:int= 0x3;
	public static  const RC_WALKABLE_AREA:int= 63;
	/// Defines the number of bits allocated to rcSpan::smin and rcSpan::smax.
	public static var RC_SPAN_HEIGHT_BITS:int= 13;
	/// Defines the maximum value for rcSpan::smin and rcSpan::smax.
	public static var RC_SPAN_MAX_HEIGHT:int= (1<<RC_SPAN_HEIGHT_BITS)-1;	
	/// Heighfield border flag.
	/// If a heightfield region ID has this bit set, then the region is a border 
	/// region and its spans are considered unwalkable.
	/// (Used during the region and contour build process.)
	/// @see rcCompactSpan::reg
	public static var RC_BORDER_REG:int= 0x8000;
	/// Border vertex flag.
	/// If a region ID has this bit set, then the associated element lies on
	/// a tile border. If a contour vertex's region ID has this bit set, the 
	/// vertex will later be removed in order to match the segments and vertices 
	/// at tile boundaries.
	/// (Used during the build process.)
	/// @see rcCompactSpan::reg, #rcContour::verts, #rcContour::rverts
	public static var RC_BORDER_VERTEX:int= 0x10000;
	/// Area border flag.
	/// If a region ID has this bit set, then the associated element lies on
	/// the border of an area.
	/// (Used during the region and contour build process.)
	/// @see rcCompactSpan::reg, #rcContour::verts, #rcContour::rverts
	public static var RC_AREA_BORDER:int= 0x20000;
	/// Applied to the region id field of contour vertices in order to extract the region id.
	/// The region id field of a vertex may have several flags applied to it.  So the
	/// fields value can't be used directly.
	/// @see rcContour::verts, rcContour::rverts
	public static var RC_CONTOUR_REG_MASK:int= 0;
	/// An value which indicates an invalid index within a mesh.
	/// @note This does not necessarily indicate an error.
	/// @see rcPolyMesh::polys
	public static var RC_MESH_NULL_IDX:int= 0;
	
	public static var RC_CONTOUR_TESS_WALL_EDGES:int= 0x01;	///< Tessellate solid (impassable) edges during contour simplification.
	public static var RC_CONTOUR_TESS_AREA_EDGES:int= 0x02;	///< Tessellate edges between areas during contour simplification.
	

	
	public static const RC_LOG_WARNING:int= 1;

}
}
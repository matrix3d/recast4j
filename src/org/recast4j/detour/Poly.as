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
/** Defines a polyogn within a dtMeshTile object. */
public class Poly {

	var index:int;
	/** The polygon is a standard convex polygon that is part of the surface of the mesh. */
	public static const DT_POLYTYPE_GROUND:int= 0;
	/** The polygon is an off-mesh connection consisting of two vertices. */
	public static const DT_POLYTYPE_OFFMESH_CONNECTION:int= 1;
	/** Index to first link in linked list. (Or #DT_NULL_LINK if there is no link.) */
	public var firstLink:int;
	/** The indices of the polygon's vertices. The actual vertices are located in MeshTile::verts. */
	public var verts:Array= new int[NavMesh.DT_VERTS_PER_POLYGON];
	/** Packed data representing neighbor polygons references and flags for each edge. */
	public var neis:Array= new int[NavMesh.DT_VERTS_PER_POLYGON];
	/** The user defined polygon flags. */
	public var flags:int;
	/** The number of vertices in the polygon. */
	public var vertCount:int;
	/**
	 * The bit packed area id and polygon type.
	 * 
	 * @note Use the structure's set and get methods to access this value.
	 */
	public var areaAndtype:int;

	public function Poly(index:int) {
		this.index = index;
	}

	/** Sets the user defined area id. [Limit: < #DT_MAX_AREAS] */
	function setArea(a:int):void {
		areaAndtype = (areaAndtype & 0xc0) | (a & 0x3);
	}

	/** Sets the polygon type. (See: #dtPolyTypes.) */
	function setType(t:int):void {
		areaAndtype = (areaAndtype & 0x3) | (t << 6);
	}

	/** Gets the user defined area id. */
	function getArea():int {
		return areaAndtype & 0x3;
	}

	/** Gets the polygon type. (See: #dtPolyTypes) */
	function getType():int {
		return areaAndtype >> 6;
	}

};
}
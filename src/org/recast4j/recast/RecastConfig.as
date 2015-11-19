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
public class RecastConfig {
	/** The width of the field along the x-axis. [Limit: >= 0] [Units: vx] **/
	public var width:int;

	/** The height of the field along the z-axis. [Limit: >= 0] [Units: vx] **/
	public var height:int;

	/** The width/height size of tile's on the xz-plane. [Limit: >= 0] [Units: vx] **/
	public var tileSize:int;

	/** The size of the non-navigable border around the heightfield. [Limit: >=0] [Units: vx] **/
	public var borderSize:int;

	/** The xz-plane cell size to use for fields. [Limit: > 0] [Units: wu] **/
	public var cs:Number;

	/** The y-axis cell size to use for fields. [Limit: > 0] [Units: wu] **/
	public var ch:Number;

	/** The minimum bounds of the field's AABB. [(x, y, z)] [Units: wu] **/
	public var bmin:Array;

	/** The maximum bounds of the field's AABB. [(x, y, z)] [Units: wu] **/
	public var bmax:Array;

	/** The maximum slope that is considered walkable. [Limits: 0 <= value < 90] [Units: Degrees] **/
	public var walkableSlopeAngle:Number;

	/**
	 * Minimum floor to 'ceiling' height that will still allow the floor area to be considered walkable. [Limit: >= 3]
	 * [Units: vx]
	 **/
	public var walkableHeight:int;

	/** Maximum ledge height that is considered to still be traversable. [Limit: >=0] [Units: vx] **/
	public var walkableClimb:int;

	/**
	 * The distance to erode/shrink the walkable area of the heightfield away from obstructions. [Limit: >=0] [Units:
	 * vx]
	 **/
	public var walkableRadius:int;

	/** The maximum allowed length for contour edges along the border of the mesh. [Limit: >=0] [Units: vx] **/
	public var maxEdgeLen:int;

	/**
	 * The maximum distance a simplfied contour's border edges should deviate the original raw contour. [Limit: >=0]
	 * [Units: vx]
	 **/
	public var maxSimplificationError:Number;

	/** The minimum number of cells allowed to form isolated island areas. [Limit: >=0] [Units: vx] **/
	public var minRegionArea:int;

	/**
	 * Any regions with a span count smaller than this value will, if possible, be merged with larger regions. [Limit:
	 * >=0] [Units: vx]
	 **/
	public var mergeRegionArea:int;

	/**
	 * The maximum number of vertices allowed for polygons generated during the contour to polygon conversion process.
	 * [Limit: >= 3]
	 **/
	public var maxVertsPerPoly:int;

	/**
	 * Sets the sampling distance to use when generating the detail mesh. (For height detail only.) [Limits: 0 or >=
	 * 0.9] [Units: wu]
	 **/
	public var detailSampleDist:Number;

	/**
	 * The maximum distance the detail mesh surface should deviate from heightfield data. (For height detail only.)
	 * [Limit: >=0] [Units: wu]
	 **/
	public var detailSampleMaxError:Number;
};
}
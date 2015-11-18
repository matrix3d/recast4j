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
/** A compact, static heightfield representing unobstructed space. */
public class CompactHeightfield {

	/** The width of the heightfield. (Along the x-axis in cell units.) */
	public var width:int;
	/** The height of the heightfield. (Along the z-axis in cell units.) */
	public var height:int;
	/** The number of spans in the heightfield. */
	public var spanCount:int;
	/** The walkable height used during the build of the field.  (See: RecastConfig::walkableHeight) */
	public var walkableHeight:int;
	/** The walkable climb used during the build of the field. (See: RecastConfig::walkableClimb) */
	public var walkableClimb:int;
	/** The AABB border size used during the build of the field. (See: RecastConfig::borderSize) */
	public var borderSize:int;
	/** The maximum distance value of any span within the field. */
	public var maxDistance:int;
	/** The maximum region id of any span within the field. */
	public var maxRegions:int;
	/** The minimum bounds in world space. [(x, y, z)] */
	public var bmin:Array;
	/** The maximum bounds in world space. [(x, y, z)] */
	public var bmax:Array;
	/** The size of each cell. (On the xz-plane.) */
	public var cs:Number;
	/** The height of each cell. (The minimum increment along the y-axis.) */
	public var ch:Number;
	/** Array of cells. [Size: #width*#height] */
	public var cells:Array;
	/** Array of spans. [Size: #spanCount] */
	public var spans:Array;
	/** Array containing border distance data. [Size: #spanCount] */
	public var dist:Array;
	/** Array containing area id data. [Size: #spanCount] */
	public var areas:Array;

}
}
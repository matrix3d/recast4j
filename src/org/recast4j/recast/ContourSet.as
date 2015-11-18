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
import java.util.ArrayList;
import java.util.List;

/** Represents a group of related contours. */
public class ContourSet {

	/** A list of the contours in the set. */
	public List<Contour> conts = new ArrayList<>();
	/** The minimum bounds in world space. [(x, y, z)] */
	var bmin:Array= new float[3];
	/** The maximum bounds in world space. [(x, y, z)] */
	var bmax:Array= new float[3];
	/** The size of each cell. (On the xz-plane.) */
	public var cs:Number;
	/** The height of each cell. (The minimum increment along the y-axis.) */
	public var ch:Number;
	/** The width of the set. (Along the x-axis in cell units.) */
	public var width:int;
	/** The height of the set. (Along the z-axis in cell units.) */
	public var height:int;
	/** The AABB border size used to generate the source data from which the contours were derived. */
	public var borderSize:int;
}
}
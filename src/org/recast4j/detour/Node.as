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
public class Node {

	public static var DT_NODE_OPEN:int= 0x01;
	public static var DT_NODE_CLOSED:int= 0x02;
	/** parent of the node is not adjacent. Found using raycast. */
	public static var DT_NODE_PARENT_DETACHED:int= 0x04;

	public var index:int;

	/** Position of the node. */
	public var pos:Array= []//new float[3]; 
	/** Cost from previous node to current node. */
	public var cost:Number;
	/** Cost up to the node. */
	public var total:Number;
	/** Index to parent node. */
	public var pidx:int;
	/** extra state information. A polyRef can have multiple nodes with different extra info. see DT_MAX_STATES_PER_NODE */
	public var state:int;
	/** Node flags. A combination of dtNodeFlags. */
	public var flags:int;
	/** Polygon ref the node corresponds to. */
	public var id:Number;

	public function Node(index:int) {
		super();
		this.index = index;
	}

}
}
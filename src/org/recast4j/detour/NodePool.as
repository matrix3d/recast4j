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

public class NodePool {

	public var m_map:Object = { };//new HashMap<>();
	public var m_nodes:Array = [];// new ArrayList<Node>();

	public function NodePool() {

	}

	public function clear():void {
		m_nodes.clear();
		m_map.clear();
	}

	public function findNodes( id:Number,  maxNodes:int):Array {
		var nodes:Array = m_map[id];
		if (nodes == null) {
			nodes = [];
		}
		return nodes;
	}

	public function findNode(id:Number):Node {
		var nodes:Array = m_map[id];
		if (nodes != null && !nodes.isEmpty()) {
			return nodes[0];
		}
		return null;
	}

	public function findNode2(id:Number, state:int):Node {
		var nodes:Array = m_map[id];
		if (nodes != null) {
			for each(var node:Node in  nodes) {
				if (node.state == state) {
					return node;
				}
			}
		}
		return null;
	}

	public function getNode(id:Number, state:int=0):Node {
		var nodes:Array = m_map[id];
		if (nodes != null) {
			for each(var node:Node in nodes) {
				if (node.state == state) {
					return node;
				}
			}
		}
		return create(id, state);
	}

	protected function create(id:Number, state:int):Node {
		var node:Node= new Node(m_nodes.length + 1);
		node.id = id;
		node.state = state;
		m_nodes.push(node);
		var nodes:Array = m_map[id];
		if (nodes == null) {
			nodes = [];
			m_map.put(id, nodes);
		}
		nodes.push(node);
		return node;
	}

	public function getNodeIdx(node:Node):int {
		return node != null ? node.index : 0;
	}

	public function getNodeAtIdx(idx:int):Node {
		return idx != 0? m_nodes.get(idx - 1) : null;
	}

	public function getNodeCount():int {
		return m_nodes.length;
	}

	/*
	
	inline int getMaxNodes() const { return m_maxNodes; }
	inline dtNodeIndex getFirst(int bucket) const { return m_first[bucket]; }
	inline dtNodeIndex getNext(int i) const { return m_next[i]; }
	*/
}
}
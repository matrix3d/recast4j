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

public class NodeQueue {

	private var m_heap:Array=[null];
		private var m_capacity:int;
		private       var m_size:int;
		
		public function NodeQueue() {
		}
		
		public function clear():void {
			m_size = 0;
		}
		
		public function getCapacity():int {
			return m_capacity;
		}
		
		public function isEmpty():Boolean {
			return m_size == 0;
		}
		
		public function push(node:Node):void {
			m_size++;
			bubbleUp(m_size - 1, node);
		}
		
		private function bubbleUp(i:int, node:Node):void {
			var parent:int= (i - 1) / 2;
			// note: (index > 0) means there is a parent
			while ((i > 0) && (m_heap[parent].total > node.total)) {
				m_heap[i] = m_heap[parent];
				i = parent;
				parent = (i - 1) / 2;
			}
			m_heap[i] = node;
		}
		
		public function modify(node:Node):void {
			for (var i:int= 0; i < m_size; ++i) {
				if (m_heap[i] == node) {
					bubbleUp(i, node);
					return;
				}
			}
		}
		
		public function pop():Node {
			var result:Node= m_heap[0];
			m_size--;
			trickleDown(0, m_heap[m_size]);
			return result;
		}
		
		private function trickleDown(i:int, node:Node):void {
			var child:int= (i * 2) + 1;
			while (child < m_size) {
				if (((child + 1) < m_size) &&
					(m_heap[child].total > m_heap[child + 1].total)) {
					child++;
				}
				m_heap[i] = m_heap[child];
				i = child;
				child = (i * 2) + 1;
			}
			bubbleUp(i, node);
		}
}
}
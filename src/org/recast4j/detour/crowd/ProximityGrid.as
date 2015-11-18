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
package org.recast4j.detour.crowd {
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class ProximityGrid {

	private static 
internal class ItemKey {

		var x:int, y;

		public function ItemKey(x:int, y:int) {
			this.x = x;
			this.y = y;
		}

		
override public function hashCode():int {
			var prime:int= 31;
			var result:int= 1;
			result = prime * result + x;
			result = prime * result + y;
			return result;
		}

		
override public function equal == (obj:Object):Boolean {
			if (this == obj)
				return true;
			if (obj == null)
				return false;
			if (getClass() != obj.getClass())
				return false;
			var other:ItemKey= ItemKey(obj);
			if (x != other.x)
				return false;
			if (y != other.y)
				return false;
			return true;
		}

	};

	private var m_cellSize:Number;
	private var m_invCellSize:Number;
	private Map<ItemKey, List<Integer>> items;
	var m_bounds:Array= new int[4];

	public function ProximityGrid(m_cellSize:Number, m_invCellSize:Number) {
		this.m_cellSize = m_cellSize;
		this.m_invCellSize = m_invCellSize;
		items = new HashMap<>();
	}

	function clear():void {
		items.clear();
		m_bounds[0] = 0x;
		m_bounds[1] = 0x;
		m_bounds[2] = -0x;
		m_bounds[3] = -0x;
	}

	function addItem(id:int, minx:Number, miny:Number, maxx:Number, maxy:Number):void {
		var iminx:int= int(Math.floor(minx * m_invCellSize));
		var iminy:int= int(Math.floor(miny * m_invCellSize));
		var imaxx:int= int(Math.floor(maxx * m_invCellSize));
		var imaxy:int= int(Math.floor(maxy * m_invCellSize));

		m_bounds[0] = Math.min(m_bounds[0], iminx);
		m_bounds[1] = Math.min(m_bounds[1], iminy);
		m_bounds[2] = Math.min(m_bounds[2], imaxx);
		m_bounds[3] = Math.min(m_bounds[3], imaxy);

		for (var y:int= iminy; y <= imaxy; ++y) {
			for (var x:int= iminx; x <= imaxx; ++x) {
				var key:ItemKey= new ItemKey(x, y);
				List<Integer> ids = items.get(key);
				if (ids == null) {
					ids = new ArrayList<>();
					items.put(key, ids);
				}
				ids.add(id);
			}
		}
	}

	Set<Integer> queryItems(var minx:Number, var miny:Number, var maxx:Number, var maxy:Number) {
		var iminx:int= int(Math.floor(minx * m_invCellSize));
		var iminy:int= int(Math.floor(miny * m_invCellSize));
		var imaxx:int= int(Math.floor(maxx * m_invCellSize));
		var imaxy:int= int(Math.floor(maxy * m_invCellSize));

		Set<Integer> result = new HashSet<>();
		for (var y:int= iminy; y <= imaxy; ++y) {
			for (var x:int= iminx; x <= imaxx; ++x) {
				var key:ItemKey= new ItemKey(x, y);
				List<Integer> ids = items.get(key);
				if (ids != null) {
					result.addAll(ids);
				}
			}
		}

		return result;
	}

	function getItemCountAt(x:int, y:int):int {
		var key:ItemKey= new ItemKey(x, y);
		List<Integer> ids = items.get(key);
		return ids != null ? ids.size() : 0;
	}
}
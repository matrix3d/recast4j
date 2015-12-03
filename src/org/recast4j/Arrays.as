package org.recast4j 
{
	/**
	 * ...
	 * @author lizhi
	 */
	public class Arrays 
	{
		
		public function Arrays() 
		{
			
		}
		
		public static function sort(a:Array, fromIndex:int, toIndex:int, compare:Function):void {
			if (fromIndex == 0 && toIndex == a.length) {
				a.sort(compare);
			}else {
				var temp:Array = a.slice(fromIndex,toIndex);
				temp.sort(compare);
				temp.unshift(toIndex-fromIndex);
				temp.unshift(fromIndex);
				a.splice.apply(null, temp);
			}
			
			
		}
		
		public static function fill(a:Array, fromIndex:int, toIndex:int, val:Object):void {
			for (var i:int = fromIndex; i < toIndex;i++ ) {
				a[i] = val;
			}
		}
		/*public static function fill2(a:Array,val:Object):void {
			fill(a, 0, a.length, val);
		}*/
		
	}

}
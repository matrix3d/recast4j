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
			var temp:Array = a.slice(0,toIndex);
			temp.sort(compare);
			temp.unshift(toIndex);
			temp.unshift(0);
			a.splice.apply(null, temp);
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
package org.recast4j 
{
	import org.recast4j.detour.Tupple2;
	import org.recast4j.detour.Tupple3;
	/**
	 * ...
	 * @author lizhi
	 */
	public class System 
	{
		
		public function System() 
		{
			
		}
		
		public static function arraycopy(src:Array,srcPos:int,dest:Array,destPos:int,length:int):void{
			for (var i:int = 0; i < length;i++ ) {
				dest.splice(destPos+i,0, src[srcPos+i]);
			}
		}
		public static function arraycopy2(src:Tupple2,srcPos:int,dest:Array,destPos:int,length:int):void{
			for (var i:int = 0; i < length; i++ ) {
				var p:int = srcPos + i;
				dest.splice(destPos+i,0, p==0?src.first:src.second);
			}
		}
		
	}

}
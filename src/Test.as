package 
{
	import flash.display.Sprite;
	/**
	 * ...
	 * @author lizhi
	 */
	public class Test extends Sprite
	{
		
		public function Test() 
		{
			var arr:Array = [0, 0, 0];
			arr.splice.apply(null, [0, 3, 1, 1]);
			trace(arr);
		}
		
	}

}
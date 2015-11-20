package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import org.recast4j.detour.BVNode;
	import org.recast4j.detour.FindDistanceToWallTest;
	import org.recast4j.recast.CompactSpan;
	
	/**
	 * ...
	 * @author lizhi
	 */
	public class Main extends Sprite 
	{
		
		public function Main() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			new FindDistanceToWallTest();
			new CompactSpan;
		}
		
	}
	
}
package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import org.recast4j.detour.BVNode;
	import org.recast4j.detour.FindDistanceToWallTest;
	import org.recast4j.detour.FindLocalNeighbourhoodTest;
	import org.recast4j.detour.NavMeshQuery;
	
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
			//new NavMeshQuery(null);
			var ft:FindDistanceToWallTest = new FindDistanceToWallTest();
			ft.setUp();
			//ft.testFindDistanceToWall();
			
			var fn:FindLocalNeighbourhoodTest = new FindLocalNeighbourhoodTest;
			fn.setUp();
			fn.testFindNearestPoly();
		}
		
	}
	
}
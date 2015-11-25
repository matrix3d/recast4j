package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	import org.recast4j.detour.BVNode;
	import test.FindDistanceToWallTest;
	import test.FindLocalNeighbourhoodTest;
	import org.recast4j.detour.NavMeshQuery;
	
	/**
	 * ...
	 * @author lizhi
	 */
	public class Main extends Sprite 
	{
		
		public function Main() 
		{
			var ft:FindDistanceToWallTest = new FindDistanceToWallTest();
			ft.setUp();
			ft.testFindDistanceToWall();
			
			/*var fn:FindLocalNeighbourhoodTest = new FindLocalNeighbourhoodTest;
			var t:Number = getTimer();
			fn.setUp();
			trace(getTimer() - t,"ms");
			t = getTimer();
			fn.testFindNearestPoly();
			trace(getTimer() - t, "ms");*/
		}
		
	}
	
}
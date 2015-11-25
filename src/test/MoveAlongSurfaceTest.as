/*
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
package test {
import org.recast4j.detour.MoveAlongSurfaceResult;
import org.recast4j.detour.QueryFilter;
import test.AbstractDetourTest;

public class MoveAlongSurfaceTest extends AbstractDetourTest {

	private var visited:Array = [
			 [ 281474976710696, 281474976710695, 281474976710694, 281474976710703, 281474976710706,
					281474976710705, 281474976710702, 281474976710701, 281474976710714, 281474976710713,
					281474976710712, 281474976710727, 281474976710730, 281474976710717, 281474976710721],
			 [ 281474976710773, 281474976710772, 281474976710768, 281474976710754, 281474976710755,
					281474976710753],
			 [ 281474976710680, 281474976710684, 281474976710688, 281474976710687, 281474976710686,
					281474976710697, 281474976710695, 281474976710694, 281474976710703, 281474976710706,
					281474976710705, 281474976710702, 281474976710701, 281474976710714, 281474976710713,
					281474976710712, 281474976710727, 281474976710730, 281474976710717, 281474976710721,
					281474976710718],
			 [ 281474976710753, 281474976710748, 281474976710752, 281474976710731],
			[ 281474976710733, 281474976710736, 281474976710738, 281474976710737, 281474976710728,
					281474976710724, 281474976710717, 281474976710729, 281474976710731, 281474976710752,
					281474976710748, 281474976710753, 281474976710755, 281474976710754, 281474976710768,
					281474976710772] ];
	private var position:Array = [ [ 6.457663, 10.197294, -18.334061], [ -1.433933, 10.197294, -1.359993],
			[ 12.184784, 9.997294, -18.941269], [ 0.863553, 10.197294, -10.310320],
			[ 18.784092, 10.197294, 3.054368] ];

	public function MoveAlongSurfaceTest() 
	{
		setUp();
		testMoveAlongSurface();
	}
	public function testMoveAlongSurface():void {
		var filter:QueryFilter= new QueryFilter();
		for (var i:int= 0; i < startRefs.length; i++) {
			var startRef:Number= startRefs[i];
			var startPos:Array= startPoss[i];
			var endPos:Array= endPoss[i];
			var path:MoveAlongSurfaceResult= query.moveAlongSurface(startRef, startPos, endPos, filter);
			for (var v:int= 0; v < 3; v++) {
				assertEquals(position[i][v], path.getResultPos()[v], 0.01);
			}
			assertEquals(visited[i].length, path.getVisited().length);
			for (var j:int= 0; j < position[i].length; j++) {
				assertEquals(visited[i][j], path.getVisited()[j]);
			}
		}
	}


}
}
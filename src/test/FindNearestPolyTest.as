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
import org.recast4j.detour.FindNearestPolyResult;
import org.recast4j.detour.QueryFilter;
import test.AbstractDetourTest;

public class FindNearestPolyTest extends AbstractDetourTest {

	private var polyRefs:Array= [ 281474976710696, 281474976710773, 281474976710680, 281474976710753,
			281474976710733];
	private var polyPos:Array = [ [ 22.606520, 10.197294, -45.918674], [ 22.331268, 10.197294, -1.040187],
			[ 18.694363, 15.803535, -73.090416], [ 0.745335, 10.197294, -5.940050],
			[ -20.651257, 5.904126, -13.712508] ];

	public function FindNearestPolyTest() 
	{
		setUp();
		testFindNearestPoly();
	}
	public function testFindNearestPoly():void {
		var filter:QueryFilter= new QueryFilter();
		var extents:Array= [ 2, 4, 2];
		for (var i:int= 0; i < startRefs.length; i++) {
			var startPos:Array= startPoss[i];
			var poly:FindNearestPolyResult= query.findNearestPoly(startPos, extents, filter);
			assertEquals(polyRefs[i], poly.getNearestRef());
			for (var v:int= 0; v < polyPos[i].length; v++) {
				assertEquals(polyPos[i][v], poly.getNearestPos()[v], 0.001);
			}
		}

	}
}
}
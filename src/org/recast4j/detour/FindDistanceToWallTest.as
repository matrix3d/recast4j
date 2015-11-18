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
package org.recast4j.detour {

public class FindDistanceToWallTest extends AbstractDetourTest {

	var distancesToWall:Array= [ 0.597511, 3.201085, 0.603713, 2.791475, 2.815544];
	var hitPosition:Array = [[ 23.177608, 10.197294, -45.742954], [ 22.331268, 10.197294, -4.241272],
			[ 18.108675, 15.743596, -73.236839], [ 1.984785, 10.197294, -8.441269],
			[ -22.315216, 4.997294, -11.441269]];
	var hitNormal:Array = [[ -0.955779, 0.000000, -0.294087], [ 0.000000, 0.000000, 1.000000],
			[ 0.965395, 0.098799, 0.241351], [ -0.444012, 0.000000, 0.896021],
			[ 0.562533, 0.306572, -0.767835] ];

	public function testFindDistanceToWall():void {
		var filter:QueryFilter= new QueryFilter();
		for (var i:int= 0; i < startRefs.length; i++) {
			var startPos:Array= startPoss[i];
			var hit:FindDistanceToWallResult= query.findDistanceToWall(startRefs[i], startPos, 3.5, filter);
			/*Assert.assertEquals(distancesToWall[i], hit.getDistance(), 0.001);
			for (var v:int= 0; v < 3; v++) {
				Assert.assertEquals(hitPosition[i][v], hit.getPosition()[v], 0.001);
			}
			for (var v:int= 0; v < 3; v++) {
				Assert.assertEquals(hitNormal[i][v], hit.getNormal()[v], 0.001);
			}*/
		}

	}
}
}
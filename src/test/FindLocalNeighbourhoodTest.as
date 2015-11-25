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

public class FindLocalNeighbourhoodTest extends AbstractDetourTest {

	private var refs:Array = [[ 281474976710696, 281474976710695, 281474976710691, 281474976710697],
			[ 281474976710773, 281474976710769, 281474976710772],
			[ 281474976710680, 281474976710674, 281474976710679, 281474976710684, 281474976710683,
					281474976710678, 281474976710677, 281474976710676],
			[ 281474976710753, 281474976710748, 281474976710750, 281474976710752],
			[ 281474976710733, 281474976710735, 281474976710736]

	];
	private var parentRefs:Array = [ [ 0, 281474976710696, 281474976710695, 281474976710695],
			[ 0, 281474976710773, 281474976710773],
			[ 0, 281474976710680, 281474976710680, 281474976710680, 281474976710680, 281474976710679,
					281474976710683, 281474976710678],
			[ 0, 281474976710753, 281474976710753, 281474976710748], [ 0, 281474976710733, 281474976710733] ];

	public function testFindNearestPoly():void {
		var filter:QueryFilter= new QueryFilter();
		for (var i:int= 0; i < startRefs.length; i++) {
			var startPos:Array= startPoss[i];
			var poly:FindLocalNeighbourhoodResult= query.findLocalNeighbourhood(startRefs[i], startPos, 3.5, filter);
			assertEquals(refs[i].length, poly.getRefs().length);
			for (var v:int= 0; v < refs[i].length; v++) {
				assertEquals(refs[i][v], poly.getRefs()[v]);
			}
		}

	}

}
}
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
import org.recast4j.detour.FindPolysAroundResult;
import org.recast4j.detour.QueryFilter;
import test.AbstractDetourTest;

public class FindPolysAroundCircleTest extends AbstractDetourTest {

	private var refs:Array = [
			[ 281474976710696, 281474976710695, 281474976710694, 281474976710691, 281474976710697,
					281474976710693, 281474976710686, 281474976710687, 281474976710692, 281474976710703,
					281474976710689],
			[ 281474976710773, 281474976710770, 281474976710769, 281474976710772, 281474976710771],
			[ 281474976710680, 281474976710674, 281474976710679, 281474976710684, 281474976710683,
					281474976710678, 281474976710682, 281474976710677, 281474976710676, 281474976710688,
					281474976710687, 281474976710675, 281474976710685, 281474976710672, 281474976710666,
					281474976710668, 281474976710681, 281474976710673],
			[ 281474976710753, 281474976710748, 281474976710755, 281474976710756, 281474976710750,
					281474976710752, 281474976710731, 281474976710729, 281474976710749, 281474976710719,
					281474976710717, 281474976710726],
			[ 281474976710733, 281474976710735, 281474976710736, 281474976710734, 281474976710739,
					281474976710742, 281474976710740, 281474976710746, 281474976710747, ] ];
	private var  parentsRefs:Array = [
			[ 0, 281474976710696, 281474976710695, 281474976710695, 281474976710695, 281474976710695,
					281474976710697, 281474976710686, 281474976710693, 281474976710694, 281474976710687],
			[ 0, 281474976710773, 281474976710773, 281474976710773, 281474976710772],
			[ 0, 281474976710680, 281474976710680, 281474976710680, 281474976710680, 281474976710679,
					281474976710683, 281474976710683, 281474976710678, 281474976710684, 281474976710688,
					281474976710677, 281474976710687, 281474976710682, 281474976710672, 281474976710672,
					281474976710675, 281474976710666],
			[ 0, 281474976710753, 281474976710753, 281474976710753, 281474976710753, 281474976710748,
					281474976710752, 281474976710731, 281474976710756, 281474976710729, 281474976710729,
					281474976710717],
			[ 0, 281474976710733, 281474976710733, 281474976710736, 281474976710736, 281474976710735,
					281474976710742, 281474976710740, 281474976710746] ];
		private var costs:Array = [
			[ 0.000000, 0.391453, 6.764245, 4.153431, 3.721995, 6.109188, 5.378797, 7.178796, 7.009186,
					7.514245, 12.655564],
			[ 0.000000, 6.161580, 2.824478, 2.828730, 8.035697],
			[ 0.000000, 1.162604, 1.954029, 2.776051, 2.046001, 2.428367, 6.429493, 6.032851, 2.878368,
					5.333885, 6.394545, 9.596563, 12.457960, 7.096575, 10.413582, 10.362305, 10.665442,
					10.593861],
			[ 0.000000, 2.483205, 6.723722, 5.727250, 3.126022, 3.543865, 5.043865, 6.843868, 7.212173,
					10.602858, 8.793867, 13.146453],
			[ 0.000000, 2.480514, 0.823685, 5.002500, 8.229258, 3.983844, 5.483844, 6.655379, 11.996962] ];
	public function FindPolysAroundCircleTest() 
	{
		setUp();
		testFindPolysAroundCircle();
	}
	public function testFindPolysAroundCircle():void {
		var filter:QueryFilter= new QueryFilter();
		for (var i:int= 0; i < startRefs.length; i++) {
			var startRef:Number= startRefs[i];
			var startPos:Array= startPoss[i];
			var polys:FindPolysAroundResult= query.findPolysAroundCircle(startRef, startPos, 7.5, filter);
			assertEquals(refs[i].length, polys.getRefs().length);
			for (var v:int= 0; v < refs[i].length; v++) {
				assertEquals(refs[i][v], polys.getRefs()[v]);
			}
			for (v= 0; v < parentsRefs[i].length; v++) {
				assertEquals(parentsRefs[i][v], polys.getParentRefs()[v]);
			}
			for (v= 0; v < costs[i].length; v++) {
				assertEquals(costs[i][v], polys.getCosts()[v], 0.01);
			}
		}

	}

}
}
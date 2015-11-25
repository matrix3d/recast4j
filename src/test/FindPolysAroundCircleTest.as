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
import org.junit.Assert;
import org.junit.Test;
import test.AbstractDetourTest;

public class FindPolysAroundCircleTest extends AbstractDetourTest {

	long[][] refs = {
			{ 281474976710696L, 281474976710695L, 281474976710694L, 281474976710691L, 281474976710697L,
					281474976710693L, 281474976710686L, 281474976710687L, 281474976710692L, 281474976710703L,
					281474976710689L},
			{ 281474976710773L, 281474976710770L, 281474976710769L, 281474976710772L, 281474976710771L},
			{ 281474976710680L, 281474976710674L, 281474976710679L, 281474976710684L, 281474976710683L,
					281474976710678L, 281474976710682L, 281474976710677L, 281474976710676L, 281474976710688L,
					281474976710687L, 281474976710675L, 281474976710685L, 281474976710672L, 281474976710666L,
					281474976710668L, 281474976710681L, 281474976710673L},
			{ 281474976710753L, 281474976710748L, 281474976710755L, 281474976710756L, 281474976710750L,
					281474976710752L, 281474976710731L, 281474976710729L, 281474976710749L, 281474976710719L,
					281474976710717L, 281474976710726L},
			{ 281474976710733L, 281474976710735L, 281474976710736L, 281474976710734L, 281474976710739L,
					281474976710742L, 281474976710740L, 281474976710746L, 281474976710747L, } };
	long[][] parentsRefs = {
			{ 0L, 281474976710696L, 281474976710695L, 281474976710695L, 281474976710695L, 281474976710695L,
					281474976710697L, 281474976710686L, 281474976710693L, 281474976710694L, 281474976710687L},
			{ 0L, 281474976710773L, 281474976710773L, 281474976710773L, 281474976710772L},
			{ 0L, 281474976710680L, 281474976710680L, 281474976710680L, 281474976710680L, 281474976710679L,
					281474976710683L, 281474976710683L, 281474976710678L, 281474976710684L, 281474976710688L,
					281474976710677L, 281474976710687L, 281474976710682L, 281474976710672L, 281474976710672L,
					281474976710675L, 281474976710666L},
			{ 0L, 281474976710753L, 281474976710753L, 281474976710753L, 281474976710753L, 281474976710748L,
					281474976710752L, 281474976710731L, 281474976710756L, 281474976710729L, 281474976710729L,
					281474976710717L},
			{ 0L, 281474976710733L, 281474976710733L, 281474976710736L, 281474976710736L, 281474976710735L,
					281474976710742L, 281474976710740L, 281474976710746L} };
	float[][] costs = {
			{ 0.000000, 0.391453, 6.764245, 4.153431, 3.721995, 6.109188, 5.378797, 7.178796, 7.009186,
					7.514245, 12.655564},
			{ 0.000000, 6.161580, 2.824478, 2.828730, 8.035697},
			{ 0.000000, 1.162604, 1.954029, 2.776051, 2.046001, 2.428367, 6.429493, 6.032851, 2.878368,
					5.333885, 6.394545, 9.596563, 12.457960, 7.096575, 10.413582, 10.362305, 10.665442,
					10.593861},
			{ 0.000000, 2.483205, 6.723722, 5.727250, 3.126022, 3.543865, 5.043865, 6.843868, 7.212173,
					10.602858, 8.793867, 13.146453},
			{ 0.000000, 2.480514, 0.823685, 5.002500, 8.229258, 3.983844, 5.483844, 6.655379, 11.996962} };

	public function testFindPolysAroundCircle():void {
		var filter:QueryFilter= new QueryFilter();
		for (var i:int= 0; i < startRefs.length; i++) {
			var startRef:Number= startRefs[i];
			var startPos:Array= startPoss[i];
			var polys:FindPolysAroundResult= query.findPolysAroundCircle(startRef, startPos, 7.5, filter);
			Assert.assertEquals(refs[i].length, polys.getRefs().length);
			for (var v:int= 0; v < refs[i].length; v++) {
				Assert.assertEquals(refs[i][v], polys.getRefs()[v).longValue());
			}
			for (var v:int= 0; v < parentsRefs[i].length; v++) {
				Assert.assertEquals(parentsRefs[i][v], polys.getParentRefs()[v).longValue());
			}
			for (var v:int= 0; v < costs[i].length; v++) {
				Assert.assertEquals(costs[i][v], polys.getCosts()[v).floatValue(), 0.01);
			}
		}

	}

}
}
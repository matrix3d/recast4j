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
import java.util.List;

import org.junit.Assert;
import org.junit.Test;

public class FindPathTest extends AbstractDetourTest {

	var statuses:Array= { Status.SUCCSESS, Status.PARTIAL_RESULT, Status.SUCCSESS, Status.SUCCSESS, Status.SUCCSESS };
	long[][] results = {
			{ 281474976710696L, 281474976710695L, 281474976710694L, 281474976710703L, 281474976710706L,
					281474976710705L, 281474976710702L, 281474976710701L, 281474976710714L, 281474976710713L,
					281474976710712L, 281474976710727L, 281474976710730L, 281474976710717L, 281474976710721L},
			{ 281474976710773L, 281474976710772L, 281474976710768L, 281474976710754L, 281474976710755L,
					281474976710753L, 281474976710748L, 281474976710752L, 281474976710731L, 281474976710729L,
					281474976710717L, 281474976710724L, 281474976710728L, 281474976710737L, 281474976710738L,
					281474976710736L, 281474976710733L, 281474976710735L, 281474976710742L, 281474976710740L,
					281474976710746L, 281474976710745L, 281474976710744L},
			{ 281474976710680L, 281474976710684L, 281474976710688L, 281474976710687L, 281474976710686L,
					281474976710697L, 281474976710695L, 281474976710694L, 281474976710703L, 281474976710706L,
					281474976710705L, 281474976710702L, 281474976710701L, 281474976710714L, 281474976710713L,
					281474976710712L, 281474976710727L, 281474976710730L, 281474976710717L, 281474976710729L,
					281474976710731L, 281474976710752L, 281474976710748L, 281474976710753L, 281474976710755L,
					281474976710754L, 281474976710768L, 281474976710772L, 281474976710773L, 281474976710770L,
					281474976710757L, 281474976710761L, 281474976710758L},
			{ 281474976710753L, 281474976710748L, 281474976710752L, 281474976710731L},
			{ 281474976710733L, 281474976710736L, 281474976710738L, 281474976710737L, 281474976710728L,
					281474976710724L, 281474976710717L, 281474976710729L, 281474976710731L, 281474976710752L,
					281474976710748L, 281474976710753L, 281474976710755L, 281474976710754L, 281474976710768L,
					281474976710772L} };

	StraightPathItem[][] straightPaths = {
			{ new StraightPathItem(new float[] { 22.606520, 10.197294, -45.918674}, 1, 281474976710696L),
					new StraightPathItem(new float[] { 3.484785, 10.197294, -34.241272}, 0, 281474976710713L),
					new StraightPathItem(new float[] { 1.984785, 10.197294, -31.241272}, 0, 281474976710712L),
					new StraightPathItem(new float[] { 1.984785, 10.197294, -29.741272}, 0, 281474976710727L),
					new StraightPathItem(new float[] { 2.584784, 10.197294, -27.941273}, 0, 281474976710730L),
					new StraightPathItem(new float[] { 6.457663, 10.197294, -18.334061}, 2, 0L) },

			{ new StraightPathItem(new float[] { 22.331268, 10.197294, -1.040187}, 1, 281474976710773L),
					new StraightPathItem(new float[] { 9.784786, 10.197294, -2.141273}, 0, 281474976710755L),
					new StraightPathItem(new float[] { 7.984783, 10.197294, -2.441269}, 0, 281474976710753L),
					new StraightPathItem(new float[] { 1.984785, 10.197294, -8.441269}, 0, 281474976710752L),
					new StraightPathItem(new float[] { -4.315216, 10.197294, -15.341270}, 0, 281474976710724L),
					new StraightPathItem(new float[] { -8.215216, 10.197294, -17.441269}, 0, 281474976710728L),
					new StraightPathItem(new float[] { -10.015216, 10.197294, -17.741272}, 0, 281474976710738L),
					new StraightPathItem(new float[] { -11.815216, 9.997294, -17.441269}, 0, 281474976710736L),
					new StraightPathItem(new float[] { -17.815216, 5.197294, -11.441269}, 0, 281474976710735L),
					new StraightPathItem(new float[] { -17.815216, 5.197294, -8.441269}, 0, 281474976710746L),
					new StraightPathItem(new float[] { -11.815216, 0.197294, 3.008419}, 2, 0L) },

			{ new StraightPathItem(new float[] { 18.694363, 15.803535, -73.090416}, 1, 281474976710680L),
					new StraightPathItem(new float[] { 17.584785, 10.197294, -49.841274}, 0, 281474976710697L),
					new StraightPathItem(new float[] { 17.284786, 10.197294, -48.041275}, 0, 281474976710695L),
					new StraightPathItem(new float[] { 16.084785, 10.197294, -45.341274}, 0, 281474976710694L),
					new StraightPathItem(new float[] { 3.484785, 10.197294, -34.241272}, 0, 281474976710713L),
					new StraightPathItem(new float[] { 1.984785, 10.197294, -31.241272}, 0, 281474976710712L),
					new StraightPathItem(new float[] { 1.984785, 10.197294, -8.441269}, 0, 281474976710753L),
					new StraightPathItem(new float[] { 7.984783, 10.197294, -2.441269}, 0, 281474976710755L),
					new StraightPathItem(new float[] { 9.784786, 10.197294, -2.141273}, 0, 281474976710768L),
					new StraightPathItem(new float[] { 38.423977, 10.197294, -0.116067}, 2, 0L) },

			{ new StraightPathItem(new float[] { 0.745335, 10.197294, -5.940050}, 1, 281474976710753L),
					new StraightPathItem(new float[] { 0.863553, 10.197294, -10.310320}, 2, 0L) },

			{ new StraightPathItem(new float[] { -20.651257, 5.904126, -13.712508}, 1, 281474976710733L),
					new StraightPathItem(new float[] { -11.815216, 9.997294, -17.441269}, 0, 281474976710738L),
					new StraightPathItem(new float[] { -10.015216, 10.197294, -17.741272}, 0, 281474976710728L),
					new StraightPathItem(new float[] { -8.215216, 10.197294, -17.441269}, 0, 281474976710724L),
					new StraightPathItem(new float[] { -4.315216, 10.197294, -15.341270}, 0, 281474976710729L),
					new StraightPathItem(new float[] { 1.984785, 10.197294, -8.441269}, 0, 281474976710753L),
					new StraightPathItem(new float[] { 7.984783, 10.197294, -2.441269}, 0, 281474976710755L),
					new StraightPathItem(new float[] { 18.784092, 10.197294, 3.054368}, 2, 0L) } };

	public function testFindPath():void {
		var filter:QueryFilter= new QueryFilter();
		for (var i:int= 0; i < startRefs.length; i++) {
			var startRef:Number= startRefs[i];
			var endRef:Number= endRefs[i];
			var startPos:Array= startPoss[i];
			var endPos:Array= endPoss[i];
			var path:FindPathResult= query.findPath(startRef, endRef, startPos, endPos, filter);
			Assert.assertEquals(statuses[i], path.getStatus());
			Assert.assertEquals(results[i].length, path.getRefs().length);
			for (var j:int= 0; j < results[i].length; j++) {
				Assert.assertEquals(results[i][j], path.getRefs()[j).longValue());
			}
		}
	}

	public function testFindPathSliced():void {
		var filter:QueryFilter= new QueryFilter();
		for (var i:int= 0; i < startRefs.length; i++) {
			var startRef:Number= startRefs[i];
			var endRef:Number= endRefs[i];
			var startPos:Array= startPoss[i];
			var endPos:Array= endPoss[i];
			query.initSlicedFindPath(startRef, endRef, startPos, endPos, filter, NavMeshQuery.DT_FINDPATH_ANY_ANGLE);
			var status:Status= Status.IN_PROGRESS;
			while (status == Status.IN_PROGRESS) {
				var res:UpdateSlicedPathResult= query.updateSlicedFindPath(10);
				status = res.getStatus();
			}
			var path:FindPathResult= query.finalizeSlicedFindPath();
			Assert.assertEquals(statuses[i], path.getStatus());
			Assert.assertEquals(results[i].length, path.getRefs().length);
			for (var j:int= 0; j < results[i].length; j++) {
				Assert.assertEquals(results[i][j], path.getRefs()[j).longValue());
			}

		}
	}

	public function testFindPathStraight():void {
		var filter:QueryFilter= new QueryFilter();
		for (var i:int= 0; i < straightPaths.length; i++) {// startRefs.length; i++) {
			var startRef:Number= startRefs[i];
			var endRef:Number= endRefs[i];
			var startPos:Array= startPoss[i];
			var endPos:Array= endPoss[i];
			var path:FindPathResult= query.findPath(startRef, endRef, startPos, endPos, filter);
			List<StraightPathItem> straightPath = query.findStraightPath(startPos, endPos, path.getRefs(), 0);
			Assert.assertEquals(straightPaths[i].length, straightPath.length);
			for (var j:int= 0; j < straightPaths[i].length; j++) {
				Assert.assertEquals(straightPaths[i][j].ref, straightPath[j).ref);
				for (var v:int= 0; v < 3; v++) {
					Assert.assertEquals(straightPaths[i][j].pos[v], straightPath[j).pos[v], 0.01);
				}
				Assert.assertEquals(straightPaths[i][j].flags, straightPath[j).flags);
			}
		}
	}

}
}
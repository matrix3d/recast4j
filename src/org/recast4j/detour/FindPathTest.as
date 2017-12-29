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
import test.AbstractDetourTest;


public class FindPathTest extends AbstractDetourTest {
	
	private var statuses:Array= [ Status.SUCCSESS, Status.PARTIAL_RESULT, Status.SUCCSESS, Status.SUCCSESS, Status.SUCCSESS ];
	private var results:Array = [
			[ 281474976710696 , 281474976710695 , 281474976710694 , 281474976710703 , 281474976710706 ,
					281474976710705 , 281474976710702 , 281474976710701 , 281474976710714 , 281474976710713 ,
					281474976710712 , 281474976710727 , 281474976710730 , 281474976710717 , 281474976710721 ],
			[ 281474976710773 , 281474976710772 , 281474976710768 , 281474976710754 , 281474976710755 ,
					281474976710753 , 281474976710748 , 281474976710752 , 281474976710731 , 281474976710729 ,
					281474976710717 , 281474976710724 , 281474976710728 , 281474976710737 , 281474976710738 ,
					281474976710736 , 281474976710733 , 281474976710735 , 281474976710742 , 281474976710740 ,
					281474976710746 , 281474976710745 , 281474976710744 ],
			[ 281474976710680 , 281474976710684 , 281474976710688 , 281474976710687 , 281474976710686 ,
					281474976710697 , 281474976710695 , 281474976710694 , 281474976710703 , 281474976710706 ,
					281474976710705 , 281474976710702 , 281474976710701 , 281474976710714 , 281474976710713 ,
					281474976710712 , 281474976710727 , 281474976710730 , 281474976710717 , 281474976710729 ,
					281474976710731 , 281474976710752 , 281474976710748 , 281474976710753 , 281474976710755 ,
					281474976710754 , 281474976710768 , 281474976710772 , 281474976710773 , 281474976710770 ,
					281474976710757 , 281474976710761 , 281474976710758 ],
			[ 281474976710753 , 281474976710748 , 281474976710752 , 281474976710731 ],
			[ 281474976710733 , 281474976710736 , 281474976710738 , 281474976710737 , 281474976710728 ,
					281474976710724 , 281474976710717 , 281474976710729 , 281474976710731 , 281474976710752 ,
					281474976710748 , 281474976710753 , 281474976710755 , 281474976710754 , 281474976710768 ,
					281474976710772 ] ];

	private var/*StraightPathItem[][]*/ straightPaths:Array = [
			[ new StraightPathItem( [ 22.606520, 10.197294, -45.918674], 1, 281474976710696 ),
					new StraightPathItem( [ 3.484785, 10.197294, -34.241272], 0, 281474976710713 ),
					new StraightPathItem( [ 1.984785, 10.197294, -31.241272], 0, 281474976710712 ),
					new StraightPathItem( [ 1.984785, 10.197294, -29.741272], 0, 281474976710727 ),
					new StraightPathItem( [ 2.584784, 10.197294, -27.941273], 0, 281474976710730 ),
					new StraightPathItem( [ 6.457663, 10.197294, -18.334061], 2, 0 ) ],

			[ new StraightPathItem( [ 22.331268, 10.197294, -1.040187], 1, 281474976710773 ),
					new StraightPathItem( [ 9.784786, 10.197294, -2.141273], 0, 281474976710755 ),
					new StraightPathItem( [ 7.984783, 10.197294, -2.441269], 0, 281474976710753 ),
					new StraightPathItem( [ 1.984785, 10.197294, -8.441269], 0, 281474976710752 ),
					new StraightPathItem( [ -4.315216, 10.197294, -15.341270], 0, 281474976710724 ),
					new StraightPathItem( [ -8.215216, 10.197294, -17.441269], 0, 281474976710728 ),
					new StraightPathItem( [ -10.015216, 10.197294, -17.741272], 0, 281474976710738 ),
					new StraightPathItem( [ -11.815216, 9.997294, -17.441269], 0, 281474976710736 ),
					new StraightPathItem( [ -17.815216, 5.197294, -11.441269], 0, 281474976710735 ),
					new StraightPathItem( [ -17.815216, 5.197294, -8.441269], 0, 281474976710746 ),
					new StraightPathItem( [ -11.815216, 0.197294, 3.008419], 2, 0 ) ],

			[ new StraightPathItem( [ 18.694363, 15.803535, -73.090416], 1, 281474976710680 ),
					new StraightPathItem( [ 17.584785, 10.197294, -49.841274], 0, 281474976710697 ),
					new StraightPathItem( [ 17.284786, 10.197294, -48.041275], 0, 281474976710695 ),
					new StraightPathItem( [ 16.084785, 10.197294, -45.341274], 0, 281474976710694 ),
					new StraightPathItem( [ 3.484785, 10.197294, -34.241272], 0, 281474976710713 ),
					new StraightPathItem( [ 1.984785, 10.197294, -31.241272], 0, 281474976710712 ),
					new StraightPathItem( [ 1.984785, 10.197294, -8.441269], 0, 281474976710753 ),
					new StraightPathItem( [ 7.984783, 10.197294, -2.441269], 0, 281474976710755 ),
					new StraightPathItem( [ 9.784786, 10.197294, -2.141273], 0, 281474976710768 ),
					new StraightPathItem( [ 38.423977, 10.197294, -0.116067], 2, 0 ) ],

			[ new StraightPathItem( [ 0.745335, 10.197294, -5.940050], 1, 281474976710753 ),
					new StraightPathItem( [ 0.863553, 10.197294, -10.310320], 2, 0 ) ],

			[ new StraightPathItem( [ -20.651257, 5.904126, -13.712508], 1, 281474976710733 ),
					new StraightPathItem( [ -11.815216, 9.997294, -17.441269], 0, 281474976710738 ),
					new StraightPathItem( [ -10.015216, 10.197294, -17.741272], 0, 281474976710728 ),
					new StraightPathItem( [ -8.215216, 10.197294, -17.441269], 0, 281474976710724 ),
					new StraightPathItem( [ -4.315216, 10.197294, -15.341270], 0, 281474976710729 ),
					new StraightPathItem( [ 1.984785, 10.197294, -8.441269], 0, 281474976710753 ),
					new StraightPathItem( [ 7.984783, 10.197294, -2.441269], 0, 281474976710755 ),
					new StraightPathItem( [ 18.784092, 10.197294, 3.054368], 2, 0 ) ] ];

	public function FindPathTest() 
	{
		setUp();
		testFindPath();
	}
					
	public function testFindPath():void {
		var filter:QueryFilter= new QueryFilter();
		for (var i:int= 0; i < startRefs.length; i++) {
			var startRef:Number= startRefs[i];
			var endRef:Number= endRefs[i];
			var startPos:Array= startPoss[i];
			var endPos:Array= endPoss[i];
			var path:FindPathResult= query.findPath(startRef, endRef, startPos, endPos, filter);
			assertEquals(statuses[i], path.getStatus());
			assertEquals(results[i].length, path.getRefs().length);
			for (var j:int= 0; j < results[i].length; j++) {
				assertEquals(results[i][j], path.getRefs()[j].longValue());
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
			var status:int= Status.IN_PROGRESS;
			while (status == Status.IN_PROGRESS) {
				var res:UpdateSlicedPathResult= query.updateSlicedFindPath(10);
				status = res.getStatus();
			}
			var path:FindPathResult= query.finalizeSlicedFindPath();
			assertEquals(statuses[i], path.getStatus());
			assertEquals(results[i].length, path.getRefs().length);
			for (var j:int= 0; j < results[i].length; j++) {
				assertEquals(results[i][j], path.getRefs()[j]/*.longValue()*/);
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
			var straightPath:Array = query.findStraightPath(startPos, endPos, path.getRefs(), 0);
			assertEquals(straightPaths[i].length, straightPath.length);
			for (var j:int= 0; j < straightPaths[i].length; j++) {
				assertEquals(straightPaths[i][j].ref, straightPath[j].ref);
				for (var v:int= 0; v < 3; v++) {
					assertEquals(straightPaths[i][j].pos[v], straightPath[j].pos[v], 0.01);
				}
				assertEquals(straightPaths[i][j].flags, straightPath[j].flags);
			}
		}
	}

}
}
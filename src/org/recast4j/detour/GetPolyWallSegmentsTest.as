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
import org.junit.Assert;
import org.junit.Test;

public class GetPolyWallSegmentsTest extends AbstractDetourTest {

	float[][] vertices = {
			{ 22.084785, 10.197294, -48.341274, 22.684784, 10.197294, -44.141273, 22.684784, 10.197294,
					-44.141273, 23.884785, 10.197294, -48.041275, 23.884785, 10.197294, -48.041275, 22.084785,
					10.197294, -48.341274},
			{ 27.784786, 10.197294, 4.158730, 28.384785, 10.197294, 2.358727, 28.384785, 10.197294, 2.358727,
					28.384785, 10.197294, -2.141273, 28.384785, 10.197294, -2.141273, 27.784786, 10.197294,
					-2.741272, 27.784786, 10.197294, -2.741272, 19.684784, 10.197294, -4.241272, 19.684784,
					10.197294, -4.241272, 19.684784, 10.197294, 4.158730, 19.684784, 10.197294, 4.158730,
					27.784786, 10.197294, 4.158730},
			{ 22.384785, 14.997294, -71.741272, 19.084785, 16.597294, -74.741272, 19.084785, 16.597294,
					-74.741272, 18.184784, 15.997294, -73.541275, 18.184784, 15.997294, -73.541275, 17.884785,
					14.997294, -72.341278, 17.884785, 14.997294, -72.341278, 17.584785, 14.997294, -70.841278,
					17.584785, 14.997294, -70.841278, 22.084785, 14.997294, -70.541275, 22.084785, 14.997294,
					-70.541275, 22.384785, 14.997294, -71.741272},
			{ 4.684784, 10.197294, -6.941269, 1.984785, 10.197294, -8.441269, 1.984785, 10.197294, -8.441269,
					-4.015217, 10.197294, -6.941269, -4.015217, 10.197294, -6.941269, -1.615215, 10.197294,
					-1.541275, -1.615215, 10.197294, -1.541275, 1.384785, 10.197294, 1.458725, 1.384785,
					10.197294, 1.458725, 7.984783, 10.197294, -2.441269, 7.984783, 10.197294, -2.441269,
					4.684784, 10.197294, -6.941269},
			{ -22.315216, 6.597294, -17.141273, -23.815216, 5.397294, -13.841270, -23.815216, 5.397294,
					-13.841270, -24.115217, 4.997294, -12.041275, -24.115217, 4.997294, -12.041275, -22.315216,
					4.997294, -11.441269, -22.315216, 4.997294, -11.441269, -17.815216, 5.197294, -11.441269,
					-17.815216, 5.197294, -11.441269, -22.315216, 6.597294, -17.141273} };
	long[][] refs = { { 281474976710695L, 0L, 0L},
			{ 0L, 281474976710770L, 0L, 281474976710769L, 281474976710772L, 0L},
			{ 281474976710683L, 281474976710674L, 0L, 281474976710679L, 281474976710684L, 0L},
			{ 281474976710750L, 281474976710748L, 0L, 0L, 281474976710755L, 281474976710756L},
			{ 0L, 0L, 0L, 281474976710735L, 281474976710736L} };

	public function testFindDistanceToWall():void {
		var filter:QueryFilter= new QueryFilter();
		for (var i:int= 0; i < startRefs.length; i++) {
			var segments:GetPolyWallSegmentsResult= query.getPolyWallSegments(startRefs[i], filter);
			Assert.assertEquals(vertices[i].length, segments.getSegmentVerts().size() * 6);
			Assert.assertEquals(refs[i].length, segments.getSegmentRefs().size());
			for (var v:int= 0; v < vertices[i].length / 6; v++) {
				for (var n:int= 0; n < 6; n++) {
					Assert.assertEquals(vertices[i][v * 6+ n], segments.getSegmentVerts().get(v)[n], 0.001);
				}
			}
			for (var v:int= 0; v < refs[i].length; v++) {
				Assert.assertEquals(refs[i][v], segments.getSegmentRefs().get(v).longValue());
			}
		}

	}
}
}
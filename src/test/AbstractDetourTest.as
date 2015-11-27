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
import flash.display.Sprite;
import org.recast4j.detour.MeshData;
import org.recast4j.detour.NavMesh;
import org.recast4j.detour.NavMeshQuery;
import org.recast4j.detour.RecastNavMeshBuilder;
import test.ObjImporter;
import org.recast4j.recast.PartitionType;

public  class AbstractDetourTest extends Sprite{

	protected var startRefs:Array= [ 281474976710696, 281474976710773, 281474976710680, 281474976710753,
			281474976710733];
	//protected var startRefs:Array= [ 0x1000028, 0x1000075,0x1000018,0x1000061,0x100004d]
	protected var endRefs:Array= [ 281474976710721, 281474976710767, 281474976710758, 281474976710731,
			281474976710772];
	//protected var endRefs:Array= [0x1000041,0x100006f,0x1000066 ,0x100004b,0x1000074]
	protected var startPoss:Array = [ [ 22.60652, 10.197294, -45.918674],
			[ 22.331268, 10.197294, -1.0401875], [ 18.694363, 15.803535, -73.090416],
			[ 0.7453353, 10.197294, -5.94005], [ -20.651257, 5.904126, -13.712508] ];

	protected var endPoss:Array = [ [ 6.4576626, 10.197294, -18.33406], [ -5.8023443, 0.19729415, 3.008419],
			[ 38.423977, 10.197294, -0.116066754], [ 0.8635526, 10.197294, -10.31032],
			[ 18.784092, 10.197294, 3.0543678] ];

	protected var nmd:MeshData;
	protected var query:NavMeshQuery;
	protected var navmesh:NavMesh;

	public function setUp():void {
		var dugeon:String = getOBJ("dungeon.obj");
		
		
		nmd = new RecastNavMeshBuilder(new ObjImporter().load(dugeon), PartitionType.WATERSHED,
				0.3, 0.2, 2.0, 0.6, 0.9, 45.0, 8, 20, 12.0, 1.3, 6, 6.0, 1.0).getMeshData();
		navmesh = new NavMesh();
		navmesh.init2(nmd, 0);
		query = new NavMeshQuery(navmesh);

	}
	
	public static function getOBJ(name:String):String {
		[Embed(source="dungeon.obj", mimeType="application/octet-stream")]var c1:Class;
		[Embed(source="nav_test.obj", mimeType="application/octet-stream")]var c2:Class;
		switch(name){
			case "dungeon.obj":
				return new c1 + "";
			case "nav_test.obj":
				return new c2 +"";
		}
		return null;
	}
	
	public function assertEquals(a:Number, b:Number, d:Number = 0,name:String=null):void {
		trace();
		trace(Math.abs(a - b) <= d, a, b, d);
		if (name) trace(name);
	}
	public function assertEquals2(name:String,a:Number, b:Number, d:Number = 0):void {
		assertEquals(a, b, d, name);
	}
	public function assertTrue(v:Boolean):void {
		trace();
		trace(v);
	}
	
	public function assertNotNull(v:Object):void {
		trace();
		trace(v!=null);
	}

}
}
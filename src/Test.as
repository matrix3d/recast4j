package 
{
	import flash.display.Sprite;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import org.recast4j.detour.FindNearestPolyResult;
	import org.recast4j.detour.io.MeshReader;
	import org.recast4j.detour.NavMesh;
	import org.recast4j.detour.NavMeshParams;
	import org.recast4j.detour.NavMeshQuery;
	import org.recast4j.detour.QueryFilter;
	import org.recast4j.detour.VectorPtr;
	/**
	 * ...
	 * @author lizhi
	 */
	public class Test extends Sprite
	{
		private var query:NavMeshQuery;
		
		public function Test() 
		{
			[Embed(source = "test/all_tiles_navmesh.bin", mimeType = "application/octet-stream")]var c:Class;
			
			var navmesh:NavMesh = new NavMesh;
			
			var b:ByteArray = new c as ByteArray;
			b.endian = Endian.LITTLE_ENDIAN;
			var magic:int = b.readInt();
			var version:int = b.readInt();
			var numTiles:int = b.readInt();
			var x:Number = b.readFloat();
			var y:Number = b.readFloat();
			var z:Number = b.readFloat();
			var tileWidth:Number = b.readFloat();
			var tileHeight:Number = b.readFloat();
			var maxTiles:Number = b.readInt();
			var maxPolys:Number = b.readInt();
			
			var params:NavMeshParams = new NavMeshParams;
			params.orig = [x, y, z];
			params.tileWidth = tileWidth;
			params.tileHeight = tileHeight;
			params.maxTiles = maxTiles;
			params.maxPolys = maxPolys;
			navmesh.init(params);
			
			for (var i:int = 0; i < numTiles; i++ ) {
				var ref:int = b.readInt();
				var size:int = b.readInt();
				var p:int = b.position + size;
				var reader:MeshReader = new MeshReader;
				navmesh.addTile(reader.read(b),1,ref);
				b.position = p;
			}
			
			query = new NavMeshQuery(navmesh);
			
			
			trace(getHeight(30, 0, 0));
		}
		
		public function getHeight(x:Number,y:Number,z:Number):Number{
			
			var p:Array = [x,y,z];
			
			var result:FindNearestPolyResult=query.findNearestPoly(p, [2,4,2],new QueryFilter);
			
			if (result.getNearestRef()) {
				return query.getPolyHeight(result.getNearestRef(),new VectorPtr(p));
			}
			
			return 0;
		}
		
	}

}
package 
{
	import flash.display.Sprite;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import org.recast4j.detour.io.MeshReader;
	import org.recast4j.detour.NavMesh;
	/**
	 * ...
	 * @author lizhi
	 */
	public class Test extends Sprite
	{
		
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
			
			for (var i:int = 0; i < numTiles; i++ ) {
				var ref:int = b.readInt();
				var size:int = b.readInt();
				var p:int = b.position + size;
				var reader:MeshReader = new MeshReader;
				reader.read(b);
				b.position = p;
			}
		}
		
	}

}
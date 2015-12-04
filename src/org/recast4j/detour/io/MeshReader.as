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
package org.recast4j.detour.io {
import flash.utils.ByteArray;
import flash.utils.Endian;
import org.recast4j.detour.Link;

import org.recast4j.detour.BVNode;
import org.recast4j.detour.MeshHeader;
import org.recast4j.detour.MeshData;
import org.recast4j.detour.OffMeshConnection;
import org.recast4j.detour.Poly;
import org.recast4j.detour.PolyDetail;

public class MeshReader {

	// C++ object sizeof
	public static var DT_POLY_DETAIL_SIZE:int= 10;

	public function read(buf:ByteArray):MeshData {
		
		buf.endian = Endian.LITTLE_ENDIAN;
		var data:MeshData= new MeshData();
		var header:MeshHeader= new MeshHeader();
		data.header = header;
		header.magic = buf.readInt();
		if (header.magic != MeshHeader.DT_NAVMESH_MAGIC) {
			trace( "Invalid magic");
		}
		header.version = buf.readInt();
		if (header.version != MeshHeader.DT_NAVMESH_VERSION) {
			trace ("Invalid version");
		}
		header.x = buf.readInt();
		header.y = buf.readInt();
		header.layer = buf.readInt();
		header.userId = buf.readInt();
		header.polyCount = buf.readInt();
		header.vertCount = buf.readInt();
		header.maxLinkCount = buf.readInt();
		header.detailMeshCount = buf.readInt();
		header.detailVertCount = buf.readInt();
		header.detailTriCount = buf.readInt();
		header.bvNodeCount = buf.readInt();
		header.offMeshConCount = buf.readInt();
		header.offMeshBase = buf.readInt();
		header.walkableHeight = buf.readFloat();
		header.walkableRadius = buf.readFloat();
		header.walkableClimb = buf.readFloat();
		for (var j:int= 0; j < 3; j++) {
			header.bmin[j] = buf.readFloat();
		}
		for (j= 0; j < 3; j++) {
			header.bmax[j] = buf.readFloat();
		}
		header.bvQuantFactor = buf.readFloat();
		data.verts = readVerts(buf, header.vertCount);
		data.polys = readPolys(buf, header);
		data.links = readLinks(buf, header);
		data.detailMeshes = readPolyDetails(buf, header);
		//align4(buf, header.detailMeshCount * DT_POLY_DETAIL_SIZE);
		data.detailVerts = readVerts(buf, header.detailVertCount);
		data.detailTris = readDTris(buf, header);
		data.bvTree = readBVTree(buf, header);
		data.offMeshCons = readOffMeshCons(buf, header);
		return data;
	}

	private function readVerts( buf:ByteArray,  count:int):Array {
		var verts:Array = [];// new float[count * 3];
		for (var i:int= 0; i < count*3; i++) {
			verts[i] = buf.readFloat();
		}
		return verts;
	}

	private function readPolys(buf:ByteArray,  header:MeshHeader):Array {
		var polys:Array = [];// new Poly[header.polyCount];
		for (var i:int= 0; i < header.polyCount; i++) {
			polys[i] = new Poly(i);
			polys[i].firstLink = buf.readInt();
			for (var j:int= 0; j < polys[i].verts.length; j++) {
				polys[i].verts[j] = buf.readUnsignedShort() ;
			}
			for (j= 0; j < polys[i].neis.length; j++) {
				polys[i].neis[j] = buf.readUnsignedShort() ;
			}
			polys[i].flags = buf.readUnsignedShort() ;
			polys[i].vertCount = buf.readUnsignedByte() ;
			polys[i].areaAndtype = buf.readUnsignedByte() ;
		}
		return polys;
	}
	
	private function readLinks(buf:ByteArray,  header:MeshHeader):Array {
		var links:Array = [];// new Poly[header.polyCount];
		for (var i:int= 0; i < header.maxLinkCount; i++) {
			var link:Link = links[i] = new Link;
			link.ref = buf.readInt();
			link.next = buf.readInt();
			link.edge = buf.readUnsignedByte();
			link.side = buf.readUnsignedByte();
			link.bmin = buf.readUnsignedByte();
			link.bmax = buf.readUnsignedByte();
			
		}
		return links;
	}
	
	private function readPolyDetails( buf:ByteArray,  header:MeshHeader):Array {
		var polys:Array = [];// new PolyDetail[header.detailMeshCount];
		for (var i:int= 0; i < header.detailMeshCount; i++) {
			polys[i] = new PolyDetail();
			polys[i].vertBase = buf.readInt();
			polys[i].triBase = buf.readInt();
			polys[i].vertCount = buf.readUnsignedByte();
			polys[i].triCount = buf.readUnsignedByte();
			buf.readShort();
		}
		return polys;
	}

	private function readDTris(buf:ByteArray, header:MeshHeader):Array {
		var tris:Array= []//4* header.detailTriCount];
		for (var i:int= 0; i < 4*header.detailTriCount; i++) {
			tris[i] = buf.readUnsignedByte() ;
		}
		return tris;
	}

	private function readBVTree(buf:ByteArray, header:MeshHeader):Array {
		var nodes:Array= []//new BVNode[header.bvNodeCount];
		for (var i:int = 0; i < header.bvNodeCount; i++) {
			nodes[i] = new BVNode();
			for (var j:int= 0; j < 3; j++) {
				nodes[i].bmin[j] = buf.readUnsignedShort();
			}
			for (j= 0; j < 3; j++) {
				nodes[i].bmax[j] = buf.readUnsignedShort();
			}
			nodes[i].i = buf.readInt();
		}
		return nodes;
	}

	private function readOffMeshCons( buf:ByteArray, header:MeshHeader):Array {
		var cons:Array= []//new OffMeshConnection[header.offMeshConCount];
		for (var i:int= 0; i < header.offMeshConCount; i++) {
			cons[i] = new OffMeshConnection();
			for (var j:int= 0; j < 6; j++) {
				cons[i].pos[j] = buf.readFloat();
			}
			cons[i].rad = buf.readFloat();
			cons[i].poly = buf.readUnsignedShort();
			cons[i].flags = buf.readUnsignedByte();
			cons[i].side = buf.readUnsignedByte();
			cons[i].userId = buf.readInt();
		}
		return cons;
	}

	private function align4(buf:ByteArray, size:int):void {
		var toSkip:int= ((size + 3) & ~3) - size;
		for (var i:int= 0; i < toSkip; i++) {
			buf.readUnsignedByte();
		}
	}

}
}
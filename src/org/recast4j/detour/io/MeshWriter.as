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

import org.recast4j.detour.MeshData;
import org.recast4j.detour.MeshHeader;

public class MeshWriter {

	public function write(stream:ByteArray, data:MeshData):void {
		stream.endian = Endian.LITTLE_ENDIAN;
		var header:MeshHeader= data.header;
		writeInt(stream, header.magic);
		writeInt(stream, header.version);
		writeInt(stream, header.x);
		writeInt(stream, header.y);
		writeInt(stream, header.layer);
		writeInt(stream, header.userId);
		writeInt(stream, header.polyCount);
		writeInt(stream, header.vertCount);
		writeInt(stream, header.maxLinkCount);
		writeInt(stream, header.detailMeshCount);
		writeInt(stream, header.detailVertCount);
		writeInt(stream, header.detailTriCount);
		writeInt(stream, header.bvNodeCount);
		writeInt(stream, header.offMeshConCount);
		writeInt(stream, header.offMeshBase);
		writeInt(stream, header.walkableHeight);
		writeInt(stream, header.walkableRadius);
		writeInt(stream, header.walkableClimb);
		writeFloat(stream, header.bmin[0]);
		writeFloat(stream, header.bmin[1]);
		writeFloat(stream, header.bmin[2]);
		writeFloat(stream, header.bmax[0]);
		writeFloat(stream, header.bmax[1]);
		writeFloat(stream, header.bmax[2]);
		writeFloat(stream, header.bvQuantFactor);
		writeVerts(stream, data.verts, header.vertCount);
		writePolys(stream, data);
		writePolyDetails(stream, data);
		align4(stream, data.header.detailMeshCount * MeshReader.DT_POLY_DETAIL_SIZE);
		writeVerts(stream, data.detailVerts, header.detailVertCount);
		writeDTris(stream, data);
		writeBVTree(stream, data);
		writeOffMeshCons(stream, data);
	}

	private function writeFloat(stream:ByteArray, value:Number):void {
		stream.writeFloat(value);
	}

	private function writeShort(stream:ByteArray, value:Number):void {
		stream.writeShort(value);
	}

	private function writeInt(stream:ByteArray, value:int):void {
		stream.writeInt(value);
	}

	private function writeVerts(stream:ByteArray, verts:Array, count:int):void {
		for (var i:int= 0; i < count * 3; i++) {
			writeFloat(stream, verts[i]);
		}
	}

	private function writePolys(stream:ByteArray, data:MeshData):void {
		for (var i:int= 0; i < data.header.polyCount; i++) {
			writeInt(stream, data.polys[i].firstLink);
			for (var j:int= 0; j < data.polys[i].verts.length; j++) {
				writeShort(stream, (data.polys[i].verts[j]));
			}
			for (j= 0; j < data.polys[i].neis.length; j++) {
				writeShort(stream, (data.polys[i].neis[j]));
			}
			writeShort(stream, (data.polys[i].flags));
			stream.writeByte(data.polys[i].vertCount);
			stream.writeByte(data.polys[i].areaAndtype);
		}
	}

	private function writePolyDetails(stream:ByteArray, data:MeshData):void {
		for (var i:int= 0; i < data.header.detailMeshCount; i++) {
			writeInt(stream, data.detailMeshes[i].vertBase);
			writeInt(stream, data.detailMeshes[i].triBase);
			stream.writeByte(data.detailMeshes[i].vertCount);
			stream.writeByte(data.detailMeshes[i].triCount);
		}
	}

	private function writeDTris(stream:ByteArray, data:MeshData):void {
		for (var i:int= 0; i < data.header.detailTriCount * 4; i++) {
			stream.writeByte(data.detailTris[i]);
		}
	}

	private function writeBVTree(stream:ByteArray, data:MeshData):void {
		for (var i:int= 0; i < data.header.bvNodeCount; i++) {
			for (var j:int= 0; j < 3; j++) {
				writeShort(stream, (data.bvTree[i].bmin[j]));
			}
			for (j= 0; j < 3; j++) {
				writeShort(stream, (data.bvTree[i].bmax[j]));
			}
			writeInt(stream, data.bvTree[i].i);
		}
	}

	private function writeOffMeshCons(stream:ByteArray, data:MeshData):void {
		for (var i:int= 0; i < data.header.offMeshConCount; i++) {
			for (var j:int= 0; j < 6; j++) {
				writeFloat(stream, data.offMeshCons[i].pos[j]);
			}
			writeFloat(stream, data.offMeshCons[i].rad);
			writeShort(stream, (data.offMeshCons[i].poly));
			stream.writeByte(data.offMeshCons[i].flags);
			stream.writeByte(data.offMeshCons[i].side);
			writeInt(stream, data.offMeshCons[i].userId);
		}
	}

	private function align4(stream:ByteArray, size:int):void {
		var toSkip:int= ((size + 3) & ~3) - size;
		for (var i:int= 0; i < toSkip; i++) {
			stream.writeByte(0);
		}
	}
}
}
package org.recast4j.detour.io {
import static org.junit.Assert.assertEquals;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

import org.junit.Before;
import org.junit.Test;
import org.recast4j.detour.MeshData;
import org.recast4j.detour.RecastNavMeshBuilder;

public class MeshReaderWriterTest {

	private var meshData:MeshData;

	public function setUp():void {
		var rcBuilder:RecastNavMeshBuilder= new RecastNavMeshBuilder();
		meshData = rcBuilder.getMeshData();
		//meshData.offMeshCons
	}

	public function test():void {
		var os:ByteArrayOutputStream= new ByteArrayOutputStream();
		var writer:MeshWriter= new MeshWriter();
		writer.write(os, meshData);
		var bais:ByteArrayInputStream= new ByteArrayInputStream(os.toByteArray());
		var reader:MeshReader= new MeshReader();
		var readData:MeshData= reader.read(bais);
		
		System.out.println("verts: " + meshData.header.vertCount);
		System.out.println("polys: " + meshData.header.polyCount);
		System.out.println("detail vert: " + meshData.header.detailVertCount);
		System.out.println("detail mesh: " + meshData.header.detailMeshCount);
		assertEquals(meshData.header.vertCount, readData.header.vertCount);
		assertEquals(meshData.header.polyCount, readData.header.polyCount);
		assertEquals(meshData.header.detailMeshCount, readData.header.detailMeshCount);
		assertEquals(meshData.header.detailTriCount, readData.header.detailTriCount);
		assertEquals(meshData.header.detailVertCount, readData.header.detailVertCount);
		assertEquals(meshData.header.bvNodeCount, readData.header.bvNodeCount);
		assertEquals(meshData.header.offMeshConCount, readData.header.offMeshConCount);
		for (var i:int= 0; i < meshData.header.vertCount; i++) {
			assertEquals(meshData.verts[i], readData.verts[i], 0.0);
		}
		for (var i:int= 0; i < meshData.header.polyCount; i++) {
			assertEquals(meshData.polys[i].firstLink, readData.polys[i].firstLink);
			assertEquals(meshData.polys[i].vertCount, readData.polys[i].vertCount);
			assertEquals(meshData.polys[i].areaAndtype, readData.polys[i].areaAndtype);
			for (var j:int= 0; j < meshData.polys[i].vertCount; j++) {
				assertEquals(meshData.polys[i].verts[j], readData.polys[i].verts[j]);
				assertEquals(meshData.polys[i].neis[j], readData.polys[i].neis[j]);
			}
		}
		for (var i:int= 0; i < meshData.header.detailMeshCount; i++) {
			assertEquals(meshData.detailMeshes[i].vertBase, readData.detailMeshes[i].vertBase);
			assertEquals(meshData.detailMeshes[i].vertCount, readData.detailMeshes[i].vertCount);
			assertEquals(meshData.detailMeshes[i].triBase, readData.detailMeshes[i].triBase);
			assertEquals(meshData.detailMeshes[i].triCount, readData.detailMeshes[i].triCount);
		}
		for (var i:int= 0; i < meshData.header.detailVertCount; i++) {
			assertEquals(meshData.detailVerts[i], readData.detailVerts[i], 0.0);
		}
		for (var i:int= 0; i < meshData.header.detailTriCount; i++) {
			assertEquals(meshData.detailTris[i], readData.detailTris[i]);
		}
		for (var i:int= 0; i < meshData.header.bvNodeCount; i++) {
			assertEquals(meshData.bvTree[i].i, readData.bvTree[i].i);
			for (var j:int= 0; j < 3; j++) {
				assertEquals(meshData.bvTree[i].bmin[j], readData.bvTree[i].bmin[j]);
				assertEquals(meshData.bvTree[i].bmax[j], readData.bvTree[i].bmax[j]);
			}
		}
		for (var i:int= 0; i < meshData.header.offMeshConCount; i++) {
			assertEquals(meshData.offMeshCons[i].flags, readData.offMeshCons[i].flags);
			assertEquals(meshData.offMeshCons[i].rad, readData.offMeshCons[i].rad, 0.0);
			assertEquals(meshData.offMeshCons[i].poly, readData.offMeshCons[i].poly);
			assertEquals(meshData.offMeshCons[i].side, readData.offMeshCons[i].side);
			assertEquals(meshData.offMeshCons[i].userId, readData.offMeshCons[i].userId);
			for (var j:int= 0; j < 6; j++) {
				assertEquals(meshData.offMeshCons[i].pos[j], readData.offMeshCons[i].pos[j], 0.0);
			}
		}
	}
}
}
package test {
import flash.utils.ByteArray;
import org.recast4j.detour.io.MeshReader;
import org.recast4j.detour.io.MeshWriter;
import org.recast4j.detour.MeshData;
import org.recast4j.detour.RecastNavMeshBuilder;

public class MeshReaderWriterTest extends AbstractDetourTest{

	private var meshData:MeshData;

	public function MeshReaderWriterTest() 
	{
		setUp();
		meshData = nmd;
		test();
	}
	//public function setUp():void {
		//var rcBuilder:RecastNavMeshBuilder= new RecastNavMeshBuilder();
		//meshData = rcBuilder.getMeshData();
		//meshData.offMeshCons
	//}

	public function test():void {
		var writer:MeshWriter= new MeshWriter();
		var bais:ByteArray = new ByteArray;
		writer.write(bais, meshData);
		bais.position = 0;
		var reader:MeshReader= new MeshReader();
		var readData:MeshData= reader.read(bais);
		
		trace("verts: " + meshData.header.vertCount);
		trace("polys: " + meshData.header.polyCount);
		trace("detail vert: " + meshData.header.detailVertCount);
		trace("detail mesh: " + meshData.header.detailMeshCount);
		assertEquals(meshData.header.vertCount, readData.header.vertCount);
		assertEquals(meshData.header.polyCount, readData.header.polyCount);
		assertEquals(meshData.header.detailMeshCount, readData.header.detailMeshCount);
		assertEquals(meshData.header.detailTriCount, readData.header.detailTriCount);
		assertEquals(meshData.header.detailVertCount, readData.header.detailVertCount);
		assertEquals(meshData.header.bvNodeCount, readData.header.bvNodeCount);
		assertEquals(meshData.header.offMeshConCount, readData.header.offMeshConCount);
		for (var i:int= 0; i < meshData.header.vertCount; i++) {
			assertEquals(meshData.verts[i], readData.verts[i], 0.01);
		}
		for (i= 0; i < meshData.header.polyCount; i++) {
			assertEquals(meshData.polys[i].firstLink, readData.polys[i].firstLink);
			assertEquals(meshData.polys[i].vertCount, readData.polys[i].vertCount);
			assertEquals(meshData.polys[i].areaAndtype, readData.polys[i].areaAndtype);
			for (var j:int= 0; j < meshData.polys[i].vertCount; j++) {
				assertEquals(meshData.polys[i].verts[j], readData.polys[i].verts[j]);
				assertEquals(meshData.polys[i].neis[j], readData.polys[i].neis[j]);
			}
		}
		for (i= 0; i < meshData.header.detailMeshCount; i++) {
			assertEquals(meshData.detailMeshes[i].vertBase, readData.detailMeshes[i].vertBase);
			assertEquals(meshData.detailMeshes[i].vertCount, readData.detailMeshes[i].vertCount);
			assertEquals(meshData.detailMeshes[i].triBase, readData.detailMeshes[i].triBase);
			assertEquals(meshData.detailMeshes[i].triCount, readData.detailMeshes[i].triCount);
		}
		for (i= 0; i < meshData.header.detailVertCount; i++) {
			assertEquals(meshData.detailVerts[i], readData.detailVerts[i], 0.01);
		}
		for (i= 0; i < meshData.header.detailTriCount; i++) {
			assertEquals(meshData.detailTris[i], readData.detailTris[i]);
		}
		for (i= 0; i < meshData.header.bvNodeCount; i++) {
			assertEquals(meshData.bvTree[i].i, readData.bvTree[i].i);
			for (j= 0; j < 3; j++) {
				assertEquals(meshData.bvTree[i].bmin[j], readData.bvTree[i].bmin[j]);
				assertEquals(meshData.bvTree[i].bmax[j], readData.bvTree[i].bmax[j]);
			}
		}
		for (i= 0; i < meshData.header.offMeshConCount; i++) {
			assertEquals(meshData.offMeshCons[i].flags, readData.offMeshCons[i].flags);
			assertEquals(meshData.offMeshCons[i].rad, readData.offMeshCons[i].rad, 0.01);
			assertEquals(meshData.offMeshCons[i].poly, readData.offMeshCons[i].poly);
			assertEquals(meshData.offMeshCons[i].side, readData.offMeshCons[i].side);
			assertEquals(meshData.offMeshCons[i].userId, readData.offMeshCons[i].userId);
			for (j= 0; j < 6; j++) {
				assertEquals(meshData.offMeshCons[i].pos[j], readData.offMeshCons[i].pos[j], 0.01);
			}
		}
	}
}
}
package org.recast4j.detour {
import org.recast4j.recast.InputGeom;
import test.ObjImporter;
import org.recast4j.recast.PartitionType;
import org.recast4j.recast.PolyMesh;
import org.recast4j.recast.PolyMeshDetail;
import org.recast4j.recast.RecastBuilder;
import org.recast4j.recast.PartitionType;

public class RecastNavMeshBuilder {

	private var meshData:MeshData;
	public var m_dmesh:PolyMeshDetail;
	/*public function RecastNavMeshBuilder() {
		this(new ObjImporter().load("dungeon.obj"), PartitionType.WATERSHED,
				0.3, 0.2, 2.0, 0.6, 0.9, 45.0, 8, 20, 12.0, 1.3, 6, 6.0, 1.0);
	}*/

	public function RecastNavMeshBuilder(m_geom:InputGeom, m_partitionType:int, m_cellSize:Number, m_cellHeight:Number,
			m_agentHeight:Number, m_agentRadius:Number, m_agentMaxClimb:Number, m_agentMaxSlope:Number, m_regionMinSize:int,
			m_regionMergeSize:int, m_edgeMaxLen:Number, m_edgeMaxError:Number, m_vertsPerPoly:int,
			m_detailSampleDist:Number, m_detailSampleMaxError:Number) {
		var rcBuilder:RecastBuilder= new RecastBuilder(m_geom, m_partitionType, m_cellSize, m_cellHeight, m_agentHeight, m_agentRadius, m_agentMaxClimb, m_agentMaxSlope, m_regionMinSize, m_regionMergeSize, m_edgeMaxLen, m_edgeMaxError, m_vertsPerPoly, m_detailSampleDist, m_detailSampleMaxError);
		rcBuilder.build();
		var m_pmesh:PolyMesh= rcBuilder.getMesh();
		for (var i:int= 0; i < m_pmesh.npolys; ++i) {
			m_pmesh.flags[i] = 1;
		}
		m_dmesh= rcBuilder.getMeshDetail();
		var params:NavMeshCreateParams= new NavMeshCreateParams();
		params.verts = m_pmesh.verts;
		params.vertCount = m_pmesh.nverts;
		params.polys = m_pmesh.polys;
		params.polyAreas = m_pmesh.areas;
		params.polyFlags = m_pmesh.flags;
		params.polyCount = m_pmesh.npolys;
		params.nvp = m_pmesh.nvp;
		params.detailMeshes = m_dmesh.meshes;
		params.detailVerts = m_dmesh.verts;
		params.detailVertsCount = m_dmesh.nverts;
		params.detailTris = m_dmesh.tris;
		params.detailTriCount = m_dmesh.ntris;
		params.walkableHeight = m_agentHeight;
		params.walkableRadius = m_agentRadius;
		params.walkableClimb = m_agentMaxClimb;
		params.bmin = m_pmesh.bmin;
		params.bmax = m_pmesh.bmax;
		params.cs = m_cellSize;
		params.ch = m_cellHeight;
		params.buildBvTree = true;
		
		params.offMeshConVerts = [];
		params.offMeshConVerts[0] = 0.1;
		params.offMeshConVerts[1] = 0.2;
		params.offMeshConVerts[2] = 0.3;
		params.offMeshConVerts[3] = 0.4;
		params.offMeshConVerts[4] = 0.5;
		params.offMeshConVerts[5] = 0.6;
		params.offMeshConRad = [];
		params.offMeshConRad[0] = 0.1;
		params.offMeshConDir = []//1];
		params.offMeshConDir[0] = 1;
		params.offMeshConAreas = []//1];
		params.offMeshConAreas[0] = 2;
		params.offMeshConFlags = []//1];
		params.offMeshConFlags[0] = 12;
		params.offMeshConUserID = []//1];
		params.offMeshConUserID[0] = 0x4567;
		params.offMeshConCount = 1;
		meshData = NavMeshBuilder.createNavMeshData(params);
	}

	public function getMeshData():MeshData {
		return meshData;
	}
}
}
package org.recast4j.recast {
import org.recast4j.recast.PartitionType;

public class RecastBuilder {

	private var m_geom:InputGeom;
	private var m_partitionType:int;// PartitionType;
	private var m_cellSize:Number;
	private var m_cellHeight:Number;
	private var m_agentHeight:Number;
	private var m_agentRadius:Number;
	private var m_agentMaxClimb:Number;
	private var m_agentMaxSlope:Number;
	private var m_regionMinSize:int;
	private var m_regionMergeSize:int;
	private var m_edgeMaxLen:Number;
	private var m_edgeMaxError:Number;
	private var m_vertsPerPoly:int;
	private var m_detailSampleDist:Number;
	private var m_detailSampleMaxError:Number;
	private var m_pmesh:PolyMesh;
	private var m_dmesh:PolyMeshDetail;

	public function RecastBuilder(m_geom:InputGeom, m_partitionType:int, m_cellSize:Number, m_cellHeight:Number,
			m_agentHeight:Number, m_agentRadius:Number, m_agentMaxClimb:Number, m_agentMaxSlope:Number, m_regionMinSize:int,
			m_regionMergeSize:int, m_edgeMaxLen:Number, m_edgeMaxError:Number, m_vertsPerPoly:int,
			m_detailSampleDist:Number, m_detailSampleMaxError:Number) {
		this.m_geom = m_geom;
		this.m_cellSize = m_cellSize;
		this.m_cellHeight = m_cellHeight;
		this.m_agentHeight = m_agentHeight;
		this.m_agentRadius = m_agentRadius;
		this.m_agentMaxClimb = m_agentMaxClimb;
		this.m_agentMaxSlope = m_agentMaxSlope;
		this.m_regionMinSize = m_regionMinSize;
		this.m_regionMergeSize = m_regionMergeSize;
		this.m_edgeMaxLen = m_edgeMaxLen;
		this.m_edgeMaxError = m_edgeMaxError;
		this.m_vertsPerPoly = m_vertsPerPoly;
		this.m_detailSampleDist = m_detailSampleDist;
		this.m_partitionType = m_partitionType;
		this.m_detailSampleMaxError = m_detailSampleMaxError;
	}

	public function build():void {
		var bmin:Array= m_geom.getMeshBoundsMin();
		var bmax:Array= m_geom.getMeshBoundsMax();
		var verts:Array= m_geom.getVerts();
		var nverts:int= verts.length / 3;
		var tris:Array= m_geom.getTris();
		var ntris:int= tris.length / 3;
		//
		// Step 1. Initialize build config.
		//

		// Init build configuration from GUI
		var m_cfg:RecastConfig= new RecastConfig();
		m_cfg.cs = m_cellSize;
		m_cfg.ch = m_cellHeight;
		m_cfg.walkableSlopeAngle = m_agentMaxSlope;
		m_cfg.walkableHeight = int(Math.ceil(m_agentHeight / m_cfg.ch));
		m_cfg.walkableClimb = int(Math.floor(m_agentMaxClimb / m_cfg.ch));
		m_cfg.walkableRadius = int(Math.ceil(m_agentRadius / m_cfg.cs));
		m_cfg.maxEdgeLen = int((m_edgeMaxLen / m_cellSize));
		m_cfg.maxSimplificationError = m_edgeMaxError;
		m_cfg.minRegionArea = m_regionMinSize * m_regionMinSize; // Note:
																	// area
																	// =
																	// size*size
		m_cfg.mergeRegionArea = m_regionMergeSize * m_regionMergeSize; // Note:
																		// area
																		// =
																		// size*size
		m_cfg.maxVertsPerPoly = m_vertsPerPoly;
		m_cfg.detailSampleDist = m_detailSampleDist < 0.9? 0: m_cellSize * m_detailSampleDist;
		m_cfg.detailSampleMaxError = m_cellHeight * m_detailSampleMaxError;

		// Set the area where the navigation will be build.
		// Here the bounds of the input mesh are used, but the
		// area could be specified by an user defined box, etc.
		m_cfg.bmin = bmin;
		m_cfg.bmax = bmax;

		var wh:Array= Recast.calcGridSize(m_cfg.bmin, m_cfg.bmax, m_cfg.cs);
		m_cfg.width = wh[0];
		m_cfg.height = wh[1];

		var m_ctx:Context= new Context();
		//
		// Step 2. Rasterize input polygon soup.
		//

		// Allocate voxel heightfield where we rasterize our input data to.
		var m_solid:Heightfield= new Heightfield(m_cfg.width, m_cfg.height, m_cfg.bmin, m_cfg.bmax, m_cfg.cs, m_cfg.ch);

		// Allocate array that can hold triangle area types.
		// If you have multiple meshes you need to process, allocate
		// and array which can hold the max number of triangles you need to
		// process.

		// Find triangles which are walkable based on their slope and rasterize
		// them.
		// If your input data is multiple meshes, you can transform them here,
		// calculate
		// the are type for each of the meshes and rasterize them.
		var m_triareas:Array= Recast.markWalkableTriangles(m_ctx, m_cfg.walkableSlopeAngle, verts, nverts, tris, ntris);
		RecastRasterization.rasterizeTriangles(m_ctx, verts, nverts, tris, m_triareas, ntris, m_solid,
				m_cfg.walkableClimb);
				//
				// Step 3. Filter walkables surfaces.
				//

		// Once all geometry is rasterized, we do initial pass of filtering to
		// remove unwanted overhangs caused by the conservative rasterization
		// as well as filter spans where the character cannot possibly stand.
		RecastFilter.filterLowHangingWalkableObstacles(m_ctx, m_cfg.walkableClimb, m_solid);
		RecastFilter.filterLedgeSpans(m_ctx, m_cfg.walkableHeight, m_cfg.walkableClimb, m_solid);
		RecastFilter.filterWalkableLowHeightSpans(m_ctx, m_cfg.walkableHeight, m_solid);

		//
		// Step 4. Partition walkable surface to simple regions.
		//

		// Compact the heightfield so that it is faster to handle from now on.
		// This will result more cache coherent data as well as the neighbours
		// between walkable cells will be calculated.
		var m_chf:CompactHeightfield= Recast.buildCompactHeightfield(m_ctx, m_cfg.walkableHeight, m_cfg.walkableClimb,
				m_solid);

		// Erode the walkable area by agent radius.
		RecastArea.erodeWalkableArea(m_ctx, m_cfg.walkableRadius, m_chf);

		// (Optional) Mark areas.
		/*
		 * ConvexVolume vols = m_geom->getConvexVolumes(); for (int i = 0; i < m_geom->getConvexVolumeCount(); ++i)
		 * rcMarkConvexPolyArea(m_ctx, vols[i].verts, vols[i].nverts, vols[i].hmin, vols[i].hmax, (unsigned
		 * char)vols[i].area, *m_chf);
		 */

		// Partition the heightfield so that we can use simple algorithm later
		// to triangulate the walkable areas.
		// There are 3 martitioning methods, each with some pros and cons:
		// 1) Watershed partitioning
		// - the classic Recast partitioning
		// - creates the nicest tessellation
		// - usually slowest
		// - partitions the heightfield into nice regions without holes or
		// overlaps
		// - the are some corner cases where this method creates produces holes
		// and overlaps
		// - holes may appear when a small obstacles is close to large open area
		// (triangulation can handle this)
		// - overlaps may occur if you have narrow spiral corridors (i.e
		// stairs), this make triangulation to fail
		// * generally the best choice if you precompute the nacmesh, use this
		// if you have large open areas
		// 2) Monotone partioning
		// - fastest
		// - partitions the heightfield into regions without holes and overlaps
		// (guaranteed)
		// - creates long thin polygons, which sometimes causes paths with
		// detours
		// * use this if you want fast navmesh generation
		// 3) Layer partitoining
		// - quite fast
		// - partitions the heighfield into non-overlapping regions
		// - relies on the triangulation code to cope with holes (thus slower
		// than monotone partitioning)
		// - produces better triangles than monotone partitioning
		// - does not have the corner cases of watershed partitioning
		// - can be slow and create a bit ugly tessellation (still better than
		// monotone)
		// if you have large open areas with small obstacles (not a problem if
		// you use tiles)
		// * good choice to use for tiled navmesh with medium and small sized
		// tiles

		if (m_partitionType == PartitionType.WATERSHED) {
			// Prepare for region partitioning, by calculating distance field
			// along the walkable surface.
			RecastRegion.buildDistanceField(m_ctx, m_chf);
			// Partition the walkable surface into simple regions without holes.
			RecastRegion.buildRegions(m_ctx, m_chf, 0, m_cfg.minRegionArea, m_cfg.mergeRegionArea);
		} else if (m_partitionType == PartitionType.MONOTONE) {
			// Partition the walkable surface into simple regions without holes.
			// Monotone partitioning does not need distancefield.
			RecastRegion.buildRegionsMonotone(m_ctx, m_chf, 0, m_cfg.minRegionArea, m_cfg.mergeRegionArea);
		} else {
			// Partition the walkable surface into simple regions without holes.
			RecastRegion.buildLayerRegions(m_ctx, m_chf, 0, m_cfg.minRegionArea);
		}

		//
		// Step 5. Trace and simplify region contours.
		//
		// Create contours.
		var m_cset:ContourSet= RecastContour.buildContours(m_ctx, m_chf, m_cfg.maxSimplificationError, m_cfg.maxEdgeLen,
				RecastConstants.RC_CONTOUR_TESS_WALL_EDGES);

		//
		// Step 6. Build polygons mesh from contours.
		//
		m_pmesh = RecastMesh.buildPolyMesh(m_ctx, m_cset, m_cfg.maxVertsPerPoly);

		//
		// Step 7. Create detail mesh which allows to access approximate height
		// on each polygon.
		//

		m_dmesh = RecastMeshDetail.buildPolyMeshDetail(m_ctx, m_pmesh, m_chf, m_cfg.detailSampleDist,
				m_cfg.detailSampleMaxError);

	}
	
	public function getMesh():PolyMesh {
		return m_pmesh;
	}

	public function getMeshDetail():PolyMeshDetail {
		return m_dmesh;
	}

}
}
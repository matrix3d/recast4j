package test {
import org.recast4j.recast.CompactHeightfield;
import org.recast4j.recast.Context;
import org.recast4j.recast.ContourSet;
import org.recast4j.recast.Heightfield;
import org.recast4j.recast.InputGeom;
import org.recast4j.recast.PartitionType;
import org.recast4j.recast.PolyMesh;
import org.recast4j.recast.PolyMeshDetail;
import org.recast4j.recast.Recast;
import org.recast4j.recast.RecastArea;
import org.recast4j.recast.RecastConfig;
import org.recast4j.recast.RecastConstants;
import org.recast4j.recast.RecastContour;
import org.recast4j.recast.RecastFilter;
import org.recast4j.recast.RecastMesh;
import org.recast4j.recast.RecastMeshDetail;
import org.recast4j.recast.RecastRasterization;
import org.recast4j.recast.RecastRegion;
import test.ObjImporter;


public class RecastSoloMeshTest extends AbstractDetourTest{

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
	private var m_vertsPerPoly:Number;
	private var m_detailSampleDist:Number;
	private var m_partitionType:int;
	private var m_detailSampleMaxError:Number;
	private var m_geom:InputGeom;

	public function resetCommonSettings():void {
		m_cellSize = 0.3;
		m_cellHeight = 0.2;
		m_agentHeight = 2.0;
		m_agentRadius = 0.6;
		m_agentMaxClimb = 0.9;
		m_agentMaxSlope = 45.0;
		m_regionMinSize = 8;
		m_regionMergeSize = 20;
		m_edgeMaxLen = 12.0;
		m_edgeMaxError = 1.3;
		m_vertsPerPoly = 6.0;
		m_detailSampleDist = 6.0;
		m_detailSampleMaxError = 1.0;
		m_partitionType = PartitionType.WATERSHED;
		
		
		var importer:ObjImporter = new ObjImporter();
		[Embed(source = "dungeon.obj", mimeType = "application/octet-stream")]var c:Class;
		m_geom= importer.load(new c +"");
	}

	public function RecastSoloMeshTest() 
	{
		testPerformance();
	}
	public function testPerformance():void {
		for (var i:int = 0; i < 1; i++) {
			trace("watershed");
			testBuild("dungeon.obj", PartitionType.WATERSHED, 52, 16, 15, 223, 118, 118, 512, 289);
			trace("monotone");
			testBuild("dungeon.obj", PartitionType.MONOTONE, 0, 17, 16, 210, 100, 100, 453, 264);
			trace("layers");
			testBuild("dungeon.obj", PartitionType.LAYERS, 0, 5, 5, 203, 97, 97, 447, 268);
		}
	}

	public function testDungeonWatershed():void {
		testBuild("dungeon.obj", PartitionType.WATERSHED, 52, 16, 15, 223, 118, 118, 512, 289);
	}

	public function testDungeonMonotone():void {
		testBuild("dungeon.obj", PartitionType.MONOTONE, 0, 17, 16, 210, 100, 100, 453, 264);
	}

	public function testDungeonLayers():void {
		testBuild("dungeon.obj", PartitionType.LAYERS, 0, 5, 5, 203, 97, 97, 447, 268);
	}

	public function testWatershed():void {
		testBuild("nav_test.obj", PartitionType.WATERSHED, 60, 48, 47, 349, 153, 153, 803, 560);
	}

	public function testMonotone():void {
		testBuild("nav_test.obj", PartitionType.MONOTONE, 0, 50, 49, 340, 185, 185, 873, 561);
	}

	public function testLayers():void {
		testBuild("nav_test.obj", PartitionType.LAYERS, 0, 19, 32, 312, 150, 150, 768, 529);
	}

	public function testBuild(filename:String, partitionType:int, expDistance:int, expRegions:int, expContours:int, expVerts:int,
			expPolys:int, expDetMeshes:int, expDetVerts:int, expDetTRis:int):void {
		resetCommonSettings();
		m_partitionType = partitionType;
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
		m_cfg.maxVertsPerPoly = int(m_vertsPerPoly);
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

		assertEquals2("maxDistance", expDistance, m_chf.maxDistance);
		assertEquals2("Regions", expRegions, m_chf.maxRegions);
		//
		// Step 5. Trace and simplify region contours.
		//

		// Create contours.
		var m_cset:ContourSet= RecastContour.buildContours(m_ctx, m_chf, m_cfg.maxSimplificationError, m_cfg.maxEdgeLen,
				RecastConstants.RC_CONTOUR_TESS_WALL_EDGES);

		assertEquals2("Contours", expContours, m_cset.conts.length);
		//
		// Step 6. Build polygons mesh from contours.
		//

		// Build polygon navmesh from the contours.
		var m_pmesh:PolyMesh= RecastMesh.buildPolyMesh(m_ctx, m_cset, m_cfg.maxVertsPerPoly);
		assertEquals2("Mesh Verts", expVerts, m_pmesh.nverts);
		assertEquals2("Mesh Polys", expPolys, m_pmesh.npolys);

		//
		// Step 7. Create detail mesh which allows to access approximate height
		// on each polygon.
		//

		var m_dmesh:PolyMeshDetail= RecastMeshDetail.buildPolyMeshDetail(m_ctx, m_pmesh, m_chf, m_cfg.detailSampleDist,
				m_cfg.detailSampleMaxError);
		assertEquals2("Mesh Detail Meshes", expDetMeshes, m_dmesh.nmeshes);
		assertEquals2("Mesh Detail Verts", expDetVerts, m_dmesh.nverts);
		assertEquals2("Mesh Detail Tris", expDetTRis, m_dmesh.ntris);
		//var time2:Number= System.nanoTime();
		//System.out.println(filename + " : " + partitionType + "  " + (time2 - time) / 1000000+ " ms" );
		//saveObj(filename.substring(0, filename.lastIndexOf('.')) + "_" + partitionType + ".obj", m_dmesh);
	}

	/*private function saveObj(filename:String, m_dmesh:PolyMeshDetail):void {
		try {
			var file:File= new File(filename);
			var fw:FileWriter= new FileWriter(file);
			for (var v:int= 0; v < m_dmesh.nverts; v++) {
				fw.write("v " + m_dmesh.verts[v * 3] + " " + m_dmesh.verts[v * 3+ 1] + " " + m_dmesh.verts[v * 3+ 2]
						+ "\n");
			}

			for (var m:int= 0; m < m_dmesh.nmeshes; m++) {
				var vfirst:int= m_dmesh.meshes[m * 4];
				var tfirst:int= m_dmesh.meshes[m * 4+ 2];
				for (var f:int= 0; f < m_dmesh.meshes[m * 4+ 3]; f++) {
					fw.write("f " + (vfirst + m_dmesh.tris[(tfirst + f) * 4] + 1) + " "
							+ (vfirst + m_dmesh.tris[(tfirst + f) * 4+ 1] + 1) + " "
							+ (vfirst + m_dmesh.tris[(tfirst + f) * 4+ 2] + 1) + "\n");
				}
			}
			fw.close();
		} catch (e:Exception) {
		}
	}*/
}
}
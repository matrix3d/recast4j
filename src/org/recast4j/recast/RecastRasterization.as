/*
Copyright (c) 2009-2010 Mikko Mononen memon@inside.org
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
package org.recast4j.recast {
public class RecastRasterization {

	private static function overlapBounds(amin:Array, amax:Array, bmin:Array, bmax:Array):Boolean {
		var overlap:Boolean= true;
		overlap = (amin[0] > bmax[0] || amax[0] < bmin[0]) ? false : overlap;
		overlap = (amin[1] > bmax[1] || amax[1] < bmin[1]) ? false : overlap;
		overlap = (amin[2] > bmax[2] || amax[2] < bmin[2]) ? false : overlap;
		return overlap;
	}

	/**
	 * The span addition can be set to favor flags. If the span is merged to another span and the new 'smax' is
	 * within 'flagMergeThr' units from the existing span, the span flags are merged.
	 * 
	 * @see Heightfield, Span.
	 */
	private static function addSpan(hf:Heightfield, x:int, y:int, smin:int, smax:int, area:int, flagMergeThr:int):void {

		var idx:int= x + y * hf.width;

		var s:Span= new Span();
		s.smin = smin;
		s.smax = smax;
		s.area = area;
		s.next = null;

		// Empty cell, add the first span.
		if (hf.spans[idx] == null) {
			hf.spans[idx] = s;
			return;
		}
		var prev:Span= null;
		var cur:Span= hf.spans[idx];

		// Insert and merge spans.
		while (cur != null) {
			if (cur.smin > s.smax) {
				// Current span is further than the new span, break.
				break;
			} else if (cur.smax < s.smin) {
				// Current span is before the new span advance.
				prev = cur;
				cur = cur.next;
			} else {
				// Merge spans.
				if (cur.smin < s.smin)
					s.smin = cur.smin;
				if (cur.smax > s.smax)
					s.smax = cur.smax;

				// Merge flags.
				if (Math.abs(s.smax - cur.smax) <= flagMergeThr)
					s.area = Math.max(s.area, cur.area);

				// Remove current span.
				var next:Span= cur.next;
				if (prev != null)
					prev.next = next;
				else
					hf.spans[idx] = next;
				cur = next;
			}
		}

		// Insert new span.
		if (prev != null) {
			s.next = prev.next;
			prev.next = s;
		} else {
			s.next = hf.spans[idx];
			hf.spans[idx] = s;
		}
	}

	//divides a convex polygons into two convex polygons on both sides of a line
	private static function dividePoly(buf:Array, in_:int, nin:int, out1:int, out2:int, x:Number, axis:int):Array {
		var d:Array = [];
		for (var i:int= 0; i < nin; ++i)
			d[i] = x - buf[in_ + i * 3+ axis];

		var m:int= 0, n:int = 0;
		var j:int;
		for (i= 0, j = nin - 1; i < nin; j = i, ++i) {
			var ina:Boolean= d[j] >= 0;
			var inb:Boolean= d[i] >= 0;
			if (ina != inb) {
				var s:Number= d[j] / (d[j] - d[i]);
				buf[out1 + m * 3+ 0] = buf[in_ + j * 3+ 0] + (buf[in_ + i * 3+ 0] - buf[in_ + j * 3+ 0]) * s;
				buf[out1 + m * 3+ 1] = buf[in_ + j * 3+ 1] + (buf[in_ + i * 3+ 1] - buf[in_ + j * 3+ 1]) * s;
				buf[out1 + m * 3+ 2] = buf[in_ + j * 3+ 2] + (buf[in_ + i * 3+ 2] - buf[in_ + j * 3+ 2]) * s;
				RecastVectors.copy2(buf, out2 + n * 3, buf, out1 + m * 3);
				m++;
				n++;
				// add the i'th point to the right polygon. Do NOT add points that are on the dividing line
				// since these were already added above
				if (d[i] > 0) {
					RecastVectors.copy2(buf, out1 + m * 3, buf, in_ + i * 3);
					m++;
				} else if (d[i] < 0) {
					RecastVectors.copy2(buf, out2 + n * 3, buf, in_ + i * 3);
					n++;
				}
			} else // same side
			{
				// add the i'th point to the right polygon. Addition is done even for points on the dividing line
				if (d[i] >= 0) {
					RecastVectors.copy2(buf, out1 + m * 3, buf, in_ + i * 3);
					m++;
					if (d[i] != 0)
						continue;
				}
				RecastVectors.copy2(buf, out2 + n * 3, buf, in_ + i * 3);
				n++;
			}
		}
		return [ m, n ];
	}

	private static function rasterizeTri(verts:Array, v0:int, v1:int, v2:int, area:int, hf:Heightfield, bmin:Array,
			bmax:Array, cs:Number, ics:Number, ich:Number, flagMergeThr:int):void {
		var w:int= hf.width;
		var h:int= hf.height;
		var tmin:Array = [];
		var tmax:Array = [];
		var by:Number= bmax[1] - bmin[1];

		// Calculate the bounding box of the triangle.
		RecastVectors.copy(tmin, verts, v0 * 3);
		RecastVectors.copy(tmax, verts, v0 * 3);
		RecastVectors.min(tmin, verts, v1 * 3);
		RecastVectors.min(tmin, verts, v2 * 3);
		RecastVectors.max(tmax, verts, v1 * 3);
		RecastVectors.max(tmax, verts, v2 * 3);

		// If the triangle does not touch the bbox of the heightfield, skip the triagle.
		if (!overlapBounds(bmin, bmax, tmin, tmax))
			return;

		// Calculate the footprint of the triangle on the grid's y-axis
		var y0:int= int(((tmin[2] - bmin[2]) * ics));
		var y1:int= int(((tmax[2] - bmin[2]) * ics));
		y0 = RecastCommon.clamp(y0, 0, h - 1);
		y1 = RecastCommon.clamp(y1, 0, h - 1);

		// Clip the triangle into all grid cells it touches.
		var buf:Array = [];
		var in_:int= 0;
		var inrow:int= 7* 3;
		var p1:int= inrow + 7* 3;
		var p2:int= p1 + 7* 3;

		RecastVectors.copy2(buf, 0, verts, v0 * 3);
		RecastVectors.copy2(buf, 3, verts, v1 * 3);
		RecastVectors.copy2(buf, 6, verts, v2 * 3);
		var nvrow:int, nvIn:int = 3;

		for (var y:int= y0; y <= y1; ++y) {
			// Clip polygon to row. Store the remaining polygon as well
			var cz:Number= bmin[2] + y * cs;
			var nvrowin:Array= dividePoly(buf, in_, nvIn, inrow, p1, cz + cs, 2);
			nvrow = nvrowin[0];
			nvIn = nvrowin[1];
			{
				var temp:int= in_;
				in_ = p1;
				p1 = temp;
			}
			if (nvrow < 3)
				continue;

			// find the horizontal bounds in the row
			var minX:Number= buf[inrow], maxX:Number = buf[inrow];
			for (var i:int= 1; i < nvrow; ++i) {
				if (minX > buf[inrow + i * 3])
					minX = buf[inrow + i * 3];
				if (maxX < buf[inrow + i * 3])
					maxX = buf[inrow + i * 3];
			}
			var x0:int= int(((minX - bmin[0]) * ics));
			var x1:int= int(((maxX - bmin[0]) * ics));
			x0 = RecastCommon.clamp(x0, 0, w - 1);
			x1 = RecastCommon.clamp(x1, 0, w - 1);

			var nv:int, nv2:int = nvrow;
			for (var x:int= x0; x <= x1; ++x) {
				// Clip polygon to column. store the remaining polygon as well
				var cx:Number= bmin[0] + x * cs;
				var nvnv2:Array= dividePoly(buf, inrow, nv2, p1, p2, cx + cs, 0);
				nv = nvnv2[0];
				nv2 = nvnv2[1];
				{
					temp= inrow;
					inrow = p2;
					p2 = temp;
				}
				if (nv < 3)
					continue;

				// Calculate min and max of the span.
				var smin:Number= buf[p1 + 1], smax:Number = buf[p1 + 1];
				for (i= 1; i < nv; ++i) {
					smin = Math.min(smin, buf[p1 + i * 3+ 1]);
					smax = Math.max(smax, buf[p1 + i * 3+ 1]);
				}
				smin -= bmin[1];
				smax -= bmin[1];
				// Skip the span if it is outside the heightfield bbox
				if (smax < 0.0)
					continue;
				if (smin > by)
					continue;
				// Clamp the span to the heightfield bbox.
				if (smin < 0.0)
					smin = 0;
				if (smax > by)
					smax = by;

				// Snap the span to the heightfield height grid.
				var ismin:int= RecastCommon.clamp(int(Math.floor(smin * ich)), 0, RecastConstants.RC_SPAN_MAX_HEIGHT);
				var ismax:int= RecastCommon.clamp(int(Math.ceil(smax * ich)), ismin + 1,
						RecastConstants.RC_SPAN_MAX_HEIGHT);

				addSpan(hf, x, y, ismin, ismax, area, flagMergeThr);
			}
		}
	}

	/**
	 * No spans will be added if the triangle does not overlap the heightfield grid.
	 * 
	 * @see Heightfield
	 */
	public static function rasterizeTriangle(ctx:Context, verts:Array, v0:int, v1:int, v2:int, area:int,
			solid:Heightfield, flagMergeThr:int):void {

		ctx.startTimer("RASTERIZE_TRIANGLES");

		var ics:Number= 1.0/ solid.cs;
		var ich:Number= 1.0/ solid.ch;
		rasterizeTri(verts, v0, v1, v2, area, solid, solid.bmin, solid.bmax, solid.cs, ics, ich, flagMergeThr);

		ctx.stopTimer("RASTERIZE_TRIANGLES");
	}

	/**
	 * Spans will only be added for triangles that overlap the heightfield grid.
	 * 
	 * @see Heightfield
	 */
	public static function rasterizeTriangles(ctx:Context, verts:Array, nv:int, tris:Array, areas:Array, nt:int,
			solid:Heightfield, flagMergeThr:int):void {

		ctx.startTimer("RASTERIZE_TRIANGLES");

		var ics:Number= 1.0/ solid.cs;
		var ich:Number= 1.0/ solid.ch;
		// Rasterize triangles.
		for (var i:int= 0; i < nt; ++i) {
			var v0:int= tris[i * 3+ 0];
			var v1:int= tris[i * 3+ 1];
			var v2:int= tris[i * 3+ 2];
			// Rasterize.
			rasterizeTri(verts, v0, v1, v2, areas[i], solid, solid.bmin, solid.bmax, solid.cs, ics, ich, flagMergeThr);
		}

		ctx.stopTimer("RASTERIZE_TRIANGLES");
	}

	/**
	 * Spans will only be added for triangles that overlap the heightfield grid.
	 * 
	 * @see Heightfield
	 */
	public static function rasterizeTriangles2(ctx:Context, verts:Array, areas:Array, nt:int, solid:Heightfield,
			flagMergeThr:int):void {
		ctx.startTimer("RASTERIZE_TRIANGLES");

		var ics:Number= 1.0/ solid.cs;
		var ich:Number= 1.0/ solid.ch;
		// Rasterize triangles.
		for (var i:int= 0; i < nt; ++i) {
			var v0:int= (i * 3+ 0);
			var v1:int= (i * 3+ 1);
			var v2:int= (i * 3+ 2);
			// Rasterize.
			rasterizeTri(verts, v0, v1, v2, areas[i], solid, solid.bmin, solid.bmax, solid.cs, ics, ich, flagMergeThr);
		}
		ctx.stopTimer("RASTERIZE_TRIANGLES");
	}
}
}
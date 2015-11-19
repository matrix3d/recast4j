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

public class InputGeom {

	public var vertices:Array;
	public var faces:Array;
	public var bmin:Array;
	public var bmax:Array;

	public function InputGeom(vertexPositions:Array, meshFaces:Array) {
		vertices = []
		for (var i:int= 0; i < vertices.length; i++) {
			vertices[i] = vertexPositions.get(i);
		}
		faces = new int[meshFaces.size()];
		for (i= 0; i < faces.length; i++) {
			faces[i] = meshFaces.get(i);
		}
		bmin = []
		bmax = [];
		RecastVectors.copy(bmin, vertices, 0);
		RecastVectors.copy(bmax, vertices, 0);
		for (i= 1; i < vertices.length / 3; i++) {
			RecastVectors.min(bmin, vertices, i * 3);
			RecastVectors.max(bmax, vertices, i * 3);
		}
	}

	public function getMeshBoundsMin():Array {
		return bmin;
	}

	public function getMeshBoundsMax():Array {
		return bmax;
	}

	public function getVerts():Array {
		return vertices;
	}

	public function getTris():Array {
		return faces;
	}

}
}
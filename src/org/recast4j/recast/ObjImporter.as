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
package org.recast4j.recast {
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

public class ObjImporter {

	private 
internal class ObjImporterContext {
	    List<Float> vertexPositions = new ArrayList<>();
	    List<Integer> meshFaces = new ArrayList<>();
	}

    public function load(is:InputStream):InputGeom {
        var context:ObjImporterContext= new ObjImporterContext();
        var reader:BufferedReader= null;
        try {
            reader = new BufferedReader(new InputStreamReader(is));
            var line:String;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                readLine(line, context);
            }
        } catch (e:Exception) {
            throw new RuntimeException(e);
        } finally {
            if (reader != null) {
                try {
					reader.close();
				} catch (e:IOException) {
					throw new RuntimeException(e.getMessage(), e);
				}
            }
        }
        return new InputGeom(context.vertexPositions, context.meshFaces);

    }

    private function readLine(line:String, context:ObjImporterContext):void {
        if (line.startsWith("v")) {
            readVertex(line, context);
        } else if (line.startsWith("f")) {
            readFace(line, context);
        }
    }

    private function readVertex(line:String, context:ObjImporterContext):void {
        if (line.startsWith("v ")) {
        	var vert:Array= readVector3f(line);
        	for (float vp : vert) {
        		context.vertexPositions.add(vp);
        	}
        }
    }

    private float[] readVector3f(var line:String) {
        var v:Array= line.split("\\s+");
        if (v.length < 4) {
            throw new RuntimeException("Invalid vector, expected 3 coordinates, found " + (v.length - 1));
        }
        return new float[]{Float.parseFloat(v[1]), Float.parseFloat(v[2]), Float.parseFloat(v[3])};
    }

    private function readFace(line:String, context:ObjImporterContext):void {
        var v:Array= line.split("\\s+");
        if (v.length < 4) {
            throw new RuntimeException("Invalid number of face vertices: 3 coordinates expected, found "
                    + v.length);
        }
        for (var j:int= 0; j < v.length - 3; j++) {
    		context.meshFaces.add(readFaceVertex(v[1], context));
        	for (var i:int= 0; i < 2; i++) {
        		context.meshFaces.add(readFaceVertex(v[2+ j + i], context));
        	}
        }
    }

    private function readFaceVertex(face:String, context:ObjImporterContext):int {
        var v:Array= face.split("/");
        return getIndex(Integer.parseInt(v[0]), context.vertexPositions.size());
    }

    private function getIndex(posi:int, size:int):int {
        if (posi > 0) {
            posi--;
        } else if (posi < 0) {
            posi = size + posi;
        } else {
            throw new RuntimeException("0 vertex index");
        }
        return posi;
    }

}
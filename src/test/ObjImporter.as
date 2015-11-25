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
package test {
	import org.recast4j.recast.InputGeom;

public class ObjImporter {


    public function load(txt:String):InputGeom {
        var context:ObjImporterContext= new ObjImporterContext();
		var line:String;
		var lines:Array = txt.split(/[\r\n]+/g);
		while ((line = lines.shift()) != null) {
			line = trim(line);
			readLine(line, context);
		}
        
        return new InputGeom(context.vertexPositions, context.meshFaces);

    }
	public function trim(s:String):String {
		return s ? s.replace(/^\s+|\s+$/gs, '') : "";
	}

    private function readLine(line:String, context:ObjImporterContext):void {
        if (line.charAt(0)=="v") {
            readVertex(line, context);
        } else if (line.charAt(0)=="f") {
            readFace(line, context);
        }
    }

    private function readVertex(line:String, context:ObjImporterContext):void {
        if (line.substr(0,2)=="v ") {
        	var vert:Array= readVector3f(line);
        	for each(var vp:Number in vert) {
        		context.vertexPositions.push(vp);
        	}
        }
    }

    private function readVector3f(line:String):Array {
        var v:Array= line.split(/\s+/);
        if (v.length < 4) {
            throw ("Invalid vector, expected 3 coordinates, found " + (v.length - 1));
        }
        return [parseFloat(v[1]), parseFloat(v[2]), parseFloat(v[3])];
    }

    private function readFace(line:String, context:ObjImporterContext):void {
        var v:Array= line.split(/\s+/);
        if (v.length < 4) {
            throw ("Invalid number of face vertices: 3 coordinates expected, found "
                    + v.length);
        }
        for (var j:int= 0; j < v.length - 3; j++) {
    		context.meshFaces.push(readFaceVertex(v[1], context));
        	for (var i:int= 0; i < 2; i++) {
        		context.meshFaces.push(readFaceVertex(v[2+ j + i], context));
        	}
        }
    }

    private function readFaceVertex(face:String, context:ObjImporterContext):int {
        var v:Array= face.split("/");
        return getIndex(parseInt(v[0]), context.vertexPositions.length);
    }

    private function getIndex(posi:int, size:int):int {
        if (posi > 0) {
            posi--;
        } else if (posi < 0) {
            posi = size + posi;
        } else {
            throw ("0 vertex index");
        }
        return posi;
    }

}
}
class ObjImporterContext {
public	var vertexPositions:Array = [];
	 public var    meshFaces:Array = [];
	}
package away3d;

import flash.Lib;
import flash.Vector;
import flash.errors.Error;
import flash.geom.Vector3D; 
import flash.geom.Matrix3D;
class Stage3DUtils {


    static public function copyColumnTo(mat:Matrix3D, column:Int, vector3D:Vector3D):Void {

      if (column > 3) {
			
			throw "Column " + column + " out of bounds (3)";
			
		}
		
		vector3D.x = mat.rawData[0 + column];
		vector3D.y = mat.rawData[4 + column];
		vector3D.z = mat.rawData[8 + column];
		vector3D.w = mat.rawData[12 + column];
    }

    static public function copyRowFrom(mat:Matrix3D, row:Int, vector3D:Vector3D):Void {
 		if (row > 3) {
			
			throw "Row " + row + " out of bounds (3)";
			
		}		
		var i = 4 * row;
		mat.rawData[i] = vector3D.x;
		mat.rawData[i + 1] = vector3D.y;
		mat.rawData[i + 2] = vector3D.z;
		mat.rawData[i + 3] = vector3D.w;
    }

    static public function copyRowTo(mat:Matrix3D, row:Int, vector3D:Vector3D) {
        if (row > 3) {
			
			throw "Row " + row + " out of bounds (3)";
			
		}		
		var i = 4 * row;
		vector3D.x = mat.rawData[i];
		vector3D.y = mat.rawData[i + 1];
		vector3D.z = mat.rawData[i + 2];
		vector3D.w = mat.rawData[i + 3];
    }

	
	
	
	static private var flashMatIndex:Array<Int>  =[0,4,8,12,
        1, 5, 9, 13,
        2, 6, 10, 14,
        3, 7, 11, 15];
    static public function copyRawDataFrom(mat:Matrix3D, vector:Vector<Float>, ?index:Int = 0, ?transpose:Bool = false):Void {
// Initial Tests - OK
        if (transpose) {
            mat.transpose();
        }
		 
        var l:Int = vector.length - index;
        for (c in 0...l) {
            mat.rawData[flashMatIndex[c]] = vector[c + index];
        }

        if (transpose) {
            mat.transpose();
        }
    }

	
    static public function copyRawDataTo(mat:Matrix3D, vector:Vector<Float>, ?index:Int = 0, ?transpose:Bool = false):Void {

// Initial Tests - OK
        if (transpose) {
            mat.transpose();
        }
        var l:Int = mat.rawData.length;
        for (c in 0...l) {
            vector[c + index ] = mat.rawData[flashMatIndex[c]];
        }
        if (transpose) {
            mat.transpose();
        }

    }
	
}
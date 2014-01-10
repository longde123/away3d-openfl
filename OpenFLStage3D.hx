/****
* 
****/

package;

import flash.display.Stage;
import flash.display.Stage3D;
import flash.errors.Error;
import flash.events.ErrorEvent;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
    #if !flash
import flash.display3D.AGLSLContext3D;
import openfl.display.OpenGLView;
import openfl.gl.GL;
import openfl.gl.GLUniformLocation;
    #end
import flash.display3D.IndexBuffer3D;
import flash.geom.Rectangle;
import flash.events.Event;
import flash.Vector;
import flash.display3D.Context3D;



class OpenFLStage3D {   
	static public function   copyColumnTo(mat:Matrix3D,column:Int, vector3D:Vector3D):Void
	{

		// Initial Tests - OK

		switch (column) {
			case 0:
				vector3D.x = mat.rawData[ 0 ];
				vector3D.y = mat.rawData[ 1 ];
				vector3D.z = mat.rawData[ 2 ];
				vector3D.w = mat.rawData[ 3 ];
				 
			case 1:
				vector3D.x = mat.rawData[ 4 ];
				vector3D.y = mat.rawData[ 5 ];
				vector3D.z = mat.rawData[ 6 ];
				vector3D.w = mat.rawData[ 7 ];
				 
			case 2:
				vector3D.x = mat.rawData[ 8 ];
				vector3D.y = mat.rawData[ 9 ];
				vector3D.z = mat.rawData[ 10 ];
				vector3D.w = mat.rawData[ 11 ];
				 
			case 3:
				vector3D.x = mat.rawData[ 12 ];
				vector3D.y = mat.rawData[ 13 ];
				vector3D.z = mat.rawData[ 14 ];
				vector3D.w = mat.rawData[ 15 ];
		 
			default:
				throw new  Error("ArgumentError, Column " + column + " out of bounds [0, ..., 3]");
		}
	}
 
	static public function  copyRowFrom(mat:Matrix3D,row:Int, vector3D:Vector3D):Void
	{

		// Initial Tests - OK

		switch (row) {
			case 0:
				mat.rawData[ 0 ] = vector3D.x;
				mat.rawData[ 4 ] = vector3D.y;
				mat.rawData[ 8 ] = vector3D.z;
				mat.rawData[ 12 ] = vector3D.w;
			 
			case 1:
				mat.rawData[ 1 ] = vector3D.x;
				mat.rawData[ 5 ] = vector3D.y;
				mat.rawData[ 9 ] = vector3D.z;
				mat.rawData[ 13 ] = vector3D.w;
			 
			case 2:
				mat.rawData[ 2 ] = vector3D.x;
				mat.rawData[ 6 ] = vector3D.y;
				mat.rawData[ 10 ] = vector3D.z;
				mat.rawData[ 14 ] = vector3D.w;
	 
			case 3:
				mat.rawData[ 3 ] = vector3D.x;
				mat.rawData[ 7 ] = vector3D.y;
				mat.rawData[ 11 ] = vector3D.z;
				mat.rawData[ 15 ] = vector3D.w;
				 
			default:
				throw new  Error("ArgumentError, Row " + row + " out of bounds [0, ..., 3]");
		}
	}
	static public function  copyRowTo(mat:Matrix3D,row:Int, vector3D:Vector3D)
	{

		// Initial Tests - OK

		switch (row) {
			case 0:
				vector3D.x = mat.rawData[ 0 ];
				vector3D.y = mat.rawData[ 4 ];
				vector3D.z = mat.rawData[ 8 ];
				vector3D.w = mat.rawData[ 12 ];
			 
			case 1:
				vector3D.x = mat.rawData[ 1 ];
				vector3D.y = mat.rawData[ 5 ];
				vector3D.z = mat.rawData[ 9 ];
				vector3D.w = mat.rawData[ 13 ];
			 
			case 2:
				vector3D.x = mat.rawData[ 2 ];
				vector3D.y = mat.rawData[ 6 ];
				vector3D.z = mat.rawData[ 10 ];
				vector3D.w = mat.rawData[ 14 ];
			 
			case 3:
				vector3D.x = mat.rawData[ 3 ];
				vector3D.y = mat.rawData[ 7 ];
				vector3D.z = mat.rawData[ 11 ];
				vector3D.w = mat.rawData[ 15 ];
			 
			default:
				throw new Error("ArgumentError, Row " + row + " out of bounds [0, ..., 3]");
		}
	}
 
	static public function copyRawDataFrom(mat:Matrix3D, vector:Vector<Float>, ?index:Int = 0, ?transpose:Bool = false):Void
	{
		// Initial Tests - OK
		if (transpose) {
			mat.transpose();
		}

		var l:Int = vector.length - index;
		for (  c in 0...l) {
			mat.rawData[c] = vector[c + index];
		}

		if (transpose) {
			mat.transpose();
		}
	}
	static public function copyRawDataTo(mat:Matrix3D, vector:Vector<Float>, ?index:Int = 0, ?transpose:Bool = false):Void
	{

		// Initial Tests - OK 
		if (transpose) {
			mat.transpose();
		}
		var l:Int = mat.rawData.length;
		for (  c in 0...l) {
			vector[c + index ] = mat.rawData[c];
		} 
		if (transpose) {
			mat.transpose();
		}

	}
    #if !flash
    static private var stage3Ds:Vector<Stage3D> = []; 
    #end
	static public function requestAGLSLContext3D(stage3D : Stage3D,?context3DRenderMode:String =  "auto"):Void 
   {
	 #if !flash
      if (OpenGLView.isSupported)   
      {
          stage3D.context3D = new AGLSLContext3D();   
          stage3D.dispatchEvent(new Event(Event.CONTEXT3D_CREATE));
      }else
      {
		  stage3D.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));  
	  }
	#end
	 #if flash
           stage3D.requestContext3D(context3DRenderMode);
	#end
      
   }
    static public function getStage3D(stage : Stage, index : Int) : Stage3D{
        #if flash
        return stage.stage3Ds[index];
        #else
        if(stage3Ds.length > index){
            return stage3Ds[index];
        }else{
            if(index > 0){
                throw "Only 1 Stage3D supported for now";
            }
            var stage3D = new Stage3D();
            stage3Ds[index] = stage3D;
            return stage3D;
        }
        #end
    }

   /**
    * Common API for both cpp and flash to set the render callback
    **/
    inline static public function setRenderCallback(context3D : Context3D, func : Event -> Void) : Void{
        #if flash
        flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, func);
        #elseif (cpp || neko || js)
        context3D.setRenderMethod(func);
        #end
    }

    /**
    * Common API for both cpp and flash to remove the render callback
    **/
    inline static public function removeRenderCallback(context3D : Context3D, func : Event -> Void) : Void{
        #if flash
        flash.Lib.current.removeEventListener(flash.events.Event.ENTER_FRAME, func);
        #elseif (cpp || neko || js)
        context3D.removeRenderMethod(func);
        #end
    }


}

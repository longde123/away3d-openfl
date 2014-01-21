/****
* 
****/

package flash.display3D.shaders;
import aglsl.assembler.AGALMiniAssembler;
import flash.utils.ByteArray;
#if (cpp || neko || js)
import openfl.gl.GL; 
#end

import flash.display3D.Context3DProgramType;

class AGLSLShaderUtils {

    inline public static function compile(programType:String, source:String):ByteArray {
        var agalMiniAssembler:AGALMiniAssembler = new AGALMiniAssembler();

        var data:ByteArray;
        var concatSource:String;
        switch(programType) {
            case "vertex":
                {
                    concatSource = "part vertex 1 \n" + source + "endpart";
                    agalMiniAssembler.assemble(concatSource);
                    data = agalMiniAssembler.r.get("vertex").data;
                }

            case "fragment":
                {
                    concatSource = "part fragment 1 \n" + source + "endpart";
                    agalMiniAssembler.assemble(concatSource);
                    data = agalMiniAssembler.r.get("fragment").data;
                }

            default:
                throw "Unknown Context3DProgramType";
        }

        return data;
    }

    inline public static function createShader(type:Context3DProgramType, shaderSource:String):flash.display3D.shaders.Shader {

		#if flash
		
		trace(shaderSource);
		return compile (cast(type,String), shaderSource);

		#elseif (cpp || neko || js)

		trace(shaderSource);
		var aglsl:aglsl.AGLSLCompiler = new aglsl.AGLSLCompiler();
	
		var glType : Int;
		var shaderType :String;
        switch(type){
            case Context3DProgramType.VERTEX: {
				glType = GL.VERTEX_SHADER;
				shaderType = "vertex";
			}
            case Context3DProgramType.FRAGMENT: {
				glType = GL.FRAGMENT_SHADER;
				shaderType = "fragment";
			}
        }

		var shaderSourceString : String =aglsl.compile(shaderType, shaderSource);
		var shader = GL.createShader (glType);
		GL.shaderSource (shader, shaderSourceString);
		GL.compileShader (shader);
		trace("--- ERR ---\n" + shaderSourceString);
		if (GL.getShaderParameter (shader, GL.COMPILE_STATUS) == 0) {
 
			var err = GL.getShaderInfoLog (shader);
			if (err != "") throw err;

		} 
		

		return shader;

		#else

        return null;

#end

    }

}
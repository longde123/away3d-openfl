package away3d.utils;

class ArrayUtils {
	inline public static function Prefill(array:Dynamic, count:UInt, ?defaultValue:Dynamic = null):Dynamic {
		#if flash
         
        #elseif (cpp || neko || js)
		var c:UInt = 0;
		while (c++ < count) {
			array.push(defaultValue);
		}
		#end
		return array;
	}
}
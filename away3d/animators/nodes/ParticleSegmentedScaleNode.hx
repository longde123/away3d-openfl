package away3d.animators.nodes;


import flash.Vector;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.animators.states.ParticleSegmentedScaleState;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.materials.passes.MaterialPassBase;
import flash.geom.Vector3D;

class ParticleSegmentedScaleNode extends ParticleNodeBase {

/** @private */
    static public var START_INDEX:Int = 0;
/** @private */
    public var _startScale:Vector3D;
/** @private */
    public var _endScale:Vector3D;
/** @private */
    public var _numSegmentPoint:Int;
/** @private */
    public var _segmentScales:Vector<Vector3D>;
/**
	 *
	 * @param	numSegmentPoint
	 * @param	startScale
	 * @param	endScale
	 * @param	segmentScales Vector.<Vector3D>. the x,y,z present the scaleX,scaleY,scaleX, and w present the life
	 */

    public function new(numSegmentPoint:Int, startScale:Vector3D, endScale:Vector3D, segmentScales:Vector<Vector3D>) {
        _stateClass = ParticleSegmentedScaleState;
//because of the stage3d register limitation, it only support the global mode
        super("ParticleSegmentedScale", ParticlePropertiesMode.GLOBAL, 0, 3);
        _numSegmentPoint = numSegmentPoint;
        _startScale = startScale;
        _endScale = endScale;
        _segmentScales = segmentScales;
    }

/**
	 * @inheritDoc
	 */

    override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String {
        pass = pass;
        var code:String = "";
        var accScale:ShaderRegisterElement;
        accScale = animationRegisterCache.getFreeVertexVectorTemp();
        animationRegisterCache.addVertexTempUsages(accScale, 1);
        var tempScale:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
        animationRegisterCache.addVertexTempUsages(tempScale, 1);
        var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
        var accTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
        var tempTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);
        animationRegisterCache.removeVertexTempUsage(accScale);
        animationRegisterCache.removeVertexTempUsage(tempScale);
        var i:Int;
        var startValue:ShaderRegisterElement;
        var deltaValues:Vector<ShaderRegisterElement>;
        startValue = animationRegisterCache.getFreeVertexConstant();
        animationRegisterCache.setRegisterIndex(this, START_INDEX, startValue.index);
        deltaValues = new Vector<ShaderRegisterElement>();
        i = 0;
        while (i < _numSegmentPoint + 1) {
            deltaValues.push(animationRegisterCache.getFreeVertexConstant());
            i++;
        }
        code += "mov " + accScale + "," + startValue + "\n";
        i = 0;
        while (i < _numSegmentPoint) {
            switch(i) {
                case 0:
                    code += "min " + tempTime + "," + animationRegisterCache.vertexLife + "," + deltaValues[i] + ".w\n";
                case 1:
                    code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + deltaValues[i - 1] + ".w\n";
                    code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
                    code += "min " + tempTime + "," + tempTime + "," + deltaValues[i] + ".w\n";
                default:
                    code += "sub " + accTime + "," + accTime + "," + deltaValues[i - 1] + ".w\n";
                    code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
                    code += "min " + tempTime + "," + tempTime + "," + deltaValues[i] + ".w\n";
            }
            code += "mul " + tempScale + "," + tempTime + "," + deltaValues[i] + "\n";
            code += "add " + accScale + "," + accScale + "," + tempScale + "\n";
            i++;
        }
//for the last segment:
        if (_numSegmentPoint == 0) tempTime = animationRegisterCache.vertexLife
        else {
            switch(_numSegmentPoint) {
                case 1:
                    code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + deltaValues[_numSegmentPoint - 1] + ".w\n";
                default:
                    code += "sub " + accTime + "," + accTime + "," + deltaValues[_numSegmentPoint - 1] + ".w\n";
            }
            code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
        }

        code += "mul " + tempScale + "," + tempTime + "," + deltaValues[_numSegmentPoint] + "\n";
        code += "add " + accScale + "," + accScale + "," + tempScale + "\n";
        code += "mul " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + accScale + ".xyz\n";
        return code;
    }

}


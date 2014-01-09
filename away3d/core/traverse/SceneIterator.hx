package away3d.core.traverse;


import flash.Vector;
import away3d.containers.ObjectContainer3D;
import away3d.containers.Scene3D;

class SceneIterator {

    static private var PRE:Int = 0;
    static private var IN:Int = 1;
    static private var POST:Int = 2;
    private var _childIndex:Int;
    private var _scene:Scene3D;
    private var _node:ObjectContainer3D;
    private var _traverseState:Int;
    private var _childIndexStack:Vector<Int>;
    private var _stackPos:Int;

    public function new(scene:Scene3D) {
        _scene = scene;
        reset();
    }

    public function reset():Void {
        _childIndexStack = new Vector<Int>();
        _node = _scene._sceneGraphRoot;
        _childIndex = 0;
        _stackPos = 0;
        _traverseState = PRE;
    }

    public function next():ObjectContainer3D {
        do {
            switch(_traverseState) {
                case PRE, IN:
                    switch(_traverseState) {
                        case PRE:
// just entered a node
                            _childIndexStack[_stackPos++] = _childIndex;
                            _childIndex = 0;
                            _traverseState = IN;
                            return _node;
                    }
                    if (_childIndex == _node.numChildren) _traverseState = POST
                    else {
                        _node = _node.getChildAt(_childIndex);
                        _traverseState = PRE;
                    }

                case POST:
                    _node = _node.parent;
                    _childIndex = _childIndexStack[--_stackPos] + 1;
                    _traverseState = IN;
            }
        }
        while ((!(_node == _scene._sceneGraphRoot && _traverseState == POST)));
        return null;
    }

}


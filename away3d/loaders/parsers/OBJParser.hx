/**
 * OBJParser provides a parser for the OBJ data type.
 */
package away3d.loaders.parsers;


import flash.Vector;
import away3d.core.base.Geometry;
import away3d.core.base.ISubGeometry;
import away3d.core.base.data.UV;
import away3d.core.base.data.Vertex;
import away3d.entities.Mesh;
import away3d.library.assets.AssetType;
import away3d.library.assets.IAsset;
import away3d.loaders.misc.ResourceDependency;
import away3d.loaders.parsers.utils.ParserUtil;
import away3d.materials.ColorMaterial;
import away3d.materials.ColorMultiPassMaterial;
import away3d.materials.MaterialBase;
import away3d.materials.TextureMaterial;
import away3d.materials.TextureMultiPassMaterial;
import away3d.materials.methods.BasicSpecularMethod;
import away3d.materials.utils.DefaultMaterialManager;
import away3d.textures.Texture2DBase;
import away3d.tools.utils.GeomUtil;
import flash.net.URLRequest;
import away3d.materials.MaterialBase;
import away3d.materials.methods.BasicSpecularMethod;
import away3d.textures.Texture2DBase;

class OBJParser extends ParserBase {
    public var scale(never, set_scale):Float;

    private var _textData:String;
    private var _startedParsing:Bool;
    private var _charIndex:Int;
    private var _oldIndex:Int;
    private var _stringLength:Int;
    private var _currentObject:ObjectGroup;
    private var _currentGroup:Group;
    private var _currentMaterialGroup:MaterialGroup;
    private var _objects:Vector<ObjectGroup>;
    private var _materialIDs:Vector<String>;
    private var _materialLoaded:Vector<LoadedMaterial>;
    private var _materialSpecularData:Vector<SpecularData>;
    private var _meshes:Vector<Mesh>;
    private var _lastMtlID:String;
    private var _objectIndex:Int;
    private var _realIndices:Array<Dynamic>;
    private var _vertexIndex:Int;
    private var _vertices:Vector<Vertex>;
    private var _vertexNormals:Vector<Vertex>;
    private var _uvs:Vector<UV>;
    private var _scale:Float;
    private var _mtlLib:Bool;
    private var _mtlLibLoaded:Bool;
    private var _activeMaterialID:String;
/**
	 * Creates a new OBJParser object.
	 * @param uri The url or id of the data or file to be parsed.
	 * @param extra The holder for extra contextual data that the parser might need.
	 */

    public function new(scale:Float = 1) {
        _mtlLibLoaded = true;
        _activeMaterialID = "";
        super(ParserDataFormat.PLAIN_TEXT);
        _scale = scale;
    }

/**
	 * Scaling factor applied directly to vertices data
	 * @param value The scaling factor.
	 */

    public function set_scale(value:Float):Float {
        _scale = value;
        return value;
    }

/**
	 * Indicates whether or not a given file extension is supported by the parser.
	 * @param extension The file extension of a potential file to be parsed.
	 * @return Whether or not the given file type is supported.
	 */

    static public function supportsType(extension:String):Bool {
        extension = extension.toLowerCase();
        return extension == "obj";
    }

/**
	 * Tests whether a data block can be parsed by the parser.
	 * @param data The data block to potentially be parsed.
	 * @return Whether or not the given data is supported.
	 */

    static public function supportsData(data:Dynamic):Bool {
        var content:String = ParserUtil.toString(data);
        var hasV:Bool;
        var hasF:Bool;
        if (content) {
            hasV = content.indexOf("
v ") != -1;
            hasF = content.indexOf("
f ") != -1;
        }
        return hasV && hasF;
    }

/**
	 * @inheritDoc
	 */

    override private function resolveDependency(resourceDependency:ResourceDependency):Void {
        if (resourceDependency.id == "mtl") {
            var str:String = ParserUtil.toString(resourceDependency.data);
            parseMtl(str);
        }

        else {
            var asset:IAsset;
            if (resourceDependency.assets.length != 1) return;
            asset = resourceDependency.assets[0];
            if (asset.assetType == AssetType.TEXTURE) {
                var lm:LoadedMaterial = new LoadedMaterial();
                lm.materialID = resourceDependency.id;
                lm.texture = cast(asset, Texture2DBase) ;
                _materialLoaded.push(lm);
                if (_meshes.length > 0) applyMaterial(lm);
            }
        }

    }

/**
	 * @inheritDoc
	 */

    override private function resolveDependencyFailure(resourceDependency:ResourceDependency):Void {
        if (resourceDependency.id == "mtl") {
            _mtlLib = false;
            _mtlLibLoaded = false;
        }

        else {
            var lm:LoadedMaterial = new LoadedMaterial();
            lm.materialID = resourceDependency.id;
            _materialLoaded.push(lm);
        }

        if (_meshes.length > 0) applyMaterial(lm);
    }

/**
	 * @inheritDoc
	 */

    override private function proceedParsing():Bool {
        var line:String;
        var creturn:String = String.fromCharCode(10);
        var trunk:Array<Dynamic>;
        if (!_startedParsing) {
            _textData = getTextData();
// Merge linebreaks that are immediately preceeded by
// the "escape" backward slash into single lines.
            _textData = _textData.replace(new EReg("\\[\r\n]+\s*", "gm"), " ");
        }
        if (_textData.indexOf(creturn) == -1) creturn = String.fromCharCode(13);
        if (!_startedParsing) {
            _startedParsing = true;
            _vertices = new Vector<Vertex>();
            _vertexNormals = new Vector<Vertex>();
            _materialIDs = new Vector<String>();
            _materialLoaded = new Vector<LoadedMaterial>();
            _meshes = new Vector<Mesh>();
            _uvs = new Vector<UV>();
            _stringLength = _textData.length;
            _charIndex = _textData.indexOf(creturn, 0);
            _oldIndex = 0;
            _objects = new Vector<ObjectGroup>();
            _objectIndex = 0;
        }
        while (_charIndex < _stringLength && hasTime()) {
            _charIndex = _textData.indexOf(creturn, _oldIndex);
            if (_charIndex == -1) _charIndex = _stringLength;
            line = _textData.substring(_oldIndex, _charIndex);
            line = line.split("
").join("");
            line = line.replace("  ", " ");
            trunk = line.split(" ");
            _oldIndex = _charIndex + 1;
            parseLine(trunk);
// If whatever was parsed on this line resulted in the
// parsing being paused to retrieve dependencies, break
// here and do not continue parsing until un-paused.
            if (parsingPaused) return MORE_TO_PARSE;
        }

        if (_charIndex >= _stringLength) {
            if (_mtlLib && !_mtlLibLoaded) return MORE_TO_PARSE;
            translate();
            applyMaterials();
            return PARSING_DONE;
        }
        return MORE_TO_PARSE;
    }

/**
	 * Parses a single line in the OBJ file.
	 */

    private function parseLine(trunk:Array<Dynamic>):Void {
        var _sw2_ = (trunk[0]);
        switch(_sw2_) {
            case "mtllib":
                _mtlLib = true;
                _mtlLibLoaded = false;
                loadMtl(trunk[1]);
            case "g":
                createGroup(trunk);
            case "o":
                createObject(trunk);
            case "usemtl":
                if (_mtlLib) {
                    if (!trunk[1]) trunk[1] = "def000";
                    _materialIDs.push(trunk[1]);
                    _activeMaterialID = trunk[1];
                    if (_currentGroup) _currentGroup.materialID = _activeMaterialID;
                }
            case "v":
                parseVertex(trunk);
            case "vt":
                parseUV(trunk);
            case "vn":
                parseVertexNormal(trunk);
            case "f":
                parseFace(trunk);
        }
    }

/**
	 * Converts the parsed data into an Away3D scenegraph structure
	 */

    private function translate():Void {
        var objIndex:Int = 0;
        while (objIndex < _objects.length) {
            var groups:Vector<Group> = _objects[objIndex].groups;
            var numGroups:Int = groups.length;
            var materialGroups:Vector<MaterialGroup>;
            var numMaterialGroups:Int;
            var geometry:Geometry;
            var mesh:Mesh;
            var m:Int;
            var sm:Int;
            var bmMaterial:MaterialBase;
            var g:Int = 0;
            while (g < numGroups) {
                geometry = new Geometry();
                materialGroups = groups[g].materialGroups;
                numMaterialGroups = materialGroups.length;
                m = 0;
                while (m < numMaterialGroups) {
                    translateMaterialGroup(materialGroups[m], geometry);
                    ++m;
                }
                if (geometry.subGeometries.length == 0) {
                    ++g;
                    continue;
                }
                ;
                finalizeAsset(geometry, "");
                if (materialMode < 2) bmMaterial = new TextureMaterial(DefaultMaterialManager.getDefaultTexture())
                else bmMaterial = new TextureMultiPassMaterial(DefaultMaterialManager.getDefaultTexture());
//bmMaterial = new TextureMaterial(DefaultMaterialManager.getDefaultTexture());
                mesh = new Mesh(geometry, bmMaterial);
                if (_objects[objIndex].name) {
// this is a full independent object ('o' tag in OBJ file)
                    mesh.name = _objects[objIndex].name;
                }

                else if (groups[g].name) {
// this is a group so the sub groups contain the actual mesh object names ('g' tag in OBJ file)
                    mesh.name = groups[g].name;
                }

                else {
// No name stored. Use empty string which will force it
// to be overridden by finalizeAsset() to type default.
                    mesh.name = "";
                }

                _meshes.push(mesh);
                if (groups[g].materialID != "") bmMaterial.name = groups[g].materialID + "~" + mesh.name
                else bmMaterial.name = _lastMtlID + "~" + mesh.name;
                if (mesh.subMeshes.length > 1) {
                    sm = 1;
                    while (sm < mesh.subMeshes.length) {
                        mesh.subMeshes[sm].material = bmMaterial;
                        ++sm;
                    }
                }
                finalizeAsset(mesh);
                ++g;
            }
            ++objIndex;
        }
    }

/**
	 * Translates an obj's material group to a subgeometry.
	 * @param materialGroup The material group data to convert.
	 * @param geometry The Geometry to contain the converted SubGeometry.
	 */

    private function translateMaterialGroup(materialGroup:MaterialGroup, geometry:Geometry):Void {
        var faces:Vector<FaceData> = materialGroup.faces;
        var face:FaceData;
        var numFaces:Int = faces.length;
        var numVerts:Int;
        var subs:Vector<ISubGeometry>;
        var vertices:Vector<Float> = new Vector<Float>();
        var uvs:Vector<Float> = new Vector<Float>();
        var normals:Vector<Float> = new Vector<Float>();
        var indices:Vector<UInt> = new Vector<UInt>();
        _realIndices = [];
        _vertexIndex = 0;
        var j:Int;
        var i:Int = 0;
        while (i < numFaces) {
            face = faces[i];
            numVerts = face.indexIds.length - 1;
            j = 1;
            while (j < numVerts) {
                translateVertexData(face, j, vertices, uvs, indices, normals);
                translateVertexData(face, 0, vertices, uvs, indices, normals);
                translateVertexData(face, j + 1, vertices, uvs, indices, normals);
                ++j;
            }
            ++i;
        }
        if (vertices.length > 0) {
            subs = GeomUtil.fromVectors(vertices, indices, uvs, normals, null, null, null);
            i = 0;
            while (i < subs.length) {
                geometry.addSubGeometry(subs[i]);
                i++;
            }
        }
    }

    private function translateVertexData(face:FaceData, vertexIndex:Int, vertices:Vector<Float>, uvs:Vector<Float>, indices:Vector<UInt>, normals:Vector<Float>):Void {
        var index:Int;
        var vertex:Vertex;
        var vertexNormal:Vertex;
        var uv:UV;
        if (!_realIndices[face.indexIds[vertexIndex]]) {
            index = _vertexIndex;
            _realIndices[face.indexIds[vertexIndex]] = ++_vertexIndex;
            vertex = _vertices[face.vertexIndices[vertexIndex] - 1];
            vertices.push(vertex.x * _scale, vertex.y * _scale, vertex.z * _scale);
            if (face.normalIndices.length > 0) {
                vertexNormal = _vertexNormals[face.normalIndices[vertexIndex] - 1];
                normals.push(vertexNormal.x, vertexNormal.y, vertexNormal.z);
            }
            if (face.uvIndices.length > 0) {
                try {
                    uv = _uvs[face.uvIndices[vertexIndex] - 1];
                    uvs.push(uv.u, uv.v);
                }
                catch (e) {
                    switch(vertexIndex) {
                        case 0:
                            uvs.push(0, 1);
                        case 1:
                            uvs.push(.5, 0);
                        case 2:
                            uvs.push(1, 1);
                    }
                }

            }
        }

        else index = _realIndices[face.indexIds[vertexIndex]] - 1;
        indices.push(index);
    }

/**
	 * Creates a new object group.
	 * @param trunk The data block containing the object tag and its parameters
	 */

    private function createObject(trunk:Array<Dynamic>):Void {
        _currentGroup = null;
        _currentMaterialGroup = null;
        _objects.push(_currentObject = new ObjectGroup());
        if (trunk) _currentObject.name = trunk[1];
    }

/**
	 * Creates a new group.
	 * @param trunk The data block containing the group tag and its parameters
	 */

    private function createGroup(trunk:Array<Dynamic>):Void {
        if (!_currentObject) createObject(null);
        _currentGroup = new Group();
        _currentGroup.materialID = _activeMaterialID;
        if (trunk) _currentGroup.name = trunk[1];
        _currentObject.groups.push(_currentGroup);
        createMaterialGroup(null);
    }

/**
	 * Creates a new material group.
	 * @param trunk The data block containing the material tag and its parameters
	 */

    private function createMaterialGroup(trunk:Array<Dynamic>):Void {
        _currentMaterialGroup = new MaterialGroup();
        if (trunk) _currentMaterialGroup.url = trunk[1];
        _currentGroup.materialGroups.push(_currentMaterialGroup);
    }

/**
	 * Reads the next vertex coordinates.
	 * @param trunk The data block containing the vertex tag and its parameters
	 */

    private function parseVertex(trunk:Array<Dynamic>):Void {
//for the very rare cases of other delimiters/charcodes seen in some obj files
        if (trunk.length > 4) {
            var nTrunk:Array<Dynamic> = [];
            var val:Float;
            var i:Int = 1;
            while (i < trunk.length) {
                val = parseFloat(trunk[i]);
                if (!Math.isNaN(val)) nTrunk.push(val);
                ++i;
            }
            _vertices.push(new Vertex(nTrunk[0], nTrunk[1], -nTrunk[2]));
        }

        else _vertices.push(new Vertex(parseFloat(trunk[1]), parseFloat(trunk[2]), -parseFloat(trunk[3])));
    }

/**
	 * Reads the next uv coordinates.
	 * @param trunk The data block containing the uv tag and its parameters
	 */

    private function parseUV(trunk:Array<Dynamic>):Void {
        if (trunk.length > 3) {
            var nTrunk:Array<Dynamic> = [];
            var val:Float;
            var i:Int = 1;
            while (i < trunk.length) {
                val = parseFloat(trunk[i]);
                if (!Math.isNaN(val)) nTrunk.push(val);
                ++i;
            }
            _uvs.push(new UV(nTrunk[0], 1 - nTrunk[1]));
        }

        else _uvs.push(new UV(parseFloat(trunk[1]), 1 - parseFloat(trunk[2])));
    }

/**
	 * Reads the next vertex normal coordinates.
	 * @param trunk The data block containing the vertex normal tag and its parameters
	 */

    private function parseVertexNormal(trunk:Array<Dynamic>):Void {
        if (trunk.length > 4) {
            var nTrunk:Array<Dynamic> = [];
            var val:Float;
            var i:Int = 1;
            while (i < trunk.length) {
                val = parseFloat(trunk[i]);
                if (!Math.isNaN(val)) nTrunk.push(val);
                ++i;
            }
            _vertexNormals.push(new Vertex(nTrunk[0], nTrunk[1], -nTrunk[2]));
        }

        else _vertexNormals.push(new Vertex(parseFloat(trunk[1]), parseFloat(trunk[2]), -parseFloat(trunk[3])));
    }

/**
	 * Reads the next face's indices.
	 * @param trunk The data block containing the face tag and its parameters
	 */

    private function parseFace(trunk:Array<Dynamic>):Void {
        var len:Int = trunk.length;
        var face:FaceData = new FaceData();
        if (!_currentGroup) createGroup(null);
        var indices:Array<Dynamic>;
        var i:Int = 1;
        while (i < len) {
            if (trunk[i] == "") {
                ++i;
                continue;
            }
            ;
            indices = trunk[i].split("/");
            face.vertexIndices.push(parseIndex(parseInt(indices[0]), _vertices.length));
            if (indices[1] && Std.string(indices[1]).length > 0) face.uvIndices.push(parseIndex(parseInt(indices[1]), _uvs.length));
            if (indices[2] && Std.string(indices[2]).length > 0) face.normalIndices.push(parseIndex(parseInt(indices[2]), _vertexNormals.length));
            face.indexIds.push(trunk[i]);
            ++i;
        }
        _currentMaterialGroup.faces.push(face);
    }

/**
	 * This is a hack around negative face coords
	 */

    private function parseIndex(index:Int, length:Int):Int {
        if (index < 0) return index + length + 1
        else return index;
    }

    private function parseMtl(data:String):Void {
        var materialDefinitions:Array<Dynamic> = data.split("newmtl");
        var lines:Array<Dynamic>;
        var trunk:Array<Dynamic>;
        var j:Int;
        var basicSpecularMethod:BasicSpecularMethod;
        var useSpecular:Bool;
        var useColor:Bool;
        var diffuseColor:Int;
        var ambientColor:Int;
        var specularColor:Int;
        var specular:Float;
        var alpha:Float;
        var mapkd:String;
        var i:Int = 0;
        while (i < materialDefinitions.length) {
            lines = ( cast(materialDefinitions[i].split("\n"), Array)).join("").split("\n");
            if (lines.length == 1) lines = materialDefinitions[i].split(String.fromCharCode(13));
            diffuseColor = ambientColor = specularColor = 0xFFFFFF;
            specular = 0;
            useSpecular = false;
            useColor = false;
            alpha = 1;
            mapkd = "";
            j = 0;
            while (j < lines.length) {
                lines[j] = lines[j].replace(new EReg("\s+$", ""), "");
                if (lines[j].substring(0, 1) != "#" && (j == 0 || lines[j] != "")) {
                    trunk = lines[j].split(" ");
                    if (Std.string(trunk[0]).charCodeAt(0) == 9 || Std.string(trunk[0]).charCodeAt(0) == 32) trunk[0] = trunk[0].substring(1, trunk[0].length);
                    if (j == 0) {
                        _lastMtlID = trunk.join("");
                        _lastMtlID = ((_lastMtlID == "")) ? "def000" : _lastMtlID;
                    }

                    else {
                        var _sw3_ = (trunk[0]);
                        switch(_sw3_) {
                            case "Ka":
                                if (trunk[1] && !Math.isNaN(Std.parseFloat(trunk[1]) /* WARNING check type */) && trunk[2] && !Math.isNaN(Std.parseFloat(trunk[2]) /* WARNING check type */) && trunk[3] && !Math.isNaN(Std.parseFloat(trunk[3]) /* WARNING check type */)) ambientColor = trunk[1] * 255 << 16 | trunk[2] * 255 << 8 | trunk[3] * 255;
                            case "Ks":
                                if (trunk[1] && !Math.isNaN(Std.parseFloat(trunk[1]) /* WARNING check type */) && trunk[2] && !Math.isNaN(Std.parseFloat(trunk[2]) /* WARNING check type */) && trunk[3] && !Math.isNaN(Std.parseFloat(trunk[3]) /* WARNING check type */)) {
                                    specularColor = trunk[1] * 255 << 16 | trunk[2] * 255 << 8 | trunk[3] * 255;
                                    useSpecular = true;
                                }
                            case "Ns":
                                if (trunk[1] && !Math.isNaN(Std.parseFloat(trunk[1]) /* WARNING check type */)) specular = Std.parseFloat(trunk[1]) /* WARNING check type */ * 0.001;
                                if (specular == 0) useSpecular = false;
                            case "Kd":
                                if (trunk[1] && !Math.isNaN(Std.parseFloat(trunk[1]) /* WARNING check type */) && trunk[2] && !Math.isNaN(Std.parseFloat(trunk[2]) /* WARNING check type */) && trunk[3] && !Math.isNaN(Std.parseFloat(trunk[3]) /* WARNING check type */)) {
                                    diffuseColor = trunk[1] * 255 << 16 | trunk[2] * 255 << 8 | trunk[3] * 255;
                                    useColor = true;
                                }
                            case "tr", "d":
                                if (trunk[1] && !Math.isNaN(Std.parseFloat(trunk[1]) /* WARNING check type */)) alpha = Std.parseFloat(trunk[1]) /* WARNING check type */;
                            case "map_Kd":
                                mapkd = parseMapKdString(trunk);
                                mapkd = mapkd.replace(new EReg("\\", "g"), "/");
                        }
                    }

                }
                ++j;
            }
            if (mapkd != "") {
                if (useSpecular) {
                    basicSpecularMethod = new BasicSpecularMethod();
                    basicSpecularMethod.specularColor = specularColor;
                    basicSpecularMethod.specular = specular;
                    var specularData:SpecularData = new SpecularData();
                    specularData.alpha = alpha;
                    specularData.basicSpecularMethod = basicSpecularMethod;
                    specularData.materialID = _lastMtlID;
                    if (!_materialSpecularData) _materialSpecularData = new Vector<SpecularData>();
                    _materialSpecularData.push(specularData);
                }
                addDependency(_lastMtlID, new URLRequest(mapkd));
            }

            else if (useColor && !Math.isNaN(diffuseColor)) {
                var lm:LoadedMaterial = new LoadedMaterial();
                lm.materialID = _lastMtlID;
                if (alpha == 0) trace("Warning: an alpha value of 0 was found in mtl color tag (Tr or d) ref:" + _lastMtlID + ", mesh(es) using it will be invisible!");
                var cm:MaterialBase;
                if (materialMode < 2) {
                    cm = new ColorMaterial(diffuseColor);
                    cast((cm), ColorMaterial).alpha = alpha;
                    cast((cm), ColorMaterial).ambientColor = ambientColor;
                    cast((cm), ColorMaterial).repeat = true;
                    if (useSpecular) {
                        cast((cm), ColorMaterial).specularColor = specularColor;
                        cast((cm), ColorMaterial).specular = specular;
                    }
                }

                else {
                    cm = new ColorMultiPassMaterial(diffuseColor);
                    cast((cm), ColorMultiPassMaterial).ambientColor = ambientColor;
                    cast((cm), ColorMultiPassMaterial).repeat = true;
                    if (useSpecular) {
                        cast((cm), ColorMultiPassMaterial).specularColor = specularColor;
                        cast((cm), ColorMultiPassMaterial).specular = specular;
                    }
                }

                lm.cm = cm;
                _materialLoaded.push(lm);
                if (_meshes.length > 0) applyMaterial(lm);
            }
            ++i;
        }
        _mtlLibLoaded = true;
    }

    private function parseMapKdString(trunk:Array<Dynamic>):String {
        var url:String = "";
        var i:Int;
        var breakflag:Bool;
        i = 1;
        while (i < trunk.length) {
            var _sw4_ = (trunk[i]);
            switch(_sw4_) {
                case "-blendu", "-blendv", "-cc", "-clamp", "-texres":
                    i += 2;
//Skip ahead 1 attribute
                case "-mm":
                    i += 3;
//Skip ahead 2 attributes
                case "-o", "-s", "-t":
                    i += 4;
//Skip ahead 3 attributes
                    continue;
                    breakflag = true;
                default:
                    breakflag = true;
            }
            if (breakflag) break;
        }
//Reconstruct URL/filename
        i;
        while (i < trunk.length) {
            url += trunk[i];
            url += " ";
            i++;
        }
//Remove the extraneous space and/or newline from the right side
        url = url.replace(new EReg("\s+$", ""), "");
        return url;
    }

    private function loadMtl(mtlurl:String):Void {
// Add raw-data dependency to queue and load dependencies now,
// which will pause the parsing in the meantime.
        addDependency("mtl", new URLRequest(mtlurl), true);
        pauseAndRetrieveDependencies();
    }

    private function applyMaterial(lm:LoadedMaterial):Void {
        var decomposeID:Array<Dynamic>;
        var mesh:Mesh;
        var mat:MaterialBase;
        var j:Int;
        var specularData:SpecularData;
        var i:Int = 0;
        while (i < _meshes.length) {
            mesh = _meshes[i];
            decomposeID = mesh.material.name.split("~");
            if (decomposeID[0] == lm.materialID) {
                if (lm.cm) {
                    if (mesh.material) mesh.material = null;
                    mesh.material = lm.cm;
                }

                else if (lm.texture) {
                    if (materialMode < 2) {
// if materialMode is 0 or 1, we create a SinglePass
                        mat = cast((mesh.material), TextureMaterial);
                        cast((mat), TextureMaterial).texture = lm.texture;
                        cast((mat), TextureMaterial).ambientColor = lm.ambientColor;
                        cast((mat), TextureMaterial).alpha = lm.alpha;
                        cast((mat), TextureMaterial).repeat = true;
                        if (lm.specularMethod) {
// By setting the specularMethod property to null before assigning
// the actual method instance, we avoid having the properties of
// the new method being overridden with the settings from the old
// one, which is default behavior of the setter.
                            cast((mat), TextureMaterial).specularMethod = null;
                            cast((mat), TextureMaterial).specularMethod = lm.specularMethod;
                        }

                        else if (_materialSpecularData) {
                            j = 0;
                            while (j < _materialSpecularData.length) {
                                specularData = _materialSpecularData[j];
                                if (specularData.materialID == lm.materialID) {
                                    cast((mat), TextureMaterial).specularMethod = null;
// Prevent property overwrite (see above)
                                    cast((mat), TextureMaterial).specularMethod = specularData.basicSpecularMethod;
                                    cast((mat), TextureMaterial).ambientColor = specularData.ambientColor;
                                    cast((mat), TextureMaterial).alpha = specularData.alpha;
                                    break;
                                }
                                ++j;
                            }
                        }
                    }

                    else {
//if materialMode==2 this is a MultiPassTexture
                        mat = cast((mesh.material), TextureMultiPassMaterial);
                        cast((mat), TextureMultiPassMaterial).texture = lm.texture;
                        cast((mat), TextureMultiPassMaterial).ambientColor = lm.ambientColor;
                        cast((mat), TextureMultiPassMaterial).repeat = true;
                        if (lm.specularMethod) {
// By setting the specularMethod property to null before assigning
// the actual method instance, we avoid having the properties of
// the new method being overridden with the settings from the old
// one, which is default behavior of the setter.
                            cast((mat), TextureMultiPassMaterial).specularMethod = null;
                            cast((mat), TextureMultiPassMaterial).specularMethod = lm.specularMethod;
                        }

                        else if (_materialSpecularData) {
                            j = 0;
                            while (j < _materialSpecularData.length) {
                                specularData = _materialSpecularData[j];
                                if (specularData.materialID == lm.materialID) {
                                    cast((mat), TextureMultiPassMaterial).specularMethod = null;
// Prevent property overwrite (see above)
                                    cast((mat), TextureMultiPassMaterial).specularMethod = specularData.basicSpecularMethod;
                                    cast((mat), TextureMultiPassMaterial).ambientColor = specularData.ambientColor;
                                    break;
                                }
                                ++j;
                            }
                        }
                    }

                }
                mesh.material.name = (decomposeID[1]) ? decomposeID[1] : decomposeID[0];
                _meshes.splice(i, 1);
                --i;
            }
            ++i;
        }
        if (lm.cm || mat) finalizeAsset(lm.cm || mat);
    }

    private function applyMaterials():Void {
        if (_materialLoaded.length == 0) return;
        var i:Int = 0;
        while (i < _materialLoaded.length) {
            applyMaterial(_materialLoaded[i]);
            ++i;
        }
    }

}

class ObjectGroup {

    public var name:String;
    public var groups:Vector<Group>;

    public function new() {
        groups = new Vector<Group>();
    }

}

class Group {

    public var name:String;
    public var materialID:String;
    public var materialGroups:Vector<MaterialGroup>;

    public function new() {
        materialGroups = new Vector<MaterialGroup>();
    }

}

class MaterialGroup {

    public var url:String;
    public var faces:Vector<FaceData>;

    public function new() {
        faces = new Vector<FaceData>();
    }

}

class SpecularData {

    public var materialID:String;
    public var basicSpecularMethod:BasicSpecularMethod;
    public var ambientColor:Int;
    public var alpha:Float;

    public function new() {
        ambientColor = 0xFFFFFF;
        alpha = 1;
    }

}

class LoadedMaterial {

    public var materialID:String;
    public var texture:Texture2DBase;
    public var cm:MaterialBase;
    public var specularMethod:BasicSpecularMethod;
    public var ambientColor:Int;
    public var alpha:Float;

    public function new() {
        ambientColor = 0xFFFFFF;
        alpha = 1;
    }


}

class FaceData {

    public var vertexIndices:Vector<UInt>;
    public var uvIndices:Vector<UInt>;
    public var normalIndices:Vector<UInt>;
    public var indexIds:Vector<String>;
// used for real index lookups

    public function new() {
        vertexIndices = new Vector<UInt>();
        uvIndices = new Vector<UInt>();
        normalIndices = new Vector<UInt>();
        indexIds = new Vector<String>();
    }

}


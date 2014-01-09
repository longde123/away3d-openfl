/**
 * Helper Class for the Mesh object <code>MeshHelper</code>
 * A series of methods usually usefull for mesh manipulations
 */
package away3d.tools.helpers;


import flash.Vector;
import away3d.containers.ObjectContainer3D;
import away3d.core.base.CompactSubGeometry;
import away3d.core.base.Geometry;
import away3d.core.base.ISubGeometry;
import away3d.core.base.Object3D;
import away3d.core.base.SubGeometry;
import away3d.core.base.data.UV;
import away3d.core.base.data.Vertex;
import away3d.entities.Mesh;
import away3d.materials.MaterialBase;
import away3d.materials.utils.DefaultMaterialManager;
import away3d.tools.utils.Bounds;
import away3d.tools.utils.GeomUtil;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class MeshHelper {

    static private var LIMIT:Int = 196605;
/**
	 * Returns the boundingRadius of an Entity of a Mesh.
	 * @param mesh        Mesh. The mesh to get the boundingRadius from.
	 */

    static public function boundingRadius(mesh:Mesh):Float {
        var radius:Float;
        try {
            radius = Math.max((mesh.maxX - mesh.minX) * cast((mesh), Object3D).scaleX, (mesh.maxY - mesh.minY) * cast((mesh), Object3D).scaleY, (mesh.maxZ - mesh.minZ) * cast((mesh), Object3D).scaleZ);
        }
        catch (e) {
            Bounds.getMeshBounds(mesh);
            radius = Math.max((Bounds.maxX - Bounds.minX) * cast((mesh), Object3D).scaleX, (Bounds.maxY - Bounds.minY) * cast((mesh), Object3D).scaleY, (Bounds.maxZ - Bounds.minZ) * cast((mesh), Object3D).scaleZ);
        }

        return radius * .5;
    }

/**
	 * Returns the boundingRadius of a ObjectContainer3D
	 * @param container        ObjectContainer3D. The ObjectContainer3D and its children to get the boundingRadius from.
	 */

    static public function boundingRadiusContainer(container:ObjectContainer3D):Float {
        Bounds.getObjectContainerBounds(container);
        var radius:Float = Math.max((Bounds.maxX - Bounds.minX) * cast((container), Object3D).scaleX, (Bounds.maxY - Bounds.minY) * cast((container), Object3D).scaleY, (Bounds.maxZ - Bounds.minZ) * cast((container), Object3D).scaleZ);
        return radius * .5;
    }

/**
	 * Recenter geometry
	 * @param mesh                Mesh. The Mesh to recenter in its own objectspace
	 * @param keepPosition    Boolean. KeepPosition applys the offset to the object position. Object is "visually" at same position.
	 */

    static public function recenter(mesh:Mesh, keepPosition:Bool = true):Void {
        Bounds.getMeshBounds(mesh);
        var dx:Float = (Bounds.minX + Bounds.maxX) * .5;
        var dy:Float = (Bounds.minY + Bounds.maxY) * .5;
        var dz:Float = (Bounds.minZ + Bounds.maxZ) * .5;
        applyPosition(mesh, -dx, -dy, -dz);
        if (!keepPosition) {
            mesh.x -= dx;
            mesh.y -= dy;
            mesh.z -= dz;
        }
    }

/**
	 * Recenter geometry of all meshes found into container
	 * @param mesh                Mesh. The Mesh to recenter in its own objectspace
	 * @param keepPosition    Boolean. KeepPosition applys the offset to the object position. Object is "visually" at same position.
	 */

    static public function recenterContainer(obj:ObjectContainer3D, keepPosition:Bool = true):Void {
        var child:ObjectContainer3D;
        if (Std.is(obj, Mesh && cast((obj), ObjectContainer3D).numChildren == 0)) recenter(cast((obj), Mesh), keepPosition);
        var i:Int = 0;
        while (i < cast((obj), ObjectContainer3D).numChildren) {
            child = cast((obj), ObjectContainer3D).getChildAt(i);
            recenterContainer(child, keepPosition);
            ++i;
        }
    }

/**
	 * Applys the rotation values of a mesh in object space and resets rotations to zero.
	 * @param mesh                Mesh. The Mesh to alter
	 */

    static public function applyRotations(mesh:Mesh):Void {
        var i:Int = 0;
        var j:Int;
        var len:Int;
        var vStride:Int;
        var vOffs:Int;
        var nStride:Int;
        var nOffs:Int;
        var geometry:Geometry = mesh.geometry;
        var geometries:Vector<ISubGeometry> = geometry.subGeometries;
        var vertices:Vector<Float>;
        var normals:Vector<Float>;
        var numSubGeoms:Int = geometries.length;
        var subGeom:ISubGeometry;
        var t:Matrix3D = mesh.transform.clone();
        t.appendScale(1 / mesh.scaleX, 1 / mesh.scaleY, 1 / mesh.scaleZ);
        var holder:Vector3D = new Vector3D();
        i = 0;
        while (i < numSubGeoms) {
            subGeom = cast((geometries[i]), ISubGeometry);
            vertices = subGeom.vertexData;
            vOffs = subGeom.vertexOffset;
            vStride = subGeom.vertexStride;
            normals = subGeom.vertexNormalData;
            nOffs = subGeom.vertexNormalOffset;
            nStride = subGeom.vertexNormalStride;
            len = subGeom.numVertices;
            j = 0;
            while (j < len) {
//verts
                holder.x = vertices[vOffs + j * vStride + 0];
                holder.y = vertices[vOffs + j * vStride + 1];
                holder.z = vertices[vOffs + j * vStride + 2];
                holder = t.deltaTransformVector(holder);
                vertices[vOffs + j * vStride + 0] = holder.x;
                vertices[vOffs + j * vStride + 1] = holder.y;
                vertices[vOffs + j * vStride + 2] = holder.z;
//norms
                holder.x = normals[nOffs + j * nStride + 0];
                holder.y = normals[nOffs + j * nStride + 1];
                holder.z = normals[nOffs + j * nStride + 2];
                holder = t.deltaTransformVector(holder);
                holder.normalize();
                normals[nOffs + j * nStride + 0] = holder.x;
                normals[nOffs + j * nStride + 1] = holder.y;
                normals[nOffs + j * nStride + 2] = holder.z;
                j++;
            }
            if (Std.is(subGeom, CompactSubGeometry)) cast((subGeom), CompactSubGeometry).updateData(vertices)
            else {
                cast((subGeom), SubGeometry).updateVertexData(vertices);
                cast((subGeom), SubGeometry).updateVertexNormalData(normals);
            }

            ++i;
        }
        mesh.rotationX = mesh.rotationY = mesh.rotationZ = 0;
    }

/**
	 * Applys the rotation values of each mesh found into an ObjectContainer3D
	 * @param obj                ObjectContainer3D. The ObjectContainer3D to alter
	 */

    static public function applyRotationsContainer(obj:ObjectContainer3D):Void {
        var child:ObjectContainer3D;
        if (Std.is(obj, Mesh && cast((obj), ObjectContainer3D).numChildren == 0)) applyRotations(cast((obj), Mesh));
        var i:Int = 0;
        while (i < cast((obj), ObjectContainer3D).numChildren) {
            child = cast((obj), ObjectContainer3D).getChildAt(i);
            applyRotationsContainer(child);
            ++i;
        }
    }

/**
	 * Applys the scaleX, scaleY and scaleZ scale factors to the mesh vertices. Resets the mesh scaleX, scaleY and scaleZ properties to 1;
	 * @param mesh                Mesh. The Mesh to rescale
	 * @param scaleX            Number. The scale factor to apply on all vertices x values.
	 * @param scaleY            Number. The scale factor to apply on all vertices y values.
	 * @param scaleZ            Number. The scale factor to apply on all vertices z values.
	 * @param parent            ObjectContainer3D. If a parent is set, the position of children is also scaled
	 */

    static public function applyScales(mesh:Mesh, scaleX:Float, scaleY:Float, scaleZ:Float, parent:ObjectContainer3D = null):Void {
        if (scaleX == 1 && scaleY == 1 && scaleZ == 1) return;
        if (mesh.animator) {
            mesh.scaleX = scaleX;
            mesh.scaleY = scaleY;
            mesh.scaleZ = scaleZ;
            return;
        }
        var i:Int = 0;
        var j:Int;
        var len:Int;
        var vStride:Int;
        var vOffs:Int;
        var geometry:Geometry = mesh.geometry;
        var geometries:Vector<ISubGeometry> = geometry.subGeometries;
        var vertices:Vector<Float>;
        var numSubGeoms:Int = geometries.length;
        var subGeom:ISubGeometry;
        i = 0;
        while (i < numSubGeoms) {
            subGeom = cast((geometries[i]), ISubGeometry);
            vOffs = subGeom.vertexOffset;
            vStride = subGeom.vertexStride;
            vertices = subGeom.vertexData;
            len = subGeom.numVertices;
            j = 0;
            while (j < len) {
                vertices[vOffs + j * vStride + 0] *= scaleX;
                vertices[vOffs + j * vStride + 1] *= scaleY;
                vertices[vOffs + j * vStride + 2] *= scaleZ;
                j++;
            }
            if (Std.is(subGeom, CompactSubGeometry)) cast((subGeom), CompactSubGeometry).updateData(vertices)
            else cast((subGeom), SubGeometry).updateVertexData(vertices);
            ++i;
        }
        mesh.scaleX = mesh.scaleY = mesh.scaleZ = 1;
        if (parent) {
            mesh.x *= scaleX;
            mesh.y *= scaleY;
            mesh.z *= scaleZ;
        }
    }

/**
	 * Applys the scale properties values of each mesh found into an ObjectContainer3D
	 * @param obj                ObjectContainer3D. The ObjectContainer3D to alter
	 * @param scaleX            Number. The scale factor to apply on all vertices x values.
	 * @param scaleY            Number. The scale factor to apply on all vertices y values.
	 * @param scaleZ            Number. The scale factor to apply on all vertices z values.
	 */

    static public function applyScalesContainer(obj:ObjectContainer3D, scaleX:Float, scaleY:Float, scaleZ:Float, parent:ObjectContainer3D = null):Void {
        parent = parent;
        var child:ObjectContainer3D;
        if (Std.is(obj, Mesh && cast((obj), ObjectContainer3D).numChildren == 0)) applyScales(cast((obj), Mesh), scaleX, scaleY, scaleZ, obj);
        var i:Int = 0;
        while (i < cast((obj), ObjectContainer3D).numChildren) {
            child = cast((obj), ObjectContainer3D).getChildAt(i);
            applyScalesContainer(child, scaleX, scaleY, scaleZ, obj);
            ++i;
        }
    }

/**
	 * Applys an offset to a mesh at vertices level
	 * @param mesh                Mesh. The Mesh to offset
	 * @param dx                    Number. The offset along the x axis
	 * @param dy                    Number. The offset along the y axis
	 * @param dz                    Number. The offset along the z axis
	 */

    static public function applyPosition(mesh:Mesh, dx:Float, dy:Float, dz:Float):Void {
        var i:Int = 0;
        var j:Int;
        var len:Int;
        var vStride:Int;
        var vOffs:Int;
        var geometry:Geometry = mesh.geometry;
        var geometries:Vector<ISubGeometry> = geometry.subGeometries;
        var vertices:Vector<Float>;
        var numSubGeoms:Int = geometries.length;
        var subGeom:ISubGeometry;
        i = 0;
        while (i < numSubGeoms) {
            subGeom = cast((geometries[i]), ISubGeometry);
            vOffs = subGeom.vertexOffset;
            vStride = subGeom.vertexStride;
            vertices = subGeom.vertexData;
            len = subGeom.numVertices;
            j = 0;
            while (j < len) {
                vertices[vOffs + j * vStride + 0] += dx;
                vertices[vOffs + j * vStride + 1] += dy;
                vertices[vOffs + j * vStride + 2] += dz;
                j++;
            }
            if (Std.is(subGeom, CompactSubGeometry)) cast((subGeom), CompactSubGeometry).updateData(vertices)
            else cast((subGeom), SubGeometry).updateVertexData(vertices);
            ++i;
        }
        mesh.x -= dx;
        mesh.y -= dy;
        mesh.z -= dz;
    }

/**
	 * Clones a Mesh
	 * @param mesh                Mesh. The mesh to clone
	 * @param newname        [optional] String. new name for the duplicated mesh. Default = "";
	 *
	 * @ returns Mesh
	 */

    static public function clone(mesh:Mesh, newName:String = ""):Mesh {
        var geometry:Geometry = mesh.geometry.clone();
        var newMesh:Mesh = new Mesh(geometry, mesh.material);
        newMesh.name = newName;
        return newMesh;
    }

/**
	 * Inverts the faces of all the Meshes into an ObjectContainer3D
	 * @param obj        ObjectContainer3D. The ObjectContainer3D to invert.
	 */

    static public function invertFacesInContainer(obj:ObjectContainer3D):Void {
        var child:ObjectContainer3D;
        if (Std.is(obj, Mesh && cast((obj), ObjectContainer3D).numChildren == 0)) invertFaces(cast((obj), Mesh));
        var i:Int = 0;
        while (i < cast((obj), ObjectContainer3D).numChildren) {
            child = cast((obj), ObjectContainer3D).getChildAt(i);
            invertFacesInContainer(child);
            ++i;
        }
    }

/**
	 * Inverts the faces of a Mesh
	 * @param mesh        Mesh. The Mesh to invert.
	 * @param invertUV        Boolean. If the uvs are inverted too. Default is false;
	 */

    static public function invertFaces(mesh:Mesh, invertU:Bool = false):Void {
        var i:Int = 0;
        var j:Int;
        var len:Int;
        var tStride:Int;
        var tOffs:Int;
        var nStride:Int;
        var nOffs:Int;
        var uStride:Int;
        var uOffs:Int;
        var geometry:Geometry = mesh.geometry;
        var geometries:Vector<ISubGeometry> = geometry.subGeometries;
        var indices:Vector<UInt>;
        var indicesC:Vector<UInt>;
        var normals:Vector<Float>;
        var tangents:Vector<Float>;
        var uvs:Vector<Float>;
        var numSubGeoms:Int = geometries.length;
        var subGeom:ISubGeometry;
        i = 0;
        while (i < numSubGeoms) {
            subGeom = cast((geometries[i]), ISubGeometry);
            indices = subGeom.indexData;
            indicesC = subGeom.indexData.concat();
            normals = subGeom.vertexNormalData;
            nOffs = subGeom.vertexNormalOffset;
            nStride = subGeom.vertexNormalStride;
            uvs = subGeom.UVData;
            uOffs = subGeom.UVOffset;
            uStride = subGeom.UVStride;
            len = subGeom.numVertices;
            tangents = subGeom.vertexTangentData;
            tOffs = subGeom.vertexTangentOffset;
            tStride = subGeom.vertexTangentStride;
            i = 0;
            while (i < indices.length) {
                indices[i + 0] = indicesC[i + 2];
                indices[i + 1] = indicesC[i + 1];
                indices[i + 2] = indicesC[i + 0];
                i += 3;
            }
            j = 0;
            while (j < len) {
                normals[nOffs + j * nStride + 0] *= -1;
                normals[nOffs + j * nStride + 1] *= -1;
                normals[nOffs + j * nStride + 2] *= -1;
                tangents[tOffs + j * tStride + 0] *= -1;
                tangents[tOffs + j * tStride + 1] *= -1;
                tangents[tOffs + j * tStride + 2] *= -1;
                if (invertU) uvs[uOffs + j * uStride + 0] = 1 - uvs[uOffs + j * uStride + 0];
                j++;
            }
            if (Std.is(subGeom, CompactSubGeometry)) cast((subGeom), CompactSubGeometry).updateData(subGeom.vertexData)
            else {
                cast((subGeom), SubGeometry).updateIndexData(indices);
                cast((subGeom), SubGeometry).updateVertexNormalData(normals);
                cast((subGeom), SubGeometry).updateVertexTangentData(tangents);
                cast((subGeom), SubGeometry).updateUVData(uvs);
            }

            ++i;
        }
    }

/**
	 * Build a Mesh from Vectors
	 * @param vertices                Vector.&lt;Number&gt;. The vertices Vector.&lt;Number&gt;, must hold a multiple of 3 numbers.
	 * @param indices                Vector.&lt;uint&gt;. The indices Vector.&lt;uint&gt;, holding the face order
	 * @param uvs                    [optional] Vector.&lt;Number&gt;. The uvs Vector, must hold a series of numbers of (vertices.length/3 * 2) entries. If none is set, default uv's are applied
	 * if no uv's are defined, default uv mapping is set.
	 * @param name                    [optional] String. new name for the generated mesh. Default = "";
	 * @param material                [optional] MaterialBase. new name for the duplicated mesh. Default = null;
	 * @param shareVertices        [optional] Boolean. Defines if the vertices are shared or not. When true surface gets a smoother appearance when exposed to light. Default = true;
	 * @param useDefaultMap    [optional] Boolean. Defines if the mesh receives the default engine map if no material is passes. Default = true;
	 *
	 * @ returns Mesh
	 */

    static public function build(vertices:Vector<Float>, indices:Vector<UInt>, uvs:Vector<Float> = null, name:String = "", material:MaterialBase = null, shareVertices:Bool = true, useDefaultMap:Bool = true, useCompactSubGeometry:Bool = true):Mesh {
        var i:Int = 0;
        if (useCompactSubGeometry) {
            var subGeoms:Vector<ISubGeometry> = GeomUtil.fromVectors(vertices, indices, uvs, null, null, null, null);
            var geometry:Geometry = new Geometry();
            i = 0;
            while (i < subGeoms.length) {
                subGeoms[i].autoDeriveVertexNormals = true;
                subGeoms[i].autoDeriveVertexTangents = true;
                geometry.addSubGeometry(subGeoms[i]);
                i++;
            }
            material = ((!material)) ? DefaultMaterialManager.getDefaultMaterial() : material;
            var m:Mesh = new Mesh(geometry, material);
            if (name != "") m.name = name;
            return m;
        }

        else {
            var subGeom:SubGeometry = new SubGeometry();
            subGeom.autoDeriveVertexNormals = true;
            subGeom.autoDeriveVertexTangents = true;
            geometry = new Geometry();
            geometry.addSubGeometry(subGeom);
            material = ((!material && useDefaultMap)) ? DefaultMaterialManager.getDefaultMaterial() : material;
            m = new Mesh(geometry, material);
            if (name != "") m.name = name;
            var nvertices:Vector<Float> = new Vector<Float>();
            var nuvs:Vector<Float> = new Vector<Float>();
            var nindices:Vector<UInt> = new Vector<UInt>();
            var defaultUVS:Vector<Float> = Vector.ofArray(cast [0, 1, .5, 0, 1, 1, .5, 0]);
            var uvid:Int = 0;
            if (shareVertices) {
                var dShared:Dictionary = new Dictionary();
                var uv:UV = new UV();
                var ref:String;
            }
            var uvind:Int;
            var vind:Int;
            var ind:Int;
//var j:uint;
            var vertex:Vertex = new Vertex();
            i = 0;
            while (i < indices.length) {
                ind = indices[i] * 3;
                vertex.x = vertices[ind];
                vertex.y = vertices[ind + 1];
                vertex.z = vertices[ind + 2];
                if (nvertices.length == LIMIT) {
                    subGeom.updateVertexData(nvertices);
                    subGeom.updateIndexData(nindices);
                    subGeom.updateUVData(nuvs);
                    if (shareVertices) {
                        dShared = null;
                        dShared = new Dictionary();
                    }
                    subGeom = new SubGeometry();
                    subGeom.autoDeriveVertexNormals = true;
                    subGeom.autoDeriveVertexTangents = true;
                    geometry.addSubGeometry(subGeom);
                    uvid = 0;
                    nvertices = new Vector<Float>();
                    nindices = new Vector<UInt>();
                    nuvs = new Vector<Float>();
                }
                vind = nvertices.length / 3;
                uvind = indices[i] * 2;
                if (shareVertices) {
                    uv.u = uvs[uvind];
                    uv.v = uvs[uvind + 1];
                    ref = vertex.toString() + uv.toString();
                    if (dShared[ref]) {
                        nindices[nindices.length] = dShared[ref];
                        {
                            ++i;
                            continue;
                        }

                    }
                    dShared[ref] = vind;
                }
                nindices[nindices.length] = vind;
                nvertices.push(vertex.x, vertex.y, vertex.z);
                if (!uvs || uvind > uvs.length - 2) {
                    nuvs.push(defaultUVS[uvid], defaultUVS[uvid + 1]);
                    uvid = ((uvid + 2 > 3)) ? 0 : uvid += 2;
                }

                else nuvs.push(uvs[uvind], uvs[uvind + 1]);
                ++i;
            }
            if (shareVertices) dShared = null;
            subGeom.updateVertexData(nvertices);
            subGeom.updateIndexData(nindices);
            subGeom.updateUVData(nuvs);
            return m;
        }

    }

/**
	 * Splits the subgeometries of a given mesh in a series of new meshes
	 * @param mesh                    Mesh. The mesh to split in a series of independant meshes from its subgeometries.
	 * @param disposeSource        Boolean. If the mesh source must be destroyed after the split. Default is false;
	 *
	 * @ returns Vector..&lt;Mesh&gt;
	 */

    static public function splitMesh(mesh:Mesh, disposeSource:Bool = false):Vector<Mesh> {
        var meshes:Vector<Mesh> = new Vector<Mesh>();
        var geometries:Vector<ISubGeometry> = mesh.geometry.subGeometries;
        var numSubGeoms:Int = geometries.length;
        if (numSubGeoms == 1) {
            meshes.push(mesh);
            return meshes;
        }
        if (Std.is(geometries[0], CompactSubGeometry)) return splitMeshCsg(mesh, disposeSource);
        var vertices:Vector<Float>;
        var indices:Vector<UInt>;
        var uvs:Vector<Float>;
        var normals:Vector<Float>;
        var tangents:Vector<Float>;
        var subGeom:ISubGeometry;
        var nGeom:Geometry;
        var nSubGeom:SubGeometry;
        var nm:Mesh;
        var nMeshMat:MaterialBase;
        var j:Int = 0;
        var i:Int = 0;
        while (i < numSubGeoms) {
            if (Std.is(geometries[0], SubGeometry)) subGeom = cast((geometries[i]), SubGeometry);
            vertices = subGeom.vertexData;
            indices = subGeom.indexData;
            uvs = subGeom.UVData;
            try {
                normals = subGeom.vertexNormalData;
                subGeom.autoDeriveVertexNormals = false;
            }
            catch (e) {
                subGeom.autoDeriveVertexNormals = true;
                normals = new Vector<Float>();
                j = 0;
                while (j < vertices.length)normals[j++] = 0.0;
            }

            try {
                tangents = subGeom.vertexTangentData;
                subGeom.autoDeriveVertexTangents = false;
            }
            catch (e) {
                subGeom.autoDeriveVertexTangents = true;
                tangents = new Vector<Float>();
                j = 0;
                while (j < vertices.length)tangents[j++] = 0.0;
            }

            vertices.fixed = false;
            indices.fixed = false;
            uvs.fixed = false;
            normals.fixed = false;
            tangents.fixed = false;
            nGeom = new Geometry();
            nm = new Mesh(nGeom, (mesh.subMeshes[i].material) ? mesh.subMeshes[i].material : nMeshMat);
            nSubGeom = new SubGeometry();
            nSubGeom.updateVertexData(vertices);
            nSubGeom.updateIndexData(indices);
            nSubGeom.updateUVData(uvs);
            nSubGeom.updateVertexNormalData(normals);
            nSubGeom.updateVertexTangentData(tangents);
            nGeom.addSubGeometry(nSubGeom);
            meshes.push(nm);
            ++i;
        }
        if (disposeSource) mesh = null;
        return meshes;
    }

    static private function splitMeshCsg(mesh:Mesh, disposeSource:Bool = false):Vector<Mesh> {
        var meshes:Vector<Mesh> = new Vector<Mesh>();
        var geometries:Vector<ISubGeometry> = mesh.geometry.subGeometries;
        var numSubGeoms:Int = geometries.length;
        if (numSubGeoms == 1) {
            meshes.push(mesh);
            return meshes;
        }
        var subGeom:ISubGeometry;
        var nGeom:Geometry;
        var nSubGeom:CompactSubGeometry;
        var nm:Mesh;
        var nMeshMat:MaterialBase;
        var i:Int = 0;
        while (i < numSubGeoms) {
            subGeom = cast((geometries[i]), CompactSubGeometry);
            nGeom = new Geometry();
            nm = new Mesh(nGeom, (mesh.subMeshes[i].material) ? mesh.subMeshes[i].material : nMeshMat);
            nSubGeom = new CompactSubGeometry();
            nSubGeom.updateData(subGeom.vertexData);
            nSubGeom.updateIndexData(subGeom.indexData);
            nGeom.addSubGeometry(nSubGeom);
            meshes.push(nm);
            ++i;
        }
        if (disposeSource) mesh = null;
        return meshes;
    }

}


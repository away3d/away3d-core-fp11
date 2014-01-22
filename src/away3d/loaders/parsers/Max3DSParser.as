package away3d.loaders.parsers
{
	import away3d.*;
	import away3d.containers.*;
	import away3d.core.base.*;
	import away3d.entities.*;
	import away3d.library.assets.*;
	import away3d.loaders.misc.*;
	import away3d.loaders.parsers.utils.*;
	import away3d.materials.*;
	import away3d.materials.utils.*;
	import away3d.textures.*;
	import away3d.tools.utils.*;
	
	import flash.geom.*;
	import flash.net.*;
	import flash.utils.*;
	
	use namespace arcane;
	
	/**
	 * Max3DSParser provides a parser for the 3ds data type.
	 */
	public class Max3DSParser extends ParserBase
	{
		private var _byteData:ByteArray;
		
		private var _textures:Object;
		private var _materials:Object;
		private var _unfinalized_objects:Object;
		
		private var _cur_obj_end:uint;
		private var _cur_obj:ObjectVO;
		
		private var _cur_mat_end:uint;
		private var _cur_mat:MaterialVO;
		private var _useSmoothingGroups:Boolean;
		
		/**
		 * Creates a new <code>Max3DSParser</code> object.
		 * 
		 * @param useSmoothingGroups Determines whether the parser looks for smoothing groups in the 3ds file or assumes uniform smoothing. Defaults to true.
		 */
		public function Max3DSParser(useSmoothingGroups:Boolean = true)
		{
			super(ParserDataFormat.BINARY);
			
			_useSmoothingGroups = useSmoothingGroups;
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension:String):Boolean
		{
			extension = extension.toLowerCase();
			return extension == "3ds";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data:*):Boolean
		{
			var ba:ByteArray;
			
			ba = ParserUtil.toByteArray(data);
			if (ba) {
				ba.position = 0;
				if (ba.readShort() == 0x4d4d)
					return true;
			}
			
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function resolveDependency(resourceDependency:ResourceDependency):void
		{
			if (resourceDependency.assets.length == 1) {
				var asset:IAsset;
				
				asset = resourceDependency.assets[0];
				if (asset.assetType == AssetType.TEXTURE) {
					var tex:TextureVO;
					
					tex = _textures[resourceDependency.id];
					tex.texture = asset as Texture2DBase;
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{
			// TODO: Implement
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function startParsing(frameLimit:Number):void
		{
			super.startParsing(frameLimit);
			
			_byteData = ParserUtil.toByteArray(_data);
			_byteData.position = 0;
			_byteData.endian = Endian.LITTLE_ENDIAN;
			
			_textures = {};
			_materials = {};
			_unfinalized_objects = {};
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function proceedParsing():Boolean
		{
			
			// TODO: With this construct, the loop will run no-op for as long
			// as there is time once file has finished reading. Consider a nice
			// way to stop loop when byte array is empty, without putting it in
			// the while-conditional, which will prevent finalizations from
			// happening after the last chunk.
			while (hasTime()) {
				
				// If we are currently working on an object, and the most recent chunk was
				// the last one in that object, finalize the current object.
				if (_cur_mat && _byteData.position >= _cur_mat_end)
					finalizeCurrentMaterial();
				else if (_cur_obj && _byteData.position >= _cur_obj_end) {
					// Can't finalize at this point, because we have to wait until the full
					// animation section has been parsed for any potential pivot definitions
					_unfinalized_objects[_cur_obj.name] = _cur_obj;
					_cur_obj_end = uint.MAX_VALUE;
					_cur_obj = null;
				}
				
				if (_byteData.bytesAvailable) {
					var cid:uint;
					var len:uint;
					var end:uint;
					
					cid = _byteData.readUnsignedShort();
					len = _byteData.readUnsignedInt();
					end = _byteData.position + (len - 6);
					
					switch (cid) {
						case 0x4D4D: // MAIN3DS
						case 0x3D3D: // EDIT3DS
						case 0xB000: // KEYF3DS
							// This types are "container chunks" and contain only
							// sub-chunks (no data on their own.) This means that
							// there is nothing more to parse at this point, and 
							// instead we should progress to the next chunk, which
							// will be the first sub-chunk of this one.
							continue;
							break;
						
						case 0xAFFF: // MATERIAL
							_cur_mat_end = end;
							_cur_mat = parseMaterial();
							break;
						
						case 0x4000: // EDIT_OBJECT
							_cur_obj_end = end;
							_cur_obj = new ObjectVO();
							_cur_obj.name = readNulTermString();
							_cur_obj.materials = new Vector.<String>();
							_cur_obj.materialFaces = {};
							break;
						
						case 0x4100: // OBJ_TRIMESH 
							_cur_obj.type = AssetType.MESH;
							break;
						
						case 0x4110: // TRI_VERTEXL
							parseVertexList();
							break;
						
						case 0x4120: // TRI_FACELIST
							parseFaceList();
							break;
						
						case 0x4140: // TRI_MAPPINGCOORDS
							parseUVList();
							break;
						
						case 0x4130: // Face materials
							parseFaceMaterialList();
							break;
						
						case 0x4160: // Transform
							_cur_obj.transform = readTransform();
							break;
						
						case 0xB002: // Object animation (including pivot)
							parseObjectAnimation(end);
							break;
						
						case 0x4150: // Smoothing groups
							parseSmoothingGroups();
							break;
						
						default:
							// Skip this (unknown) chunk
							_byteData.position += (len - 6);
							break;
					}
					
					// Pause parsing if there were any dependencies found during this
					// iteration (i.e. if there are any dependencies that need to be
					// retrieved at this time.)
					if (dependencies.length) {
						pauseAndRetrieveDependencies();
						break;
					}
				}
			}
			
			// More parsing is required if the entire byte array has not yet
			// been read, or if there is a currently non-finalized object in
			// the pipeline.
			if (_byteData.bytesAvailable || _cur_obj || _cur_mat)
				return MORE_TO_PARSE;
			else {
				var name:String;
				
				// Finalize any remaining objects before ending.
				for (name in _unfinalized_objects) {
					var obj:ObjectContainer3D;
					obj = constructObject(_unfinalized_objects[name]);
					if (obj)
						finalizeAsset(obj, name);
				}
				
				return PARSING_DONE;
			}
		}
		
		private function parseMaterial():MaterialVO
		{
			var mat:MaterialVO;
			
			mat = new MaterialVO();
			
			while (_byteData.position < _cur_mat_end) {
				var cid:uint;
				var len:uint;
				var end:uint;
				
				cid = _byteData.readUnsignedShort();
				len = _byteData.readUnsignedInt();
				end = _byteData.position + (len - 6);
				
				switch (cid) {
					case 0xA000: // Material name
						mat.name = readNulTermString();
						break;
					
					case 0xA010: // Ambient color
						mat.ambientColor = readColor();
						break;
					
					case 0xA020: // Diffuse color
						mat.diffuseColor = readColor();
						break;
					
					case 0xA030: // Specular color
						mat.specularColor = readColor();
						break;
					
					case 0xA081: // Two-sided, existence indicates "true"
						mat.twoSided = true;
						break;
					
					case 0xA200: // Main (color) texture 
						mat.colorMap = parseTexture(end);
						break;
					
					case 0xA204: // Specular map
						mat.specularMap = parseTexture(end);
						break;
					
					default:
						_byteData.position = end;
						break;
				}
			}
			
			return mat;
		}
		
		private function parseTexture(end:uint):TextureVO
		{
			var tex:TextureVO;
			
			tex = new TextureVO();
			
			while (_byteData.position < end) {
				var cid:uint;
				var len:uint;
				
				cid = _byteData.readUnsignedShort();
				len = _byteData.readUnsignedInt();
				
				switch (cid) {
					case 0xA300:
						tex.url = readNulTermString();
						break;
					
					default:
						// Skip this unknown texture sub-chunk
						_byteData.position += (len - 6);
						break;
				}
			}
			
			_textures[tex.url] = tex;
			addDependency(tex.url, new URLRequest(tex.url));
			
			return tex;
		}
		
		private function parseVertexList():void
		{
			var i:uint;
			var len:uint;
			var count:uint;
			
			count = _byteData.readUnsignedShort();
			_cur_obj.verts = new Vector.<Number>(count*3, true);
			
			i = 0;
			len = _cur_obj.verts.length;
			while (i < len) {
				var x:Number, y:Number, z:Number;
				
				x = _byteData.readFloat();
				y = _byteData.readFloat();
				z = _byteData.readFloat();
				
				_cur_obj.verts[i++] = x;
				_cur_obj.verts[i++] = z;
				_cur_obj.verts[i++] = y;
			}
		}
		
		private function parseFaceList():void
		{
			var i:uint;
			var len:uint;
			var count:uint;
			
			count = _byteData.readUnsignedShort();
			_cur_obj.indices = new Vector.<uint>(count*3, true);
			
			i = 0;
			len = _cur_obj.indices.length;
			while (i < len) {
				var i0:uint, i1:uint, i2:uint;
				
				i0 = _byteData.readUnsignedShort();
				i1 = _byteData.readUnsignedShort();
				i2 = _byteData.readUnsignedShort();
				
				_cur_obj.indices[i++] = i0;
				_cur_obj.indices[i++] = i2;
				_cur_obj.indices[i++] = i1;
				
				// Skip "face info", irrelevant in Away3D
				_byteData.position += 2;
			}
			
			_cur_obj.smoothingGroups = new Vector.<uint>(count, true);
		}
		
		private function parseSmoothingGroups():void
		{
			var len:uint = _cur_obj.indices.length/3;
			var i:uint = 0;
			while (i < len) {
				_cur_obj.smoothingGroups[i] = _byteData.readUnsignedInt();
				i++;
			}
		}
		
		private function parseUVList():void
		{
			var i:uint;
			var len:uint;
			var count:uint;
			
			count = _byteData.readUnsignedShort();
			_cur_obj.uvs = new Vector.<Number>(count*2, true);
			
			i = 0;
			len = _cur_obj.uvs.length;
			while (i < len) {
				_cur_obj.uvs[i++] = _byteData.readFloat();
				_cur_obj.uvs[i++] = 1.0 - _byteData.readFloat();
			}
		}
		
		private function parseFaceMaterialList():void
		{
			var mat:String;
			var count:uint;
			var i:uint;
			var faces:Vector.<uint>;
			
			mat = readNulTermString();
			count = _byteData.readUnsignedShort();
			
			faces = new Vector.<uint>(count, true);
			i = 0;
			while (i < faces.length)
				faces[i++] = _byteData.readUnsignedShort();
			
			_cur_obj.materials.push(mat);
			_cur_obj.materialFaces[mat] = faces;
		}
		
		private function parseObjectAnimation(end:Number):void
		{
			var vo:ObjectVO;
			var obj:ObjectContainer3D;
			var pivot:Vector3D;
			var name:String;
			var hier:int;
			
			// Pivot defaults to origin
			pivot = new Vector3D;
			
			while (_byteData.position < end) {
				var cid:uint;
				var len:uint;
				
				cid = _byteData.readUnsignedShort();
				len = _byteData.readUnsignedInt();
				
				switch (cid) {
					case 0xb010: // Name/hierarchy
						name = readNulTermString();
						_byteData.position += 4;
						hier = _byteData.readShort();
						break;
					
					case 0xb013: // Pivot
						pivot.x = _byteData.readFloat();
						pivot.z = _byteData.readFloat();
						pivot.y = _byteData.readFloat();
						break;
					
					default:
						_byteData.position += (len - 6);
						break;
				}
			}
			
			// If name is "$$$DUMMY" this is an empty object (e.g. a container)
			// and will be ignored in this version of the parser
			// TODO: Implement containers in 3DS parser.
			if (name != '$$$DUMMY' && _unfinalized_objects.hasOwnProperty(name)) {
				vo = _unfinalized_objects[name];
				obj = constructObject(vo, pivot);
				
				if (obj)
					finalizeAsset(obj, vo.name);
				
				delete _unfinalized_objects[name];
			}
		}
		
		private function constructObject(obj:ObjectVO, pivot:Vector3D = null):ObjectContainer3D
		{
			if (obj.type == AssetType.MESH) {
				var i:uint;
				var subs:Vector.<ISubGeometry>;
				var geom:Geometry;
				var mat:MaterialBase;
				var mesh:Mesh;
				var mtx:Matrix3D;
				var vertices:Vector.<VertexVO>;
				var faces:Vector.<FaceVO>;
				
				if (obj.materials.length > 1)
					trace('The Away3D 3DS parser does not support multiple materials per mesh at this point.');
				
				// Ignore empty objects
				if (!obj.indices || obj.indices.length == 0)
					return null;
				
				vertices = new Vector.<VertexVO>(obj.verts.length/3, false);
				faces = new Vector.<FaceVO>(obj.indices.length/3, true);
				
				prepareData(vertices, faces, obj);
				
				if (_useSmoothingGroups)
					applySmoothGroups(vertices, faces);
				
				obj.verts = new Vector.<Number>(vertices.length*3, true);
				for (i = 0; i < vertices.length; i++) {
					obj.verts[i*3] = vertices[i].x;
					obj.verts[i*3 + 1] = vertices[i].y;
					obj.verts[i*3 + 2] = vertices[i].z;
				}
				obj.indices = new Vector.<uint>(faces.length*3, true);
				for (i = 0; i < faces.length; i++) {
					obj.indices[i*3] = faces[i].a;
					obj.indices[i*3 + 1] = faces[i].b;
					obj.indices[i*3 + 2] = faces[i].c;
				}
				
				if (obj.uvs) {
					// If the object had UVs to start with, use UVs generated by
					// smoothing group splitting algorithm. Otherwise those UVs
					// will be nonsense and should be skipped.
					obj.uvs = new Vector.<Number>(vertices.length*2, true);
					for (i = 0; i < vertices.length; i++) {
						obj.uvs[i*2] = vertices[i].u;
						obj.uvs[i*2 + 1] = vertices[i].v;
					}
				}
				
				geom = new Geometry();
				
				// Construct sub-geometries (potentially splitting buffers)
				// and add them to geometry.
				subs = GeomUtil.fromVectors(obj.verts, obj.indices, obj.uvs, null, null, null, null);
				for (i = 0; i < subs.length; i++)
					geom.subGeometries.push(subs[i]);
				
				if (obj.materials.length > 0) {
					var mname:String;
					mname = obj.materials[0];
					mat = _materials[mname].material;
				}
				
				// Apply pivot translation to geometry if a pivot was
				// found while parsing the keyframe chunk earlier.
				if (pivot) {
					if (obj.transform) {
						// If a transform was found while parsing the
						// object chunk, use it to find the local pivot vector
						var dat:Vector.<Number> = obj.transform.concat();
						dat[12] = 0;
						dat[13] = 0;
						dat[14] = 0;
						mtx = new Matrix3D(dat);
						pivot = mtx.transformVector(pivot);
					}
					
					pivot.scaleBy(-1);
					
					mtx = new Matrix3D();
					mtx.appendTranslation(pivot.x, pivot.y, pivot.z);
					geom.applyTransformation(mtx);
				}
				
				// Apply transformation to geometry if a transformation
				// was found while parsing the object chunk earlier.
				if (obj.transform) {
					mtx = new Matrix3D(obj.transform);
					mtx.invert();
					geom.applyTransformation(mtx);
				}
				
				// Final transform applied to geometry. Finalize the geometry,
				// which will no longer be modified after this point.
				finalizeAsset(geom, obj.name.concat('_geom'));
				
				// Build mesh and return it
				mesh = new Mesh(geom, mat);
				mesh.transform = new Matrix3D(obj.transform);
				return mesh;
			}
			
			// If reached, unknown
			return null;
		}
		
		private function prepareData(vertices:Vector.<VertexVO>, faces:Vector.<FaceVO>, obj:ObjectVO):void
		{
			// convert raw ObjectVO's data to structured VertexVO and FaceVO
			var i:int;
			var j:int;
			var k:int;
			var len:int = obj.verts.length;
			for (i = 0, j = 0, k = 0; i < len; ) {
				var v:VertexVO = new VertexVO;
				v.x = obj.verts[i++];
				v.y = obj.verts[i++];
				v.z = obj.verts[i++];
				if (obj.uvs) {
					v.u = obj.uvs[j++];
					v.v = obj.uvs[j++];
				}
				vertices[k++] = v;
			}
			len = obj.indices.length;
			for (i = 0, k = 0; i < len; ) {
				var f:FaceVO = new FaceVO();
				f.a = obj.indices[i++];
				f.b = obj.indices[i++];
				f.c = obj.indices[i++];
				f.smoothGroup = obj.smoothingGroups[k];
				faces[k++] = f;
			}
		}
		
		private function applySmoothGroups(vertices:Vector.<VertexVO>, faces:Vector.<FaceVO>):void
		{
			// clone vertices according to following rule:
			// clone if vertex's in faces from groups 1+2 and 3
			// don't clone if vertex's in faces from groups 1+2, 3 and 1+3
			
			var i:int;
			var j:int;
			var k:int;
			var l:int;
			var len:int;
			var numVerts:uint = vertices.length;
			var numFaces:uint = faces.length;
			
			// extract groups data for vertices
			var vGroups:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>(numVerts, true);
			for (i = 0; i < numVerts; i++)
				vGroups[i] = new Vector.<uint>;
			for (i = 0; i < numFaces; i++) {
				var face:FaceVO = FaceVO(faces[i]);
				for (j = 0; j < 3; j++) {
					var groups:Vector.<uint> = vGroups[(j == 0)? face.a : ((j == 1)? face.b : face.c)];
					var group:uint = face.smoothGroup;
					for (k = groups.length - 1; k >= 0; k--) {
						if ((group & groups[k]) > 0) {
							group |= groups[k];
							groups.splice(k, 1);
							k = groups.length - 1;
						}
					}
					groups.push(group);
				}
			}
			// clone vertices
			var vClones:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>(numVerts, true);
			for (i = 0; i < numVerts; i++) {
				if ((len = vGroups[i].length) < 1)
					continue;
				var clones:Vector.<uint> = new Vector.<uint>(len, true);
				vClones[i] = clones;
				clones[0] = i;
				var v0:VertexVO = vertices[i];
				for (j = 1; j < len; j++) {
					var v1:VertexVO = new VertexVO;
					v1.x = v0.x;
					v1.y = v0.y;
					v1.z = v0.z;
					v1.u = v0.u;
					v1.v = v0.v;
					clones[j] = vertices.length;
					vertices.push(v1);
				}
			}
			numVerts = vertices.length;
			
			for (i = 0; i < numFaces; i++) {
				face = FaceVO(faces[i]);
				group = face.smoothGroup;
				for (j = 0; j < 3; j++) {
					k = (j == 0)? face.a : ((j == 1)? face.b : face.c);
					groups = vGroups[k];
					len = groups.length;
					clones = vClones[k];
					for (l = 0; l < len; l++) {
						if (((group == 0) && (groups[l] == 0)) ||
							((group & groups[l]) > 0)) {
							var index:uint = clones[l];
							if (group == 0) {
								// vertex is unique if no smoothGroup found
								groups.splice(l, 1);
								clones.splice(l, 1);
							}
							if (j == 0)
								face.a = index;
							else if (j == 1)
								face.b = index;
							else
								face.c = index;
							l = len;
						}
					}
				}
			}
		}
		
		private function finalizeCurrentMaterial():void
		{
			var mat:MaterialBase;
			if (materialMode < 2) {
				if (_cur_mat.colorMap)
					mat = new TextureMaterial(_cur_mat.colorMap.texture || DefaultMaterialManager.getDefaultTexture());
				else
					mat = new ColorMaterial(_cur_mat.diffuseColor);
				SinglePassMaterialBase(mat).ambientColor = _cur_mat.ambientColor;
				SinglePassMaterialBase(mat).specularColor = _cur_mat.specularColor;
			} else {
				if (_cur_mat.colorMap)
					mat = new TextureMultiPassMaterial(_cur_mat.colorMap.texture || DefaultMaterialManager.getDefaultTexture());
				else
					mat = new ColorMultiPassMaterial(_cur_mat.diffuseColor);
				MultiPassMaterialBase(mat).ambientColor = _cur_mat.ambientColor;
				MultiPassMaterialBase(mat).specularColor = _cur_mat.specularColor;
			}
			
			mat.bothSides = _cur_mat.twoSided;
			
			finalizeAsset(mat, _cur_mat.name);
			
			_materials[_cur_mat.name] = _cur_mat;
			_cur_mat.material = mat;
			
			_cur_mat = null;
		}
		
		private function readNulTermString():String
		{
			var chr:uint;
			var str:String = new String();
			
			while ((chr = _byteData.readUnsignedByte()) > 0)
				str += String.fromCharCode(chr);
			
			return str;
		}
		
		private function readTransform():Vector.<Number>
		{
			var data:Vector.<Number>;
			
			data = new Vector.<Number>(16, true);
			
			// X axis
			data[0] = _byteData.readFloat(); // X
			data[2] = _byteData.readFloat(); // Z
			data[1] = _byteData.readFloat(); // Y
			data[3] = 0;
			
			// Z axis
			data[8] = _byteData.readFloat(); // X
			data[10] = _byteData.readFloat(); // Z
			data[9] = _byteData.readFloat(); // Y
			data[11] = 0;
			
			// Y Axis
			data[4] = _byteData.readFloat(); // X 
			data[6] = _byteData.readFloat(); // Z
			data[5] = _byteData.readFloat(); // Y
			data[7] = 0;
			
			// Translation
			data[12] = _byteData.readFloat(); // X
			data[14] = _byteData.readFloat(); // Z
			data[13] = _byteData.readFloat(); // Y
			data[15] = 1;
			
			return data;
		}
		
		private function readColor():uint
		{
			var cid:uint;
			var len:uint;
			var r:uint, g:uint, b:uint;
			
			cid = _byteData.readUnsignedShort();
			len = _byteData.readUnsignedInt();
			
			switch (cid) {
				case 0x0010: // Floats
					r = _byteData.readFloat()*255;
					g = _byteData.readFloat()*255;
					b = _byteData.readFloat()*255;
					break;
				case 0x0011: // 24-bit color
					r = _byteData.readUnsignedByte();
					g = _byteData.readUnsignedByte();
					b = _byteData.readUnsignedByte();
					break;
				default:
					_byteData.position += (len - 6);
					break;
			}
			
			return (r << 16) | (g << 8) | b;
		}
	}
}

import away3d.materials.MaterialBase;
import away3d.textures.Texture2DBase;

import flash.geom.Vector3D;

internal class TextureVO
{
	public var url:String;
	public var texture:Texture2DBase;
	
	public function TextureVO()
	{
	}
}

internal class MaterialVO
{
	public var name:String;
	public var ambientColor:uint;
	public var diffuseColor:uint;
	public var specularColor:uint;
	public var twoSided:Boolean;
	public var colorMap:TextureVO;
	public var specularMap:TextureVO;
	public var material:MaterialBase;
	
	public function MaterialVO()
	{
	}
}

internal class ObjectVO
{
	public var name:String;
	public var type:String;
	public var pivotX:Number;
	public var pivotY:Number;
	public var pivotZ:Number;
	public var transform:Vector.<Number>;
	public var verts:Vector.<Number>;
	public var indices:Vector.<uint>;
	public var uvs:Vector.<Number>;
	public var materialFaces:Object;
	public var materials:Vector.<String>;
	public var smoothingGroups:Vector.<uint>;
	
	public function ObjectVO()
	{
	}
}

internal class VertexVO
{
	public var x:Number;
	public var y:Number;
	public var z:Number;
	public var u:Number;
	public var v:Number;
	public var normal:Vector3D;
	public var tangent:Vector3D;
	
	public function VertexVO()
	{
	}
}

internal class FaceVO
{
	public var a:uint;
	public var b:uint;
	public var c:uint;
	public var smoothGroup:uint;
	
	public function FaceVO()
	{
	}
}

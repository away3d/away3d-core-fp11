package away3d.loaders.parsers
{
	import away3d.arcane;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;
	import away3d.library.assets.AssetType;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.loaders.parsers.utils.ParserUtil;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	use namespace arcane;

	public class Max3DSParser extends ParserBase
	{
		private var _byteData : ByteArray;
		
		private var _cur_obj_end : uint;
		private var _cur_obj : ObjectVO;
		
		private var _cur_mat_name : String;
		
		
		public function Max3DSParser()
		{
			super(ParserDataFormat.BINARY);
		}
		
		
		
		public static function supportsType(extension : String) : Boolean
		{
			extension = extension.toLowerCase();
			return extension == "3ds";
		}
		
		
		public static function supportsData(data : *) : Boolean
		{
			var ba : ByteArray;
			
			ba = ParserUtil.toByteArray(data);
			if (ba) {
				ba.position = 0;
				if (ba.readShort() == 0x4d4d)
					return true;
			}
			
			return false;
		}
		
		
		arcane override function resolveDependency(resourceDependency:ResourceDependency):void
		{
			
		}
		
		
		arcane override function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{
			
		}
		
		
		protected override function proceedParsing():Boolean
		{
			if (!_byteData) {
				_byteData = ParserUtil.toByteArray(_data);
				_byteData.position = 0;
				_byteData.endian = Endian.LITTLE_ENDIAN;
			}
			
			// If we are currently working on an object, and the most recent chunk was
			// the last one in that object, finalize the current object.
			if (_cur_obj_end && _byteData.position >= _cur_obj_end)
				finalizeCurrentObject();
			
			while (_byteData.bytesAvailable && true) {
				var cid : uint;
				var len : uint;
				
				cid = _byteData.readUnsignedShort();
				len = _byteData.readUnsignedInt();
				
				trace('chunk:', cid.toString(16), len);
				
				switch (cid) {
					case 0x4D4D: // MAIN3DS
					case 0x3D3D: // EDIT3DS
					case 0xAFFF: // MATERIAL
						// This types are "container chunks" and contain only
						// sub-chunks (no data on their own.) This means that
						// there is nothing more to parse at this point, and 
						// instead we should progress to the next chunk, which
						// will be the first sub-chunk of this one.
						continue;
						break;
					
					
					case 0xA000: // Material name
						_cur_mat_name = readNulTermString();
						break;
					
					case 0x4000: // EDIT_OBJECT
						_cur_obj_end = _byteData.position + (len-6);
						_cur_obj = new ObjectVO();
						_cur_obj.name = readNulTermString();
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
					
					case 0x4111: // TRI_VERTEXOPTIONS
					default:
						// Skip this (unknown) chunk
						_byteData.position += (len-6);
						break;
				}
			}
			
			
			// More parsing is required if the entire byte array has not yet
			// been read, or if there is a currently non-finalized object in
			// the pipeline.
			if (_byteData.bytesAvailable || _cur_obj)
				return MORE_TO_PARSE;
			else
				return PARSING_DONE;
		}
		
		
		private function parseVertexList() : void
		{
			var i : uint;
			var len : uint;
			var count : uint;
			
			count = _byteData.readUnsignedShort();
			_cur_obj.verts = new Vector.<Number>(count*3, true);
			
			i = 0;
			len = _cur_obj.verts.length;
			while (i<len) {
				var x : Number, y : Number, z : Number;
				
				x = _byteData.readFloat();
				y = _byteData.readFloat();
				z = _byteData.readFloat();
				
				_cur_obj.verts[i++] = x;
				_cur_obj.verts[i++] = z;
				_cur_obj.verts[i++] = y;
			}
		}
		
		
		private function parseFaceList() : void
		{
			var i : uint;
			var len : uint;
			var count : uint;
			
			count = _byteData.readUnsignedShort();
			_cur_obj.indices = new Vector.<uint>(count*3, true);
			
			i = 0;
			len = _cur_obj.indices.length;
			while (i < len) {
				var i0 : uint, i1 : uint, i2 : uint;
				
				i0 = _byteData.readUnsignedShort(); 
				i1 = _byteData.readUnsignedShort(); 
				i2 = _byteData.readUnsignedShort(); 
				
				_cur_obj.indices[i++] = i0;
				_cur_obj.indices[i++] = i2;
				_cur_obj.indices[i++] = i1;
				
				// Skip "face info", irrelevant in Away3D
				_byteData.position += 2;
			}
		}
		
		
		private function parseUVList() : void
		{
			var i : uint;
			var len : uint;
			var count : uint;
			
			count = _byteData.readUnsignedShort();
			_cur_obj.uvs = new Vector.<Number>(count*2, true);
			
			i = 0;
			len = _cur_obj.uvs.length;
			while (i < len) {
				_cur_obj.uvs[i++] = _byteData.readFloat();
				_cur_obj.uvs[i++] = 1.0 - _byteData.readFloat();
			}
		}
		
		
		private function parseFaceMaterialList() : void
		{
			var mat : String;
			var count : uint;
			var i : uint;
			var faces : Vector.<uint>;
				
			mat = readNulTermString();
			count = _byteData.readUnsignedShort();
			
			faces = new Vector.<uint>(count, true);
			i = 0;
			while (i<faces.length) {
				faces[i++] = _byteData.readUnsignedShort();
			}
			
			_cur_obj.materialFaces[mat] = faces;
		}
		
		
		private function finalizeCurrentObject() : void
		{
			if (_cur_mat_name) {
				
			}
			
			if (_cur_obj) {
				if (_cur_obj.type == AssetType.MESH) {
					var geom : Geometry;
					var sub : SubGeometry;
					var mesh : Mesh;
					
					sub = new SubGeometry();
					sub.autoDeriveVertexNormals = true;
					sub.autoDeriveVertexTangents = true;
					sub.updateVertexData(_cur_obj.verts);
					sub.updateIndexData(_cur_obj.indices);
					sub.updateUVData(_cur_obj.uvs);
					
					geom = new Geometry();
					geom.subGeometries.push(sub);
					finalizeAsset(geom, _cur_obj.name.concat('_geom'));
					
					mesh = new Mesh(null, geom);
					finalizeAsset(mesh, _cur_obj.name);
				}
				
				_cur_obj = null;
			}
		}
		
		
		private function readNulTermString() : String
		{
			var chr : uint;
			var str : String = new String();
			
			while ((chr = _byteData.readUnsignedByte()) > 0) {
				str += String.fromCharCode(chr);
			}
			
			return str;
		}
	}
}

internal class ObjectVO
{
	public var name : String;
	public var type : String;
	public var verts : Vector.<Number>;
	public var indices : Vector.<uint>;
	public var uvs : Vector.<Number>;
	public var materialFaces : Object;
}


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
		private var _cur_obj_name : String;
		private var _cur_obj_type : String;
		private var _cur_obj_verts : Vector.<Number>;
		private var _cur_obj_inds : Vector.<uint>;
		
		
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
			if (_cur_obj_end && _byteData.position > _cur_obj_end)
				finalizeCurrentObject();
			
			while (_byteData.bytesAvailable && true) {
				var cid : uint;
				var len : uint;
				
				cid = _byteData.readShort();
				len = _byteData.readUnsignedInt();
				
				trace('chunk:', cid.toString(16), len);
				
				switch (cid) {
					case 0x4D4D: // MAIN3DS
					case 0x3D3D: // EDIT3DS
						// This types are "container chunks" and contain only
						// sub-chunks (no data on their own.) This means that
						// there is nothing more to parse at this point, and 
						// instead we should progress to the next chunk, which
						// will be the first sub-chunk of this one.
						continue;
						break;
					
					case 0xAFFF: // EDIT_MATERIAL
						break;
					
					case 0x4000: // EDIT_OBJECT
						_cur_obj_end = _byteData.position + (len-6);
						trace('cur obj end:', _cur_obj_end);
						_cur_obj_name = readNulTermString();
						break;
					
					case 0x4100: // OBJ_TRIMESH 
						_cur_obj_type = AssetType.MESH;
						break;
					
					case 0x4110: // TRI_VERTEXL
						parseVertexList();
						break;
					
					case 0x4120: // TRI_FACELIST
						parseFaceList();
						break;
					
					case 0x4140: // TRI_MAPPINGCOORDS
						break;
					
					case 0x4170: // TRI_MAPPINGSTANDARD
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
			if (_byteData.bytesAvailable || _cur_obj_type)
				return MORE_TO_PARSE;
			else
				return PARSING_DONE;
		}
		
		
		private function parseVertexList() : void
		{
			var i : uint;
			var count : uint;
			
			count = _byteData.readUnsignedShort();
			_cur_obj_verts = new Vector.<Number>(count*3, true);
			
			i = 0;
			while (i<_cur_obj_verts.length) {
				var x : Number, y : Number, z : Number;
				
				x = _byteData.readFloat();
				y = _byteData.readFloat();
				z = _byteData.readFloat();
				
				_cur_obj_verts[i++] = x;
				_cur_obj_verts[i++] = z;
				_cur_obj_verts[i++] = y;
			}
		}
		
		
		private function parseFaceList() : void
		{
			var i : uint;
			var count : uint;
			
			count = _byteData.readUnsignedShort();
			_cur_obj_inds = new Vector.<uint>(count*3, true);
			
			i = 0;
			while (i < _cur_obj_inds.length) {
				var i0 : uint, i1 : uint, i2 : uint;
				
				i0 = _byteData.readUnsignedShort(); 
				i1 = _byteData.readUnsignedShort(); 
				i2 = _byteData.readUnsignedShort(); 
				
				_cur_obj_inds[i++] = i0;
				_cur_obj_inds[i++] = i2;
				_cur_obj_inds[i++] = i1;
				
				// Skip "face info", irrelevant in Away3D
				_byteData.position += 2;
			}
		}
		
		
		private function finalizeCurrentObject() : void
		{
			if (_cur_obj_type == AssetType.MESH) {
				var geom : Geometry;
				var sub : SubGeometry;
				var mesh : Mesh;
				
				sub = new SubGeometry();
				sub.updateVertexData(_cur_obj_verts);
				sub.updateIndexData(_cur_obj_inds);
				
				geom = new Geometry();
				geom.subGeometries.push(sub);
				finalizeAsset(geom, _cur_obj_name.concat('_geom'));
				
				mesh = new Mesh(null, geom);
				finalizeAsset(mesh, _cur_obj_name);
			}
			
			_cur_obj_type = null;
			_cur_obj_name = null;
			_cur_obj_verts = null;
			_cur_obj_inds = null;
			_cur_obj_end = 0;
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
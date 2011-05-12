package away3d.loaders.parsers
{
	import away3d.animators.data.SkeletonAnimationSequence;
	import away3d.animators.skeleton.JointPose;
	import away3d.animators.skeleton.Skeleton;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.animators.skeleton.SkeletonPose;
	import away3d.arcane;
	import away3d.core.base.Geometry;
	import away3d.core.base.SkinnedSubGeometry;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;
	import away3d.library.assets.BitmapDataAsset;
	import away3d.library.assets.IAsset;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.materials.BitmapMaterial;
	import away3d.materials.MaterialBase;
	
	import flash.display.BitmapData;
	import flash.geom.Matrix3D;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	use namespace arcane;

	/**
	 * AWDParser provides a parser for the AWD data type.
	 */
	public class AWD2Parser extends ParserBase
	{
		private var _cur_block_id : uint;
		private var _blocks : Vector.<AWDBlock>;

		private var _version : Array;
		private var _compression : uint;
		private var _streaming : Boolean;
		
		private var _optimized_for_accuracy : Boolean;
		
		private var _texture_users : Object = {};
		
		private var _parsed_header : Boolean;
		private var _body : ByteArray;

		public static const UNCOMPRESSED : uint = 0;
		public static const DEFLATE : uint = 1;
		public static const LZMA : uint = 2;
		
		
		
		public static const AWD_ATTR_INT16 : uint = 1;
		public static const AWD_ATTR_INT32 : uint = 2;
		public static const AWD_ATTR_FLOAT32 : uint = 3;
		public static const AWD_ATTR_FLOAT64 : uint = 4;
		public static const AWD_ATTR_STRING : uint = 5;
		public static const AWD_ATTR_BADDR : uint = 6;
		public static const AWD_ATTR_MTX4 : uint = 7;

			
			
		/**
		 * Creates a new AWDParser object.
		 * @param uri The url or id of the data or file to be parsed.
		 * @param extra The holder for extra contextual data that the parser might need.
		 */
		public function AWD2Parser()
		{
			super(ParserDataFormat.BINARY);
			
			_blocks = new Vector.<AWDBlock>;
			_blocks[0] = new AWDBlock;
			_blocks[0].data = null; // Zero address means null in AWD

			_version = [];
		}

		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension : String) : Boolean
		{
			extension = extension.toLowerCase();
			return extension == "awd";
		}
		
		
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependency(resourceDependency:ResourceDependency):void
		{
			if (resourceDependency.assets.length == 1) {
				var bmp : BitmapDataAsset = resourceDependency.assets[0] as BitmapDataAsset;
				if (bmp) {
					var mat : BitmapMaterial;
					var users : Array = _texture_users[resourceDependency.id];
					for each (mat in users) {
						mat.bitmapData = bmp.bitmapData;
					}
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		/*override arcane function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{
			// apply system default
			//BitmapMaterial(mesh.material).bitmapData = defaultBitmapData;
		}*/

		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data : *) : Boolean
		{
			var magic : String;
			var bytes : ByteArray = ByteArray(data);

			bytes.position = 0;
			magic = data.readUTFBytes(3);
			bytes.position = 0;

			if (magic == 'AWD')
				return true;

			return false;
		}


		/**
		 * @inheritDoc
		 */
		protected override function proceedParsing() : Boolean
		{
			if (!_parsed_header) {
				_byteData.endian = Endian.BIG_ENDIAN;
				
				//TODO: Create general-purpose parseBlockRef(requiredType) (return _blocks[addr] or throw error)
				
				// Parse header and decompress body
				parseHeader();
				switch (_compression) {
					case DEFLATE:
						// TODO: Decompress deflate into _body;
						_body = new ByteArray;
						_byteData.readBytes(_body, 0, _byteData.bytesAvailable);
						_body.inflate();
						_body.position = 0;
						break;
					case LZMA:
						// TODO: Decompress LZMA into _body
						/*
						var decoder : LZMADecoder;
						var properties : Vector.<int>;
						var out_size : int;
						
						_body = new ByteArray;
						
						properties = new Vector.<int>(5, true);
						for(var i: int = 0; i < 5; ++i) {
							properties[i] = _byteData.readUnsignedByte()
						}
						
						out_size = _byteData.readUnsignedInt();
						trace('out size: ', out_size);
						
						decoder = new LZMADecoder;
						decoder.setDecoderProperties(properties);
						//decoder.setDecoderProperties(Vector.<int>([0x5d, 0, 0, 0, 1]));
						decoder.code(_byteData, _body, out_size);
						_body.position = 0;
						*/
						_body.position = _body.length;
						trace('LZMA decoding not yet supported in AWD parser.');
						break;
					case UNCOMPRESSED:
						_body = _byteData;
						break;
				}
				
				_parsed_header = true;
			}
			
			while (_body.bytesAvailable > 0 && hasTime()) {
				parseNextBlock();
			}
			
			// Return complete status
			if (_body.bytesAvailable==0) {
				return PARSING_DONE;
            }
			else return MORE_TO_PARSE;
		}
		
		private function parseHeader() : void
		{
			var flags : uint;
			var body_len : Number;
			
			// Skip magic string and parse version
			_byteData.position = 3;
			_version[0] = _byteData.readUnsignedByte();
			_version[1] = _byteData.readUnsignedByte();
			
			// Parse bit flags and compression
			flags = _byteData.readUnsignedShort();
			_streaming 					= (flags & 0x1) == 0x1;
			_optimized_for_accuracy 	= (flags & 0x2) == 0x2;
			
			_compression = _byteData.readUnsignedByte();
			
			trace('HEADER:');
			trace('version:', _version[0], _version[1]);
			trace('streaming?', _streaming);
			trace('accurate?', _optimized_for_accuracy);
			trace('compression:', _compression);
			
			// Check file integrity
			body_len = _byteData.readUnsignedInt();
			trace('body len: ', body_len);
			if (!_streaming && body_len != _byteData.bytesAvailable) {
				trace('error: body len does not match file length');
				// TODO: Throw error since size does not match
			}
		}
		
		private function parseNextBlock() : void
		{
			var assetData : IAsset;
			var ns : uint, type : uint, len : uint;
			
			_cur_block_id = _body.readUnsignedInt();
			ns = _body.readUnsignedByte();
			type = _body.readUnsignedByte();
			len = _body.readUnsignedInt();
			
			trace('block:', ns, _cur_block_id, type, len);
			switch (type) {
				case 1:
					trace('Parsing mesh data');
					assetData = parseMeshData(len);
					break;
				case 24:
					//trace('Parsing mesh instance');
					assetData = parseMeshInstance(len);
					break;
				case 81:
					trace('Parsing material');
					assetData = parseMaterial(len);
					break;
				case 82:
					trace('Parsing texture');
					assetData = parseTexture(len);
					break;
				case 101:
					trace('Parsing skeleton');
					assetData = parseSkeleton(len);
					break;
				case 102:
					trace('Parsing pose');
					assetData = parseSkeletonPose(len);
					break;
				case 103:
					trace('Parsing animation');
					assetData = parseSkeletonAnimation(len);
					break;
				default:
					//trace('Ignoring block!');
					_body.position += len;
					break;
			}
			
			// Store block reference for later use
			_blocks[_cur_block_id] = new AWDBlock();
			_blocks[_cur_block_id].data = assetData;
			_blocks[_cur_block_id].id = _cur_block_id;
		}
		
		
		private function parseMaterial(blockLength : uint) : MaterialBase
		{
			var name : String;
			var type : uint;
			var props : AWDProperties;
			var mat : MaterialBase;
			
			name = parseVarStr();
			type = _body.readUnsignedByte();
			
			props = parseProperties({ 1:AWD_ATTR_INT32, 2:AWD_ATTR_BADDR });
			parseUserAttributes();
			
			if (type == 1) { // Color material
			}
			else if (type == 2) { // Bitmap material
				var bmp : BitmapData;
				var bmp_asset : BitmapDataAsset;
				var tex_addr : uint;
				
				tex_addr = props.get(2, 0);
				trace('texture addr: ', tex_addr);
				bmp_asset = _blocks[tex_addr].data;
				if (bmp_asset) {
					bmp = bmp_asset.bitmapData;
				}
				
				mat = new BitmapMaterial(bmp);
				_texture_users[tex_addr.toString()].push(mat);
			}
			
			finalizeAsset(mat, name);
			
			return mat;
		}
		
		
		private function parseTexture(blockLength : uint) : BitmapDataAsset
		{
			var name : String;
			var type : uint;
			var data_len : uint;
			var asset : BitmapDataAsset;
			
			name = parseVarStr();
			type = _body.readUnsignedByte();
			data_len = _body.readUnsignedInt();
			
			// External
			if (type == 0) {
				var url : String;
				
				url = _body.readUTFBytes(data_len);
				trace('tex url:', url);
				
				// TODO: Create dependency
				_texture_users[_cur_block_id.toString()] = [];
				_dependencies.push(new ResourceDependency(_cur_block_id.toString(), new URLRequest(url), null, this));
			}
			else {
			}
			
			// Ignore for now
			parseProperties(null);
			parseUserAttributes();
			
			
			// TODO: Don't do this. Get texture properly
			asset = new BitmapDataAsset(defaultBitmapData);
			finalizeAsset(asset, name);
			return asset
		}

		
		private function parseSkeleton(blockLength : uint) : Skeleton
		{
			var name : String;
			var num_joints : uint;
			var joints_parsed : uint;
			var skeleton : Skeleton;
			
			name = parseVarStr();
			num_joints = _body.readUnsignedInt();
			skeleton = new Skeleton();
			
			// Discard properties for now
			parseProperties(null);
			
			trace('name:', name,'joints:', num_joints);
 			joints_parsed = 0;
			while (joints_parsed < num_joints) {
				var parent_id : uint;
				var joint_name : String;
				var joint : SkeletonJoint;
				var ibp : Matrix3D;
				
				// Ignore joint id
				_body.readUnsignedInt();

				joint = new SkeletonJoint();
				joint.parentIndex = _body.readUnsignedInt() -1; // 0=null in AWD
				joint.name = parseVarStr();
				
				ibp = parseMatrix3D();
				joint.inverseBindPose = ibp.rawData;

				skeleton.joints.push(joint);
				joints_parsed++;
			}

			// Discard attributes for now
			parseUserAttributes();
			
			finalizeAsset(skeleton, name);
			
			return skeleton;
		}
		
		private function parseSkeletonPose(blockLength : uint) : SkeletonPose
		{
			var name : String;
			var pose : SkeletonPose;
			var num_joints : uint;
			var joints_parsed : uint;
			
			name = parseVarStr();
			num_joints = _body.readUnsignedShort();
			
			// Ignore properties for now
			parseProperties(null);
			
			pose = new SkeletonPose();
			
			joints_parsed = 0;
			while (joints_parsed < num_joints) {
				var joint_pose : JointPose;
				var has_transform : uint;
				
				joint_pose = new JointPose();
				
				has_transform = _body.readUnsignedByte();
				if (has_transform == 1) {
					var mtx0 : Matrix3D;
					var mtx_data : Vector.<Number> = parseMatrixRawData();
					
					var mtx : Matrix3D = new Matrix3D(mtx_data);
					joint_pose.orientation.fromMatrix(mtx);
					joint_pose.translation.copyFrom(mtx.position);

					pose.jointPoses[joints_parsed] = joint_pose;
				}
				
				joints_parsed++;
			}
			
			// Skip attributes for now
			parseUserAttributes();
			
			finalizeAsset(pose, name);
			
			return pose;
		}
		
		private function parseSkeletonAnimation(blockLength : uint) : SkeletonAnimationSequence
		{
			var name : String;
			var num_frames : uint;
			var frames_parsed : uint;
			var frame_rate : uint;
			var frame_dur : Number;
			var animation : SkeletonAnimationSequence;
			
			name = parseVarStr();
			animation = new SkeletonAnimationSequence(name);
			
			num_frames = _body.readUnsignedShort();
			frame_rate = _body.readUnsignedByte();
			frame_dur = 1000/frame_rate;
			
			// Ignore properties for now (none in spec)
			parseProperties(null);
			
			frames_parsed = 0;
			while (frames_parsed < num_frames) {
				var pose_addr : uint;
				
				//TODO: Check for null?
				pose_addr = _body.readUnsignedInt();
				animation.addFrame(_blocks[pose_addr].data as SkeletonPose, frame_dur);
				
				frames_parsed++;
			}
			
			// Ignore attributes for now
			parseUserAttributes();
			
			finalizeAsset(animation, name);
			
			return animation;
		}

		private function parseMeshInstance(blockLength : uint) : Mesh
		{
			var name : String;
			var mesh : Mesh, geom : Geometry;
			var par_id : uint, data_id : uint;
			var mtx : Matrix3D;
			var materials : Vector.<MaterialBase>;
			var num_materials : uint;
			var materials_parsed : uint;
			
			par_id = _body.readUnsignedInt();
			mtx = parseMatrix3D();
			name = parseVarStr();
			
			data_id = _body.readUnsignedInt();
			geom = _blocks[data_id].data as Geometry;
			
			materials = new Vector.<MaterialBase>;
			num_materials = _body.readUnsignedShort();
			materials_parsed = 0;
			while (materials_parsed < num_materials) {
				var mat_id : uint;
				mat_id = _body.readUnsignedInt();
				
				materials.push(_blocks[mat_id].data);
				
				materials_parsed++;
			}
			
			mesh = new Mesh(null, geom);
			mesh.transform = mtx;
			
			if (materials.length == 1) {
				mesh.material = materials[0];
			}
			else if (materials.length > 1) {
				var i : uint;
				// Assign each sub-mesh in the mesh a material from the list. If more sub-meshes
				// than materials, repeat the last material for all remaining sub-meshes.
				for (i=0; i<mesh.subMeshes.length; i++) {
					mesh.subMeshes[i].material = materials[Math.min(materials.length-1, i)];
				}
			}
			
			// Ignore for now
			parseProperties(null);
			parseUserAttributes();
			
			finalizeAsset(mesh, name);

			return mesh;
		}
		
		
		private function parseMeshData(blockLength : uint) : Geometry
		{
			var name : String;
			var geom : Geometry;
			var skeleton : Skeleton;
			var num_subs : uint;
			var subs_parsed : uint;
			var props : AWDProperties;
			var bsm : Matrix3D;
			
			// Read name and sub count
			name = parseVarStr();
			num_subs = _body.readUnsignedShort();
			
			// Read optional properties
			props = parseProperties({ 1:AWD_ATTR_BADDR }); 
			skeleton = _blocks[props.get(1, 0)].data;
			
			var mtx : Matrix3D;
			var bsm_data : Array = props.get(2, null);
			if (bsm_data) {
				bsm = new Matrix3D(Vector.<Number>(bsm_data));
			}
			
			geom = new Geometry();

			// Loop through sub meshes
			subs_parsed = 0;
			while (subs_parsed < num_subs) {
				var mat_id : uint, sm_len : uint, sm_end : uint;
				var sub_geom : SubGeometry;
				var skinned_sub_geom : SkinnedSubGeometry;
				
				if (skeleton || true)
					sub_geom = skinned_sub_geom = new SkinnedSubGeometry(3); // TODO: Don't hard code this
				else
					sub_geom = new SubGeometry();
				
				sm_len = _body.readUnsignedInt();
				sm_end = _body.position + sm_len;
				
				// Loop through data streams
				while (_body.position < sm_end) {
					var idx : uint = 0;
					var read_float : Function, read_int : Function;
					var str_type : uint, str_len : uint, str_end : uint;
					
					str_type = _body.readUnsignedByte();
					str_len = _body.readUnsignedInt();
					str_end = _body.position + str_len;
					
					// Define which methods to use when reading floating
					// point and integer numbers respectively. This way, 
					// the optimization test and ByteArray dot-lookup
					// won't have to be made every iteration in the loop.
					if (_optimized_for_accuracy) {
						read_float = _body.readDouble;
						read_int = _body.readUnsignedInt;
					}
					else {
						read_float = _body.readFloat;
						read_int = _body.readUnsignedShort;
					}
					
					var x:Number, y:Number, z:Number;
					
					if (str_type == 1) {
						var verts : Vector.<Number> = new Vector.<Number>;
						while (_body.position < str_end) {
							x = read_float();
							y = read_float();
							z = read_float();
							
							verts[idx++] = x;
							verts[idx++] = y;
							verts[idx++] = z;
						}
						sub_geom.updateVertexData(verts);
					}
					else if (str_type == 2) {
						var indices : Vector.<uint> = new Vector.<uint>;
						while (_body.position < str_end) {
							indices[idx++] = read_int();
						}
						sub_geom.updateIndexData(indices);
					}
					else if (str_type == 3) {
						var uvs : Vector.<Number> = new Vector.<Number>;
						while (_body.position < str_end) {
							uvs[idx++] = read_float();
						}
						sub_geom.updateUVData(uvs);
					}
					else if (str_type == 7 && skinned_sub_geom) {
						var w_indices : Vector.<Number> = new Vector.<Number>;
						while (_body.position < str_end) {
							w_indices[idx++] = read_int()*3;
						}
						skinned_sub_geom.jointIndexData = w_indices;
					}
					else if (str_type == 8 && skinned_sub_geom) {
							var weights : Vector.<Number> = new Vector.<Number>;
						while (_body.position < str_end) {
							weights[idx++] = read_float();
						}
						skinned_sub_geom.jointWeightsData = weights;
					}
					else {
						trace('unknown str type:', str_type);
						_body.position = str_end;
					}
				}
				
				subs_parsed++;
				geom.addSubGeometry(sub_geom);
			}
			
			parseUserAttributes();
			
			finalizeAsset(geom, name);
			
			return geom;
		}
		
		
		private function parseVarStr() : String
		{
			var len : uint;
			
			len = _body.readUnsignedShort();
			return _body.readUTFBytes(len);
		}
		
		
		// TODO: Improve this by having some sort of key=type dictionary
		private function parseProperties(expected : Object) : AWDProperties
		{
			var list_end : uint;
			var list_len : uint;
			var props : AWDProperties;
			
			props = new AWDProperties();
			
			list_len = _body.readUnsignedInt();
			list_end = _body.position + list_len;
			
			if (expected) {
				while (_body.position < list_end) {
					var len : uint;
					var key : uint;
					var type : uint;
				
					key = _body.readUnsignedShort();
					len = _body.readUnsignedShort();
					if (expected.hasOwnProperty(key))
						type = expected[key];
				
					props.set(key, parseAttrValue(type, len));
				}
			}
			
			return props;
		}
		
		private function parseUserAttributes() : Object
		{
			var list_len : uint;
			
			// TODO: Implement user attributes
			list_len = _body.readUnsignedInt();
			_body.position += list_len; // Skip for now
			
			return null;
		}
		
		private function parseAttrValue(type : uint, len : uint) : *
		{
			var elem_len : uint;
			var read_func : Function;
			
			switch (type) {
				case 1:
					elem_len = 2;
					read_func = _body.readShort;
					break;
				case 2:
				case 6:
					elem_len = 4;
					read_func = _body.readUnsignedInt;
					break;
				case 7:
					elem_len = 8;
					read_func = _body.readDouble;
					break;
			}
			
			if (elem_len < len) {
				var list : Array;
				var num_read : uint;
				var num_elems : uint;
				
				list = [];
				num_read = 0;
				num_elems = len / elem_len;
				while (num_read < num_elems) {
					list.push(read_func());
					num_read++;
				}
				
				return list;
			}
			else {
				var val : *;
				
				val = read_func();
				return val;
			}
		}
		
		private function parseMatrix3D() : Matrix3D
		{
			var mtx : Matrix3D = new Matrix3D(parseMatrixRawData());
			return mtx;
		}
		
		private function parseMatrixRawData() : Vector.<Number>
		{
			var i : uint;
			var mtx_raw : Vector.<Number> = new Vector.<Number>;
			for (i=0; i<16; i++) {
				mtx_raw[i] = _body.readDouble();
			}
			
			return mtx_raw;
		}
	}
}


internal class AWDBlock
{
	public var id : uint;
	public var data : *;
}

internal dynamic class AWDProperties
{
	public function set(key : uint, value : *) : void
	{
		this[key.toString()] = value;
	}
	
	public function get(key : uint, fallback : *) : *
	{
		if (this.hasOwnProperty(key.toString()))
			return this[key.toString()];
		else return fallback;
	}
}



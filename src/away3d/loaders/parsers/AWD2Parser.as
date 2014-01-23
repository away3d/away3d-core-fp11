package away3d.loaders.parsers
{
	import away3d.*;
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	import away3d.cameras.*;
	import away3d.cameras.lenses.*;
	import away3d.containers.*;
	import away3d.core.base.*;
	import away3d.entities.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	import away3d.lights.shadowmaps.*;
	import away3d.loaders.misc.*;
	import away3d.loaders.parsers.utils.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.*;
	import away3d.materials.utils.*;
	import away3d.primitives.*;
	import away3d.textures.*;
	import away3d.tools.utils.*;
	
	import flash.display.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.utils.*;
	
	use namespace arcane;
	
	/**
	 * AWDParser provides a parser for the AWD data type.
	 */
	public class AWD2Parser extends ParserBase
	{
		//set to "true" to have some traces in the Console
		private var _debug:Boolean = false;
		private var _byteData:ByteArray;
		private var _cur_block_id:uint;
		private var _blocks:Vector.<AWDBlock>;
		private var _newBlockBytes:ByteArray;
		
		private var _version:Array;
		private var _compression:uint;
		
		private var _accuracyOnBlocks:Boolean;
		
		private var _accuracyMatrix:Boolean;
		private var _accuracyGeo:Boolean;
		private var _accuracyProps:Boolean;
		
		private var _matrixNrType:uint;
		private var _geoNrType:uint;
		private var _propsNrType:uint;
		
		private var _streaming:Boolean;
		
		private var _texture_users:Object;
		
		private var _body:ByteArray;
		
		private var _defaultTexture:BitmapTexture;
		private var _defaultCubeTexture:BitmapCubeTexture;
		private var _defaultBitmapMaterial:TextureMaterial;
		private var _cubeTextures:Array;
		
		public static const COMPRESSIONMODE_LZMA:String = "lzma";
		
		public static const UNCOMPRESSED:uint = 0;
		public static const DEFLATE:uint = 1;
		public static const LZMA:uint = 2;
		
		public static const INT8:uint = 1;
		public static const INT16:uint = 2;
		public static const INT32:uint = 3;
		public static const UINT8:uint = 4;
		public static const UINT16:uint = 5;
		public static const UINT32:uint = 6;
		public static const FLOAT32:uint = 7;
		public static const FLOAT64:uint = 8;
		
		public static const BOOL:uint = 21;
		public static const COLOR:uint = 22;
		public static const BADDR:uint = 23;
		
		public static const AWDSTRING:uint = 31;
		public static const AWDBYTEARRAY:uint = 32;
		
		public static const VECTOR2x1:uint = 41;
		public static const VECTOR3x1:uint = 42;
		public static const VECTOR4x1:uint = 43;
		public static const MTX3x2:uint = 44;
		public static const MTX3x3:uint = 45;
		public static const MTX4x3:uint = 46;
		public static const MTX4x4:uint = 47;
		
		private var blendModeDic:Vector.<String>;
		private var _depthSizeDic:Vector.<uint>;
		
		/**
		 * Creates a new AWDParser object.
		 * @param uri The url or id of the data or file to be parsed.
		 * @param extra The holder for extra contextual data that the parser might need.
		 */
		public function AWD2Parser()
		{
			super(ParserDataFormat.BINARY);		
			
			blendModeDic = new Vector.<String>(); // used to translate ints to blendMode-strings
			blendModeDic.push(BlendMode.NORMAL);
			blendModeDic.push(BlendMode.ADD);
			blendModeDic.push(BlendMode.ALPHA);
			blendModeDic.push(BlendMode.DARKEN);
			blendModeDic.push(BlendMode.DIFFERENCE);
			blendModeDic.push(BlendMode.ERASE);
			blendModeDic.push(BlendMode.HARDLIGHT);
			blendModeDic.push(BlendMode.INVERT);
			blendModeDic.push(BlendMode.LAYER);
			blendModeDic.push(BlendMode.LIGHTEN);
			blendModeDic.push(BlendMode.MULTIPLY);
			blendModeDic.push(BlendMode.NORMAL);
			blendModeDic.push(BlendMode.OVERLAY);
			blendModeDic.push(BlendMode.SCREEN);
			blendModeDic.push(BlendMode.SHADER);
			blendModeDic.push(BlendMode.OVERLAY);
			
			_depthSizeDic = new Vector.<uint>(); // used to translate ints to depthSize-values
			_depthSizeDic.push(256);
			_depthSizeDic.push(512);
			_depthSizeDic.push(2048);
			_depthSizeDic.push(1024);
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension:String):Boolean
		{
			extension = extension.toLowerCase();
			return extension == "awd";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data:*):Boolean
		{
			return (ParserUtil.toString(data, 3) == 'AWD');
		}
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependency(resourceDependency:ResourceDependency):void
		{
			// this function will be called when Dependency has finished loading.
			// the Assets waiting for this Bitmap, can be Texture or CubeTexture.
			// if the Bitmap is awaited by a CubeTexture, we need to check if its the last Bitmap of the CubeTexture, 
			// so we know if we have to finalize the Asset (CubeTexture) or not.
			if (resourceDependency.assets.length == 1) {
				var isCubeTextureArray:Array = resourceDependency.id.split("#");
				var ressourceID:String = isCubeTextureArray[0];
				var asset:TextureProxyBase;
				var thisBitmapTexture:Texture2DBase;
				var block:AWDBlock;
				if (isCubeTextureArray.length == 1) {
					asset = resourceDependency.assets[0] as Texture2DBase;
					if (asset) {
						var mat:TextureMaterial;
						var users:Array;
						block = _blocks[parseInt(resourceDependency.id)];
						block.data = asset; // Store finished asset						
						// Reset name of texture to the one defined in the AWD file,
						// as opposed to whatever the image parser came up with.
						asset.resetAssetPath(block.name, null, true);
						block.name = asset.name;
						// Finalize texture asset to dispatch texture event, which was
						// previously suppressed while the dependency was loaded.
						finalizeAsset(asset);
						if (_debug) {
							trace("Successfully loadet Bitmap for texture");
							trace("Parsed CubeTexture: Name = " + block.name);
						}
					}
				}
				if (isCubeTextureArray.length > 1) {
					thisBitmapTexture = resourceDependency.assets[0] as BitmapTexture;
					_cubeTextures[uint(isCubeTextureArray[1])] = BitmapTexture(thisBitmapTexture).bitmapData;
					_texture_users[ressourceID].push(1);
					
					if (_debug)
						trace("Successfully loadet Bitmap " + _texture_users[ressourceID].length + " / 6 for Cubetexture");
					if (_texture_users[ressourceID].length == _cubeTextures.length) {
						asset = new BitmapCubeTexture(_cubeTextures[0], _cubeTextures[1], _cubeTextures[2], _cubeTextures[3], _cubeTextures[4], _cubeTextures[5]);
						block = _blocks[ressourceID];
						block.data = asset; // Store finished asset				
						// Reset name of texture to the one defined in the AWD file,
						// as opposed to whatever the image parser came up with.
						asset.resetAssetPath(block.name, null, true);
						block.name = asset.name;
						// Finalize texture asset to dispatch texture event, which was
						// previously suppressed while the dependency was loaded.
						finalizeAsset(asset);
						if (_debug)
							trace("Parsed CubeTexture: Name = " + block.name);
					}
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{
			//not used - if a dependcy fails, the awaiting Texture or CubeTexture will never be finalized, and the default-bitmaps will be used.
			// this means, that if one Bitmap of a CubeTexture fails, the CubeTexture will have the DefaultTexture applied for all six Bitmaps.
		}
		
		/**
		 * Resolve a dependency name
		 *
		 * @param resourceDependency The dependency to be resolved.
		 */
		arcane override function resolveDependencyName(resourceDependency:ResourceDependency, asset:IAsset):String
		{
			var oldName:String = asset.name;
			if (asset) {
				var block:AWDBlock = _blocks[parseInt(resourceDependency.id)];
				// Reset name of texture to the one defined in the AWD file,
				// as opposed to whatever the image parser came up with.
				asset.resetAssetPath(block.name, null, true);
			}
			var newName:String = asset.name;
			asset.name = oldName;
			return newName;
		}
		
		
		/**
		 * @inheritDoc
		 */
		protected override function startParsing(frameLimit:Number):void
		{
			super.startParsing(frameLimit);
			
			_texture_users = {};
			
			_byteData = getByteData();
			
			_blocks = new Vector.<AWDBlock>();
			_blocks[0] = new AWDBlock();
			_blocks[0].data = null; // Zero address means null in AWD
			
			_version = []; // will contain 2 int (major-version, minor-version) for awd-version-check
			
			//parse header
			_byteData.endian = Endian.LITTLE_ENDIAN;
			
			// Parse header and decompress body if needed
			parseHeader();
			switch (_compression) {
				case DEFLATE:
					_body = new ByteArray();
					_byteData.readBytes(_body, 0, _byteData.bytesAvailable);
					_body.uncompress();
					break;
				case LZMA:
					_body = new ByteArray();
					_byteData.readBytes(_body, 0, _byteData.bytesAvailable);
					_body.uncompress(COMPRESSIONMODE_LZMA);
					break;
				case UNCOMPRESSED:
					_body = _byteData;
					break;
			}
			
			_body.endian = Endian.LITTLE_ENDIAN;
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function proceedParsing():Boolean
		{	
			while (_body.bytesAvailable > 0 && !parsingPaused && hasTime())
				parseNextBlock();
			
			// Return complete status
			if (_body.bytesAvailable == 0)
				return PARSING_DONE;
			else
				return MORE_TO_PARSE;
		}
		
		private function parseHeader():void
		{
			var flags:uint;
			var body_len:Number;
			_byteData.position = 3; // Skip magic string and parse version
			_version[0] = _byteData.readUnsignedByte();
			_version[1] = _byteData.readUnsignedByte();
			
			flags = _byteData.readUnsignedShort(); // Parse bit flags 
			_streaming = bitFlags.test(flags, bitFlags.FLAG1);
			if ((_version[0] == 2) && (_version[1] == 1)) {
				_accuracyMatrix = bitFlags.test(flags, bitFlags.FLAG2);
				_accuracyGeo = bitFlags.test(flags, bitFlags.FLAG3);
				_accuracyProps = bitFlags.test(flags, bitFlags.FLAG4);
			}
			// if we set _accuracyOnBlocks, the precision-values are read from each block-header.
			
			// set storagePrecision types
			_geoNrType = FLOAT32;
			if (_accuracyGeo)
				_geoNrType = FLOAT64;
			_matrixNrType = FLOAT32;
			if (_accuracyMatrix)
				_matrixNrType = FLOAT64;
			_propsNrType = FLOAT32;
			if (_accuracyProps)
				_propsNrType = FLOAT64;
			
			_compression = _byteData.readUnsignedByte(); // compression	
			
			if (_debug) {
				trace("Import AWDFile of version = " + _version[0] + " - " + _version[1]);
				trace("Global Settings = Compression = " + _compression + " | Streaming = " + _streaming + " | Matrix-Precision = " + _accuracyMatrix + " | Geometry-Precision = " + _accuracyGeo + " | Properties-Precision = " + _accuracyProps);
			}
			
			// Check file integrity
			body_len = _byteData.readUnsignedInt();
			if (!_streaming && body_len != _byteData.bytesAvailable)
				dieWithError('AWD2 body length does not match header integrity field');
		}
		
		private function parseNextBlock():void
		{
			var block:AWDBlock;
			var assetData:IAsset;
			var isParsed:Boolean;
			var ns:uint, type:uint, flags:uint, len:uint;
			_cur_block_id = _body.readUnsignedInt();
			ns = _body.readUnsignedByte();
			type = _body.readUnsignedByte();
			flags = _body.readUnsignedByte();
			len = _body.readUnsignedInt();
			var blockCompression:Boolean = bitFlags.test(flags, bitFlags.FLAG4);
			var blockCompressionLZMA:Boolean = bitFlags.test(flags, bitFlags.FLAG5);
			if (_accuracyOnBlocks) {
				_accuracyMatrix = bitFlags.test(flags, bitFlags.FLAG1);
				_accuracyGeo = bitFlags.test(flags, bitFlags.FLAG2);
				_accuracyProps = bitFlags.test(flags, bitFlags.FLAG3);
				_geoNrType = FLOAT32;
				if (_accuracyGeo)
					_geoNrType = FLOAT64;
				_matrixNrType = FLOAT32;
				if (_accuracyMatrix)
					_matrixNrType = FLOAT64;
				_propsNrType = FLOAT32;
				if (_accuracyProps)
					_propsNrType = FLOAT64;
			}
			
			var blockEndAll:uint = _body.position + len;
			if (len > _body.bytesAvailable) {
				dieWithError('AWD2 block length is bigger than the bytes that are available!');
				_body.position += _body.bytesAvailable;
				return;
			}
			_newBlockBytes = new ByteArray();
			_body.readBytes(_newBlockBytes, 0, len);
			if (blockCompression) {
				if (blockCompressionLZMA)
					_newBlockBytes.uncompress(COMPRESSIONMODE_LZMA);
				else
					_newBlockBytes.uncompress();
			}
			_newBlockBytes.endian = Endian.LITTLE_ENDIAN;
			_newBlockBytes.position = 0;
			block = new AWDBlock();
			block.len = _newBlockBytes.position + len;
			block.id = _cur_block_id;
			
			var blockEndBlock:uint = _newBlockBytes.position + len;
			if (blockCompression) {
				blockEndBlock = _newBlockBytes.position + _newBlockBytes.length;
				block.len = blockEndBlock;
			}
			
			if (_debug)
				trace("AWDBlock:  ID = " + _cur_block_id + " | TypeID = " + type + " | Compression = " + blockCompression + " | Matrix-Precision = " + _accuracyMatrix + " | Geometry-Precision = " + _accuracyGeo + " | Properties-Precision = " + _accuracyProps);
			
			_blocks[_cur_block_id] = block;
			if ((_version[0] == 2) && (_version[1] == 1)) {
				switch (type) {
					case 11:
						parsePrimitves(_cur_block_id);
						isParsed = true;
						break;
					case 31:
						parseSkyBoxInstance(_cur_block_id);
						isParsed = true;
						break;
					case 41:
						parseLight(_cur_block_id);
						isParsed = true;
						break;
					case 42:
						parseCamera(_cur_block_id);
						isParsed = true;
						break;
					case 43:
						parseTextureProjector(_cur_block_id);
						isParsed = true;
						break;
					case 51:
						parseLightPicker(_cur_block_id);
						isParsed = true;
						break;
					case 81:
						parseMaterial_v1(_cur_block_id);
						isParsed = true;
						break;
					case 83:
						parseCubeTexture(_cur_block_id);
						isParsed = true;
						break;
					case 91:
						parseSharedMethodBlock(_cur_block_id);
						isParsed = true;
						break;
					case 92:
						parseShadowMethodBlock(_cur_block_id);
						isParsed = true;
						break;
					case 111:
						parseMeshPoseAnimation(_cur_block_id, true);
						isParsed = true;
						break;
					case 112:
						parseMeshPoseAnimation(_cur_block_id);
						isParsed = true;
						break;
					case 113:
						parseVertexAnimationSet(_cur_block_id);
						isParsed = true;
						break;
					case 122:
						parseAnimatorSet(_cur_block_id);
						isParsed = true;
						break;
					case 253:
						parseCommand(_cur_block_id);
						isParsed = true;
						break;
				}
			}
			if (isParsed == false) {
				switch (type) {
					case 1:
						parseTriangleGeometrieBlock(_cur_block_id);
						break;
					case 22:
						parseContainer(_cur_block_id);
						break;
					case 23:
						parseMeshInstance(_cur_block_id);
						break;
					case 81:
						parseMaterial(_cur_block_id);
						break;
					case 82:
						parseTexture(_cur_block_id);
						break;
					case 101:
						parseSkeleton(_cur_block_id);
						break;
					case 102:
						parseSkeletonPose(_cur_block_id);
						break;
					case 103:
						parseSkeletonAnimation(_cur_block_id);
						break;
					case 121:
						parseUVAnimation(_cur_block_id);
						break;
					case 254:
						parseNameSpace(_cur_block_id);
						break;
					case 255:
						parseMetaData(_cur_block_id);
						break;
					default:
						if (_debug)
							trace("AWDBlock:   Unknown BlockType  (BlockID = " + _cur_block_id + ") - Skip " + len + " bytes");
						_newBlockBytes.position += len;
						break;
				}
			}
			var msgCnt:uint = 0;
			if (_newBlockBytes.position == blockEndBlock) {
				if (_debug) {
					if (block.errorMessages) {
						while (msgCnt < block.errorMessages.length) {
							trace("        (!) Error: " + block.errorMessages[msgCnt] + " (!)");
							msgCnt++;
						}
					}
				}
				if (_debug)
					trace("\n");
			} else {
				if (_debug) {
					trace("  (!)(!)(!) Error while reading AWDBlock ID " + _cur_block_id + " = skip to next block");
					if (block.errorMessages) {
						while (msgCnt < block.errorMessages.length) {
							trace("        (!) Error: " + block.errorMessages[msgCnt] + " (!)");
							msgCnt++;
						}
					}
				}
			}
			
			_body.position = blockEndAll;
			_newBlockBytes = null;
		
		}
		
		//Block ID = 1
		private function parseTriangleGeometrieBlock(blockID:uint):void
		{
			
			var geom:Geometry = new Geometry();
			
			// Read name and sub count
			var name:String = parseVarStr();
			var num_subs:uint = _newBlockBytes.readUnsignedShort();
			
			// Read optional properties
			var props:AWDProperties = parseProperties({1:_geoNrType, 2:_geoNrType});
			var geoScaleU:Number = props.get(1, 1);
			var geoScaleV:Number = props.get(2, 1);
			var sub_geoms:Vector.<ISubGeometry> = new Vector.<ISubGeometry>;
			// Loop through sub meshes
			var subs_parsed:uint = 0;
			while (subs_parsed < num_subs) {
				var i:uint;
				var sm_len:uint, sm_end:uint;
				var w_indices:Vector.<Number>;
				var weights:Vector.<Number>;
				
				sm_len = _newBlockBytes.readUnsignedInt();
				sm_end = _newBlockBytes.position + sm_len;
				
				// Ignore for now
				var subProps:AWDProperties = parseProperties({1:_geoNrType, 2:_geoNrType});
				// Loop through data streams
				while (_newBlockBytes.position < sm_end) {
					var idx:uint = 0;
					var str_ftype:uint, str_type:uint, str_len:uint, str_end:uint;
					
					// Type, field type, length
					str_type = _newBlockBytes.readUnsignedByte();
					str_ftype = _newBlockBytes.readUnsignedByte();
					str_len = _newBlockBytes.readUnsignedInt();
					str_end = _newBlockBytes.position + str_len;
					
					var x:Number, y:Number, z:Number;
					
					if (str_type == 1) {
						var verts:Vector.<Number> = new Vector.<Number>();
						while (_newBlockBytes.position < str_end) {
							// TODO: Respect stream field type
							x = readNumber(_accuracyGeo);
							y = readNumber(_accuracyGeo);
							z = readNumber(_accuracyGeo);
							
							verts[idx++] = x;
							verts[idx++] = y;
							verts[idx++] = z;
						}
					} else if (str_type == 2) {
						var indices:Vector.<uint> = new Vector.<uint>();
						while (_newBlockBytes.position < str_end) {
							// TODO: Respect stream field type
							indices[idx++] = _newBlockBytes.readUnsignedShort();
						}
					} else if (str_type == 3) {
						var uvs:Vector.<Number> = new Vector.<Number>();
						while (_newBlockBytes.position < str_end)
							uvs[idx++] = readNumber(_accuracyGeo);
					} else if (str_type == 4) {
						var normals:Vector.<Number> = new Vector.<Number>();
						while (_newBlockBytes.position < str_end)
							normals[idx++] = readNumber(_accuracyGeo);
					} else if (str_type == 6) {
						w_indices = new Vector.<Number>();
						while (_newBlockBytes.position < str_end)
							w_indices[idx++] = _newBlockBytes.readUnsignedShort()*3; // TODO: Respect stream field type
					} else if (str_type == 7) {
						weights = new Vector.<Number>();
						while (_newBlockBytes.position < str_end)
							weights[idx++] = readNumber(_accuracyGeo);
					} else
						_newBlockBytes.position = str_end;
				}
				parseUserAttributes(); // Ignore sub-mesh attributes for now
				
				sub_geoms = GeomUtil.fromVectors(verts, indices, uvs, normals, null, weights, w_indices);
				
				var scaleU:Number = subProps.get(1, 1);
				var scaleV:Number = subProps.get(2, 1);
				var setSubUVs:Boolean = false; //this should remain false atm, because in AwayBuilder the uv is only scaled by the geometry
				if ((geoScaleU != scaleU) || (geoScaleV != scaleV)) {
					trace("set sub uvs");
					setSubUVs = true;
					scaleU = geoScaleU/scaleU;
					scaleV = geoScaleV/scaleV;
				}
				for (i = 0; i < sub_geoms.length; i++) {
					if (setSubUVs)
						sub_geoms[i].scaleUV(scaleU, scaleV);
					geom.addSubGeometry(sub_geoms[i]);
						// TODO: Somehow map in-sub to out-sub indices to enable look-up
						// when creating meshes (and their material assignments.)
				}
				subs_parsed++;
			}
			if ((geoScaleU != 1) || (geoScaleV != 1))
				geom.scaleUV(geoScaleU, geoScaleV);
			parseUserAttributes();
			finalizeAsset(geom, name);
			_blocks[blockID].data = geom;
			
			if (_debug)
				trace("Parsed a TriangleGeometry: Name = " + name + "| SubGeometries = " + sub_geoms.length);
		
		}
		
		//Block ID = 11
		private function parsePrimitves(blockID:uint):void
		{
			var name:String;
			var geom:Geometry;
			var primType:uint;
			var subs_parsed:uint;
			var props:AWDProperties;
			var bsm:Matrix3D;
			
			// Read name and sub count
			name = parseVarStr();
			primType = _newBlockBytes.readUnsignedByte();
			props = parseProperties({101:_geoNrType, 102:_geoNrType, 103:_geoNrType, 110:_geoNrType, 111:_geoNrType, 301:UINT16, 302:UINT16, 303:UINT16, 701:BOOL, 702:BOOL, 703:BOOL, 704:BOOL});
			
			var primitveTypes:Array = ["Unsupported Type-ID", "PlaneGeometry", "CubeGeometry", "SphereGeometry", "CylinderGeometry", "ConeGeometry", "CapsuleGeometry", "TorusGeometry"]
			switch (primType) {
				// to do, not all properties are set on all primitives
				case 1:
					geom = new PlaneGeometry(props.get(101, 100), props.get(102, 100), props.get(301, 1), props.get(302, 1), props.get(701, true), props.get(702, false));
					break;
				case 2:
					geom = new CubeGeometry(props.get(101, 100), props.get(102, 100), props.get(103, 100), props.get(301, 1), props.get(302, 1), props.get(303, 1), props.get(701, true));
					break;
				case 3:
					geom = new SphereGeometry(props.get(101, 50), props.get(301, 16), props.get(302, 12), props.get(701, true));
					break;
				case 4:
					geom = new CylinderGeometry(props.get(101, 50), props.get(102, 50), props.get(103, 100), props.get(301, 16), props.get(302, 1), true, true, true); // bool701, bool702, bool703, bool704);
					if (!props.get(701, true))
						CylinderGeometry(geom).topClosed = false;
					if (!props.get(702, true))
						CylinderGeometry(geom).bottomClosed = false;
					if (!props.get(703, true))
						CylinderGeometry(geom).yUp = false;
					
					break;
				case 5:
					geom = new ConeGeometry(props.get(101, 50), props.get(102, 100), props.get(301, 16), props.get(302, 1), props.get(701, true), props.get(702, true));
					break;
				case 6:
					geom = new CapsuleGeometry(props.get(101, 50), props.get(102, 100), props.get(301, 16), props.get(302, 15), props.get(701, true));
					break;
				case 7:
					geom = new TorusGeometry(props.get(101, 50), props.get(102, 50), props.get(301, 16), props.get(302, 8), props.get(701, true));
					break;
				default:
					geom = new Geometry();
					trace("ERROR: UNSUPPORTED PRIMITIVE_TYPE");
					break;
			}
			if ((props.get(110, 1) != 1) || (props.get(111, 1) != 1)) {
				geom.subGeometries;
				geom.scaleUV(props.get(110, 1), props.get(111, 1));
			}
			parseUserAttributes();
			geom.name = name;
			finalizeAsset(geom, name);
			_blocks[blockID].data = geom;
			if (_debug) {
				if ((primType < 0) || (primType > 7))
					primType = 0;
				trace("Parsed a Primivite: Name = " + name + "| type = " + primitveTypes[primType]);
			}
		}
		
		// Block ID = 22
		private function parseContainer(blockID:uint):void
		{
			var name:String;
			var par_id:uint;
			var mtx:Matrix3D;
			var ctr:ObjectContainer3D;
			var parent:ObjectContainer3D;
			
			par_id = _newBlockBytes.readUnsignedInt();
			mtx = parseMatrix3D();
			name = parseVarStr();
			var parentName:String = "Root (TopLevel)";
			ctr = new ObjectContainer3D();
			ctr.transform = mtx;
			var returnedArray:Array = getAssetByID(par_id, [AssetType.CONTAINER, AssetType.LIGHT, AssetType.MESH, AssetType.ENTITY, AssetType.SEGMENT_SET])
			if (returnedArray[0]) {
				ObjectContainer3D(returnedArray[1]).addChild(ctr);
				parentName = ObjectContainer3D(returnedArray[1]).name;
			} else if (par_id > 0)
				_blocks[blockID].addError("Could not find a parent for this ObjectContainer3D");
			
			// in AWD version 2.1 we read the Container properties
			if ((_version[0] == 2) && (_version[1] == 1)) {
				var props:Object = parseProperties({1:_matrixNrType, 2:_matrixNrType, 3:_matrixNrType, 4:UINT8});
				ctr.pivotPoint = new Vector3D(props.get(1, 0), props.get(2, 0), props.get(3, 0));
			}
			// in other versions we do not read the Container properties
			else
				parseProperties(null);
			// the extraProperties should only be set for AWD2.1-Files, but is read for both versions
			ctr.extra = parseUserAttributes();
			finalizeAsset(ctr, name);
			_blocks[blockID].data = ctr;
			if (_debug)
				trace("Parsed a Container: Name = '" + name + "' | Parent-Name = " + parentName);
		}
		
		// Block ID = 23
		private function parseMeshInstance(blockID:uint):void
		{
			var num_materials:uint;
			var materials_parsed:uint;
			var parent:ObjectContainer3D;
			
			var par_id:uint = _newBlockBytes.readUnsignedInt();
			var mtx:Matrix3D = parseMatrix3D();
			var name:String = parseVarStr();
			var parentName:String = "Root (TopLevel)";
			var data_id:uint = _newBlockBytes.readUnsignedInt();
			var geom:Geometry;
			var returnedArrayGeometry:Array = getAssetByID(data_id, [AssetType.GEOMETRY])
			if (returnedArrayGeometry[0])
				geom = returnedArrayGeometry[1] as Geometry;
			else {
				_blocks[blockID].addError("Could not find a Geometry for this Mesh. A empty Geometry is created!");
				geom = new Geometry();
			}
			
			_blocks[blockID].geoID = data_id;
			var materials:Vector.<MaterialBase> = new Vector.<MaterialBase>();
			num_materials = _newBlockBytes.readUnsignedShort();
			var materialNames:Array = new Array();
			materials_parsed = 0;
			var returnedArrayMaterial:Array;
			while (materials_parsed < num_materials) {
				var mat_id:uint;
				mat_id = _newBlockBytes.readUnsignedInt();
				returnedArrayMaterial = getAssetByID(mat_id, [AssetType.MATERIAL])
				if ((!returnedArrayMaterial[0]) && (mat_id > 0))
					_blocks[blockID].addError("Could not find Material Nr " + materials_parsed + " (ID = " + mat_id + " ) for this Mesh");
				materials.push(returnedArrayMaterial[1] as MaterialBase);
				materialNames.push(MaterialBase(returnedArrayMaterial[1]).name);
				
				materials_parsed++;
			}
			
			var mesh:Mesh = new Mesh(geom, null);
			mesh.transform = mtx;
			
			var returnedArrayParent:Array = getAssetByID(par_id, [AssetType.CONTAINER, AssetType.LIGHT, AssetType.MESH, AssetType.ENTITY, AssetType.SEGMENT_SET])
			if (returnedArrayParent[0]) {
				ObjectContainer3D(returnedArrayParent[1]).addChild(mesh);
				parentName = ObjectContainer3D(returnedArrayParent[1]).name;
			} else if (par_id > 0)
				_blocks[blockID].addError("Could not find a parent for this Mesh");
			
			if (materials.length >= 1 && mesh.subMeshes.length == 1)
				mesh.material = materials[0];
			else if (materials.length > 1) {
				var i:uint;
				// Assign each sub-mesh in the mesh a material from the list. If more sub-meshes
				// than materials, repeat the last material for all remaining sub-meshes.
				for (i = 0; i < mesh.subMeshes.length; i++)
					mesh.subMeshes[i].material = materials[Math.min(materials.length - 1, i)];
			}
			if ((_version[0] == 2) && (_version[1] == 1)) {
				var props:Object = parseProperties({1:_matrixNrType, 2:_matrixNrType, 3:_matrixNrType, 4:UINT8, 5:BOOL});
				mesh.pivotPoint = new Vector3D(props.get(1, 0), props.get(2, 0), props.get(3, 0));
				mesh.castsShadows = props.get(5, true);
			} else
				parseProperties(null);
			mesh.extra = parseUserAttributes();
			finalizeAsset(mesh, name);
			_blocks[blockID].data = mesh;
			if (_debug)
				trace("Parsed a Mesh: Name = '" + name + "' | Parent-Name = " + parentName + "| Geometry-Name = " + geom.name + " | SubMeshes = " + mesh.subMeshes.length + " | Mat-Names = " + materialNames.toString());
		
		}
		
		//Block ID 31
		private function parseSkyBoxInstance(blockID:uint):void
		{
			var name:String = parseVarStr();
			var cubeTexAddr:uint = _newBlockBytes.readUnsignedInt();
			
			var returnedArrayCubeTex:Array = getAssetByID(cubeTexAddr, [AssetType.TEXTURE], "CubeTexture");
			if ((!returnedArrayCubeTex[0]) && (cubeTexAddr != 0))
				_blocks[blockID].addError("Could not find the Cubetexture (ID = " + cubeTexAddr + " ) for this SkyBox");
			var asset:SkyBox = new SkyBox(returnedArrayCubeTex[1] as BitmapCubeTexture);
			
			parseProperties(null)
			asset.extra = parseUserAttributes();
			finalizeAsset(asset, name);
			_blocks[blockID].data = asset;
			if (_debug)
				trace("Parsed a SkyBox: Name = '" + name + "' | CubeTexture-Name = " + BitmapCubeTexture(returnedArrayCubeTex[1]).name);
		
		}
		
		//Block ID = 41
		private function parseLight(blockID:uint):void
		{
			var light:LightBase;
			var newShadowMapper:ShadowMapperBase;
			var par_id:uint = _newBlockBytes.readUnsignedInt();
			var mtx:Matrix3D = parseMatrix3D();
			var name:String = parseVarStr();
			var lightType:uint = _newBlockBytes.readUnsignedByte();
			var props:AWDProperties = parseProperties({1:_propsNrType, 2:_propsNrType, 3:COLOR, 4:_propsNrType, 5:_propsNrType, 6:BOOL, 7:COLOR, 8:_propsNrType, 9:UINT8, 10:UINT8, 11:_propsNrType, 12:UINT16, 21:_matrixNrType, 22:_matrixNrType, 23:_matrixNrType});
			var shadowMapperType:uint = props.get(9, 0);
			var parentName:String = "Root (TopLevel)";
			var lightTypes:Array = ["Unsupported LightType", "PointLight", "DirectionalLight"];
			var shadowMapperTypes:Array = ["No ShadowMapper", "DirectionalShadowMapper", "NearDirectionalShadowMapper", "CascadeShadowMapper", "CubeMapShadowMapper"];
			if (lightType == 1) {
				light = new PointLight();
				PointLight(light).radius = props.get(1, 90000);
				PointLight(light).fallOff = props.get(2, 100000);
				if (shadowMapperType > 0) {
					if (shadowMapperType == 4)
						newShadowMapper = new CubeMapShadowMapper();
				}
				light.transform = mtx;
			}
			if (lightType == 2) {
				light = new DirectionalLight(props.get(21, 0), props.get(22, -1), props.get(23, 1));
				if (shadowMapperType > 0) {
					if (shadowMapperType == 1)
						newShadowMapper = new DirectionalShadowMapper();
					if (shadowMapperType == 2)
						newShadowMapper = new NearDirectionalShadowMapper(props.get(11, 0.5));
					if (shadowMapperType == 3)
						newShadowMapper = new CascadeShadowMapper(props.get(12, 3));
				}
			}
			if ((lightType != 2) && (lightType != 1)){
				_blocks[blockID].addError("Unsuported lighttype = "+lightType);
				return
				
			}
			light.color = props.get(3, 0xffffff);
			light.specular = props.get(4, 1.0);
			light.diffuse = props.get(5, 1.0);
			light.ambientColor = props.get(7, 0xffffff);
			light.ambient = props.get(8, 0.0);
			// if a shadowMapper has been created, adjust the depthMapSize if needed, assign to light and set castShadows to true
			if (newShadowMapper) {
				if (newShadowMapper is CubeMapShadowMapper) {
					if (props.get(10, 1) != 1)
						newShadowMapper.depthMapSize = _depthSizeDic[props.get(10, 1)];
				} else {
					if (props.get(10, 2) != 2)
						newShadowMapper.depthMapSize = _depthSizeDic[props.get(10, 2)];
				}
				
				light.shadowMapper = newShadowMapper;
				light.castsShadows = true;
			}
			if (par_id != 0) {
				var returnedArrayParent:Array = getAssetByID(par_id, [AssetType.CONTAINER, AssetType.LIGHT, AssetType.MESH, AssetType.ENTITY, AssetType.SEGMENT_SET])
				if (returnedArrayParent[0]) {
					ObjectContainer3D(returnedArrayParent[1]).addChild(light);
					parentName = ObjectContainer3D(returnedArrayParent[1]).name;
				} else
					_blocks[blockID].addError("Could not find a parent for this Light");
			}
			
			parseUserAttributes();
			
			finalizeAsset(light, name);
			
			_blocks[blockID].data = light;
			if (_debug)
				trace("Parsed a Light: Name = '" + name + "' | Type = " + lightTypes[lightType] + " | Parent-Name = " + parentName + " | ShadowMapper-Type = " + shadowMapperTypes[shadowMapperType]);
		
		}
		
		//Block ID = 43
		private function parseCamera(blockID:uint):void
		{
			
			var par_id:uint = _newBlockBytes.readUnsignedInt();
			var mtx:Matrix3D = parseMatrix3D();
			var name:String = parseVarStr();
			var parentName:String = "Root (TopLevel)";
			var lens:LensBase;
			_newBlockBytes.readUnsignedByte(); //set as active camera
			_newBlockBytes.readShort(); //lengthof lenses - not used yet
			var lenstype:uint = _newBlockBytes.readShort();
			var props:AWDProperties = parseProperties({101:_propsNrType, 102:_propsNrType, 103:_propsNrType, 104:_propsNrType});
			switch (lenstype) {
				case 5001:
					lens = new PerspectiveLens(props.get(101, 60));
					break;
				case 5002:
					lens = new OrthographicLens(props.get(101, 500));
					break;
				case 5003:
					lens = new OrthographicOffCenterLens(props.get(101, -400), props.get(102, 400), props.get(103, -300), props.get(104, 300));
					break;
				default:
					trace("unsupportedLenstype");
					return;
			}
			var camera:Camera3D = new Camera3D(lens);
			camera.transform = mtx;
			var returnedArrayParent:Array = getAssetByID(par_id, [AssetType.CONTAINER, AssetType.LIGHT, AssetType.MESH, AssetType.ENTITY, AssetType.SEGMENT_SET])
			if (returnedArrayParent[0]) {
				ObjectContainer3D(returnedArrayParent[1]).addChild(camera);
				parentName = ObjectContainer3D(returnedArrayParent[1]).name;
			} else if (par_id > 0)
				_blocks[blockID].addError("Could not find a parent for this Camera");
			camera.name = name;
			props = parseProperties({1:_matrixNrType, 2:_matrixNrType, 3:_matrixNrType, 4:UINT8, 101:_propsNrType, 102:_propsNrType});
			camera.pivotPoint = new Vector3D(props.get(1, 0), props.get(2, 0), props.get(3, 0));
			camera.lens.near = props.get(101, 20);
			camera.lens.far = props.get(102, 3000);
			camera.extra = parseUserAttributes();
			finalizeAsset(camera, name);
			
			_blocks[blockID].data = camera
			if (_debug)
				trace("Parsed a Camera: Name = '" + name + "' | Lenstype = " + lens + " | Parent-Name = " + parentName);
		
		}
		
		//Block ID = 43
		private function parseTextureProjector(blockID:uint):void
		{
			
			var par_id:uint = _newBlockBytes.readUnsignedInt();
			var mtx:Matrix3D = parseMatrix3D();
			var name:String = parseVarStr();
			var parentName:String = "Root (TopLevel)";
			var tex_id:uint = _newBlockBytes.readUnsignedInt();
			var returnedArrayGeometry:Array = getAssetByID(tex_id, [AssetType.TEXTURE])
			if ((!returnedArrayGeometry[0]) && (tex_id != 0))
				_blocks[blockID].addError("Could not find the Texture (ID = " + tex_id + " ( for this TextureProjector!");
			var textureProjector:TextureProjector = new TextureProjector(returnedArrayGeometry[1]);
			textureProjector.name = name;
			textureProjector.aspectRatio = _newBlockBytes.readFloat();
			textureProjector.fieldOfView = _newBlockBytes.readFloat();
			textureProjector.transform = mtx;
			var props:AWDProperties = parseProperties({1:_matrixNrType, 2:_matrixNrType, 3:_matrixNrType, 4:UINT8});
			textureProjector.pivotPoint = new Vector3D(props.get(1, 0), props.get(2, 0), props.get(3, 0));
			textureProjector.extra = parseUserAttributes();
			finalizeAsset(textureProjector, name);
			
			_blocks[blockID].data = textureProjector
			if (_debug)
				trace("Parsed a TextureProjector: Name = '" + name + "' | Texture-Name = " + Texture2DBase(returnedArrayGeometry[1]).name + " | Parent-Name = " + parentName);
		
		}
		
		//Block ID = 51
		private function parseLightPicker(blockID:uint):void
		{
			var name:String = parseVarStr();
			var numLights:uint = _newBlockBytes.readUnsignedShort();
			var lightsArray:Array = new Array();
			var k:int = 0;
			var lightID:int = 0;
			var returnedArrayLight:Array;
			var lightsArrayNames:Array = new Array();
			for (k = 0; k < numLights; k++) {
				lightID = _newBlockBytes.readUnsignedInt();
				returnedArrayLight = getAssetByID(lightID, [AssetType.LIGHT])
				if (returnedArrayLight[0]) {
					lightsArray.push(returnedArrayLight[1] as LightBase);
					lightsArrayNames.push(LightBase(returnedArrayLight[1]).name);
				} else
					_blocks[blockID].addError("Could not find a Light Nr " + k + " (ID = " + lightID + " ) for this LightPicker");
			}
			if (lightsArray.length == 0) {
				_blocks[blockID].addError("Could not create this LightPicker, cause no Light was found.");
				parseUserAttributes();
				return; //return without any more parsing for this block
			}
			var lightPick:LightPickerBase = new StaticLightPicker(lightsArray);
			lightPick.name = name;
			parseUserAttributes();
			finalizeAsset(lightPick, name);
			
			_blocks[blockID].data = lightPick
			if (_debug)
				trace("Parsed a StaticLightPicker: Name = '" + name + "' | Texture-Name = " + lightsArrayNames.toString());
		}
		
		//Block ID = 81
		private function parseMaterial(blockID:uint):void
		{
			// TODO: not used
			////blockLength = block.len; 
			var name:String;
			var type:uint;
			var props:AWDProperties;
			var mat:MaterialBase;
			var attributes:Object;
			var finalize:Boolean;
			var num_methods:uint;
			var methods_parsed:uint;
			var returnedArray:Array;
			
			name = parseVarStr();
			type = _newBlockBytes.readUnsignedByte();
			num_methods = _newBlockBytes.readUnsignedByte();
			
			// Read material numerical properties
			// (1=color, 2=bitmap url, 10=alpha, 11=alpha_blending, 12=alpha_threshold, 13=repeat)
			props = parseProperties({1:INT32, 2:BADDR, 10:_propsNrType, 11:BOOL, 12:_propsNrType, 13:BOOL});
			
			methods_parsed = 0;
			while (methods_parsed < num_methods) {
				var method_type:uint;
				
				method_type = _newBlockBytes.readUnsignedShort();
				parseProperties(null);
				parseUserAttributes();
				methods_parsed += 1;
			}
			var debugString:String = "";
			attributes = parseUserAttributes();
			if (type == 1) { // Color material
				debugString += "Parsed a ColorMaterial(SinglePass): Name = '" + name + "' | ";
				var color:uint;
				color = props.get(1, 0xcccccc);
				if (materialMode < 2)
					mat = new ColorMaterial(color, props.get(10, 1.0));
				else
					mat = new ColorMultiPassMaterial(color);
				
			} else if (type == 2) {
				var tex_addr:uint = props.get(2, 0);
				returnedArray = getAssetByID(tex_addr, [AssetType.TEXTURE])
				if ((!returnedArray[0]) && (tex_addr > 0))
					_blocks[blockID].addError("Could not find the DiffsueTexture (ID = " + tex_addr + " ) for this Material");
				
				if (materialMode < 2) {
					mat = new TextureMaterial(returnedArray[1]);
					TextureMaterial(mat).alphaBlending = props.get(11, false);
					TextureMaterial(mat).alpha = props.get(10, 1.0);
					debugString += "Parsed a TextureMaterial(SinglePass): Name = '" + name + "' | Texture-Name = " + mat.name;
				} else {
					mat = new TextureMultiPassMaterial(returnedArray[1]);
					debugString += "Parsed a TextureMaterial(MultipAss): Name = '" + name + "' | Texture-Name = " + mat.name;
				}
			}
			
			mat.extra = attributes;
			if (materialMode < 2)
				SinglePassMaterialBase(mat).alphaThreshold = props.get(12, 0.0);
			else
				MultiPassMaterialBase(mat).alphaThreshold = props.get(12, 0.0);
			mat.repeat = props.get(13, false);
			
			finalizeAsset(mat, name);
			
			_blocks[blockID].data = mat;
			if (_debug)
				trace(debugString);
		}
		
		// Block ID = 81 AWD2.1		
		private function parseMaterial_v1(blockID:uint):void
		{
			var mat:MaterialBase;
			var normalTexture:Texture2DBase;
			var specTexture:Texture2DBase;
			var returnedArray:Array;
			var name:String = parseVarStr();
			var type:uint = _newBlockBytes.readUnsignedByte();
			var num_methods:uint = _newBlockBytes.readUnsignedByte();
			var props:AWDProperties = parseProperties({1:UINT32, 2:BADDR, 3:BADDR, 4:UINT8, 5:BOOL, 6:BOOL, 7:BOOL, 8:BOOL, 9:UINT8, 10:_propsNrType, 11:BOOL, 12:_propsNrType, 13:BOOL, 15:_propsNrType, 16:UINT32, 17:BADDR, 18:_propsNrType, 19:_propsNrType, 20:UINT32, 21:BADDR, 22:BADDR});
			
			var spezialType:uint = props.get(4, 0);
			var debugString:String = "";
			if (spezialType >= 2) { //this is no supported material
				_blocks[blockID].addError("Material-spezialType '" + spezialType + "' is not supported, can only be 0:singlePass, 1:MultiPass !");
				return;
			}
			if (materialMode == 1)
				spezialType = 0;
			else if (materialMode == 2)
				spezialType = 1;
			if (spezialType < 2) { //this is SinglePass or MultiPass					
				if (type == 1) { // Color material
					var color:uint = color = props.get(1, 0xcccccc);
					if (spezialType == 1) { //	MultiPassMaterial
						mat = new ColorMultiPassMaterial(color);
						debugString += "Parsed a ColorMaterial(MultiPass): Name = '" + name + "' | ";
					} else { //	SinglePassMaterial
						mat = new ColorMaterial(color, props.get(10, 1.0));
						ColorMaterial(mat).alphaBlending = props.get(11, false);
						debugString += "Parsed a ColorMaterial(SinglePass): Name = '" + name + "' | ";
					}
				} else if (type == 2) { // texture material
					
					var tex_addr:uint = props.get(2, 0);
					returnedArray = getAssetByID(tex_addr, [AssetType.TEXTURE])
					if ((!returnedArray[0]) && (tex_addr > 0))
						_blocks[blockID].addError("Could not find the DiffsueTexture (ID = " + tex_addr + " ) for this TextureMaterial");
					var texture:Texture2DBase = returnedArray[1];
					
					var ambientTexture:Texture2DBase;
					var ambientTex_addr:uint = props.get(17, 0);
					returnedArray = getAssetByID(ambientTex_addr, [AssetType.TEXTURE])
					if ((!returnedArray[0]) && (ambientTex_addr != 0))
						_blocks[blockID].addError("Could not find the AmbientTexture (ID = " + ambientTex_addr + " ) for this TextureMaterial");
					if (returnedArray[0])
						ambientTexture = returnedArray[1]
					if (spezialType == 1) { // MultiPassMaterial
						mat = new TextureMultiPassMaterial(texture);
						debugString += "Parsed a TextureMaterial(MultiPass): Name = '" + name + "' | Texture-Name = " + texture.name;
						if (ambientTexture) {
							TextureMultiPassMaterial(mat).ambientTexture = ambientTexture;
							debugString += " | AmbientTexture-Name = " + ambientTexture.name;
						}
					} else { //	SinglePassMaterial
						mat = new TextureMaterial(texture);
						debugString += "Parsed a TextureMaterial(SinglePass): Name = '" + name + "' | Texture-Name = " + texture.name;
						if (ambientTexture) {
							TextureMaterial(mat).ambientTexture = ambientTexture;
							debugString += " | AmbientTexture-Name = " + ambientTexture.name;
						}
						TextureMaterial(mat).alpha = props.get(10, 1.0);
						TextureMaterial(mat).alphaBlending = props.get(11, false);
					}
					
				}
				var normalTex_addr:uint = props.get(3, 0);
				returnedArray = getAssetByID(normalTex_addr, [AssetType.TEXTURE])
				if ((!returnedArray[0]) && (normalTex_addr != 0))
					_blocks[blockID].addError("Could not find the NormalTexture (ID = " + normalTex_addr + " ) for this TextureMaterial");
				if (returnedArray[0]) {
					normalTexture = returnedArray[1];
					debugString += " | NormalTexture-Name = " + normalTexture.name;
				}
				
				var specTex_addr:uint = props.get(21, 0);
				returnedArray = getAssetByID(specTex_addr, [AssetType.TEXTURE])
				if ((!returnedArray[0]) && (specTex_addr != 0))
					_blocks[blockID].addError("Could not find the SpecularTexture (ID = " + specTex_addr + " ) for this TextureMaterial");
				if (returnedArray[0]) {
					specTexture = returnedArray[1];
					debugString += " | SpecularTexture-Name = " + specTexture.name;
				}
				var lightPickerAddr:uint = props.get(22, 0);
				returnedArray = getAssetByID(lightPickerAddr, [AssetType.LIGHT_PICKER])
				if ((!returnedArray[0]) && (lightPickerAddr))
					_blocks[blockID].addError("Could not find the LightPicker (ID = " + lightPickerAddr + " ) for this TextureMaterial");
				else {
					MaterialBase(mat).lightPicker = returnedArray[1] as LightPickerBase;
						//debugString+=" | Lightpicker-Name = "+LightPickerBase(returnedArray[1]).name; 
				}
				
				MaterialBase(mat).smooth = props.get(5, true);
				MaterialBase(mat).mipmap = props.get(6, true);
				MaterialBase(mat).bothSides = props.get(7, false);
				MaterialBase(mat).alphaPremultiplied = props.get(8, false);
				MaterialBase(mat).blendMode = blendModeDic[props.get(9, 0)];
				MaterialBase(mat).repeat = props.get(13, false);
				
				if (spezialType == 0) { // this is a SinglePassMaterial					
					if (normalTexture)
						SinglePassMaterialBase(mat).normalMap = normalTexture;
					if (specTexture)
						SinglePassMaterialBase(mat).specularMap = specTexture;
					SinglePassMaterialBase(mat).alphaThreshold = props.get(12, 0.0);
					SinglePassMaterialBase(mat).ambient = props.get(15, 1.0);
					SinglePassMaterialBase(mat).ambientColor = props.get(16, 0xffffff);
					SinglePassMaterialBase(mat).specular = props.get(18, 1.0);
					SinglePassMaterialBase(mat).gloss = props.get(19, 50);
					SinglePassMaterialBase(mat).specularColor = props.get(20, 0xffffff);
				}
				
				else { // this is MultiPassMaterial					
					if (normalTexture)
						MultiPassMaterialBase(mat).normalMap = normalTexture;
					if (specTexture)
						MultiPassMaterialBase(mat).specularMap = specTexture;
					MultiPassMaterialBase(mat).alphaThreshold = props.get(12, 0.0);
					MultiPassMaterialBase(mat).ambient = props.get(15, 1.0);
					MultiPassMaterialBase(mat).ambientColor = props.get(16, 0xffffff);
					MultiPassMaterialBase(mat).specular = props.get(18, 1.0);
					MultiPassMaterialBase(mat).gloss = props.get(19, 50);
					MultiPassMaterialBase(mat).specularColor = props.get(20, 0xffffff);
				}
				
				var methods_parsed:uint = 0;
				var targetID:uint;
				while (methods_parsed < num_methods) {
					var method_type:uint;
					method_type = _newBlockBytes.readUnsignedShort();
					props = parseProperties({1:BADDR, 2:BADDR, 3:BADDR, 101:_propsNrType, 102:_propsNrType, 103:_propsNrType, 201:UINT32, 202:UINT32, 301:UINT16, 302:UINT16, 401:UINT8, 402:UINT8, 601:COLOR, 602:COLOR, 701:BOOL, 702:BOOL, 801:MTX4x4});
					switch (method_type) {
						case 999: //wrapper-Methods that will load a previous parsed EffektMethod returned
							targetID = props.get(1, 0);
							returnedArray = getAssetByID(targetID, [AssetType.EFFECTS_METHOD]);
							if (!returnedArray[0])
								_blocks[blockID].addError("Could not find the EffectMethod (ID = " + targetID + " ) for this Material");
							else {
								if (spezialType == 0)
									SinglePassMaterialBase(mat).addMethod(returnedArray[1]);
								if (spezialType == 1)
									MultiPassMaterialBase(mat).addMethod(returnedArray[1]);
								debugString += " | EffectMethod-Name = " + EffectMethodBase(returnedArray[1]).name;
							}
							break;
						case 998: //wrapper-Methods that will load a previous parsed ShadowMapMethod 
							targetID = props.get(1, 0);
							returnedArray = getAssetByID(targetID, [AssetType.SHADOW_MAP_METHOD]);
							if (!returnedArray[0])
								_blocks[blockID].addError("Could not find the ShadowMethod (ID = " + targetID + " ) for this Material");
							else {
								if (spezialType == 0)
									SinglePassMaterialBase(mat).shadowMethod = returnedArray[1];
								if (spezialType == 1)
									MultiPassMaterialBase(mat).shadowMethod = returnedArray[1];
								debugString += " | ShadowMethod-Name = " + ShadowMapMethodBase(returnedArray[1]).name;
							}
							break;
						
						case 1: //EnvMapAmbientMethod                             
							targetID = props.get(1, 0);
							returnedArray = getAssetByID(targetID, [AssetType.TEXTURE], "CubeTexture");
							if (!returnedArray[0])
								_blocks[blockID].addError("Could not find the EnvMap (ID = " + targetID + " ) for this EnvMapAmbientMethodMaterial");
							if (spezialType == 0)
								SinglePassMaterialBase(mat).ambientMethod = new EnvMapAmbientMethod(returnedArray[1]);
							if (spezialType == 1)
								MultiPassMaterialBase(mat).ambientMethod = new EnvMapAmbientMethod(returnedArray[1]);
							debugString += " | EnvMapAmbientMethod | EnvMap-Name =" + CubeTextureBase(returnedArray[1]).name;
							break;
						
						case 51: //DepthDiffuseMethod
							if (spezialType == 0)
								SinglePassMaterialBase(mat).diffuseMethod = new DepthDiffuseMethod();
							if (spezialType == 1)
								MultiPassMaterialBase(mat).diffuseMethod = new DepthDiffuseMethod();
							debugString += " | DepthDiffuseMethod";
							break;
						case 52: //GradientDiffuseMethod
							targetID = props.get(1, 0);
							returnedArray = getAssetByID(targetID, [AssetType.TEXTURE]);
							if (!returnedArray[0])
								_blocks[blockID].addError("Could not find the GradientDiffuseTexture (ID = " + targetID + " ) for this GradientDiffuseMethod");
							if (spezialType == 0)
								SinglePassMaterialBase(mat).diffuseMethod = new GradientDiffuseMethod(returnedArray[1]);
							if (spezialType == 1)
								MultiPassMaterialBase(mat).diffuseMethod = new GradientDiffuseMethod(returnedArray[1]);
							debugString += " | GradientDiffuseMethod | GradientDiffuseTexture-Name =" + Texture2DBase(returnedArray[1]).name;
							break;
						case 53: //WrapDiffuseMethod
							if (spezialType == 0)
								SinglePassMaterialBase(mat).diffuseMethod = new WrapDiffuseMethod(props.get(101, 5));
							if (spezialType == 1)
								MultiPassMaterialBase(mat).diffuseMethod = new WrapDiffuseMethod(props.get(101, 5));
							debugString += " | WrapDiffuseMethod";
							break;
						case 54: //LightMapDiffuseMethod
							targetID = props.get(1, 0);
							returnedArray = getAssetByID(targetID, [AssetType.TEXTURE]);
							if (!returnedArray[0])
								_blocks[blockID].addError("Could not find the LightMap (ID = " + targetID + " ) for this LightMapDiffuseMethod");
							if (spezialType == 0)
								SinglePassMaterialBase(mat).diffuseMethod = new LightMapDiffuseMethod(returnedArray[1], blendModeDic[props.get(401, 10)], false, SinglePassMaterialBase(mat).diffuseMethod);
							if (spezialType == 1)
								MultiPassMaterialBase(mat).diffuseMethod = new LightMapDiffuseMethod(returnedArray[1], blendModeDic[props.get(401, 10)], false, MultiPassMaterialBase(mat).diffuseMethod);
							debugString += " | LightMapDiffuseMethod | LightMapTexture-Name =" + Texture2DBase(returnedArray[1]).name;
							break;
						case 55: //CelDiffuseMethod
							if (spezialType == 0) {
								SinglePassMaterialBase(mat).diffuseMethod = new CelDiffuseMethod(props.get(401, 3), SinglePassMaterialBase(mat).diffuseMethod);
								CelDiffuseMethod(SinglePassMaterialBase(mat).diffuseMethod).smoothness = props.get(101, 0.1);
							}
							if (spezialType == 1) {
								MultiPassMaterialBase(mat).diffuseMethod = new CelDiffuseMethod(props.get(401, 3), MultiPassMaterialBase(mat).diffuseMethod);
								CelDiffuseMethod(MultiPassMaterialBase(mat).diffuseMethod).smoothness = props.get(101, 0.1);
							}
							debugString += " | CelDiffuseMethod";
							break;
						case 56: //SubSurfaceScatteringMethod
							if (spezialType == 0) {
								SinglePassMaterialBase(mat).diffuseMethod = new SubsurfaceScatteringDiffuseMethod(); //depthMapSize and depthMapOffset ?
								SubsurfaceScatteringDiffuseMethod(SinglePassMaterialBase(mat).diffuseMethod).scattering = props.get(101, 0.2);
								SubsurfaceScatteringDiffuseMethod(SinglePassMaterialBase(mat).diffuseMethod).translucency = props.get(102, 1);
								SubsurfaceScatteringDiffuseMethod(SinglePassMaterialBase(mat).diffuseMethod).scatterColor = props.get(601, 0xffffff);
							}
							if (spezialType == 1) {
								MultiPassMaterialBase(mat).diffuseMethod = new SubsurfaceScatteringDiffuseMethod(); //depthMapSize and depthMapOffset ?
								SubsurfaceScatteringDiffuseMethod(MultiPassMaterialBase(mat).diffuseMethod).scattering = props.get(101, 0.2);
								SubsurfaceScatteringDiffuseMethod(MultiPassMaterialBase(mat).diffuseMethod).translucency = props.get(102, 1);
								SubsurfaceScatteringDiffuseMethod(MultiPassMaterialBase(mat).diffuseMethod).scatterColor = props.get(601, 0xffffff);
							}
							debugString += " | SubSurfaceScatteringMethod";
							break;
						
						case 101: //AnisotropicSpecularMethod 
							if (spezialType == 0)
								SinglePassMaterialBase(mat).specularMethod = new AnisotropicSpecularMethod();
							if (spezialType == 1)
								MultiPassMaterialBase(mat).specularMethod = new AnisotropicSpecularMethod();
							debugString += " | AnisotropicSpecularMethod";
							break;
						case 102: //PhongSpecularMethod
							if (spezialType == 0)
								SinglePassMaterialBase(mat).specularMethod = new PhongSpecularMethod();
							if (spezialType == 1)
								MultiPassMaterialBase(mat).specularMethod = new PhongSpecularMethod();
							debugString += " | PhongSpecularMethod";
							break;
						case 103: //CellSpecularMethod
							if (spezialType == 0) {
								SinglePassMaterialBase(mat).specularMethod = new CelSpecularMethod(props.get(101, 0.5), SinglePassMaterialBase(mat).specularMethod);
								CelSpecularMethod(SinglePassMaterialBase(mat).specularMethod).smoothness = props.get(102, 0.1);
							}
							if (spezialType == 1) {
								MultiPassMaterialBase(mat).specularMethod = new CelSpecularMethod(props.get(101, 0.5), MultiPassMaterialBase(mat).specularMethod);
								CelSpecularMethod(MultiPassMaterialBase(mat).specularMethod).smoothness = props.get(102, 0.1);
							}
							debugString += " | CellSpecularMethod";
							break;
						case 104: //FresnelSpecularMethod
							if (spezialType == 0) {
								SinglePassMaterialBase(mat).specularMethod = new FresnelSpecularMethod(props.get(701, true), SinglePassMaterialBase(mat).specularMethod);
								FresnelSpecularMethod(SinglePassMaterialBase(mat).specularMethod).fresnelPower = props.get(101, 5);
								FresnelSpecularMethod(SinglePassMaterialBase(mat).specularMethod).normalReflectance = props.get(102, 0.1);
							}
							if (spezialType == 1) {
								MultiPassMaterialBase(mat).specularMethod = new FresnelSpecularMethod(props.get(701, true), MultiPassMaterialBase(mat).specularMethod);
								FresnelSpecularMethod(MultiPassMaterialBase(mat).specularMethod).fresnelPower = props.get(101, 5);
								FresnelSpecularMethod(MultiPassMaterialBase(mat).specularMethod).normalReflectance = props.get(102, 0.1);
							}
							debugString += " | FresnelSpecularMethod";
							break;
						//case 151://HeightMapNormalMethod - thios is not implemented for now, but might appear later
						//break;
						case 152: //SimpleWaterNormalMethod
							targetID = props.get(1, 0);
							returnedArray = getAssetByID(targetID, [AssetType.TEXTURE]);
							if (!returnedArray[0])
								_blocks[blockID].addError("Could not find the SecoundNormalMap (ID = " + targetID + " ) for this SimpleWaterNormalMethod");
							if (spezialType == 0) {
								if (!SinglePassMaterialBase(mat).normalMap)
									_blocks[blockID].addError("Could not find a normal Map on this Material to use with this SimpleWaterNormalMethod");
								SinglePassMaterialBase(mat).normalMap = returnedArray[1];
								SinglePassMaterialBase(mat).normalMethod = new SimpleWaterNormalMethod(SinglePassMaterialBase(mat).normalMap, returnedArray[1]);
							}
							if (spezialType == 1) {
								if (!MultiPassMaterialBase(mat).normalMap)
									_blocks[blockID].addError("Could not find a normal Map on this Material to use with this SimpleWaterNormalMethod");
								MultiPassMaterialBase(mat).normalMap = returnedArray[1];
								MultiPassMaterialBase(mat).normalMethod = new SimpleWaterNormalMethod(MultiPassMaterialBase(mat).normalMap, returnedArray[1]);
							}
							debugString += " | SimpleWaterNormalMethod | Second-NormalTexture-Name = " + Texture2DBase(returnedArray[1]).name;
							break;
					}
					parseUserAttributes();
					methods_parsed += 1;
				}
			}
			MaterialBase(mat).extra = parseUserAttributes();
			finalizeAsset(mat, name);
			_blocks[blockID].data = mat;
			if (_debug)
				trace(debugString);
		}
		
		//Block ID = 82
		private function parseTexture(blockID:uint):void
		{
			var asset:Texture2DBase;
			
			_blocks[blockID].name = parseVarStr();
			var type:uint = _newBlockBytes.readUnsignedByte();
			var data_len:uint;
			_texture_users[_cur_block_id.toString()] = [];
			
			// External
			if (type == 0) {
				data_len = _newBlockBytes.readUnsignedInt();
				var url:String;
				url = _newBlockBytes.readUTFBytes(data_len);
				addDependency(_cur_block_id.toString(), new URLRequest(url), false, null, true);
			} else {
				data_len = _newBlockBytes.readUnsignedInt();
				var data:ByteArray;
				data = new ByteArray();
				_newBlockBytes.readBytes(data, 0, data_len);
				addDependency(_cur_block_id.toString(), null, false, data, true);
			}
			// Ignore for now
			parseProperties(null);
			_blocks[blockID].extras = parseUserAttributes();
			pauseAndRetrieveDependencies();
			_blocks[blockID].data = asset;
			if (_debug) {
				var textureStylesNames:Array = ["external", "embed"]
				trace("Start parsing a " + textureStylesNames[type] + " Bitmap for Texture");
			}
		}
		
		//Block ID = 83
		private function parseCubeTexture(blockID:uint):void
		{
			//blockLength = block.len;
			var data_len:uint;
			var asset:CubeTextureBase;
			var i:int;
			_cubeTextures = new Array();
			_texture_users[_cur_block_id.toString()] = [];
			var type:uint = _newBlockBytes.readUnsignedByte();
			_blocks[blockID].name = parseVarStr();
			
			for (i = 0; i < 6; i++) {
				_texture_users[_cur_block_id.toString()] = [];
				_cubeTextures.push(null);
				// External
				if (type == 0) {
					data_len = _newBlockBytes.readUnsignedInt();
					var url:String;
					url = _newBlockBytes.readUTFBytes(data_len);
					addDependency(_cur_block_id.toString() + "#" + i, new URLRequest(url), false, null, true);
				} else {
					data_len = _newBlockBytes.readUnsignedInt();
					var data:ByteArray;
					data = new ByteArray();
					_newBlockBytes.readBytes(data, 0, data_len);
					addDependency(_cur_block_id.toString() + "#" + i, null, false, data, true);
				}
			}
			
			// Ignore for now
			parseProperties(null);
			_blocks[blockID].extras = parseUserAttributes();
			pauseAndRetrieveDependencies();
			_blocks[blockID].data = asset;
			if (_debug) {
				var textureStylesNames:Array = ["external", "embed"]
				trace("Start parsing 6 " + textureStylesNames[type] + " Bitmaps for CubeTexture");
			}
		}
		
		//Block ID = 91
		private function parseSharedMethodBlock(blockID:uint):void
		{
			var asset:EffectMethodBase;
			_blocks[blockID].name = parseVarStr();
			asset = parseSharedMethodList(blockID);
			parseUserAttributes();
			_blocks[blockID].data = asset;
			finalizeAsset(asset, _blocks[blockID].name);
			_blocks[blockID].data = asset;
			if (_debug)
				trace("Parsed a EffectMethod: Name = " + asset.name + " Type = " + asset);
		}
		
		// this functions reads and creates a EffectMethod 
		private function parseSharedMethodList(blockID:uint):EffectMethodBase
		{
			
			var methodType:uint = _newBlockBytes.readUnsignedShort();
			var effectMethodReturn:EffectMethodBase;
			var props:AWDProperties = parseProperties({1:BADDR, 2:BADDR, 3:BADDR, 101:_propsNrType, 102:_propsNrType, 103:_propsNrType, 104:_propsNrType, 105:_propsNrType, 106:_propsNrType, 107:_propsNrType, 201:UINT32, 202:UINT32, 301:UINT16, 302:UINT16, 401:UINT8, 402:UINT8, 601:COLOR, 602:COLOR, 701:BOOL, 702:BOOL});
			var targetID:uint;
			var returnedArray:Array;
			switch (methodType) {
				// Effect Methods
				case 401: //ColorMatrix
					effectMethodReturn = new ColorMatrixMethod(props.get(101, new Array(0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)));
					break;
				case 402: //ColorTransform
					effectMethodReturn = new ColorTransformMethod();
					var offCol:uint = props.get(601, 0x00000000);
					var newColorTransform:ColorTransform = new ColorTransform(props.get(102, 1), props.get(103, 1), props.get(104, 1), props.get(101, 1), ((offCol >> 16) & 0xFF), ((offCol >> 8) & 0xFF), (offCol & 0xFF), ((offCol >> 24) & 0xFF));
					ColorTransformMethod(effectMethodReturn).colorTransform = newColorTransform;
					break;
				case 403: //EnvMap
					targetID = props.get(1, 0);
					returnedArray = getAssetByID(targetID, [AssetType.TEXTURE], "CubeTexture");
					if (!returnedArray[0])
						_blocks[blockID].addError("Could not find the EnvMap (ID = " + targetID + " ) for this EnvMapMethod");
					effectMethodReturn = new EnvMapMethod(returnedArray[1], props.get(101, 1));
					targetID = props.get(2, 0);
					if (targetID > 0) {
						returnedArray = getAssetByID(targetID, [AssetType.TEXTURE]);
						if (!returnedArray[0])
							_blocks[blockID].addError("Could not find the Mask-texture (ID = " + targetID + " ) for this EnvMapMethod");
						EnvMapMethod(effectMethodReturn).mask = returnedArray[1];
					}
					break;
				case 404: //LightMapMethod
					targetID = props.get(1, 0);
					returnedArray = getAssetByID(targetID, [AssetType.TEXTURE]);
					if (!returnedArray[0])
						_blocks[blockID].addError("Could not find the LightMap (ID = " + targetID + " ) for this LightMapMethod");
					effectMethodReturn = new LightMapMethod(returnedArray[1], blendModeDic[props.get(401, 10)]); //usesecondaryUV not set					
					break;
				case 405: //ProjectiveTextureMethod
					targetID = props.get(1, 0);
					returnedArray = getAssetByID(targetID, [AssetType.TEXTURE_PROJECTOR]);
					if (!returnedArray[0])
						_blocks[blockID].addError("Could not find the TextureProjector (ID = " + targetID + " ) for this ProjectiveTextureMethod");
					effectMethodReturn = new ProjectiveTextureMethod(returnedArray[1], blendModeDic[props.get(401, 10)]);
					break;
				case 406: //RimLightMethod
					effectMethodReturn = new RimLightMethod(props.get(601, 0xffffff), props.get(101, 0.4), props.get(102, 2));
					break;
				case 407: //AlphaMaskMethod
					targetID = props.get(1, 0);
					returnedArray = getAssetByID(targetID, [AssetType.TEXTURE]);
					if (!returnedArray[0])
						_blocks[blockID].addError("Could not find the Alpha-texture (ID = " + targetID + " ) for this AlphaMaskMethod");
					effectMethodReturn = new AlphaMaskMethod(returnedArray[1], props.get(701, false));
					break;
				case 408: //RefractionEnvMapMethod
					targetID = props.get(1, 0);
					returnedArray = getAssetByID(targetID, [AssetType.TEXTURE], "CubeTexture");
					if (!returnedArray[0])
						_blocks[blockID].addError("Could not find the EnvMap (ID = " + targetID + " ) for this RefractionEnvMapMethod");
					effectMethodReturn = new RefractionEnvMapMethod(returnedArray[1], props.get(101, 0.1), props.get(102, 0.01), props.get(103, 0.01), props.get(104, 0.01));
					RefractionEnvMapMethod(effectMethodReturn).alpha = props.get(104, 1);
					break;
				case 409: //OutlineMethod
					effectMethodReturn = new OutlineMethod(props.get(601, 0x00000000), props.get(101, 1), props.get(701, true), props.get(702, false));
					break;
				case 410: //FresnelEnvMapMethod
					targetID = props.get(1, 0);
					returnedArray = getAssetByID(targetID, [AssetType.TEXTURE], "CubeTexture");
					if (!returnedArray[0])
						_blocks[blockID].addError("Could not find the EnvMap (ID = " + targetID + " ) for this FresnelEnvMapMethod");
					effectMethodReturn = new FresnelEnvMapMethod(returnedArray[1], props.get(101, 1));
					break;
				case 411: //FogMethod
					effectMethodReturn = new FogMethod(props.get(101, 0), props.get(102, 1000), props.get(601, 0x808080));
					break;
				
			}
			parseUserAttributes();
			return effectMethodReturn;
		}
		
		//Block ID = 92
		private function parseShadowMethodBlock(blockID:uint):void
		{
			var type:uint;
			var data_len:uint;
			var asset:ShadowMapMethodBase;
			var shadowLightID:uint;
			_blocks[blockID].name = parseVarStr();
			shadowLightID = _newBlockBytes.readUnsignedInt();
			var returnedArray:Array = getAssetByID(shadowLightID, [AssetType.LIGHT]);
			if (!returnedArray[0]) {
				_blocks[blockID].addError("Could not find the TargetLight (ID = " + shadowLightID + " ) for this ShadowMethod - ShadowMethod not created");
				return;
			}
			asset = parseShadowMethodList(returnedArray[1] as LightBase, blockID);
			if (!asset)
				return;
			parseUserAttributes(); // Ignore for now
			finalizeAsset(asset, _blocks[blockID].name);
			_blocks[blockID].data = asset;
			if (_debug)
				trace("Parsed a ShadowMapMethodMethod: Name = " + asset.name + " | Type = " + asset + " | Light-Name = " + LightBase(returnedArray[1]));
		}
		
		// this functions reads and creates a ShadowMethodMethod
		private function parseShadowMethodList(light:LightBase, blockID:uint):ShadowMapMethodBase
		{
			
			var methodType:uint = _newBlockBytes.readUnsignedShort();
			var shadowMethod:ShadowMapMethodBase;
			var props:AWDProperties = parseProperties({1:BADDR, 2:BADDR, 3:BADDR, 101:_propsNrType, 102:_propsNrType, 103:_propsNrType, 201:UINT32, 202:UINT32, 301:UINT16, 302:UINT16, 401:UINT8, 402:UINT8, 601:COLOR, 602:COLOR, 701:BOOL, 702:BOOL, 801:MTX4x4});
			var targetID:uint;
			var returnedArray:Array;
			switch (methodType) {
				case 1001: //CascadeShadowMapMethod
					targetID = props.get(1, 0);
					returnedArray = getAssetByID(targetID, [AssetType.SHADOW_MAP_METHOD]);
					if (!returnedArray[0]) {
						_blocks[blockID].addError("Could not find the ShadowBaseMethod (ID = " + targetID + " ) for this CascadeShadowMapMethod - ShadowMethod not created");
						return shadowMethod;
					}
					shadowMethod = new CascadeShadowMapMethod(returnedArray[1]);
					break;
				case 1002: //NearShadowMapMethod
					targetID = props.get(1, 0);
					returnedArray = getAssetByID(targetID, [AssetType.SHADOW_MAP_METHOD]);
					if (!returnedArray[0]) {
						_blocks[blockID].addError("Could not find the ShadowBaseMethod (ID = " + targetID + " ) for this NearShadowMapMethod - ShadowMethod not created");
						return shadowMethod;
					}
					shadowMethod = new NearShadowMapMethod(returnedArray[1]);
					break;
				case 1101: //FilteredShadowMapMethod					
					shadowMethod = new FilteredShadowMapMethod(DirectionalLight(light));
					FilteredShadowMapMethod(shadowMethod).alpha = props.get(101, 1);
					FilteredShadowMapMethod(shadowMethod).epsilon = props.get(102, 0.002);
					break;
				case 1102: //DitheredShadowMapMethod
					shadowMethod = new DitheredShadowMapMethod(DirectionalLight(light), props.get(201, 5));
					DitheredShadowMapMethod(shadowMethod).alpha = props.get(101, 1);
					DitheredShadowMapMethod(shadowMethod).epsilon = props.get(102, 0.002);
					DitheredShadowMapMethod(shadowMethod).range = props.get(103, 1);
					break;
				case 1103: //SoftShadowMapMethod
					shadowMethod = new SoftShadowMapMethod(DirectionalLight(light), props.get(201, 5));
					SoftShadowMapMethod(shadowMethod).alpha = props.get(101, 1);
					SoftShadowMapMethod(shadowMethod).epsilon = props.get(102, 0.002);
					SoftShadowMapMethod(shadowMethod).range = props.get(103, 1);
					break;
				case 1104: //HardShadowMapMethod
					shadowMethod = new HardShadowMapMethod(light);
					HardShadowMapMethod(shadowMethod).alpha = props.get(101, 1);
					HardShadowMapMethod(shadowMethod).epsilon = props.get(102, 0.002);
					break;
				
			}
			parseUserAttributes();
			return shadowMethod;
		}
		
		//Block ID 101
		private function parseSkeleton(blockID:uint):void
		{
			var name:String = parseVarStr();
			var num_joints:uint = _newBlockBytes.readUnsignedShort();
			var skeleton:Skeleton = new Skeleton();
			parseProperties(null); // Discard properties for now		
			
			var joints_parsed:uint = 0;
			while (joints_parsed < num_joints) {
				var joint:SkeletonJoint;
				var ibp:Matrix3D;
				// Ignore joint id
				_newBlockBytes.readUnsignedShort();
				joint = new SkeletonJoint();
				joint.parentIndex = _newBlockBytes.readUnsignedShort() - 1; // 0=null in AWD
				joint.name = parseVarStr();
				
				ibp = parseMatrix3D();
				joint.inverseBindPose = ibp.rawData;
				// Ignore joint props/attributes for now
				parseProperties(null);
				parseUserAttributes();
				skeleton.joints.push(joint);
				joints_parsed++;
			}
			
			// Discard attributes for now
			parseUserAttributes();
			finalizeAsset(skeleton, name);
			_blocks[blockID].data = skeleton;
			if (_debug)
				trace("Parsed a Skeleton: Name = " + skeleton.name + " | Number of Joints = " + joints_parsed);
		}
		
		//Block ID = 102
		private function parseSkeletonPose(blockID:uint):void
		{
			var name:String = parseVarStr();
			var num_joints:uint = _newBlockBytes.readUnsignedShort();
			parseProperties(null); // Ignore properties for now
			
			var pose:SkeletonPose = new SkeletonPose();
			
			var joints_parsed:uint = 0;
			while (joints_parsed < num_joints) {
				var joint_pose:JointPose;
				var has_transform:uint;
				joint_pose = new JointPose();
				has_transform = _newBlockBytes.readUnsignedByte();
				if (has_transform == 1) {
					var mtx_data:Vector.<Number> = parseMatrix43RawData();
					
					var mtx:Matrix3D = new Matrix3D(mtx_data);
					joint_pose.orientation.fromMatrix(mtx);
					joint_pose.translation.copyFrom(mtx.position);
					
					pose.jointPoses[joints_parsed] = joint_pose;
				}
				joints_parsed++;
			}
			// Skip attributes for now
			parseUserAttributes();
			finalizeAsset(pose, name);
			_blocks[blockID].data = pose;
			if (_debug)
				trace("Parsed a SkeletonPose: Name = " + pose.name + " | Number of Joints = " + joints_parsed);
		}
		
		//blockID 103
		private function parseSkeletonAnimation(blockID:uint):void
		{
			var frame_dur:Number;
			var pose_addr:uint;
			var name:String = parseVarStr();
			var clip:SkeletonClipNode = new SkeletonClipNode();
			var num_frames:uint = _newBlockBytes.readUnsignedShort();
			parseProperties(null); // Ignore properties for now 
			
			var frames_parsed:uint = 0;
			var returnedArray:Array;
			while (frames_parsed < num_frames) {
				pose_addr = _newBlockBytes.readUnsignedInt();
				frame_dur = _newBlockBytes.readUnsignedShort();
				returnedArray = getAssetByID(pose_addr, [AssetType.SKELETON_POSE]);
				if (!returnedArray[0])
					_blocks[blockID].addError("Could not find the SkeletonPose Frame # " + frames_parsed + " (ID = " + pose_addr + " ) for this SkeletonClipNode");
				else
					clip.addFrame(_blocks[pose_addr].data as SkeletonPose, frame_dur);
				frames_parsed++;
			}
			if (clip.frames.length == 0) {
				_blocks[blockID].addError("Could not this SkeletonClipNode, because no Frames where set.");
				return;
			}
			// Ignore attributes for now
			parseUserAttributes();
			finalizeAsset(clip, name);
			_blocks[blockID].data = clip;
			if (_debug)
				trace("Parsed a SkeletonClipNode: Name = " + clip.name + " | Number of Frames = " + clip.frames.length);
		}
		
		//Block ID = 111 /  Block ID = 112
		private function parseMeshPoseAnimation(blockID:uint, poseOnly:Boolean = false):void
		{
			var num_frames:uint = 1;
			var num_submeshes:uint;
			var frames_parsed:uint;
			var subMeshParsed:uint;
			var frame_dur:Number;
			var x:Number;
			var y:Number;
			var z:Number;
			var str_len:Number;
			var str_end:Number;
			var geometry:Geometry;
			var subGeom:CompactSubGeometry;
			var idx:int = 0;
			var clip:VertexClipNode = new VertexClipNode();
			var indices:Vector.<uint>;
			var verts:Vector.<Number>;
			var num_Streams:int = 0;
			var streamsParsed:int = 0;
			var streamtypes:Vector.<int> = new Vector.<int>;
			var props:AWDProperties;
			var thisGeo:Geometry;
			var name:String = parseVarStr();
			var geoAdress:int = _newBlockBytes.readUnsignedInt();
			var returnedArray:Array = getAssetByID(geoAdress, [AssetType.GEOMETRY]);
			if (!returnedArray[0]) {
				_blocks[blockID].addError("Could not find the target-Geometry-Object " + geoAdress + " ) for this VertexClipNode");
				return;
			}
			var uvs:Vector.<Vector.<Number>> = getUVForVertexAnimation(geoAdress);
			if (!poseOnly)
				num_frames = _newBlockBytes.readUnsignedShort();
			
			num_submeshes = _newBlockBytes.readUnsignedShort();
			num_Streams = _newBlockBytes.readUnsignedShort();
			streamsParsed = 0;
			while (streamsParsed < num_Streams) {
				streamtypes.push(_newBlockBytes.readUnsignedShort());
				streamsParsed++;
			}
			props = parseProperties({1:BOOL, 2:BOOL});
			
			clip.looping = props.get(1, true);
			clip.stitchFinalFrame = props.get(2, false);
			
			frames_parsed = 0;
			while (frames_parsed < num_frames) {
				frame_dur = _newBlockBytes.readUnsignedShort();
				geometry = new Geometry();
				subMeshParsed = 0;
				while (subMeshParsed < num_submeshes) {
					streamsParsed = 0;
					str_len = _newBlockBytes.readUnsignedInt();
					str_end = _newBlockBytes.position + str_len;
					while (streamsParsed < num_Streams) {
						if (streamtypes[streamsParsed] == 1) {
							indices = returnedArray[1].subGeometries[subMeshParsed].indexData;
							verts = new Vector.<Number>();
							idx = 0;
							while (_newBlockBytes.position < str_end) {
								x = readNumber(_accuracyGeo)
								y = readNumber(_accuracyGeo)
								z = readNumber(_accuracyGeo)
								verts[idx++] = x;
								verts[idx++] = y;
								verts[idx++] = z;
							}
							subGeom = new CompactSubGeometry();
							subGeom.fromVectors(verts, uvs[subMeshParsed], null, null);
							subGeom.updateIndexData(indices);
							subGeom.vertexNormalData;
							subGeom.vertexTangentData;
							subGeom.autoDeriveVertexNormals = false;
							subGeom.autoDeriveVertexTangents = false;
							subMeshParsed++;
							geometry.addSubGeometry(subGeom)
						} else
							_newBlockBytes.position = str_end;
						streamsParsed++;
					}
				}
				clip.addFrame(geometry, frame_dur);
				frames_parsed++;
			}
			parseUserAttributes();
			finalizeAsset(clip, name);
			
			_blocks[blockID].data = clip;
			if (_debug)
				trace("Parsed a VertexClipNode: Name = " + clip.name + " | Target-Geometry-Name = " + Geometry(returnedArray[1]).name + " | Number of Frames = " + clip.frames.length);
		}
		
		//BlockID 113
		private function parseVertexAnimationSet(blockID:uint):void
		{
			var poseBlockAdress:int
			var outputString:String = "";
			var name:String = parseVarStr();
			var num_frames:uint = _newBlockBytes.readUnsignedShort();
			var props:AWDProperties = parseProperties({1:UINT16});
			var frames_parsed:uint = 0;
			var skeletonFrames:Vector.<SkeletonClipNode> = new Vector.<SkeletonClipNode>;
			var vertexFrames:Vector.<VertexClipNode> = new Vector.<VertexClipNode>;
			while (frames_parsed < num_frames) {
				poseBlockAdress = _newBlockBytes.readUnsignedInt();
				var returnedArray:Array = getAssetByID(poseBlockAdress, [AssetType.ANIMATION_NODE]);
				if (!returnedArray[0])
					_blocks[blockID].addError("Could not find the AnimationClipNode Nr " + frames_parsed + " ( " + poseBlockAdress + " ) for this AnimationSet");
				else {
					if (returnedArray[1] is VertexClipNode)
						vertexFrames.push(returnedArray[1])
					if (returnedArray[1] is SkeletonClipNode)
						skeletonFrames.push(returnedArray[1])
				}
				frames_parsed++;
			}
			if ((vertexFrames.length == 0) && (skeletonFrames.length == 0)) {
				_blocks[blockID].addError("Could not create this AnimationSet, because it contains no animations");
				return;
			}
			parseUserAttributes();
			if (vertexFrames.length > 0) {
				var newVertexAnimationSet:VertexAnimationSet = new VertexAnimationSet();
				for each (var vertexFrame:VertexClipNode in vertexFrames)
					newVertexAnimationSet.addAnimation(vertexFrame);
				finalizeAsset(newVertexAnimationSet, name);
				_blocks[blockID].data = newVertexAnimationSet;
				if (_debug)
					trace("Parsed a VertexAnimationSet: Name = " + name + " | Animations = " + newVertexAnimationSet.animations.length + " | Animation-Names = " + newVertexAnimationSet.animationNames.toString());
				
			} else if (skeletonFrames.length > 0) {
				returnedArray = getAssetByID(poseBlockAdress, [AssetType.ANIMATION_NODE]);
				var newSkeletonAnimationSet:SkeletonAnimationSet = new SkeletonAnimationSet(props.get(1, 4)); //props.get(1,4));
				for each (var skeletFrame:SkeletonClipNode in skeletonFrames)
					newSkeletonAnimationSet.addAnimation(skeletFrame);
				finalizeAsset(newSkeletonAnimationSet, name);
				_blocks[blockID].data = newSkeletonAnimationSet;
				if (_debug)
					trace("Parsed a SkeletonAnimationSet: Name = " + name + " | Animations = " + newSkeletonAnimationSet.animations.length + " | Animation-Names = " + newSkeletonAnimationSet.animationNames.toString());
				
			}
		}
		
		//blockID 121
		private function parseUVAnimation(blockID:uint):void
		{
			var name:String = parseVarStr();
			var num_frames:uint = _newBlockBytes.readUnsignedShort();
			var props:AWDProperties = parseProperties(null);
			var clip:UVClipNode = new UVClipNode();
			var dummy:Sprite = new Sprite();
			var frames_parsed:uint = 0;
			while (frames_parsed < num_frames) {
				// TODO: Replace this with some reliable way to decompose a 2d matrix
				var mtx:Matrix = parseMatrix2D();
				mtx.scale(100, 100);
				dummy.transform.matrix = mtx;
				var frame_dur:uint = _newBlockBytes.readUnsignedShort();
				var frame:UVAnimationFrame = new UVAnimationFrame(dummy.x*0.01, dummy.y*0.01, dummy.scaleX/100, dummy.scaleY/100, dummy.rotation);
				clip.addFrame(frame, frame_dur);
				frames_parsed++;
			}
			// Ignore for now
			parseUserAttributes();
			finalizeAsset(clip, name);
			_blocks[blockID].data = clip;
			if (_debug)
				trace("Parsed a UVClipNode: Name = " + name + " | Number of Frames = " + frames_parsed);
		}
		
		//BlockID 122
		private function parseAnimatorSet(blockID:uint):void
		{
			var targetMesh:Mesh;
			var animSetBlockAdress:int
			var targetAnimationSet:AnimationSetBase;
			var outputString:String = "";
			var name:String = parseVarStr();
			var type:uint = _newBlockBytes.readUnsignedShort();
			
			var props:AWDProperties = parseProperties({1:BADDR});
			
			animSetBlockAdress = _newBlockBytes.readUnsignedInt();
			var targetMeshLength:uint = _newBlockBytes.readUnsignedShort();
			var meshAdresses:Vector.<uint> = new Vector.<uint>;
			for (var i:int = 0; i < targetMeshLength; i++)
				meshAdresses.push(_newBlockBytes.readUnsignedInt());
			
			var activeState:uint = _newBlockBytes.readUnsignedShort();
			var autoplay:Boolean = Boolean(_newBlockBytes.readUnsignedByte());
			parseUserAttributes();
			parseUserAttributes();
			
			var returnedArray:Array;
			var targetMeshes:Vector.<Mesh> = new Vector.<Mesh>;
			
			for (i = 0; i < meshAdresses.length; i++) {
				returnedArray = getAssetByID(meshAdresses[i], [AssetType.MESH]);
				if (returnedArray[0])
					targetMeshes.push(returnedArray[1] as Mesh);
			}
			returnedArray = getAssetByID(animSetBlockAdress, [AssetType.ANIMATION_SET]);
			if (!returnedArray[0]) {
				_blocks[blockID].addError("Could not find the AnimationSet ( " + animSetBlockAdress + " ) for this Animator");;
				return
			}
			targetAnimationSet = returnedArray[1] as AnimationSetBase;
			var thisAnimator:AnimatorBase;
			if (type == 1) {
				
				returnedArray = getAssetByID(props.get(1, 0), [AssetType.SKELETON]);
				if (!returnedArray[0]) {
					_blocks[blockID].addError("Could not find the Skeleton ( " + props.get(1, 0) + " ) for this Animator");
					return
				}
				thisAnimator = new SkeletonAnimator(targetAnimationSet as SkeletonAnimationSet, returnedArray[1] as Skeleton);
				
			} else if (type == 2)
				thisAnimator = new VertexAnimator(targetAnimationSet as VertexAnimationSet);
			
			finalizeAsset(thisAnimator, name);
			_blocks[blockID].data = thisAnimator;
			for (i = 0; i < targetMeshes.length; i++) {
				if (type == 1)
					targetMeshes[i].animator = SkeletonAnimator(thisAnimator);
				if (type == 2)
					targetMeshes[i].animator = VertexAnimator(thisAnimator);
				
			}
			if (_debug)
				trace("Parsed a Animator: Name = " + name);
		}
		
		//Block ID = 253
		private function parseCommand(blockID:uint):void
		{
			var hasBlocks:Boolean = Boolean(_newBlockBytes.readUnsignedByte());
			var par_id:uint = _newBlockBytes.readUnsignedInt();
			var mtx:Matrix3D = parseMatrix3D();
			var name:String = parseVarStr();
			
			var parentObject:ObjectContainer3D;
			var targetObject:ObjectContainer3D;
			var returnedArray:Array = getAssetByID(par_id, [AssetType.CONTAINER, AssetType.LIGHT, AssetType.MESH, AssetType.ENTITY, AssetType.SEGMENT_SET]);
			if (returnedArray[0])
				parentObject = ObjectContainer3D(returnedArray[1]);
			
			var numCommands:uint = _newBlockBytes.readShort();
			var typeCommand:uint = _newBlockBytes.readShort();
			var props:AWDProperties = parseProperties({1:BADDR});
			switch (typeCommand) {
				case 1:
					var targetID:uint = props.get(1, 0);
					var returnedArrayTarget:Array = getAssetByID(targetID, [AssetType.LIGHT, AssetType.TEXTURE_PROJECTOR]); //for no only light is requested!!!!
					if ((!returnedArrayTarget[0]) && (targetID != 0)) {
						_blocks[blockID].addError("Could not find the light (ID = " + targetID + " ( for this CommandBock!");
						return;
					}
					targetObject = returnedArrayTarget[1];
					if (parentObject)
						parentObject.addChild(targetObject);
					targetObject.transform = mtx;
					break;
			}
			if (targetObject) {
				props = parseProperties({1:_matrixNrType, 2:_matrixNrType, 3:_matrixNrType, 4:UINT8});
				targetObject.pivotPoint = new Vector3D(props.get(1, 0), props.get(2, 0), props.get(3, 0));
				targetObject.extra = parseUserAttributes();
			}
			_blocks[blockID].data = targetObject
			if (_debug)
				trace("Parsed a CommandBlock: Name = '" + name);
		
		}
		
		//blockID 254
		private function parseNameSpace(blockID:uint):void
		{
			var id:uint = _newBlockBytes.readUnsignedByte();
			var nameSpaceString:String = parseVarStr();
			if (_debug)
				trace("Parsed a NameSpaceBlock: ID = " + id + " | String = " + nameSpaceString);
		}
		
		//blockID 255
		private function parseMetaData(blockID:uint):void
		{
			var props:AWDProperties = parseProperties({1:UINT32, 2:AWDSTRING, 3:AWDSTRING, 4:AWDSTRING, 5:AWDSTRING});
			if (_debug) {
				trace("Parsed a MetaDataBlock: TimeStamp         = " + props.get(1, 0));
				trace("                        EncoderName       = " + props.get(2, "unknown"));
				trace("                        EncoderVersion    = " + props.get(3, "unknown"));
				trace("                        GeneratorName     = " + props.get(4, "unknown"));
				trace("                        GeneratorVersion  = " + props.get(5, "unknown"));
			}
		
		}
		
		// Helper - functions
		private function getUVForVertexAnimation(meshID:uint):Vector.<Vector.<Number>>
		{
			if (_blocks[meshID].data is Mesh)
				meshID = _blocks[meshID].geoID;
			if (_blocks[meshID].uvsForVertexAnimation)
				return _blocks[meshID].uvsForVertexAnimation;
			var geometry:Geometry = Geometry(_blocks[[meshID]].data);
			var geoCnt:int = 0;
			var ud:Vector.<Number>;
			var uStride:uint;
			var uOffs:uint;
			var numPoints:uint;
			var i:int;
			var newUvs:Vector.<Number>;
			_blocks[meshID].uvsForVertexAnimation = new Vector.<Vector.<Number>>;
			while (geoCnt < geometry.subGeometries.length) {
				newUvs = new Vector.<Number>;
				numPoints = geometry.subGeometries[geoCnt].numVertices;
				ud = geometry.subGeometries[geoCnt].UVData;
				uStride = geometry.subGeometries[geoCnt].UVStride;
				uOffs = geometry.subGeometries[geoCnt].UVOffset;
				for (i = 0; i < numPoints; i++) {
					newUvs.push(ud[uOffs + i*uStride + 0]);
					newUvs.push(ud[uOffs + i*uStride + 1]);
				}
				_blocks[meshID].uvsForVertexAnimation.push(newUvs);
				geoCnt++;
			}
			return _blocks[meshID].uvsForVertexAnimation;
		}
		
		private function parseVarStr():String
		{
			var len:uint = _newBlockBytes.readUnsignedShort();
			return _newBlockBytes.readUTFBytes(len);
		}
		
		private function parseProperties(expected:Object):AWDProperties
		{
			var list_end:uint;
			var list_len:uint;
			var propertyCnt:uint = 0;
			var props:AWDProperties = new AWDProperties();
			
			list_len = _newBlockBytes.readUnsignedInt();
			list_end = _newBlockBytes.position + list_len;
			if (expected) {
				while (_newBlockBytes.position < list_end) {
					var len:uint;
					var key:uint;
					var type:uint;
					key = _newBlockBytes.readUnsignedShort();
					len = _newBlockBytes.readUnsignedInt();
					if ((_newBlockBytes.position + len) > list_end) {
						trace("           Error in reading property # " + propertyCnt + " = skipped to end of propertie-list");
						_newBlockBytes.position = list_end;
						return props;
					}
					if (expected.hasOwnProperty(key.toString())) {
						type = expected[key];
						props.set(key, parseAttrValue(type, len));
					} else
						_newBlockBytes.position += len;
					propertyCnt += 1;
					
				}
			} else
				_newBlockBytes.position = list_end;
			
			return props;
		}
		
		private function parseUserAttributes():Object
		{
			var attributes:Object;
			var list_len:uint;
			var attibuteCnt:uint;
			
			list_len = _newBlockBytes.readUnsignedInt();
			if (list_len > 0) {
				var list_end:uint;
				
				attributes = {};
				
				list_end = _newBlockBytes.position + list_len;
				while (_newBlockBytes.position < list_end) {
					var ns_id:uint;
					var attr_key:String;
					var attr_type:uint;
					var attr_len:uint;
					var attr_val:*;
					
					// TODO: Properly tend to namespaces in attributes
					ns_id = _newBlockBytes.readUnsignedByte();
					attr_key = parseVarStr();
					attr_type = _newBlockBytes.readUnsignedByte();
					attr_len = _newBlockBytes.readUnsignedInt();
					
					if ((_newBlockBytes.position + attr_len) > list_end) {
						trace("           Error in reading attribute # " + attibuteCnt + " = skipped to end of attribute-list");
						_newBlockBytes.position = list_end;
						return attributes;
					}
					switch (attr_type) {
						case AWDSTRING:
							attr_val = _newBlockBytes.readUTFBytes(attr_len);
							break;
						case INT8:
							attr_val = _newBlockBytes.readByte();
							break;
						case INT16:
							attr_val = _newBlockBytes.readShort();
							break;
						case INT32:
							attr_val = _newBlockBytes.readInt();
							break;
						case BOOL:
						case UINT8:
							attr_val = _newBlockBytes.readUnsignedByte();
							break;
						case UINT16:
							attr_val = _newBlockBytes.readUnsignedShort();
							break;
						case UINT32:
						case BADDR:
							attr_val = _newBlockBytes.readUnsignedInt();
							break;
						case FLOAT32:
							attr_val = _newBlockBytes.readFloat();
							break;
						case FLOAT64:
							attr_val = _newBlockBytes.readDouble();
							break;
						default:
							attr_val = 'unimplemented attribute type ' + attr_type;
							_newBlockBytes.position += attr_len;
							break;
					}
					
					if (_debug)
						trace("attribute = name: " + attr_key + "  / value = " + attr_val);
					attributes[attr_key] = attr_val;
					attibuteCnt += 1;
				}
			}
			
			return attributes;
		}
		
		private function getDefaultMaterial():IAsset
		{
			if (!_defaultBitmapMaterial)
				_defaultBitmapMaterial = DefaultMaterialManager.getDefaultMaterial();
			return _defaultBitmapMaterial;
		}
		
		private function getDefaultTexture():IAsset
		{
			if (!_defaultTexture)
				_defaultTexture = DefaultMaterialManager.getDefaultTexture();
			return _defaultTexture;
		}
		
		private function getDefaultCubeTexture():IAsset
		{
			if (!_defaultCubeTexture) {
				if (!_defaultTexture)
					_defaultTexture = DefaultMaterialManager.getDefaultTexture();
				var defaultBitmap:BitmapData = _defaultTexture.bitmapData;
				_defaultCubeTexture = new BitmapCubeTexture(defaultBitmap, defaultBitmap, defaultBitmap, defaultBitmap, defaultBitmap, defaultBitmap);
				_defaultCubeTexture.name = "defaultTexture";
			}
			return _defaultCubeTexture;
		}
		
		private function getDefaultAsset(assetType:String, extraTypeInfo:String):IAsset
		{
			switch (true) {
				case (assetType == AssetType.TEXTURE):
					if (extraTypeInfo == "CubeTexture")
						return getDefaultCubeTexture();
					if (extraTypeInfo == "SingleTexture")
						return getDefaultTexture();
					break;
				case (assetType == AssetType.MATERIAL):
					return getDefaultMaterial()
					break;
				default:
					break;
			}
			return null;
		
		}
		
		private function getAssetByID(assetID:uint, assetTypesToGet:Array, extraTypeInfo:String = "SingleTexture"):Array
		{
			var returnArray:Array = new Array();
			var typeCnt:int = 0;
			if (assetID > 0) {
				if (_blocks[assetID]) {
					if (_blocks[assetID].data) {
						while (typeCnt < assetTypesToGet.length) {
							if (IAsset(_blocks[assetID].data).assetType == assetTypesToGet[typeCnt]) {
								//if the right assetType was found 
								if ((assetTypesToGet[typeCnt] == AssetType.TEXTURE) && (extraTypeInfo == "CubeTexture")) {
									if (_blocks[assetID].data is BitmapCubeTexture) {
										returnArray.push(true);
										returnArray.push(_blocks[assetID].data);
										return returnArray;
									}
								}
								if ((assetTypesToGet[typeCnt] == AssetType.TEXTURE) && (extraTypeInfo == "SingleTexture")) {
									if (_blocks[assetID].data is BitmapTexture) {
										returnArray.push(true);
										returnArray.push(_blocks[assetID].data);
										return returnArray;
									}
								} else {
									returnArray.push(true);
									returnArray.push(_blocks[assetID].data);
									return returnArray;
									
								}
							}
							if ((assetTypesToGet[typeCnt] == AssetType.GEOMETRY) && (IAsset(_blocks[assetID].data).assetType == AssetType.MESH)) {
								returnArray.push(true);
								returnArray.push(Mesh(_blocks[assetID].data).geometry);
								return returnArray;
							}
							typeCnt++;
						}
					}
				}
			}
			// if the function has not returned anything yet, the asset is not found, or the found asset is not the right type.
			returnArray.push(false);
			returnArray.push(getDefaultAsset(assetTypesToGet[0], extraTypeInfo));
			return returnArray;
		}
		
		private function parseAttrValue(type:uint, len:uint):*
		{
			var elem_len:uint;
			var read_func:Function;
			
			switch (type) {
				case BOOL:
				case INT8:
					elem_len = 1;
					read_func = _newBlockBytes.readByte;
					break;
				case INT16:
					elem_len = 2;
					read_func = _newBlockBytes.readShort;
					break;
				case INT32:
					elem_len = 4;
					read_func = _newBlockBytes.readInt;
					break;
				case UINT8:
					elem_len = 1;
					read_func = _newBlockBytes.readUnsignedByte;
					break;
				case UINT16:
					elem_len = 2;
					read_func = _newBlockBytes.readUnsignedShort;
					break;
				case UINT32:
				case COLOR:
				case BADDR:
					elem_len = 4;
					read_func = _newBlockBytes.readUnsignedInt;
					break;
				case FLOAT32:
					elem_len = 4;
					read_func = _newBlockBytes.readFloat;
					break;
				case FLOAT64:
					elem_len = 8;
					read_func = _newBlockBytes.readDouble;
					break;
				
				case AWDSTRING:
					return _newBlockBytes.readUTFBytes(len);
				case VECTOR2x1:
				case VECTOR3x1:
				case VECTOR4x1:
				case MTX3x2:
				case MTX3x3:
				case MTX4x3:
				case MTX4x4:
					elem_len = 8;
					read_func = _newBlockBytes.readDouble;
					break;
			}
			
			if (elem_len < len) {
				var list:Array;
				var num_read:uint;
				var num_elems:uint;
				
				list = [];
				num_read = 0;
				num_elems = len/elem_len;
				while (num_read < num_elems) {
					list.push(read_func());
					num_read++;
				}
				
				return list;
			} else {
				var val:*;
				
				val = read_func();
				return val;
			}
		}
		
		private function parseMatrix2D():Matrix
		{
			var mtx:Matrix;
			var mtx_raw:Vector.<Number> = parseMatrix32RawData();
			
			mtx = new Matrix(mtx_raw[0], mtx_raw[1], mtx_raw[2], mtx_raw[3], mtx_raw[4], mtx_raw[5]);
			return mtx;
		}
		
		private function parseMatrix3D():Matrix3D
		{
			return new Matrix3D(parseMatrix43RawData());
		}
		
		private function parseMatrix32RawData():Vector.<Number>
		{
			var i:uint;
			var mtx_raw:Vector.<Number> = new Vector.<Number>(6, true);
			for (i = 0; i < 6; i++)
				mtx_raw[i] = _newBlockBytes.readFloat();
			
			return mtx_raw;
		}
		
		private function readNumber(precision:Boolean = false):Number
		{
			if (precision)
				return _newBlockBytes.readDouble();
			return _newBlockBytes.readFloat();
		}
		
		private function parseMatrix43RawData():Vector.<Number>
		{
			var mtx_raw:Vector.<Number> = new Vector.<Number>(16, true);
			
			mtx_raw[0] = readNumber(_accuracyMatrix);
			mtx_raw[1] = readNumber(_accuracyMatrix);
			mtx_raw[2] = readNumber(_accuracyMatrix);
			mtx_raw[3] = 0.0;
			mtx_raw[4] = readNumber(_accuracyMatrix);
			mtx_raw[5] = readNumber(_accuracyMatrix);
			mtx_raw[6] = readNumber(_accuracyMatrix);
			mtx_raw[7] = 0.0;
			mtx_raw[8] = readNumber(_accuracyMatrix);
			mtx_raw[9] = readNumber(_accuracyMatrix);
			mtx_raw[10] = readNumber(_accuracyMatrix);
			mtx_raw[11] = 0.0;
			mtx_raw[12] = readNumber(_accuracyMatrix);
			mtx_raw[13] = readNumber(_accuracyMatrix);
			mtx_raw[14] = readNumber(_accuracyMatrix);
			mtx_raw[15] = 1.0;
			
			//TODO: fix max exporter to remove NaN values in joint 0 inverse bind pose
			if (isNaN(mtx_raw[0])) {
				mtx_raw[0] = 1;
				mtx_raw[1] = 0;
				mtx_raw[2] = 0;
				mtx_raw[4] = 0;
				mtx_raw[5] = 1;
				mtx_raw[6] = 0;
				mtx_raw[8] = 0;
				mtx_raw[9] = 0;
				mtx_raw[10] = 1;
				mtx_raw[12] = 0;
				mtx_raw[13] = 0;
				mtx_raw[14] = 0;
				
			}
			
			return mtx_raw;
		}
	}
}

import flash.utils.ByteArray;

internal class AWDBlock
{
	public var id:uint;
	public var name:String;
	public var data:*;
	public var len:*;
	public var geoID:uint;
	public var extras:Object;
	public var bytes:ByteArray;
	public var errorMessages:Vector.<String>;
	public var uvsForVertexAnimation:Vector.<Vector.<Number>>;
	
	public function AWDBlock()
	{
	}
	
	public function addError(errorMsg:String):void
	{
		if (!errorMessages)
			errorMessages = new Vector.<String>();
		errorMessages.push(errorMsg);
	}
}

internal class bitFlags
{
	public static const FLAG1:uint = 1;
	public static const FLAG2:uint = 2;
	public static const FLAG3:uint = 4;
	public static const FLAG4:uint = 8;
	public static const FLAG5:uint = 16;
	public static const FLAG6:uint = 32;
	public static const FLAG7:uint = 64;
	public static const FLAG8:uint = 128;
	public static const FLAG9:uint = 256;
	public static const FLAG10:uint = 512;
	public static const FLAG11:uint = 1024;
	public static const FLAG12:uint = 2048;
	public static const FLAG13:uint = 4096;
	public static const FLAG14:uint = 8192;
	public static const FLAG15:uint = 16384;
	public static const FLAG16:uint = 32768;
	
	public static function test(flags:uint, testFlag:uint):Boolean
	{
		return (flags & testFlag) == testFlag;
	}
}

internal dynamic class AWDProperties
{
	public function set(key:uint, value:*):void
	{
		this[key.toString()] = value;
	}
	
	public function get(key:uint, fallback:*):*
	{
		if (this.hasOwnProperty(key.toString()))
			return this[key.toString()];
		else
			return fallback;
	}
}


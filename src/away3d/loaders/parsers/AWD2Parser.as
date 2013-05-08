package away3d.loaders.parsers {
	import away3d.*;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	import away3d.containers.*;
	import away3d.core.base.*;
	import away3d.entities.*;
	import away3d.library.assets.*;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.PointLight;
	import away3d.lights.shadowmaps.CascadeShadowMapper;
	import away3d.lights.shadowmaps.CubeMapShadowMapper;
	import away3d.lights.shadowmaps.DirectionalShadowMapper;
	import away3d.lights.shadowmaps.NearDirectionalShadowMapper;
	import away3d.lights.shadowmaps.ShadowMapperBase;
	import away3d.loaders.misc.*;
	import away3d.loaders.parsers.utils.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.LightPickerBase;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.AlphaMaskMethod;
	import away3d.materials.methods.AnisotropicSpecularMethod;
	import away3d.materials.methods.CascadeShadowMapMethod;
	import away3d.materials.methods.CelDiffuseMethod;
	import away3d.materials.methods.CelSpecularMethod;
	import away3d.materials.methods.ColorMatrixMethod;
	import away3d.materials.methods.ColorTransformMethod;
	import away3d.materials.methods.DepthDiffuseMethod;
	import away3d.materials.methods.DitheredShadowMapMethod;
	import away3d.materials.methods.EffectMethodBase;
	import away3d.materials.methods.EnvMapAmbientMethod;
	import away3d.materials.methods.EnvMapMethod;
	import away3d.materials.methods.FilteredShadowMapMethod;
	import away3d.materials.methods.FogMethod;
	import away3d.materials.methods.FresnelEnvMapMethod;
	import away3d.materials.methods.FresnelSpecularMethod;
	import away3d.materials.methods.GradientDiffuseMethod;
	import away3d.materials.methods.HardShadowMapMethod;
	import away3d.materials.methods.LightMapDiffuseMethod;
	import away3d.materials.methods.LightMapMethod;
	import away3d.materials.methods.NearShadowMapMethod;
	import away3d.materials.methods.OutlineMethod;
	import away3d.materials.methods.PhongSpecularMethod;
	import away3d.materials.methods.ProjectiveTextureMethod;
	import away3d.materials.methods.RefractionEnvMapMethod;
	import away3d.materials.methods.RimLightMethod;
	import away3d.materials.methods.ShadowMapMethodBase;
	import away3d.materials.methods.SimpleWaterNormalMethod;
	import away3d.materials.methods.SoftShadowMapMethod;
	import away3d.materials.methods.SubsurfaceScatteringDiffuseMethod;
	import away3d.materials.methods.WrapDiffuseMethod;
	import away3d.materials.utils.*;
	import away3d.primitives.SkyBox;
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
		private var _debug:Boolean=false;
		private var _byteData : ByteArray;
		private var _startedParsing : Boolean;
		private var _cur_block_id : uint;
		private var _blocks : Vector.<AWDBlock>;
		
		private var _version : Array;
		private var _compression : uint;
		private var _streaming : Boolean;
		
		private var _texture_users : Object = {};
		
		private var _parsed_header : Boolean;
		private var _body : ByteArray;
		
		private var _defaultTexture :BitmapTexture;
		private var _cubeTextures :Array;
		
		public static const UNCOMPRESSED : uint = 0;
		public static const DEFLATE : uint = 1;
		public static const LZMA : uint = 2;
		
		
		
		public static const INT8 : uint = 1;
		public static const INT16 : uint = 2;
		public static const INT32 : uint = 3;
		public static const UINT8 : uint = 4;
		public static const UINT16 : uint = 5;
		public static const UINT32 : uint = 6;
		public static const FLOAT32 : uint = 7;
		public static const FLOAT64 : uint = 8;
		
		public static const BOOL : uint = 21;
		public static const COLOR : uint = 22;
		public static const BADDR : uint = 23;
		
		public static const AWDSTRING : uint = 31;
		public static const AWDBYTEARRAY : uint = 32;
		
		public static const VECTOR2x1 : uint = 41;
		public static const VECTOR3x1 : uint = 42;
		public static const VECTOR4x1 : uint = 43;
		public static const MTX3x2 : uint = 44;
		public static const MTX3x3 : uint = 45;
		public static const MTX4x3 : uint = 46;
		public static const MTX4x4 : uint = 47;
		
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
			
			_blocks = new Vector.<AWDBlock>();
			_blocks[0] = new AWDBlock();
			_blocks[0].data = null; // Zero address means null in AWD
			_defaultTexture=DefaultMaterialManager.getDefaultTexture();
				
			blendModeDic=new Vector.<String>();
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
			
			_depthSizeDic=new Vector.<uint>();
			_depthSizeDic.push(256);
			_depthSizeDic.push(512);
			_depthSizeDic.push(2048);
			
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
				var isCubeTextureArray:Array=resourceDependency.id.split("#");
				var ressourceID:String=isCubeTextureArray[0];
				var asset :TextureProxyBase;
				var thisBitmapTexture:Texture2DBase;
				var block : AWDBlock;
				if (isCubeTextureArray.length==1){
					asset = resourceDependency.assets[0] as Texture2DBase;
					if (asset) {
						//var mat : TextureMaterial;
						///var users : Array;
						block = _blocks[parseInt(resourceDependency.id)];
						
						// Store finished asset
						block.data = asset;
						
						// Reset name of texture to the one defined in the AWD file,
						// as opposed to whatever the image parser came up with.
						asset.resetAssetPath(block.name, null, true);
						
						// Finalize texture asset to dispatch texture event, which was
						// previously suppressed while the dependency was loaded.
						finalizeAsset(asset);
						
					}
				}
				if (isCubeTextureArray.length>1){
					thisBitmapTexture = resourceDependency.assets[0] as BitmapTexture;
					_cubeTextures[uint(isCubeTextureArray[1])] = BitmapTexture(thisBitmapTexture).bitmapData; 
					_texture_users[ressourceID].push(1);
					if(_texture_users[ressourceID].length==_cubeTextures.length){
						//
						asset = new BitmapCubeTexture(_cubeTextures[0],_cubeTextures[1],_cubeTextures[2],_cubeTextures[3],_cubeTextures[4],_cubeTextures[5]);
						block = _blocks[ressourceID];
						// Store finished asset
						block.data = asset;
						
						// Reset name of texture to the one defined in the AWD file,
						// as opposed to whatever the image parser came up with.
						asset.resetAssetPath(block.name, null, true);
						
						// Finalize texture asset to dispatch texture event, which was
						// previously suppressed while the dependency was loaded.
						finalizeAsset(asset);
					}
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{
			if (_texture_users.hasOwnProperty(resourceDependency.id)) {
				var mat : TextureMaterial;
				var users : Array;
				
				var texture : BitmapTexture = DefaultMaterialManager.getDefaultTexture();
				
				users = _texture_users[resourceDependency.id];
				for each (mat in users) {
					mat.texture = texture;
					finalizeAsset(mat);
				}
			}
		}
		
		/**
		 * Resolve a dependency name
		 *
		 * @param resourceDependency The dependency to be resolved.
		 */
		arcane override function resolveDependencyName(resourceDependency : ResourceDependency, asset:IAsset) : String
		{
			var oldName:String = asset.name;
			if (asset) {
				var block : AWDBlock = _blocks[parseInt(resourceDependency.id)];
				
				// Reset name of texture to the one defined in the AWD file,
				// as opposed to whatever the image parser came up with.
				asset.resetAssetPath(block.name, null, true);
			}
			var newName:String = asset.name;
			asset.name = oldName;
			
			return newName;
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data : *) : Boolean
		{
			return (ParserUtil.toString(data, 3)=='AWD');
		}
		
		
		/**
		 * @inheritDoc
		 */
		protected override function proceedParsing() : Boolean
		{
			if(!_startedParsing) {
				_byteData = getByteData();
				_startedParsing = true;
			}
			
			if (!_parsed_header) {
				_byteData.endian = Endian.LITTLE_ENDIAN;
				
				//TODO: Create general-purpose parseBlockRef(requiredType) (return _blocks[addr] or throw error)
				
				// Parse header and decompress body
				parseHeader();
				switch (_compression) {
					case DEFLATE:
						_body = new ByteArray();
						_byteData.readBytes(_body, 0, _byteData.bytesAvailable);
						_body.uncompress();
						break;
					case LZMA:
						// TODO: Decompress LZMA into _body
						dieWithError('LZMA decoding not yet supported in AWD parser.');
						break;
					case UNCOMPRESSED:
						_body = _byteData;
						break;
				}
				
				_body.endian = Endian.LITTLE_ENDIAN;
				_parsed_header = true;
			}
			
			while (_body.bytesAvailable > 0 && !parsingPaused && hasTime()) {
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
			
			if(_debug)trace("version = "+_version[0]+" - "+_version[1]);
			
			// Parse bit flags and compression
			flags = _byteData.readUnsignedShort();
			_streaming 	= (flags & 0x1) == 0x1;
			
			_compression = _byteData.readUnsignedByte();
			
			// Check file integrity
			body_len = _byteData.readUnsignedInt();
			if (!_streaming && body_len != _byteData.bytesAvailable) {
				dieWithError('AWD2 body length does not match header integrity field');
			}
		}
		
		private function parseNextBlock() : void
		{
			var block : AWDBlock;
			var assetData : IAsset;
			var ns : uint, type : uint, flags : uint, len : uint;
			
			_cur_block_id = _body.readUnsignedInt();
			ns = _body.readUnsignedByte();
			type = _body.readUnsignedByte();
			flags = _body.readUnsignedByte();
			len = _body.readUnsignedInt();
			
			block = new AWDBlock();
			if ((_version[0]==2)&&(_version[1]==1)){// change this to any other values than version[0] = 2 and version[1] = 1, to parse like AWD2.0 (with some addional bug fixes)
				if(_debug)trace("Import AWD2.1-File");
				switch (type) {
					case 1:
						if(_debug)trace("import MeshData");
						assetData = parseMeshData(len);
						break;
					case 22:
						if(_debug)trace("import Container");
						assetData = parseContainer(len);
						break;
					case 23:
						if(_debug)trace("import MeshInstance");
						assetData = parseMeshInstance(len);
						break;
					case 31:
						if(_debug)trace("import SkyBox");
						assetData = parseSkyBoxInstance(len);
						break;
					case 41:
						if(_debug)trace("import Light");
						assetData = parseLight(len);
						break;
					case 51:
						if(_debug)trace("import LightPicker");
						assetData = parseLightPicker(len);
						break;
					case 81:
						if(_debug)trace("import Material_v1");
						assetData = parseMaterial_v1(len);
						break;
					case 82:
						if(_debug)trace("import Texture");
						assetData = parseTexture(len, block);
						break;
					case 83:
						if(_debug)trace("import CubeTexture");
						assetData = parseCubeTexture(len, block);
						break;
					case 91:
						if(_debug)trace("import SharedMethodBlock");
						assetData = parseSharedMethodBlock(len,block);
						break;
					case 92:
						if(_debug)trace("import ShadowMapMethodBlock");
						assetData = parseShadowMethodBlock(len,block);	
						break;
					case 101:
						if(_debug)trace("import parseSkeleton");
						assetData = parseSkeleton(len);
						break;
					case 102:
						if(_debug)trace("import parseSkeletonPose");
						assetData = parseSkeletonPose(len);
						break;
					case 103:
						if(_debug)trace("import parseSkeletonAnimation");
						assetData = parseSkeletonAnimation(len);
						break;
					case 121:
						if(_debug)trace("import parseUVAnimation");
						assetData = parseUVAnimation(len);
						break;
					default:
						//trace('Ignoring block!');
						_body.position += len;
						break;
				}
			}
			else{
				if(_debug)trace("Import AWD2.0-File");
				
				switch (type) {
					case 1:
						assetData = parseMeshData(len);
						break;
					case 22:
						assetData = parseContainer(len);
						break;
					case 23:
						assetData = parseMeshInstance(len);
						break;
					case 81:
						assetData = parseMaterial(len);
						break;
					case 82:
						assetData = parseTexture(len, block);
						break;
					case 101:
						assetData = parseSkeleton(len);
						break;
					case 102:
						assetData = parseSkeletonPose(len);
						break;
					case 103:
						assetData = parseSkeletonAnimation(len);
						break;
					case 121:
						assetData = parseUVAnimation(len);
						break;
					default:
						//trace('Ignoring block!');
						_body.position += len;
						break;
				}
			}
			
			// Store block reference for later use
			_blocks[_cur_block_id] = block;
			_blocks[_cur_block_id].data = assetData;
			_blocks[_cur_block_id].id = _cur_block_id;
		}
		
		private function parseUVAnimation(blockLength : uint) : UVClipNode
		{
			// TODO: not used
			blockLength = blockLength; 
			var name : String;
			var num_frames : uint;
			var frames_parsed : uint;
			var props : AWDProperties;
			var dummy : Sprite;
			var clip : UVClipNode;
			
			name = parseVarStr();
			num_frames = _body.readUnsignedShort();
			
			props = parseProperties(null);
			
			clip = new UVClipNode();
			
			frames_parsed = 0;
			dummy = new Sprite();
			while (frames_parsed < num_frames) {
				var mtx : Matrix;
				var frame_dur : uint;
				var frame : UVAnimationFrame;
				
				// TODO: Replace this with some reliable way to decompose a 2d matrix
				mtx = parseMatrix2D();
				mtx.scale(100, 100);
				dummy.transform.matrix = mtx;
				
				frame_dur = _body.readUnsignedShort();
				
				frame = new UVAnimationFrame(dummy.x*0.01, dummy.y*0.01, dummy.scaleX/100, dummy.scaleY/100, dummy.rotation);
				clip.addFrame(frame, frame_dur);
				
				frames_parsed++;
			}
			
			// Ignore for now
			parseUserAttributes();
			
			finalizeAsset(clip, name);
			
			return clip;
		}
				
		private function parseSkyBoxInstance(blockLength : uint) : SkyBox
		{		
			//var type : uint;
			//var data_len : uint;
			var cubetex:BitmapCubeTexture;
			var name:String;
			name = parseVarStr();
			if(_debug)trace("SkyBox name = "+name);
			cubetex=_blocks[_body.readUnsignedInt()].data;
			if(_debug)trace("SkyBox found its texture = "+cubetex.name);
			var asset:SkyBox=new SkyBox(cubetex);
				
			parseProperties(null);
			parseUserAttributes();
			
			//block.data=asset;
			finalizeAsset(asset, name);
			
			return asset;
			
		}
		private function parseMaterial(blockLength : uint) : MaterialBase
		{
			var name : String;
			var type : uint;
			var props : AWDProperties;
			var mat :MaterialBase;
			var attributes : Object;
			//var finalize : Boolean;
			var num_methods : uint;
			var methods_parsed : uint;
			
			name = parseVarStr();
			type = _body.readUnsignedByte();
			num_methods = _body.readUnsignedByte();
			
			// Read material numerical properties
			// (1=color, 2=bitmap url, 10=alpha, 11=alpha_blending, 12=alpha_threshold, 13=repeat)
			props = parseProperties({ 1:INT32, 2:BADDR, 
				10:FLOAT32, 11:BOOL, 
				12:FLOAT32, 13:BOOL });
			
			methods_parsed = 0;
			while (methods_parsed < num_methods) {
				var method_type : uint;
				
				method_type = _body.readUnsignedShort();
				parseProperties(null);
				parseUserAttributes();
				methods_parsed+=1;
			}
			
			attributes = parseUserAttributes();
			
			if (type == 1) { // Color material
				var color : uint;
				
				color = props.get(1, 0xcccccc);
				mat = new ColorMaterial(color, props.get(10, 1.0));
				
			}
			else if (type == 2) { // Bitmap material
				var texture : Texture2DBase;
				var tex_addr : uint;
				
				tex_addr = props.get(2, 0);
				if ((_blocks[tex_addr]) && (tex_addr > 0)) {
					texture = _blocks[tex_addr].data;				
				}
				else {
					texture = _defaultTexture; }
				// If bitmap asset has already been loaded
				mat = new TextureMaterial(texture);
				TextureMaterial(mat).alphaBlending = Boolean(props.get(11, false));
				TextureMaterial(mat).alpha = props.get(10, 1.0);
			}
			
			mat.extra = attributes;
			SinglePassMaterialBase(mat).alphaThreshold = props.get(12, 0.0);
			mat.repeat = Boolean(props.get(13, true));
			
			finalizeAsset(mat, name);
			
			return mat;
		}
		
		
		
		private function parseMaterial_v1(blockLength : uint) : MaterialBase
		{
			var name : String;
			var type : uint;
			var props : AWDProperties;
			var mat : MaterialBase;
			var attributes : Object;
			//var finalize : Boolean;
			var num_methods : uint;
			var methods_parsed : uint;
			
			var normalTexture : Texture2DBase;
			var normalTex_addr : uint;
			var specTexture : Texture2DBase;
			var specTex_addr : uint;
			var lightPickerAddr:int;
			var spezialType:uint;	
			
			name = parseVarStr();
			type = _body.readUnsignedByte();
			num_methods = _body.readUnsignedByte();
			
			// Read material numerical properties (id 14 is not used/skipped for now)
			props = parseProperties({ 	1:UINT32, 	2:BADDR,	3:BADDR,	4:UINT8,	5:BOOL,		6:BOOL, 	7:BOOL, 
										8:BOOL,		9:UINT8,	10:FLOAT32, 11:BOOL, 	12:FLOAT32, 13:BOOL, 	15:FLOAT32,		
										16:UINT32, 	17:BADDR,	18:FLOAT32, 19:FLOAT32,	20:UINT32, 	21:BADDR, 	22:BADDR	});	
			
			
			spezialType=props.get(4,0);			
			
			//var skyboxMateri:SkyBoxMaterial;
			
			if(_debug)trace("type = " + type);
			if(_debug)trace("spezialType = " + spezialType);
			
			if (spezialType==2){
			}
			if (spezialType>2){//this is no supported material
				trace("material-spezialType is not supported, can only be 0:singlePass, 1:MultiPass, 2:SkyBox !");
			}
			if (spezialType<2){//this is SinglePass or MultiPass					
				if (type == 1) { // Color material
					var color : uint = color = props.get(1, 0xcccccc);
					if (spezialType==1){	//	MultiPassMaterial
						mat = new ColorMultiPassMaterial(color);}
					else {	//	SinglePassMaterial
						mat = new ColorMaterial(color, props.get(10, 1.0));
						ColorMaterial(mat).alphaBlending=Boolean(props.get(11,false));
					}
				}
				else if (type == 2) { // texture material
					
					var texture : Texture2DBase;// = new BitmapTexture(new BitmapData(1024, 1024, false));
					var tex_addr : uint;
					var ambientTexture : Texture2DBase;
					var ambientTex_addr : uint;
					
					tex_addr = props.get(2, 0);			
					if (tex_addr>0)	texture = _blocks[tex_addr].data;	
					
					ambientTex_addr = props.get(17, 0);
					if (ambientTex_addr>0)	ambientTexture = _blocks[ambientTex_addr].data;
					
					if (spezialType==1){	// MultiPassMaterial
						mat = new TextureMultiPassMaterial(texture);
						if (ambientTexture) {TextureMultiPassMaterial(mat).ambientTexture = ambientTexture;}		
					}
					else {	//	SinglePassMaterial
						mat = new TextureMaterial(texture);
						if (ambientTexture) {TextureMaterial(mat).ambientTexture = ambientTexture;}
						TextureMaterial(mat).alpha=props.get(10,1.0);
						TextureMaterial(mat).alphaBlending = Boolean(props.get(11, false));
					}		
					
				}
				normalTex_addr = props.get(3, 0);
				if (normalTex_addr>0){
					normalTexture = _blocks[normalTex_addr].data;
				}					
				specTex_addr = props.get(21, 0);
				if (specTex_addr>0){
					specTexture = _blocks[specTex_addr].data;
				}
				
				
				lightPickerAddr=props.get(22,0);
				if (lightPickerAddr>0){
					MaterialBase(mat).lightPicker=_blocks[lightPickerAddr].data;
				}
				MaterialBase(mat).smooth=Boolean(props.get(5,true));
				MaterialBase(mat).mipmap=Boolean(props.get(6,true));
				MaterialBase(mat).bothSides=Boolean(props.get(7,false));
				MaterialBase(mat).alphaPremultiplied=Boolean(props.get(8,false));
				MaterialBase(mat).blendMode=blendModeDic[props.get(9, 0)];
				MaterialBase(mat).repeat= Boolean(props.get(13, true));
				
				if (spezialType==0){// this is a SinglePassMaterial
					
					if (normalTexture) {	SinglePassMaterialBase(mat).normalMap = normalTexture;}
					SinglePassMaterialBase(mat).alphaThreshold=props.get(12, 0.0);
					SinglePassMaterialBase(mat).ambient=props.get(15,1.0);
					SinglePassMaterialBase(mat).ambientColor=props.get(16,0xffffff);
					SinglePassMaterialBase(mat).specular=props.get(18,1.0);
					SinglePassMaterialBase(mat).gloss=props.get(19,50);
					SinglePassMaterialBase(mat).specularColor=props.get(20,0xffffff);
					if (specTexture) {		SinglePassMaterialBase(mat).specularMap = specTexture;}
					
				}
				
				else {	// this is MultiPassMaterial
					
					if (normalTexture) {	MultiPassMaterialBase(mat).normalMap = normalTexture;}
					MultiPassMaterialBase(mat).alphaThreshold=props.get(12, 0.0);
					MultiPassMaterialBase(mat).ambient=props.get(15,1.0);
					MultiPassMaterialBase(mat).ambientColor=props.get(16,0xffffff);
					MultiPassMaterialBase(mat).specular=props.get(18,1.0);
					MultiPassMaterialBase(mat).gloss=props.get(19,50);
					MultiPassMaterialBase(mat).specularColor=props.get(20,0xffffff);
					if (specTexture) {		MultiPassMaterialBase(mat).specularMap = specTexture;}
				}
				
				methods_parsed = 0;
				var methodObj1:Texture2DBase;
				var cubeTexture:CubeTextureBase;
				while (methods_parsed < num_methods) {
					var method_type : uint;				
					method_type = _body.readUnsignedShort();
					
					props = parseProperties({ 	1:BADDR,2:BADDR,3:BADDR,	101:FLOAT32,102:FLOAT32,103:FLOAT32,
												201:UINT32,202:UINT32,		301:UINT16,302:UINT16,
												401:UINT8,402:UINT8,		601:COLOR,602:COLOR,
												701:BOOL,702:BOOL,			801:MTX4x4});	
					switch (method_type){
						case 999://wrapper-Methods that will load a previous parsed EffektMethod 
							if(_blocks[props.get(1,0)].data){
								if(spezialType==0)	SinglePassMaterialBase(mat).addMethod(_blocks[props.get(1,0)].data);
								if(spezialType==1)	MultiPassMaterialBase(mat).addMethod(_blocks[props.get(1,0)].data);
							}
							break;
						case 998://wrapper-Methods that will load a previous parsed ShadowMapMethod 
							if(_blocks[props.get(1,0)].data){
								if(spezialType==0){
									SinglePassMaterialBase(mat).shadowMethod=_blocks[props.get(1,0)].data;
									if(_debug)trace("SinglePassMaterial has shadowmerthod applied:  "+SinglePassMaterialBase(mat).shadowMethod);
								}
								if(spezialType==1)	MultiPassMaterialBase(mat).shadowMethod=_blocks[props.get(1,0)].data;
							}
							break;
						
						case 1://EnvMapAmbientMethod
							cubeTexture=new CubeTextureBase();
							if(_blocks[props.get(1,0)].data)cubeTexture=_blocks[props.get(1,0)].data;
							if(spezialType==0)	SinglePassMaterialBase(mat).ambientMethod=new EnvMapAmbientMethod(cubeTexture);
							if(spezialType==1)	MultiPassMaterialBase(mat).ambientMethod=new EnvMapAmbientMethod(cubeTexture);
							break;
						
						case 51://DepthDiffuseMethod
							if(spezialType==0)	SinglePassMaterialBase(mat).diffuseMethod=new DepthDiffuseMethod();
							if(spezialType==1)	MultiPassMaterialBase(mat).diffuseMethod=new DepthDiffuseMethod();
							break;							
						case 52://GradientDiffuseMethod
							methodObj1=_defaultTexture;
							if(_blocks[props.get(1,0)].data) methodObj1=_blocks[props.get(1,0)].data;
							if(spezialType==0)	SinglePassMaterialBase(mat).diffuseMethod=new GradientDiffuseMethod(methodObj1);
							if(spezialType==1)	MultiPassMaterialBase(mat).diffuseMethod=new GradientDiffuseMethod(methodObj1);
							break;
						case 53://WrapDiffuseMethod
							if(spezialType==0)	SinglePassMaterialBase(mat).diffuseMethod=new WrapDiffuseMethod(props.get(101,5));
							if(spezialType==1)	MultiPassMaterialBase(mat).diffuseMethod=new WrapDiffuseMethod(props.get(101,5));
							break;
						case 54://LightMapDiffuseMethod
							methodObj1=_defaultTexture;
							if(_blocks[props.get(1,0)].data)methodObj1=_blocks[props.get(1,0)].data;
							if(spezialType==0)	SinglePassMaterialBase(mat).diffuseMethod=new LightMapDiffuseMethod(methodObj1,blendModeDic[props.get(401,10)],false,SinglePassMaterialBase(mat).diffuseMethod);
							if(spezialType==1)	MultiPassMaterialBase(mat).diffuseMethod=new LightMapDiffuseMethod(methodObj1,blendModeDic[props.get(401,10)],false,MultiPassMaterialBase(mat).diffuseMethod);
							break;
						case 55://CelDiffuseMethod
							if(spezialType==0){	
								SinglePassMaterialBase(mat).diffuseMethod=new CelDiffuseMethod(props.get(401,3),SinglePassMaterialBase(mat).diffuseMethod);
								CelDiffuseMethod(SinglePassMaterialBase(mat).diffuseMethod).smoothness=props.get(101,0.1);
								}
							if(spezialType==1){	
								MultiPassMaterialBase(mat).diffuseMethod=new CelDiffuseMethod(props.get(401,3),MultiPassMaterialBase(mat).diffuseMethod);
								CelDiffuseMethod(MultiPassMaterialBase(mat).diffuseMethod).smoothness=props.get(101,0.1);
							}
							break;
						case 56://SubSurfaceScatteringMethod
							if(spezialType==0){	
								SinglePassMaterialBase(mat).diffuseMethod=new SubsurfaceScatteringDiffuseMethod();//depthMapSize and depthMapOffset ?
								SubsurfaceScatteringDiffuseMethod(SinglePassMaterialBase(mat).diffuseMethod).scattering=props.get(101,0.2);
								SubsurfaceScatteringDiffuseMethod(SinglePassMaterialBase(mat).diffuseMethod).translucency=props.get(102,1);
								SubsurfaceScatteringDiffuseMethod(SinglePassMaterialBase(mat).diffuseMethod).scatterColor=props.get(601,0xffffff);
							}
							if(spezialType==1){	
								MultiPassMaterialBase(mat).diffuseMethod=new SubsurfaceScatteringDiffuseMethod();//depthMapSize and depthMapOffset ?
								SubsurfaceScatteringDiffuseMethod(MultiPassMaterialBase(mat).diffuseMethod).scattering=props.get(101,0.2);
								SubsurfaceScatteringDiffuseMethod(MultiPassMaterialBase(mat).diffuseMethod).translucency=props.get(102,1);
								SubsurfaceScatteringDiffuseMethod(MultiPassMaterialBase(mat).diffuseMethod).scatterColor=props.get(601,0xffffff);
							}
							break;
						
						case 101://AnisotropicSpecularMethod 
							if(spezialType==0)	SinglePassMaterialBase(mat).specularMethod=new AnisotropicSpecularMethod();
							if(spezialType==1)	MultiPassMaterialBase(mat).specularMethod=new AnisotropicSpecularMethod();
							break;
						case 102://PhongSpecularMethod
							if(spezialType==0)	SinglePassMaterialBase(mat).specularMethod=new PhongSpecularMethod();
							if(spezialType==1)	MultiPassMaterialBase(mat).specularMethod=new PhongSpecularMethod();
							break;
						case 103://CellSpecularMethod
							if(spezialType==0){	
								SinglePassMaterialBase(mat).specularMethod=new CelSpecularMethod(props.get(101,0.5),SinglePassMaterialBase(mat).specularMethod);
								CelSpecularMethod(SinglePassMaterialBase(mat).specularMethod).smoothness=props.get(102,0.1);
							}
							if(spezialType==1){
								MultiPassMaterialBase(mat).specularMethod=new CelSpecularMethod(props.get(101,0.5),MultiPassMaterialBase(mat).specularMethod);
								CelSpecularMethod(MultiPassMaterialBase(mat).specularMethod).smoothness=props.get(102,0.1);
							}
							break;
						case 104://FresnelSpecularMethod
							if(spezialType==0){	
								SinglePassMaterialBase(mat).specularMethod=new FresnelSpecularMethod(Boolean(props.get(701,true)),SinglePassMaterialBase(mat).specularMethod);
								FresnelSpecularMethod(SinglePassMaterialBase(mat).specularMethod).fresnelPower=props.get(101,5);
								FresnelSpecularMethod(SinglePassMaterialBase(mat).specularMethod).normalReflectance=props.get(102,0.1);
							}
							if(spezialType==1){
								MultiPassMaterialBase(mat).specularMethod=new FresnelSpecularMethod(Boolean(props.get(701,true)),MultiPassMaterialBase(mat).specularMethod);
								FresnelSpecularMethod(MultiPassMaterialBase(mat).specularMethod).fresnelPower=props.get(101,5);
								FresnelSpecularMethod(MultiPassMaterialBase(mat).specularMethod).normalReflectance=props.get(102,0.1);
							}
							break;
						//case 151://HeightMapNormalMethod
							//break;
						case 152://SimpleWaterNormalMethod
							methodObj1=_defaultTexture;
							if(_blocks[props.get(1,0)].data)methodObj1=_blocks[props.get(1,0)].data;
							if(spezialType==0){
								if(!SinglePassMaterialBase(mat).normalMap)SinglePassMaterialBase(mat).normalMap=methodObj1;
								SinglePassMaterialBase(mat).normalMethod=new SimpleWaterNormalMethod(SinglePassMaterialBase(mat).normalMap,methodObj1);
							}
							if(spezialType==1){								
								if(!SinglePassMaterialBase(mat).normalMap)SinglePassMaterialBase(mat).normalMap=methodObj1;
								MultiPassMaterialBase(mat).normalMethod=new SimpleWaterNormalMethod(MultiPassMaterialBase(mat).normalMap,methodObj1);
							}
							break;
					}
					parseUserAttributes();
					methods_parsed+=1;
				}
			
			}
			
			
			attributes = parseUserAttributes();
			//mat.extra = attributes;
			
			finalizeAsset(mat, name);
			
			
			return mat;
		}
		
		private function parseShadowMethodBlock(blockLength : uint, block : AWDBlock) : ShadowMapMethodBase
		{		
			//var type : uint;
			//var data_len : uint;
			var asset:ShadowMapMethodBase;
			var thisLight:LightBase;
			block.name = parseVarStr();
			if(_debug)trace("ShadowMethod name = "+block.name);
			thisLight=_blocks[_body.readUnsignedInt()].data;
			if(_debug)trace("ShadowMethod light = "+thisLight.name);
			asset=parseShadowMethodList(thisLight); 
			// Ignore for now
			parseUserAttributes();
			block.data=asset;
			finalizeAsset(asset, block.name);
						
			return asset;
			
		}
		
		// this functions reads and creates a ShadowMethodMethod
		private function parseShadowMethodList(light:LightBase) :ShadowMapMethodBase
		{
			
			var methodType:uint = _body.readUnsignedShort();
			var shadowMethod:ShadowMapMethodBase;
			var props:Object;
			// to do: reduce number of properties (
			props = parseProperties({ 	1:BADDR,2:BADDR,3:BADDR,
										101:FLOAT32,102:FLOAT32,103:FLOAT32,
										201:UINT32,202:UINT32,
										301:UINT16,302:UINT16,
										401:UINT8,402:UINT8,
										601:COLOR,602:COLOR,
										701:BOOL,702:BOOL,
										801:MTX4x4});	
			
			switch (methodType){
				
				case 1001://CascadeShadowMapMethod
					shadowMethod=new CascadeShadowMapMethod(_blocks[props.get(1,0)].data);
					break;
				case 1002://NearShadowMapMethod
					shadowMethod=new NearShadowMapMethod(_blocks[props.get(1,0)].data);
					break;
				case 1101://FilteredShadowMapMethod					
					shadowMethod=new FilteredShadowMapMethod(DirectionalLight(light));
					FilteredShadowMapMethod(shadowMethod).alpha=props.get(101,1);
					FilteredShadowMapMethod(shadowMethod).epsilon=props.get(102,0.002);
					break;
				case 1102://DitheredShadowMapMethod
					shadowMethod=new DitheredShadowMapMethod(DirectionalLight(light),props.get(201,5));
					DitheredShadowMapMethod(shadowMethod).alpha=props.get(101,1);
					DitheredShadowMapMethod(shadowMethod).epsilon=props.get(102,0.002);
					DitheredShadowMapMethod(shadowMethod).range=props.get(103,1);
					break;
				case 1103://SoftShadowMapMethod
					shadowMethod=new SoftShadowMapMethod(DirectionalLight(light),props.get(201,5));
					SoftShadowMapMethod(shadowMethod).alpha=props.get(101,1);
					SoftShadowMapMethod(shadowMethod).epsilon=props.get(102,0.002);
					SoftShadowMapMethod(shadowMethod).range=props.get(103,1);
					break;
				case 1104://HardShadowMapMethod
					shadowMethod=new HardShadowMapMethod(light);
					HardShadowMapMethod(shadowMethod).alpha=props.get(101,1);
					HardShadowMapMethod(shadowMethod).alpha=props.get(102,0.002);
					break;				
				
			}
			parseUserAttributes();
			return shadowMethod;
		}
		
		//sharedMethodBlocks are EffectMethods
		private function parseSharedMethodBlock(blockLength : uint, block : AWDBlock) : EffectMethodBase
		{
			//var type : uint;
			//var data_len : uint;
			var asset:EffectMethodBase;
			
			block.name = parseVarStr();
			if(_debug)trace("EffectsMethod name = "+block.name);
			asset=parseSharedMethodList(); 
			// Ignore for now
			parseUserAttributes();
			block.data=asset;
			finalizeAsset(asset, block.name);	
			
			return asset;
		}
		
		// this functions reads and creates a EffectMethod 
		private function parseSharedMethodList() :EffectMethodBase
		{
			
			var methodType:uint = _body.readUnsignedShort();
			var effectMethodReturn:EffectMethodBase;
			var props:Object;
			props = parseProperties({ 	1:BADDR,		2:BADDR,		3:BADDR,
										101:FLOAT32,	102:FLOAT32,	103:FLOAT32,	104:FLOAT32,	105:FLOAT32,	106:FLOAT32,	107:FLOAT32,
										201:UINT32,		202:UINT32,
										301:UINT16,		302:UINT16,
										401:UINT8,		402:UINT8,
										601:COLOR,		602:COLOR,
										701:BOOL,		702:BOOL});	
			var effectTex1:Texture2DBase= _defaultTexture;
			//var effectTex2:Texture2DBase= _defaultTexture;
			var cubetex1:CubeTextureBase=new CubeTextureBase();
			//var cubetex2:CubeTextureBase=new CubeTextureBase();
			switch (methodType){
				// Effect Methods
				case 401://ColorMatrix
					// to do - map the values to a colormatrix
					effectMethodReturn=new ColorMatrixMethod(props.get(101,new Array(0,0,0,1, 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)));
					break;
				case 402://ColorTransform
					effectMethodReturn=new ColorTransformMethod();
					var offCol:uint=props.get(601,0x00000000);
					var newColorTransform:ColorTransform=new ColorTransform(props.get(102,1),props.get(103,1),props.get(104,1),props.get(101,1),(( offCol >> 16 ) & 0xFF),(( offCol >> 8 ) & 0xFF),(offCol & 0xFF),(( offCol >> 24 ) & 0xFF));
					ColorTransformMethod(effectMethodReturn).colorTransform=newColorTransform;
					
					break;
				case 403://EnvMap
					cubetex1=new BitmapCubeTexture(_defaultTexture.bitmapData,_defaultTexture.bitmapData,_defaultTexture.bitmapData,_defaultTexture.bitmapData,_defaultTexture.bitmapData,_defaultTexture.bitmapData);
					if(_blocks[props.get(1,0)].data) cubetex1=_blocks[props.get(1,0)].data;
					effectMethodReturn=new EnvMapMethod(cubetex1,props.get(101,1));
					if (props.get(2,0)>0)EnvMapMethod(effectMethodReturn).mask=_blocks[props.get(2,0)].data;
					break;
				case 404://LightMapMethod
					if (props.get(1,0)>0)effectTex1=_blocks[props.get(1,0)].data;
					effectMethodReturn=new LightMapMethod(effectTex1,blendModeDic[props.get(401,10)]);//usesecondaryUV not set					
					break;
				case 405://ProjectiveTextureMethod
					var textureprojector:TextureProjector= new TextureProjector(effectTex1);
					if (props.get(1,0)>0) textureprojector=_blocks[props.get(1,0)].data;
					effectMethodReturn=new ProjectiveTextureMethod(textureprojector,blendModeDic[props.get(401,10)]);					
					break;
				case 406://RimLightMethod
					effectMethodReturn=new RimLightMethod(props.get(601,0xffffff),props.get(101,0.4),props.get(101,2));//blendMode
					break;
				case 407://AlphaMaskMethod
					if (props.get(1,0)>0)effectTex1=_blocks[props.get(1,0)].data;
					effectMethodReturn=new AlphaMaskMethod(effectTex1,Boolean(props.get(701,false)));					
					break;
				case 408://RefractionEnvMapMethod
					if (props.get(1,0)>0)cubetex1=_blocks[props.get(1,0)].data;
					effectMethodReturn=new RefractionEnvMapMethod(cubetex1,props.get(101,0.1),props.get(102,0.01),props.get(103,0.01),props.get(104,0.01));
					RefractionEnvMapMethod(effectMethodReturn).alpha=props.get(104,1);					
					break;
				case 409://OutlineMethod
					effectMethodReturn=new OutlineMethod(props.get(601,0x00000000),props.get(101,1),Boolean(props.get(701,true)),Boolean(props.get(702,false)));
					break;
				case 410://FresnelEnvMapMethod
					cubetex1=new BitmapCubeTexture(_defaultTexture.bitmapData,_defaultTexture.bitmapData,_defaultTexture.bitmapData,_defaultTexture.bitmapData,_defaultTexture.bitmapData,_defaultTexture.bitmapData);
					if(_blocks[props.get(1,0)].data) cubetex1=_blocks[props.get(1,0)].data;
					effectMethodReturn=new FresnelEnvMapMethod(cubetex1,props.get(101,1));
					break;
				case 411://FogMethod
					effectMethodReturn=new FogMethod(props.get(101,0),props.get(102,1000),props.get(601,0x808080));
					break;				
			
				
			}
			parseUserAttributes();
			return effectMethodReturn;
		}
		private function parseLight(blockLength : uint) : LightBase
		{
			var name : String;
			var par_id : uint;
			var lightType : uint;
			//var numShadowMethods : uint;
			var mtx : Matrix3D;
			var light : LightBase;
			var parent : ObjectContainer3D;
			var props : AWDProperties;
			var newShadowMapper:ShadowMapperBase;
			
			par_id = _body.readUnsignedInt();
			mtx = parseMatrix3D();
			name = parseVarStr();
			lightType=_body.readUnsignedByte();
			props = parseProperties({ 	1:FLOAT32, 	2:FLOAT32,	3:COLOR,		4:FLOAT32,
				5:FLOAT32,	6:BOOL,		7:COLOR,		8:FLOAT32, 9:UINT8, 10:UINT8 ,11:FLOAT32 ,12:UINT16 , 21:FLOAT32, 22:FLOAT32,23:FLOAT32});	
			
			var shadowMapperType:uint=props.get(9,0);
			if (lightType==1){
				if(_debug)trace("shadowMapperType = "+shadowMapperType);
				light=new PointLight();
				PointLight(light).radius = props.get(1,90000);
				PointLight(light).fallOff = props.get(2,100000);				
				if(shadowMapperType>0){
					if(shadowMapperType==4) newShadowMapper=new CubeMapShadowMapper();
				}
				light.transform = mtx;
				
			}
			if (lightType==2){
				
				light=new DirectionalLight(props.get(21,0),props.get(22,-1),props.get(23,1));			
				if(shadowMapperType>0){
					if(_debug)trace("shadowMapperType = "+shadowMapperType);
					if(shadowMapperType==1) newShadowMapper=new DirectionalShadowMapper();
					if(shadowMapperType==2) newShadowMapper=new NearDirectionalShadowMapper(props.get(11,0.5));
					if(shadowMapperType==3)	newShadowMapper=new CascadeShadowMapper(props.get(12,3));
				}
			}
			
			light.color = props.get(3,0xffffff);
			light.specular = props.get(4,1.0);
			light.diffuse = props.get(5,1.0);
			light.ambientColor = props.get(7,0xffffff);
			light.ambient =  props.get(8,0.0);	
			
			// if a shadowMapper has been created, adjust the depthMapSize if needed, assign to light and set castShadows to true
			if(newShadowMapper){
				if(props.get(10,0)>0)newShadowMapper.depthMapSize=_depthSizeDic[props.get(10,0)>0];
				light.shadowMapper=newShadowMapper;
				light.castsShadows=true;
			}
			
			// dont know if this makes trouble intern in AwayBuilders scenegraph. For Away3d "stand-alone, this seams to be correct, but for Awaybuilder they should be inserted into Root ?
			parent = _blocks[par_id].data as ObjectContainer3D;
			if (parent) {
				parent.addChild(light);
			}
			
			parseUserAttributes();
			
			finalizeAsset(light, name);
			
			return light;
			
		}
		private function parseLightPicker(blockLength : uint) : LightPickerBase
		{
			var name:String=parseVarStr();
			var numLights:uint=_body.readUnsignedShort();
			var lightsArray:Array=new Array();
			var k:int=0;
			for (k=0;k<numLights;k++){
				lightsArray.push(_blocks[_body.readUnsignedInt()].data);
			}
			var lightPick:LightPickerBase=new StaticLightPicker(lightsArray);
			lightPick.name=name;
			parseUserAttributes();
			finalizeAsset(lightPick, name);
			
			return lightPick;
		}
		private function parseCubeTexture(blockLength : uint, block : AWDBlock) :CubeTextureBase
		{
			blockLength = blockLength; 
			var type : uint;
			var data_len : uint;
			var asset : CubeTextureBase;
			var i:int;
			_cubeTextures=new Array();
			_texture_users[_cur_block_id.toString()] = [];	
			type = _body.readUnsignedByte();
			block.name = parseVarStr();
			
			for (i=0;i<6;i++){
				data_len = _body.readUnsignedInt();			
				_texture_users[_cur_block_id.toString()] = [];	
				_cubeTextures.push(null);
				// External
				if (type == 0) {
					var url : String;
					
					url = _body.readUTFBytes(data_len);
					
					addDependency(_cur_block_id.toString()+"#"+i, new URLRequest(url), false, null, true);
				}
				else {
					var data : ByteArray;
					
					data = new ByteArray();
					_body.readBytes(data, 0, data_len);
					
					addDependency(_cur_block_id.toString()+"#"+i, null, false, data, true);
				}
			}
			
			// Ignore for now
			parseProperties(null);
			parseUserAttributes();
			
			pauseAndRetrieveDependencies();
			
			return asset;
		}
		private function parseTexture(blockLength : uint, block : AWDBlock) : Texture2DBase
		{
			var type : uint;
			var data_len : uint;
			var asset : Texture2DBase;
			
			block.name = parseVarStr();
			type = _body.readUnsignedByte();
			data_len = _body.readUnsignedInt();
			
			_texture_users[_cur_block_id.toString()] = [];
			
			// External
			if (type == 0) {
				var url : String;
				
				url = _body.readUTFBytes(data_len);
				
				addDependency(_cur_block_id.toString(), new URLRequest(url), false, null, true);
			}
			else {
				var data : ByteArray;
				
				data = new ByteArray();
				_body.readBytes(data, 0, data_len);
				
				addDependency(_cur_block_id.toString(), null, false, data, true);
			}
			
			// Ignore for now
			parseProperties(null);
			parseUserAttributes();
			
			pauseAndRetrieveDependencies();
			
			return asset;
		}
		
		
		private function parseSkeleton(blockLength : uint) : Skeleton
		{
			var name : String;
			var num_joints : uint;
			var joints_parsed : uint;
			var skeleton : Skeleton;
			
			name = parseVarStr();
			num_joints = _body.readUnsignedShort();
			skeleton = new Skeleton();
			
			// Discard properties for now
			parseProperties(null);
			
			joints_parsed = 0;
			while (joints_parsed < num_joints) {
				// TODO: not used
				//	var parent_id : uint;
				// TODO: not used
				//var joint_name : String;
				var joint : SkeletonJoint;
				var ibp : Matrix3D;
				
				// Ignore joint id
				_body.readUnsignedShort();
				
				joint = new SkeletonJoint();
				joint.parentIndex = _body.readUnsignedShort() -1; // 0=null in AWD
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
					// TODO: not used
					// var mtx0 : Matrix3D;
					var mtx_data : Vector.<Number> = parseMatrix43RawData();
					
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
		
		private function parseSkeletonAnimation(blockLength : uint) : SkeletonClipNode
		{
			var name : String;
			var num_frames : uint;
			var frames_parsed : uint;
			var frame_dur : Number;
			
			name = parseVarStr();
			var clip : SkeletonClipNode = new SkeletonClipNode();
			
			num_frames = _body.readUnsignedShort();
			
			// Ignore properties for now (none in spec)
			parseProperties(null);
			
			frames_parsed = 0;
			while (frames_parsed < num_frames) {
				var pose_addr : uint;
				
				//TODO: Check for null?
				pose_addr = _body.readUnsignedInt();
				frame_dur = _body.readUnsignedShort();
				clip.addFrame(_blocks[pose_addr].data as SkeletonPose, frame_dur);
				
				frames_parsed++;
			}
			
			// Ignore attributes for now
			parseUserAttributes();
			
			finalizeAsset(clip, name);
			
			return clip;
		}
		
		private function parseContainer(blockLength : uint) : ObjectContainer3D
		{
			var name : String;
			var par_id : uint;
			var mtx : Matrix3D;
			var ctr : ObjectContainer3D;
			var parent : ObjectContainer3D;
			
			par_id = _body.readUnsignedInt();
			mtx = parseMatrix3D();
			name = parseVarStr();
			
			ctr = new ObjectContainer3D();
			ctr.transform = mtx;
			
			parent = _blocks[par_id].data as ObjectContainer3D;
			if (parent) {
				parent.addChild(ctr);
			}
						
			if ((_version[0]==2)&&(_version[1]==1)){
				//to do: add to documentation: Comatiner properties are: 1:pivot.x, 2:pivot.y, 3:pivot.z, 4:visible=uint
				var props:Object = parseProperties({ 	1:FLOAT32, 	2:FLOAT32,	3:FLOAT32,		4:UINT8});	
				ctr.pivotPoint=new Vector3D(props.get(1,0),props.get(2,0),props.get(3,0));
				
			}
			else{
				parseProperties(null);
				
			}
			
			
			ctr.extra = parseUserAttributes();
			
			finalizeAsset(ctr, name);
			
			return ctr;
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
			var parent : ObjectContainer3D;
			
			par_id = _body.readUnsignedInt();
			mtx = parseMatrix3D();
			name = parseVarStr();
			
			data_id = _body.readUnsignedInt();
			geom = _blocks[data_id].data as Geometry;
			
			materials = new Vector.<MaterialBase>();
			num_materials = _body.readUnsignedShort();
			materials_parsed = 0;
			while (materials_parsed < num_materials) {
				var mat_id : uint;
				mat_id = _body.readUnsignedInt();
				
				materials.push(_blocks[mat_id].data);
				
				materials_parsed++;
			}
			
			mesh = new Mesh(geom, null);
			mesh.transform = mtx;
			
			// Add to parent if one exists
			parent = _blocks[par_id].data as ObjectContainer3D;
			if (parent) {
				parent.addChild(mesh);
			}
			
			if (materials.length >= 1 && mesh.subMeshes.length == 1) {
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
			// to do: use the properties to read the mesh.castShadow - not encoded atm
			
			if ((_version[0]==2)&&(_version[1]==1)){
				//to do: add to documentation: Mes properties extent the Container Properties with 5:Bool castShadows
				var props:Object = parseProperties({ 	1:FLOAT32, 	2:FLOAT32,	3:FLOAT32,		4:UINT8, 5:BOOL});	
				mesh.pivotPoint=new Vector3D(props.get(1,0),props.get(2,0),props.get(3,0));
				mesh.castsShadows=Boolean(props.get(5,false));
				mesh.castsShadows=true;
				trace("MeshCastShadows = "+mesh.castsShadows);
				
			}
			else{
				parseProperties(null);
				
			}
			
			mesh.extra = parseUserAttributes();
			
			finalizeAsset(mesh, name);
			
			return mesh;
		}
		
		
		private function parseMeshData(blockLength : uint) : Geometry
		{
			blockLength=blockLength;
			var name : String;
			var geom : Geometry;
			var num_subs : uint;
			var subs_parsed : uint;
			var props : AWDProperties;
			//var bsm : Matrix3D;
			
			// Read name and sub count
			name = parseVarStr();
			num_subs = _body.readUnsignedShort();
			
			// Read optional properties
			props = parseProperties({ 1:MTX4x4 }); 
			
			geom = new Geometry();
			
			// Loop through sub meshes
			subs_parsed = 0;
			while (subs_parsed < num_subs) {
				var i : uint;
				var sm_len : uint, sm_end : uint;
				var sub_geoms : Vector.<ISubGeometry>;
				var w_indices : Vector.<Number>;
				var weights : Vector.<Number>;
				
				sm_len = _body.readUnsignedInt();
				sm_end = _body.position + sm_len;
				
				// Ignore for now
				parseProperties(null);
				
				// Loop through data streams
				while (_body.position < sm_end) {
					var idx : uint = 0;
					var str_ftype : uint;
					var str_type : uint, str_len : uint, str_end : uint;
					
					// Type, field type, length
					str_type = _body.readUnsignedByte();
					str_ftype = _body.readUnsignedByte();
					str_len = _body.readUnsignedInt();
					str_end = _body.position + str_len;
					
					var x:Number, y:Number, z:Number;
					
					if (str_type == 1) {
						var verts : Vector.<Number> = new Vector.<Number>();
						while (_body.position < str_end) {
							// TODO: Respect stream field type
							x = _body.readFloat();
							y = _body.readFloat();
							z = _body.readFloat();
							
							verts[idx++] = x;
							verts[idx++] = y;
							verts[idx++] = z;
						}
					}
					else if (str_type == 2) {
						var indices : Vector.<uint> = new Vector.<uint>();
						while (_body.position < str_end) {
							// TODO: Respect stream field type
							indices[idx++] = _body.readUnsignedShort();
						}
					}
					else if (str_type == 3) {
						var uvs : Vector.<Number> = new Vector.<Number>();
						while (_body.position < str_end) {
							// TODO: Respect stream field type
							uvs[idx++] = _body.readFloat();
						}
					}
					else if (str_type == 4) {
						var normals : Vector.<Number> = new Vector.<Number>();
						while (_body.position < str_end) {
							// TODO: Respect stream field type
							normals[idx++] = _body.readFloat();
						}
					}
					else if (str_type == 6) {
						w_indices = new Vector.<Number>();
						while (_body.position < str_end) {
							// TODO: Respect stream field type
							w_indices[idx++] = _body.readUnsignedShort()*3;
						}
					}
					else if (str_type == 7) {
						weights = new Vector.<Number>();
						while (_body.position < str_end) {
							// TODO: Respect stream field type
							weights[idx++] = _body.readFloat();
						}
					}
					else {
						_body.position = str_end;
					}
				}
				
				// Ignore sub-mesh attributes for now
				parseUserAttributes();
				
				sub_geoms = GeomUtil.fromVectors(verts, indices, uvs, normals, null, weights, w_indices);
				for (i=0; i<sub_geoms.length; i++) {
					geom.addSubGeometry(sub_geoms[i]);
					// TODO: Somehow map in-sub to out-sub indices to enable look-up
					// when creating meshes (and their material assignments.)
				}
				
				subs_parsed++;
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
					len = _body.readUnsignedInt();
					if (expected.hasOwnProperty(key.toString())) {
						type = expected[key];
						props.set(key, parseAttrValue(type, len));
					}
					else {
						_body.position += len;
					}
					
				}
			}
			
			return props;
		}
		
		private function parseUserAttributes() : Object
		{
			var attributes : Object;
			var list_len : uint;
			
			list_len = _body.readUnsignedInt();
			if (list_len > 0) {
				var list_end : uint;
				
				attributes = {};
				
				list_end = _body.position + list_len;
				while (_body.position < list_end) {
					var ns_id : uint;
					var attr_key : String;
					var attr_type : uint;
					var attr_len : uint;
					var attr_val : *;
					
					// TODO: Properly tend to namespaces in attributes
					ns_id = _body.readUnsignedByte();
					attr_key = parseVarStr();
					attr_type = _body.readUnsignedByte();
					attr_len = _body.readUnsignedInt();
					
					switch (attr_type) {
						case AWDSTRING:
							attr_val = _body.readUTFBytes(attr_len);
							break;
						case INT8:
							attr_val = _body.readByte();
							break;
						case INT16:
							attr_val = _body.readShort();
							break;
						case INT32:
							attr_val = _body.readInt();
							break;
						case BOOL:
						case UINT8:
							attr_val = _body.readUnsignedByte();
							break;
						case UINT16:
							attr_val = _body.readUnsignedShort();
							break;
						case UINT32:
						case BADDR:
							attr_val = _body.readUnsignedInt();
							break;
						case FLOAT32:
							attr_val = _body.readFloat();
							break;
						case FLOAT64:
							attr_val = _body.readDouble();
							break;
						default:
							attr_val = 'unimplemented attribute type '+attr_type;
							_body.position += attr_len;
							break;
					}
					
					if(_debug)trace("attribute = name: "+attr_key+"  / value = "+attr_val);
					attributes[attr_key] = attr_val;
				}
			}
			
			return attributes;
		}
		
		private function parseAttrValue(type : uint, len : uint) : *
		{
			var elem_len : uint;
			var read_func : Function;
			
			switch (type) {
				case INT8:
					elem_len = 1;
					read_func = _body.readByte;
					break;
				case INT16:
					elem_len = 2;
					read_func = _body.readShort;
					break;
				case INT32:
					elem_len = 4;
					read_func = _body.readInt;
					break;
				case BOOL:
				case UINT8:
					elem_len = 1;
					read_func = _body.readUnsignedByte;
					break;
				case UINT16:
					elem_len = 2;
					read_func = _body.readUnsignedShort;
					break;
				case UINT32:
				case COLOR:
				case BADDR:
					elem_len = 4;
					read_func = _body.readUnsignedInt;
					break;
				case FLOAT32:
					elem_len = 4;
					read_func = _body.readFloat;
					break;
				case FLOAT64:
					elem_len = 8;
					read_func = _body.readDouble;
					break;
				case VECTOR2x1:
				case VECTOR3x1:
				case VECTOR4x1:
				case MTX3x2:
				case MTX3x3:
				case MTX4x3:
				case MTX4x4:
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
		
		private function parseMatrix2D() : Matrix
		{
			var mtx : Matrix;
			var mtx_raw : Vector.<Number> = parseMatrix32RawData();
			
			mtx = new Matrix(mtx_raw[0], mtx_raw[1], mtx_raw[2], mtx_raw[3], mtx_raw[4], mtx_raw[5]);
			return mtx;
		}
		
		private function parseMatrix3D() : Matrix3D
		{
			return new Matrix3D(parseMatrix43RawData());
		}
		
		
		private function parseMatrix32RawData() : Vector.<Number>
		{
			var i : uint;
			var mtx_raw : Vector.<Number> = new Vector.<Number>(6, true);
			for (i=0; i<6; i++)
				mtx_raw[i] = _body.readFloat();
			
			return mtx_raw;
		}
		
		private function parseMatrix43RawData() : Vector.<Number>
		{
			var mtx_raw : Vector.<Number> = new Vector.<Number>(16, true);
			
			mtx_raw[0] = _body.readFloat();
			mtx_raw[1] = _body.readFloat();
			mtx_raw[2] = _body.readFloat();
			mtx_raw[3] = 0.0;
			mtx_raw[4] = _body.readFloat();
			mtx_raw[5] = _body.readFloat();
			mtx_raw[6] = _body.readFloat();
			mtx_raw[7] = 0.0;
			mtx_raw[8] = _body.readFloat();
			mtx_raw[9] = _body.readFloat();
			mtx_raw[10] = _body.readFloat();
			mtx_raw[11] = 0.0;
			mtx_raw[12] = _body.readFloat();
			mtx_raw[13] = _body.readFloat();
			mtx_raw[14] = _body.readFloat();
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


internal class AWDBlock
{
	public var id : uint;
	public var name : String;
	public var data : *;
	public function AWDBlock() {} 
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


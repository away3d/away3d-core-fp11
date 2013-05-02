package away3d.loaders.parsers
{
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
	import away3d.loaders.misc.*;
	import away3d.loaders.parsers.utils.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.LightPickerBase;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.AlphaMaskMethod;
	import away3d.materials.methods.CascadeShadowMapMethod;
	import away3d.materials.methods.ColorMatrixMethod;
	import away3d.materials.methods.ColorTransformMethod;
	import away3d.materials.methods.DitheredShadowMapMethod;
	import away3d.materials.methods.EffectMethodBase;
	import away3d.materials.methods.EnvMapMethod;
	import away3d.materials.methods.FilteredShadowMapMethod;
	import away3d.materials.methods.FogMethod;
	import away3d.materials.methods.FresnelEnvMapMethod;
	import away3d.materials.methods.HardShadowMapMethod;
	import away3d.materials.methods.LightMapMethod;
	import away3d.materials.methods.NearShadowMapMethod;
	import away3d.materials.methods.OutlineMethod;
	import away3d.materials.methods.ProjectiveTextureMethod;
	import away3d.materials.methods.RefractionEnvMapMethod;
	import away3d.materials.methods.RimLightMethod;
	import away3d.materials.methods.ShadingMethodBase;
	import away3d.materials.methods.ShadowMapMethodBase;
	import away3d.materials.methods.SoftShadowMapMethod;
	import away3d.materials.utils.*;
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
		
		public static const UNCOMPRESSED : uint = 0;
		public static const DEFLATE : uint = 1;
		public static const LZMA : uint = 2;
		
		
		
		public static const AWD_FIELD_INT8 : uint = 1;
		public static const AWD_FIELD_INT16 : uint = 2;
		public static const AWD_FIELD_INT32 : uint = 3;
		public static const AWD_FIELD_UINT8 : uint = 4;
		public static const AWD_FIELD_UINT16 : uint = 5;
		public static const AWD_FIELD_UINT32 : uint = 6;
		public static const AWD_FIELD_FLOAT32 : uint = 7;
		public static const AWD_FIELD_FLOAT64 : uint = 8;
		
		public static const AWD_FIELD_BOOL : uint = 21;
		public static const AWD_FIELD_COLOR : uint = 22;
		public static const AWD_FIELD_BADDR : uint = 23;
		
		public static const AWD_FIELD_STRING : uint = 31;
		public static const AWD_FIELD_BYTEARRAY : uint = 32;
		
		public static const AWD_FIELD_VECTOR2x1 : uint = 41;
		public static const AWD_FIELD_VECTOR3x1 : uint = 42;
		public static const AWD_FIELD_VECTOR4x1 : uint = 43;
		public static const AWD_FIELD_MTX3x2 : uint = 44;
		public static const AWD_FIELD_MTX3x3 : uint = 45;
		public static const AWD_FIELD_MTX4x3 : uint = 46;
		public static const AWD_FIELD_MTX4x4 : uint = 47;
		
		private var blendModeDic:Vector.<String>;
		
		private var _debug:Boolean=true;
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
				var asset : Texture2DBase = resourceDependency.assets[0] as Texture2DBase;
				if (asset) {
					var mat : TextureMaterial;
					var users : Array;
					var block : AWDBlock = _blocks[parseInt(resourceDependency.id)];
					
					// Store finished asset
					block.data = asset;
					
					// Reset name of texture to the one defined in the AWD file,
					// as opposed to whatever the image parser came up with.
					asset.resetAssetPath(block.name, null, true);
					
					// Finalize texture asset to dispatch texture event, which was
					// previously suppressed while the dependency was loaded.
					finalizeAsset(asset);
					
					users = _texture_users[resourceDependency.id];
					for each (mat in users) {
						mat.texture = asset;
						finalizeAsset(mat);
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
						if(_debug)trace("import parseMeshData");
						assetData = parseMeshData(len);
						break;
					case 22:
						if(_debug)trace("import parseContainer");
						assetData = parseContainer(len);
						break;
					case 23:
						if(_debug)trace("import parseMeshInstance");
						assetData = parseMeshInstance(len);
						break;
					case 41:
						if(_debug)trace("import parseLight");
						assetData = parseLight(len);
						break;
					case 51:
						if(_debug)trace("import parseLightPicker");
						assetData = parseLightPicker(len);
						break;
					case 81:
						if(_debug)trace("import parseMaterial_v1");
						assetData = parseMaterial_v1(len);
						break;
					case 82:
						if(_debug)trace("import parseTexture");
						assetData = parseTexture(len, block);
						break;
					case 91:
						if(_debug)trace("import parseSharedMethodBlock");
						var effectOrShadowMapMethod:ShadingMethodBase=parseSharedMethodBlock(len,block);
						if (effectOrShadowMapMethod is EffectMethodBase){
							assetData = EffectMethodBase(effectOrShadowMapMethod);							
						}
						if (effectOrShadowMapMethod is ShadowMapMethodBase){
							assetData = ShadowMapMethodBase(effectOrShadowMapMethod);							
						}
						else{
							if(_debug)trace("unknown SharedMethod");
						}
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
		
		
		
		private function parseMaterial(blockLength : uint) : MaterialBase
		{
			// TODO: not used
			blockLength = blockLength; 
			var name : String;
			var type : uint;
			var props : AWDProperties;
			var mat :MaterialBase;
			var attributes : Object;
			var finalize : Boolean;
			var num_methods : uint;
			var methods_parsed : uint;
			
			name = parseVarStr();
			type = _body.readUnsignedByte();
			num_methods = _body.readUnsignedByte();
			
			// Read material numerical properties
			// (1=color, 2=bitmap url, 10=alpha, 11=alpha_blending, 12=alpha_threshold, 13=repeat)
			props = parseProperties({ 1:AWD_FIELD_INT32, 2:AWD_FIELD_BADDR, 
				10:AWD_FIELD_FLOAT32, 11:AWD_FIELD_BOOL, 
				12:AWD_FIELD_FLOAT32, 13:AWD_FIELD_BOOL });
			
			methods_parsed = 0;
			while (methods_parsed < num_methods) {
				var method_type : uint;
				
				method_type = _body.readUnsignedShort();
				parseProperties(new Object());
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
				//TODO: not used
				//var bmp : BitmapData;
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
				TextureMaterial(mat).alphaBlending = props.get(11, false);
				TextureMaterial(mat).alpha = props.get(10, 1.0);
			}
			
			mat.extra = attributes;
			SinglePassMaterialBase(mat).alphaThreshold = props.get(12, 0.0);
			mat.repeat = props.get(13, false);
			
			finalizeAsset(mat, name);
			
			return mat;
		}
		
		
		
		private function parseMaterial_v1(blockLength : uint) : MaterialBase
		{
			// TODO: not used
			blockLength = blockLength; 
			var name : String;
			var type : uint;
			var props : AWDProperties;
			var mat : MaterialBase;
			var attributes : Object;
			var finalize : Boolean;
			var num_methods : uint;
			var methods_parsed : uint;
			
			var normalTexture : Texture2DBase;
			var normalTex_addr : uint;
			var specTexture : Texture2DBase;
			var specTex_addr : uint;
			
			name = parseVarStr();
			type = _body.readUnsignedByte();
			num_methods = _body.readUnsignedByte();
			
			// Read material numerical properties
			// (1=color, 2=bitmap url, 10=alpha, 11=alpha_blending, 12=alpha_threshold, 13=repeat)
			props = parseProperties({ 	1:AWD_FIELD_UINT32, 	
				2:AWD_FIELD_BADDR,		
				3:AWD_FIELD_BADDR,		
				4:AWD_FIELD_UINT8,		
				5:AWD_FIELD_BOOL,
				6:AWD_FIELD_BOOL,		
				7:AWD_FIELD_BOOL,		
				8:AWD_FIELD_BOOL,		
				9:AWD_FIELD_UINT8,		
				10:AWD_FIELD_FLOAT32, 
				11:AWD_FIELD_BOOL, 		
				12:AWD_FIELD_FLOAT32, 	
				13:AWD_FIELD_BOOL,		
				15:AWD_FIELD_FLOAT32,	
				16:AWD_FIELD_UINT32, 
				17:AWD_FIELD_BADDR,		
				18:AWD_FIELD_FLOAT32, 	
				19:AWD_FIELD_FLOAT32,	
				20:AWD_FIELD_UINT32, 	
				21:AWD_FIELD_BADDR,
				22:AWD_FIELD_BADDR});	
			
			
			//MaterialProperties
			// 1 color - 				used for ColorMaterials/ColorMultiPassMaterials
			// 2 texture - 				used for TextureMaterials/TextureMultiPassMaterials
			// 3 normalMap - 			used for SinglePassBaseMaterial/MultiPassBaseMaterial
			// 4 isSingle - 			0: singlepass, 1:Multipass, 2:skybox
			// 5 smooth - 				used for BaseMaterial
			// 6 mipmap - 				used for BaseMaterial
			// 7 bothSides - 			used for BaseMaterial
			// 8 alphaPremultiplied - 	used for BaseMaterial
			// 9 blendMode - 			used for BaseMaterial
			// 10 alpha - 				used for SinglePassBaseMaterials only
			// 11 alpha-Blending - 		used for SinglePassBaseMaterials only
			// 12 alphaThreshold - 		used for SinglePassBaseMaterial/MultiPassBaseMaterial
			// 13 repeat - 				used for BaseMaterial
			// 14 diffuse-Level - 		NOT USED IN THIS VERSION
			// 15 ambient - 			used for SinglePassBaseMaterial/MultiPassBaseMaterial
			// 16 ambientColor - 		used for SinglePassBaseMaterial/MultiPassBaseMaterial
			// 18 ambient-textur - 		used for TextureMaterial/TextureMultiPassMaterial
			// 17 specular - 			used for SinglePassBaseMaterial/MultiPassBaseMaterial
			// 19 gloss - 				used for SinglePassBaseMaterial/MultiPassBaseMaterial
			// 20 specularColor - 		used for SinglePassBaseMaterial/MultiPassBaseMaterial
			// 21 specular-texture - 	used for SinglePassBaseMaterial/MultiPassBaseMaterial			
			
			
			var isSingle:Boolean=props.get(4,0);			
			
			if(_debug)trace("type = " + type);
			if(_debug)trace("spezialType = " + isSingle);
			if (type == 1) { // Color material
				var color : uint = color = props.get(1, 0xcccccc);
				if (isSingle==1){	//	MultiPassMaterial
					mat = new ColorMultiPassMaterial(color);}
				else {	//	SinglePassMaterial
					mat = new ColorMaterial(color, props.get(10, 1.0));
					ColorMaterial(mat).alphaBlending=props.get(11,false);
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
				
				if (isSingle==1){	// MultiPassMaterial
					mat = new TextureMultiPassMaterial(texture);
					if (ambientTexture) {TextureMultiPassMaterial(mat).ambientTexture = ambientTexture;}		
				}
				else {	//	SinglePassMaterial
					mat = new TextureMaterial(texture);
					if (ambientTexture) {TextureMaterial(mat).ambientTexture = ambientTexture;}
					TextureMaterial(mat).alpha=props.get(10,1.0);
					TextureMaterial(mat).alphaBlending = props.get(11, false);
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
			
			
			var lightPickerAddr:int=props.get(22,0);
			if (lightPickerAddr>0){
				MaterialBase(mat).lightPicker=_blocks[lightPickerAddr].data;
			}
			MaterialBase(mat).smooth=props.get(5,true);
			MaterialBase(mat).mipmap=props.get(6,true);
			MaterialBase(mat).bothSides=props.get(7,false);
			MaterialBase(mat).alphaPremultiplied=props.get(8,false);
			MaterialBase(mat).blendMode=blendModeDic[props.get(9, 0)];
			MaterialBase(mat).repeat=props.get(13, true);
			
			if (isSingle==0){	// this is a multiPass material
				
				if (normalTexture) {	SinglePassMaterialBase(mat).normalMap = normalTexture;}
				SinglePassMaterialBase(mat).alphaThreshold=props.get(12, 0.0);
				SinglePassMaterialBase(mat).ambient=props.get(15,1.0);
				SinglePassMaterialBase(mat).ambientColor=props.get(16,0xffffff);
				SinglePassMaterialBase(mat).specular=props.get(18,1.0);
				SinglePassMaterialBase(mat).gloss=props.get(19,50);
				SinglePassMaterialBase(mat).specularColor=props.get(20,0xffffff);
				if (specTexture) {		SinglePassMaterialBase(mat).specularMap = specTexture;}
				
			}
			else {	// this is a singleMaterial
				
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
			//trace("num_methods = "+num_methods)
			// trace: material methods: this can be: multiple shadingMethods, one shadowMethod (SharedMethodBlock), multiple effectsMethods (SharedMethodBlock)
			while (methods_parsed < num_methods) {
				var method_type : uint;				
				method_type = _body.readUnsignedShort();
				props = parseProperties({ 	1130:AWD_FIELD_BADDR	});	
				if (method_type==999){
					// to do: check if this SharedMethodBlock is a ShadowMethod, and if it allready has been created ( ShadowMethods will be created when creating a light that casts shadows)
					if (_blocks[props.get(1130,0)].data is EffectMethodBase)SinglePassMaterialBase(mat).addMethod(_blocks[props.get(1130,0)].data);
				}
				else{
					// to do: if method_type!=999 this method must be a ShadingMethod, and must be created and applied.
					// composite Methods will allways appear later in order than theyre basemethods, 
					// so first we will apply the baseMethod, than we for example the mat.diffuseMethod as baseMethod for a DiffuseCompositeMethod
				}
				parseUserAttributes();
				methods_parsed+=1;
			}
			
			
			
			attributes = parseUserAttributes();
			//mat.extra = attributes;
			
			finalizeAsset(mat, name);
			
			
			return mat;
		}
		
		
		private function parseSharedMethodBlock(blockLength : uint, block : AWDBlock) : ShadingMethodBase
		{
			// TODO: not used
			blockLength = blockLength; 
			var type : uint;
			var data_len : uint;
			var asset:ShadingMethodBase;
			
			block.name = parseVarStr();
			if(_debug)trace("blockname = "+block.name);
			asset=parseSharedMethodList(); 
			// Ignore for now
			parseUserAttributes();
			block.data=asset;
			if (asset is EffectMethodBase){
				finalizeAsset(EffectMethodBase(asset), block.name);}
			if (asset is ShadowMapMethodBase){
				finalizeAsset(ShadowMapMethodBase(asset), block.name);}
			
			
			return asset;
		}
		
		// this functions reads a Method found in a SharedMethod-Block - possible Method-Types: EffectMethods / ShadowMethod
		private function parseSharedMethodList() :ShadingMethodBase
		{
			
			var methodType:uint = _body.readUnsignedShort();
			var shadingMethodReturn:Object;
			var props:Object;
			// to do: reduce number of properties (
			props = parseProperties({ 	1:AWD_FIELD_COLOR, 	2:AWD_FIELD_COLOR,	3:AWD_FIELD_FLOAT32,100:AWD_FIELD_BADDR,101:AWD_FIELD_BADDR,102:AWD_FIELD_BADDR,103:AWD_FIELD_BADDR,104:AWD_FIELD_BADDR,
				105:AWD_FIELD_BADDR,201:AWD_FIELD_BOOL,202:AWD_FIELD_BOOL,203:AWD_FIELD_BOOL,204:AWD_FIELD_BOOL,1001:AWD_FIELD_MTX4x4,1101:AWD_FIELD_FLOAT32,1102:AWD_FIELD_FLOAT32,1103:AWD_FIELD_FLOAT32,1104:AWD_FIELD_FLOAT32,
				1105:AWD_FIELD_COLOR,1106:AWD_FIELD_FLOAT32,1107:AWD_FIELD_FLOAT32,1108:AWD_FIELD_FLOAT32,1109:AWD_FIELD_FLOAT32,1110:AWD_FIELD_FLOAT32,1111:AWD_FIELD_FLOAT32,1112:AWD_FIELD_FLOAT32,
				1113:AWD_FIELD_FLOAT32,1114:AWD_FIELD_FLOAT32,1115:AWD_FIELD_FLOAT32,1116:AWD_FIELD_FLOAT32,1117:AWD_FIELD_FLOAT32,1118:AWD_FIELD_FLOAT32,1119:AWD_FIELD_FLOAT32,1120:AWD_FIELD_FLOAT32,1121:AWD_FIELD_FLOAT32,
				1121:AWD_FIELD_FLOAT32,1122:AWD_FIELD_FLOAT32,1123:AWD_FIELD_UINT8,1124:AWD_FIELD_UINT8,1125:AWD_FIELD_UINT8,1127:AWD_FIELD_UINT32,1128:AWD_FIELD_UINT32,1129:AWD_FIELD_INT32,
				1130:AWD_FIELD_BADDR,1140:AWD_FIELD_FLOAT32,1141:AWD_FIELD_FLOAT32,1142:AWD_FIELD_FLOAT32, 1143:AWD_FIELD_FLOAT32, 1144:AWD_FIELD_FLOAT32,1145:AWD_FIELD_FLOAT32, 1146:AWD_FIELD_FLOAT32,
				1501:AWD_FIELD_FLOAT32,1502:AWD_FIELD_FLOAT32,1503:AWD_FIELD_FLOAT32,1504:AWD_FIELD_FLOAT32	});	
			
			switch (methodType){
				// Effect Methods
				case 401://ColorMatrix
					// to do - map the values to a colormatrix
					shadingMethodReturn=new ColorMatrixMethod(props.get(1001,new Matrix3D()));
					break;
				case 402://ColorTransform
					shadingMethodReturn=new ColorTransformMethod();
					var offSetColor:uint=props.get(1105,0x00000000);// to do: apply offsetColor into colortransform
					var newColorTransform:ColorTransform=new ColorTransform(props.get(1102,1),props.get(1103,1),props.get(1104,1),props.get(1101,1),0,0,0,0);
					ColorTransformMethod(shadingMethodReturn).colorTransform=newColorTransform;
					
					break;
				case 403://EnvMap
					if (props.get(101,0)>0){
						shadingMethodReturn=new EnvMapMethod(_blocks[props.get(101,0)].data,props.get(3,1));
						if (props.get(1146,0)>0)EnvMapMethod(shadingMethodReturn).mask=_blocks[props.get(1146,0)].data;
					}
					break;
				case 404://LightMapMethod
					if (props.get(100,0)>0){
						shadingMethodReturn=new LightMapMethod(_blocks[props.get(100,0)].data,blendModeDic[props.get(1124,10)]);//usesecondaryUV not set
					}
					break;
				case 405://ProjectiveTextureMethod
					if (props.get(102,0)>0){
						shadingMethodReturn=new ProjectiveTextureMethod(_blocks[props.get(102,0)].data,blendModeDic[props.get(1124,10)]);
					}
					break;
				case 406://RimLightMethod
					shadingMethodReturn=new RimLightMethod(props.get(1,0xffffff),props.get(1107,0.4),props.get(1106,2));//blendMode
					break;
				case 407://AlphaMaskMethod
					if (props.get(100,0)>0){
						shadingMethodReturn=new AlphaMaskMethod(_blocks[props.get(100,0)].data,props.get(203,false));
					}
					break;
				case 408://RefractionEnvMapMethod
					if (props.get(101,0)>0){
						shadingMethodReturn=new RefractionEnvMapMethod(_blocks[props.get(101,0)].data,props.get(1129,0.1),props.get(1111,0.01),props.get(1143,0.01),props.get(1144,0.01));
					}
					break;
				case 409://OutlineMethod
					shadingMethodReturn=new OutlineMethod(props.get(2,0x00000000),props.get(1121,1),props.get(202,true),props.get(201,false));
					break;
				case 410://FresnelEnvMapMethod
					if (props.get(101,0)>0){
						shadingMethodReturn=new FresnelEnvMapMethod(props.get(101,0),props.get(3,1));
					}
					break;
				case 411://FogMethod
					shadingMethodReturn=new FogMethod(props.get(1122,0),props.get(1145,1000),props.get(1,0x808080));
					break;
				
				//shadowMapMethods
				// shadowMethods cannot be created at this point, since there constructior might needs access to a light, that has not been parsed yet
				// to do: add the needed data to tha AWDBlock, and finalize when needed (by light)
				/*
				case 1001://CascadeShadowMapMethod
					//shadingMethodReturn=new CascadeShadowMapMethod(_blocks[props.get(1130,0)].data);
					break;
				case 1002://NearShadowMapMethod
					//shadingMethodReturn=new NearShadowMapMethod(_blocks[props.get(1130,0)].data);
					break;
				case 1003://NearShadowMapMethod
					//shadingMethodReturn=new FilteredShadowMapMethod(_blocks[props.get(1130,0)].data);
					break;
				case 1004://DitheredShadowMapMethod
					//shadingMethodReturn=new DitheredShadowMapMethod(_blocks[props.get(1130,0)].data);
					break;
				case 1005://SoftShadowMapMethod
					//shadingMethodReturn=new SoftShadowMapMethod(_blocks[props.get(1130,0)].data);
					break;
				case 1006://HardShadowMapMethod
					//shadingMethodReturn=new HardShadowMapMethod(_blocks[props.get(1130,0)].data);
					//shadingMethodReturn=new NearShadowMapMethod(_blocks[props.get(1130,0)].data);
					break;
				*/
				
				
			}
			parseUserAttributes();
			return shadingMethodReturn as ShadingMethodBase;
		}
		private function parseLight(blockLength : uint) : LightBase
		{
			var name : String;
			var par_id : uint;
			var lightType : uint;
			var numShadowMethods : uint;
			var mtx : Matrix3D;
			var light : LightBase;
			var parent : ObjectContainer3D;
			var props : AWDProperties;
			
			par_id = _body.readUnsignedInt();
			mtx = parseMatrix3D();
			name = parseVarStr();
			lightType=_body.readUnsignedByte();
			numShadowMethods=_body.readUnsignedByte();
			props = parseProperties({ 	1:AWD_FIELD_FLOAT32, 	2:AWD_FIELD_FLOAT32,	3:AWD_FIELD_COLOR,		4:AWD_FIELD_FLOAT32,
				5:AWD_FIELD_FLOAT32,	6:AWD_FIELD_BOOL,		7:AWD_FIELD_COLOR,		8:AWD_FIELD_FLOAT32});	
			
			if (lightType==1){
				light=new PointLight();
				PointLight(light).radius = props.get(1,90000);
				PointLight(light).fallOff = props.get(2,100000);
			}
			if (lightType==2){
				light=new DirectionalLight();
			}
			light.transform = mtx;
			
			light.color = props.get(3,0xffffff);
			light.specular = props.get(4,1.0);
			light.diffuse = props.get(5,1.0);
			light.castsShadows = props.get(6,false);
			light.ambientColor = props.get(7,0xffffff);
			light.ambient =  props.get(8,0.0);
			
			// read List of Methods for the Lights - Method can either be a ShadowMapMethod in a SharedMethodBlock, or a ShadowMapper for the specific type of light
			var methods_parsed:uint = 0;
			while (methods_parsed < numShadowMethods) {
				var method_type : uint;				
				method_type = _body.readUnsignedShort();
				props = parseProperties({ 	1130:AWD_FIELD_BADDR, 1125:AWD_FIELD_UINT8, 1120:AWD_FIELD_FLOAT32, 1128:AWD_FIELD_UINT16	});	
				if (method_type==999){
					if(_debug)trace("SharedMethod = "+_blocks[props.get(1125,0)].data);// to do: create and apply ShadowMapMethod
				}
				if ((method_type==1501)&&(light is DirectionalLight)){
					if(_debug)trace("to do create and apply  DirectionalShadowMapper= "+_blocks[props.get(1130,0)].data);// to do: create and apply DirectionalShadowMapper
				}
				if ((method_type==1502)&&(light is DirectionalLight)){
					if(_debug)trace("to do create and apply  NearDirectionalShadowMapper= "+_blocks[props.get(1130,0)].data);// to do: create and apply NearDirectionalShadowMapper					
				}
				if ((method_type==1503)&&(light is DirectionalLight)){
					if(_debug)trace("to do create and apply  CascadeShadowMapper= "+_blocks[props.get(1130,0)].data);// to do: create and apply CascadeShadowMapper					
				}
				if ((method_type==1504)&&(light is PointLight)){
					if(_debug)trace("to do create and apply  CubeMapShadowMapper= "+_blocks[props.get(1130,0)].data);// to do: create and apply CubeMapShadowMapper					
				}
				parseUserAttributes();
				methods_parsed+=1;
			}
			
			
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
			parseUserAttributes();
			finalizeAsset(lightPick, lightPick.name);
			
			return lightPick
		}
		private function parseTexture(blockLength : uint, block : AWDBlock) : Texture2DBase
		{
			// TODO: not used
			blockLength = blockLength; 
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
			// TODO: not used
			blockLength = blockLength; 
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
			// TODO: not used
			blockLength = blockLength; 
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
			
			parseProperties(null);
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
			parseProperties(null);
			mesh.extra = parseUserAttributes();
			
			finalizeAsset(mesh, name);
			
			return mesh;
		}
		
		
		private function parseMeshData(blockLength : uint) : Geometry
		{
			var name : String;
			var geom : Geometry;
			var num_subs : uint;
			var subs_parsed : uint;
			var props : AWDProperties;
			var bsm : Matrix3D;
			
			// Read name and sub count
			name = parseVarStr();
			num_subs = _body.readUnsignedShort();
			
			// Read optional properties
			props = parseProperties({ 1:AWD_FIELD_MTX4x4 }); 
			
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
						case AWD_FIELD_STRING:
							attr_val = _body.readUTFBytes(attr_len);
							break;
						default:
							attr_val = 'unimplemented attribute type '+attr_type;
							_body.position += attr_len;
							break;
					}
					
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
				case AWD_FIELD_INT8:
					elem_len = 1;
					read_func = _body.readByte;
					break;
				case AWD_FIELD_INT16:
					elem_len = 2;
					read_func = _body.readShort;
					break;
				case AWD_FIELD_INT32:
					elem_len = 4;
					read_func = _body.readInt;
					break;
				case AWD_FIELD_BOOL:
				case AWD_FIELD_UINT8:
					elem_len = 1;
					read_func = _body.readUnsignedByte;
					break;
				case AWD_FIELD_UINT16:
					elem_len = 2;
					read_func = _body.readUnsignedShort;
					break;
				case AWD_FIELD_UINT32:
				case AWD_FIELD_BADDR:
					elem_len = 4;
					read_func = _body.readUnsignedInt;
					break;
				case AWD_FIELD_FLOAT32:
					elem_len = 4;
					read_func = _body.readFloat;
					break;
				case AWD_FIELD_FLOAT64:
					elem_len = 8;
					read_func = _body.readDouble;
					break;
				case AWD_FIELD_VECTOR2x1:
				case AWD_FIELD_VECTOR3x1:
				case AWD_FIELD_VECTOR4x1:
				case AWD_FIELD_MTX3x2:
				case AWD_FIELD_MTX3x3:
				case AWD_FIELD_MTX4x3:
				case AWD_FIELD_MTX4x4:
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


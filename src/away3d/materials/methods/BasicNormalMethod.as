package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;

	/**
	 * BasicNormalMethod is the default method for standard tangent-space normal mapping.
	 */
	public class BasicNormalMethod extends ShadingMethodBase
	{
		private var _texture:Texture2DBase;
		private var _useTexture:Boolean;
		protected var _normalTextureRegister:ShaderRegisterElement;

		/**
		 * if you want to use compressed normalmaps, it highly recommended to encode them as texture with alpha channel
		 * in green channel you need to store X value
		 * in alpha channgel you need to store Y value
		 * Away3D restores the z value inside GPU program
		 */
		private var _useAlphaCompression:Boolean = false;

		/**
		 * Creates a new BasicNormalMethod object.
		 */
		public function BasicNormalMethod()
		{
			super();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			vo.needsUV = Boolean(_texture);
		}

		/**
		 * Indicates whether or not this method outputs normals in tangent space. Override for object-space normals.
		 */
		arcane function get tangentSpace():Boolean
		{
			return true;
		}
		
		/**
		 * Indicates if the normal method output is not based on a texture (if not, it will usually always return true)
		 * Override if subclasses are different.
		 */
		arcane function get hasOutput():Boolean
		{
			return _useTexture;
		}

		/**
		 * @inheritDoc
		 */
		override public function copyFrom(method:ShadingMethodBase):void
		{
			normalMap = BasicNormalMethod(method).normalMap;
		}

		/**
		 * The texture containing the normals per pixel.
		 */
		public function get normalMap():Texture2DBase
		{
			return _texture;
		}
		
		public function set normalMap(value:Texture2DBase):void
		{
			if (Boolean(value) != _useTexture ||
				(value && _texture && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format))) {
				invalidateShaderProgram();
			}

			_useTexture = Boolean(value);
			_texture = value;

			if(_texture && _texture.format == COMPRESSED_ALPHA) {
				_useAlphaCompression = true;
			}
		}

		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData():void
		{
			super.cleanCompilationData();
			_normalTextureRegister = null;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			if (_texture)
				_texture = null;
		}


		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			if (vo.texturesIndex >= 0)
				stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		arcane function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			_normalTextureRegister = regCache.getFreeTextureReg();
			vo.texturesIndex = _normalTextureRegister.index;
			var code:String = "";
			code += getTex2DSampleCode(vo, targetReg, _normalTextureRegister, _texture);
			if(_useAlphaCompression) {
				code += "add " + targetReg + ".xy, " + targetReg + ".yw, " + targetReg + ".yw\n"
				code += "sub " + targetReg + ".xy, " + targetReg + ".xy, " + _sharedRegisters.commons + ".ww\n"
				code += "mul " + targetReg + ".zw, " + targetReg + ".xy, " + targetReg + ".xy\n"
				code += "add " + targetReg + ".w, " + targetReg + ".w, " + targetReg + ".z\n"
				code += "sub " + targetReg + ".z, " + _sharedRegisters.commons + ".w, " + targetReg + ".w\n"
				code += "sqt " + targetReg + ".z, " + targetReg + ".z\n"
			}else{
				code += "add " + targetReg + ".xyz, " + targetReg + ".xyz, " + targetReg + ".xyz\n";
				code += "sub " + targetReg + ".xyz, " + targetReg + ".xyz, " + _sharedRegisters.commons + ".www\n";
				code += "nrm " + targetReg + ".xyz, " + targetReg + ".xyz\n";
			}

			return code;
		}

		public function get useAlphaCompression():Boolean {
			return _useAlphaCompression;
		}

		public function set useAlphaCompression(value:Boolean):void {
			if(_useAlphaCompression == value) return;
			_useAlphaCompression = value;
			invalidateShaderProgram();
		}
	}
}

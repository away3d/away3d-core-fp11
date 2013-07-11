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
			return getTex2DSampleCode(vo, targetReg, _normalTextureRegister, _texture) +
				"sub " + targetReg + ".xyz, " + targetReg + ".xyz, " + _sharedRegisters.commons + ".xxx	\n" +
				"nrm " + targetReg + ".xyz, " + targetReg + ".xyz							\n";
		}
	}
}

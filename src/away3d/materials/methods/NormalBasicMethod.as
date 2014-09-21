package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.utils.ShaderCompilerHelper;
    import away3d.textures.Texture2DBase;

    import flash.display3D.Context3DMipFilter;
    import flash.display3D.Context3DTextureFilter;

    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.Context3DWrapMode;

    use namespace arcane;

	/**
	 * BasicNormalMethod is the default method for standard tangent-space normal mapping.
	 */
	public class NormalBasicMethod extends ShadingMethodBase
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
		public function NormalBasicMethod()
		{
			super();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
            methodVO.needsUV = _useTexture;
		}

        /**
         * Indicates whether or not this method outputs normals in tangent space. Override for object-space normals.
         */
        arcane function outputsTangentNormals():Boolean
        {
            return true;
        }


        /**
         * @inheritDoc
         */
        override public function copyFrom(method:ShadingMethodBase):void
        {
            normalMap = NormalBasicMethod(method).normalMap;
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

            if(_texture && _texture.format == Context3DTextureFormat.COMPRESSED_ALPHA) {
                _useAlphaCompression = true;
            }
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
		arcane override function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
			if (methodVO.texturesIndex >= 0) {
                stage.context3D.setSamplerStateAt(methodVO.texturesIndex, shaderObject.repeatTextures? Context3DWrapMode.REPEAT:Context3DWrapMode.CLAMP, shaderObject.useSmoothTextures? Context3DTextureFilter.LINEAR : Context3DTextureFilter.NEAREST, shaderObject.useMipmapping? Context3DMipFilter.MIPLINEAR : Context3DMipFilter.MIPNONE);
                stage.activateTexture(methodVO.texturesIndex, this._texture);
            }
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			_normalTextureRegister = registerCache.getFreeTextureReg();
            methodVO.texturesIndex = _normalTextureRegister.index;
			var code:String = "";
			code += ShaderCompilerHelper.getTex2DSampleCode(targetReg, sharedRegisters, this._normalTextureRegister, this._texture, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping);
			if(_useAlphaCompression) {
				code += "add " + targetReg + ".xy, " + targetReg + ".yw, " + targetReg + ".yw\n";
				code += "sub " + targetReg + ".xy, " + targetReg + ".xy, " + sharedRegisters.commons + ".ww\n";
				code += "mul " + targetReg + ".zw, " + targetReg + ".xy, " + targetReg + ".xy\n";
				code += "add " + targetReg + ".w, " + targetReg + ".w, " + targetReg + ".z\n";
				code += "sub " + targetReg + ".z, " + sharedRegisters.commons + ".w, " + targetReg + ".w\n";
				code += "sqt " + targetReg + ".z, " + targetReg + ".z\n";
			}else{
				code += "add " + targetReg + ".xyz, " + targetReg + ".xyz, " + targetReg + ".xyz\n";
				code += "sub " + targetReg + ".xyz, " + targetReg + ".xyz, " + sharedRegisters.commons + ".www\n";
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

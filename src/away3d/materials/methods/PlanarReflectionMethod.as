package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.PlanarReflectionTexture;
	
	use namespace arcane;
	
	/**
	 * PlanarReflectionMethod is a material method that adds reflections from a PlanarReflectionTexture object.
	 *
	 * @see away3d.textures.PlanarReflectionTexture
	 */
	public class PlanarReflectionMethod extends EffectMethodBase
	{
		private var _texture:PlanarReflectionTexture;
		private var _alpha:Number = 1;
		private var _normalDisplacement:Number = 0;
		
		/**
		 * Creates a new PlanarReflectionMethod
		 * @param texture The PlanarReflectionTexture used to render the reflected view.
		 * @param alpha The reflectivity of the surface.
		 */
		public function PlanarReflectionMethod(texture:PlanarReflectionTexture, alpha:Number = 1)
		{
			super();
			_texture = texture;
			_alpha = alpha;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			methodVO.needsProjection = true;
            methodVO.needsNormals = _normalDisplacement > 0;
		}
		
		/**
		 * The reflectivity of the surface.
		 */
		public function get alpha():Number
		{
			return _alpha;
		}
		
		public function set alpha(value:Number):void
		{
			_alpha = value;
		}
		
		/**
		 * The PlanarReflectionTexture used to render the reflected view.
		 */
		public function get texture():PlanarReflectionTexture
		{
			return _texture;
		}
		
		public function set texture(value:PlanarReflectionTexture):void
		{
			_texture = value;
		}
		
		/**
		 * The amount of displacement on the surface, for use with water waves.
		 */
		public function get normalDisplacement():Number
		{
			return _normalDisplacement;
		}
		
		public function set normalDisplacement(value:Number):void
		{
			if (_normalDisplacement == value)
				return;
			if (_normalDisplacement == 0 || value == 0)
				invalidateShaderProgram();
			_normalDisplacement = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
			var index:int = methodVO.fragmentConstantsIndex;
			stage.activateTexture(methodVO.texturesIndex, _texture);
			shaderObject.fragmentConstantData[index] = _texture.textureRatioX*.5;
			shaderObject.fragmentConstantData[uint(index + 1)] = _texture.textureRatioY*.5;
			shaderObject.fragmentConstantData[uint(index + 3)] = _alpha;
			if (_normalDisplacement > 0) {
				shaderObject.fragmentConstantData[uint(index + 2)] = _normalDisplacement;
				shaderObject.fragmentConstantData[uint(index + 4)] = .5 + _texture.textureRatioX*.5 - 1/_texture.width;
				shaderObject.fragmentConstantData[uint(index + 5)] = .5 + _texture.textureRatioY*.5 - 1/_texture.height;
				shaderObject.fragmentConstantData[uint(index + 6)] = .5 - _texture.textureRatioX*.5 + 1/_texture.width;
				shaderObject.fragmentConstantData[uint(index + 7)] = .5 - _texture.textureRatioY*.5 + 1/_texture.height;
			}
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var textureReg:ShaderRegisterElement = registerCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
			var dataReg:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
			
			var filter:String = shaderObject.useSmoothTextures? "linear" : "nearest";
			var code:String;
			methodVO.texturesIndex = textureReg.index;
			methodVO.fragmentConstantsIndex = dataReg.index*4;
			// fc0.x = .5
			
			var projectionReg:ShaderRegisterElement = sharedRegisters.projectionFragment;
			
			registerCache.addFragmentTempUsages(temp, 1);
			
			code = "div " + temp + ", " + projectionReg + ", " + projectionReg + ".w\n" +
				"mul " + temp + ", " + temp + ", " + dataReg + "\n" +
				"add " + temp + ", " + temp + ", fc0.xx\n";
			
			if (_normalDisplacement > 0) {
				var dataReg2:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
				code += "add " + temp + ".w, " + projectionReg + ".w, " + "fc0.w\n" +
					"sub " + temp + ".z, fc0.w, " + sharedRegisters.normalFragment + ".y\n" +
					"div " + temp + ".z, " + temp + ".z, " + temp + ".w\n" +
					"mul " + temp + ".z, " + dataReg + ".z, " + temp + ".z\n" +
					"add " + temp + ".x, " + temp + ".x, " + temp + ".z\n" +
					"min " + temp + ".x, " + temp + ".x, " + dataReg2 + ".x\n" +
					"max " + temp + ".x, " + temp + ".x, " + dataReg2 + ".z\n";
			}
			
			var temp2:ShaderRegisterElement = registerCache.getFreeFragmentSingleTemp();
			code += "tex " + temp + ", " + temp + ", " + textureReg + " <2d," + filter + ">\n" +
				"sub " + temp2 + ", " + temp + ".w,  fc0.x\n" +
				"kil " + temp2 + "\n" +
				"sub " + temp + ", " + temp + ", " + targetReg + "\n" +
				"mul " + temp + ", " + temp + ", " + dataReg + ".w\n" +
				"add " + targetReg + ", " + targetReg + ", " + temp + "\n";

            registerCache.removeFragmentTempUsage(temp);
			
			return code;
		}
	}
}

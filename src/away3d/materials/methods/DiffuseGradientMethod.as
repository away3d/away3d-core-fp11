package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderLightingObject;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.utils.ShaderCompilerHelper;
    import away3d.textures.Texture2DBase;
	
	use namespace arcane;
	
	/**
	 * GradientDiffuseMethod is an alternative to BasicDiffuseMethod in which the shading can be modulated with a gradient
	 * to introduce color-tinted shading as opposed to the single-channel diffuse strength. This can be used as a crude
	 * approximation to subsurface scattering (for instance, the mid-range shading for skin can be tinted red to similate
	 * scattered light within the skin attributing to the final colour)
	 */
	public class DiffuseGradientMethod extends DiffuseBasicMethod
	{
		private var _gradientTextureRegister:ShaderRegisterElement;
		private var _gradient:Texture2DBase;
		
		/**
		 * Creates a new GradientDiffuseMethod object.
		 * @param gradient A texture that contains the light colour based on the angle. This can be used to change
		 * the light colour due to subsurface scattering when the surface faces away from the light.
		 */
		public function DiffuseGradientMethod(gradient:Texture2DBase)
		{
			super();
			_gradient = gradient;
		}

		/**
		 * A texture that contains the light colour based on the angle. This can be used to change the light colour
		 * due to subsurface scattering when the surface faces away from the light.
		 */
		public function get gradient():Texture2DBase
		{
			return _gradient;
		}
		
		public function set gradient(value:Texture2DBase):void
		{
			if (value.hasMipMaps != _gradient.hasMipMaps || value.format != _gradient.format)
				invalidateShaderProgram();
			_gradient = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData():void
		{
			super.cleanCompilationData();
			_gradientTextureRegister = null;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPreLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String = super.getFragmentPreLightingCode(shaderObject, methodVO, registerCache, sharedRegisters);
			_isFirstLight = true;

			if (shaderObject.numLights > 0) {
				_gradientTextureRegister = registerCache.getFreeTextureReg();
				methodVO.secondaryTexturesIndex = _gradientTextureRegister.index;
			}
			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerLight(shaderObject:ShaderLightingObject, methodVO:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String = "";
			var t:ShaderRegisterElement;
			
			// write in temporary if not first light, so we can add to total diffuse colour
			if (_isFirstLight)
				t = _totalLightColorReg;
			else {
				t = registerCache.getFreeFragmentVectorTemp();
                registerCache.addFragmentTempUsages(t, 1);
			}
			
			code += "dp3 " + t + ".w, " + lightDirReg + ".xyz, " + sharedRegisters.normalFragment + ".xyz\n" +
				"mul " + t + ".w, " + t + ".w, " + sharedRegisters.commons + ".x\n" +
				"add " + t + ".w, " + t + ".w, " + sharedRegisters.commons + ".x\n" +
				"mul " + t + ".xyz, " + t + ".w, " + lightDirReg + ".w\n";
			
			if (_modulateMethod != null)
				code += _modulateMethod(shaderObject, methodVO, t, registerCache, sharedRegisters);
			
			code +=ShaderCompilerHelper.getTex2DSampleCode(t, sharedRegisters, _gradientTextureRegister, _gradient, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping, t, "clamp") +
				//					"mul " + t + ".xyz, " + t + ".xyz, " + t + ".w\n" +
				"mul " + t + ".xyz, " + t + ".xyz, " + lightColReg + ".xyz\n";
			
			if (!_isFirstLight) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + t + ".xyz\n";
				registerCache.removeFragmentTempUsage(t);
			}
			
			_isFirstLight = false;
			
			return code;
		}

		/**
		 * @inheritDoc
		 */
		override public function applyShadow(shaderObject:ShaderLightingObject, methodVO:MethodVO, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var t:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			
			return "mov " + t + ", " + sharedRegisters.shadowTarget + ".wwww\n" +
                    ShaderCompilerHelper.getTex2DSampleCode(t, sharedRegisters, _gradientTextureRegister, _gradient, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping, t, "clamp") +
				"mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
			super.activate(shaderObject, methodVO, stage);
            stage.activateTexture(methodVO.secondaryTexturesIndex, _gradient);
		}
	}
}

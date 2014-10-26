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
    import away3d.textures.CubeTextureBase;
	import away3d.textures.Texture2DBase;
	
	import flash.display3D.Context3D;
	
	use namespace arcane;

	/**
	 * FresnelEnvMapMethod provides a method to add fresnel-based reflectivity to an object using cube maps, which gets
	 * stronger as the viewing angle becomes more grazing.
	 */
	public class EffectFresnelEnvMapMethod extends EffectMethodBase
	{
		private var _cubeTexture:CubeTextureBase;
		private var _fresnelPower:Number = 5;
		private var _normalReflectance:Number = 0;
		private var _alpha:Number;
		private var _mask:Texture2DBase;

		/**
		 * Creates an FresnelEnvMapMethod object.
		 * @param envMap The environment map containing the reflected scene.
		 * @param alpha The reflectivity of the material.
		 */
		public function EffectFresnelEnvMapMethod(envMap:CubeTextureBase, alpha:Number = 1)
		{
			super();
			_cubeTexture = envMap;
			_alpha = alpha;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			methodVO.needsNormals = true;
			methodVO.needsView = true;
			methodVO.needsUV = _mask != null;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initConstants(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
            shaderObject.fragmentConstantData[methodVO.fragmentConstantsIndex + 3] = 1;
		}

		/**
		 * An optional texture to modulate the reflectivity of the surface.
		 */
		public function get mask():Texture2DBase
		{
			return _mask;
		}
		
		public function set mask(value:Texture2DBase):void
		{
			if (Boolean(value) != Boolean(_mask) ||
				(value && _mask && (value.hasMipMaps != _mask.hasMipMaps || value.format != _mask.format))) {
				invalidateShaderProgram();
			}
			_mask = value;
		}

		/**
		 * The power used in the Fresnel equation. Higher values make the fresnel effect more pronounced. Defaults to 5.
		 */
		public function get fresnelPower():Number
		{
			return _fresnelPower;
		}
		
		public function set fresnelPower(value:Number):void
		{
			_fresnelPower = value;
		}
		
		/**
		 * The cubic environment map containing the reflected scene.
		 */
		public function get envMap():CubeTextureBase
		{
			return _cubeTexture;
		}
		
		public function set envMap(value:CubeTextureBase):void
		{
			_cubeTexture = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
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
		 * The minimum amount of reflectance, ie the reflectance when the view direction is normal to the surface or light direction.
		 */
		public function get normalReflectance():Number
		{
			return _normalReflectance;
		}
		
		public function set normalReflectance(value:Number):void
		{
			_normalReflectance = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
			var data:Vector.<Number> = shaderObject.fragmentConstantData;
			var index:int = methodVO.fragmentConstantsIndex;

			data[index] = _alpha;
			data[index + 1] = _normalReflectance;
			data[index + 2] = _fresnelPower;
            stage.activateTexture(methodVO.texturesIndex, _cubeTexture);
			if (_mask)
                stage.activateTexture(methodVO.texturesIndex + 1, _mask);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var dataRegister:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
			var temp:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
			var code:String = "";
			var cubeMapReg:ShaderRegisterElement = registerCache.getFreeTextureReg();
			var viewDirReg:ShaderRegisterElement = sharedRegisters.viewDirFragment;
			var normalReg:ShaderRegisterElement = sharedRegisters.normalFragment;

            methodVO.texturesIndex = cubeMapReg.index;
            methodVO.fragmentConstantsIndex = dataRegister.index*4;

            registerCache.addFragmentTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = registerCache.getFreeFragmentVectorTemp();
			
			// r = V - 2(V.N)*N
			code += "dp3 " + temp + ".w, " + viewDirReg + ".xyz, " + normalReg + ".xyz		\n" +
				"add " + temp + ".w, " + temp + ".w, " + temp + ".w											\n" +
				"mul " + temp + ".xyz, " + normalReg + ".xyz, " + temp + ".w						\n" +
				"sub " + temp + ".xyz, " + temp + ".xyz, " + viewDirReg + ".xyz					\n" +
                ShaderCompilerHelper.getTexCubeSampleCode(temp, cubeMapReg, this._cubeTexture, shaderObject.useSmoothTextures, shaderObject.useMipmapping, temp) +
				"sub " + temp2 + ".w, " + temp + ".w, fc0.x									\n" +               	// -.5
				"kil " + temp2 + ".w\n" +	// used for real time reflection mapping - if alpha is not 1 (mock texture) kil output
				"sub " + temp + ", " + temp + ", " + targetReg + "											\n";
			
			// calculate fresnel term
			code += "dp3 " + viewDirReg + ".w, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" +   // dot(V, H)
				"sub " + viewDirReg + ".w, " + dataRegister + ".w, " + viewDirReg + ".w\n" +             // base = 1-dot(V, H)
				
				"pow " + viewDirReg + ".w, " + viewDirReg + ".w, " + dataRegister + ".z\n" +             // exp = pow(base, 5)
				
				"sub " + normalReg + ".w, " + dataRegister + ".w, " + viewDirReg + ".w\n" +             // 1 - exp
				"mul " + normalReg + ".w, " + dataRegister + ".y, " + normalReg + ".w\n" +             // f0*(1 - exp)
				"add " + viewDirReg + ".w, " + viewDirReg + ".w, " + normalReg + ".w\n" +          // exp + f0*(1 - exp)
				
				// total alpha
				"mul " + viewDirReg + ".w, " + dataRegister + ".x, " + viewDirReg + ".w\n";
			
			if (_mask) {
				var maskReg:ShaderRegisterElement = registerCache.getFreeTextureReg();
				code += ShaderCompilerHelper.getTex2DSampleCode(temp2, sharedRegisters, maskReg, _mask, shaderObject.useSmoothTextures, shaderObject.repeatTextures, shaderObject.useMipmapping) +
					"mul " + viewDirReg + ".w, " + temp2 + ".x, " + viewDirReg + ".w\n";
			}
			
			// blend
			code += "mul " + temp + ", " + temp + ", " + viewDirReg + ".w						\n" +
				"add " + targetReg + ", " + targetReg + ", " + temp + "						\n";

            registerCache.removeFragmentTempUsage(temp);
			
			return code;
		}
	}
}

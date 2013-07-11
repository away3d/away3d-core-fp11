package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;
	import away3d.textures.Texture2DBase;
	
	import flash.display3D.Context3D;
	
	use namespace arcane;

	/**
	 * EnvMapMethod provides a material method to perform reflection mapping using cube maps.
	 */
	public class EnvMapMethod extends EffectMethodBase
	{
		private var _cubeTexture:CubeTextureBase;
		private var _alpha:Number;
		private var _mask:Texture2DBase;

		/**
		 * Creates an EnvMapMethod object.
		 * @param envMap The environment map containing the reflected scene.
		 * @param alpha The reflectivity of the surface.
		 */
		public function EnvMapMethod(envMap:CubeTextureBase, alpha:Number = 1)
		{
			super();
			_cubeTexture = envMap;
			_alpha = alpha;
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
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			vo.needsNormals = true;
			vo.needsView = true;
			vo.needsUV = _mask != null;
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
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			var context:Context3D = stage3DProxy._context3D;
			vo.fragmentData[vo.fragmentConstantsIndex] = _alpha;
			context.setTextureAt(vo.texturesIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
			if (_mask)
				context.setTextureAt(vo.texturesIndex + 1, _mask.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var dataRegister:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code:String = "";
			var cubeMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			vo.texturesIndex = cubeMapReg.index;
			vo.fragmentConstantsIndex = dataRegister.index*4;
			
			regCache.addFragmentTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			
			// r = I - 2(I.N)*N
			code += "dp3 " + temp + ".w, " + _sharedRegisters.viewDirFragment + ".xyz, " + _sharedRegisters.normalFragment + ".xyz		\n" +
				"add " + temp + ".w, " + temp + ".w, " + temp + ".w											\n" +
				"mul " + temp + ".xyz, " + _sharedRegisters.normalFragment + ".xyz, " + temp + ".w						\n" +
				"sub " + temp + ".xyz, " + temp + ".xyz, " + _sharedRegisters.viewDirFragment + ".xyz					\n" +
				getTexCubeSampleCode(vo, temp, cubeMapReg, _cubeTexture, temp) +
				"sub " + temp2 + ".w, " + temp + ".w, fc0.x									\n" +               	// -.5
				"kil " + temp2 + ".w\n" +	// used for real time reflection mapping - if alpha is not 1 (mock texture) kil output
				"sub " + temp + ", " + temp + ", " + targetReg + "											\n";
			
			if (_mask) {
				var maskReg:ShaderRegisterElement = regCache.getFreeTextureReg();
				code += getTex2DSampleCode(vo, temp2, maskReg, _mask, _sharedRegisters.uvVarying) +
					"mul " + temp + ", " + temp2 + ", " + temp + "\n";
			}
			code += "mul " + temp + ", " + temp + ", " + dataRegister + ".x										\n" +
				"add " + targetReg + ", " + targetReg + ", " + temp + "										\n";
			
			regCache.removeFragmentTempUsage(temp);
			
			return code;
		}
	}
}

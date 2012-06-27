package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class FresnelEnvMapMethod extends EffectMethodBase
	{
		private var _cubeTexture : CubeTextureBase;
		private var _fresnelPower : Number = 5;
		private var _normalReflectance : Number = 0;
		private var _alpha : Number;

		public function FresnelEnvMapMethod(envMap : CubeTextureBase, alpha : Number = 1)
		{
			super();
			_cubeTexture = envMap;
			_alpha = alpha;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsNormals = true;
			vo.needsView = true;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			vo.fragmentData[vo.fragmentConstantsIndex+3] = 1;
		}

		public function get fresnelPower() : Number
		{
			return _fresnelPower;
		}

		public function set fresnelPower(value : Number) : void
		{
			_fresnelPower = value;
		}

		/**
		 * The cube environment map to use for the diffuse lighting.
		 */
		public function get envMap() : CubeTextureBase
		{
			return _cubeTexture;
		}

		public function set envMap(value : CubeTextureBase) : void
		{
			_cubeTexture = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
		}

		public function get alpha() : Number
		{
			return _alpha;
		}

		public function set alpha(value : Number) : void
		{
			_alpha = value;
		}

		/**
		 * The minimum amount of reflectance, ie the reflectance when the view direction is normal to the surface or light direction.
		 */
		public function get normalReflectance() : Number
		{
			return _normalReflectance;
		}

		public function set normalReflectance(value : Number) : void
		{
			_normalReflectance = value;
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			data[index] = _alpha;
			data[index+1] = _normalReflectance;
			data[index+2] = _fresnelPower;
			stage3DProxy.setTextureAt(vo.texturesIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var dataRegister : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : String = "";
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			vo.texturesIndex = cubeMapReg.index;
			vo.fragmentConstantsIndex = dataRegister.index*4;

			// r = V - 2(V.N)*N
			code += "dp3 " + temp + ".w, " + _viewDirFragmentReg + ".xyz, " + _normalFragmentReg + ".xyz		\n" +
					"add " + temp + ".w, " + temp + ".w, " + temp + ".w											\n" +
					"mul " + temp + ".xyz, " + _normalFragmentReg + ".xyz, " + temp + ".w						\n" +
					"sub " + temp + ".xyz, " + _viewDirFragmentReg + ".xyz, " + temp + ".xyz					\n" +
					"neg " + temp + ".xyz, " + temp + ".xyz														\n" +
					"tex " + temp + ", " + temp + ", " + cubeMapReg + " <cube, " + (vo.useSmoothTextures? "linear" : "nearest") + ",miplinear,clamp>\n" +
					"sub " + temp + ", " + temp + ", " + targetReg + "											\n";

			// calculate fresnel term
			code += "dp3 " + _viewDirFragmentReg+".w, " + _viewDirFragmentReg+".xyz, " + _normalFragmentReg+".xyz\n" +   // dot(V, H)
            		"sub " + _viewDirFragmentReg+".w, " + dataRegister+".w, " + _viewDirFragmentReg+".w\n" +             // base = 1-dot(V, H)

					"pow " + _viewDirFragmentReg+".w, " + _viewDirFragmentReg+".w, " + dataRegister+".z\n" +             // exp = pow(base, 5)

					"sub " + _normalFragmentReg+".w, " + dataRegister+".w, " + _viewDirFragmentReg+".w\n" +             // 1 - exp
					"mul " + _normalFragmentReg+".w, " + dataRegister+".y, " + _normalFragmentReg+".w\n" +             // f0*(1 - exp)
					"add " + _viewDirFragmentReg+".w, " + _viewDirFragmentReg+".w, " + _normalFragmentReg+".w\n" +          // exp + f0*(1 - exp)

					// total alpha
					"mul " + _viewDirFragmentReg+".w, " + dataRegister+".x, " + _viewDirFragmentReg+".w\n" +

					// blend
					"mul " + temp + ", " + temp + ", " + _viewDirFragmentReg + ".w						\n" +
					"add " + targetReg + ".xyzw, " + targetReg+".xyzw, " + temp + ".xyzw						\n";


			return code;
		}
	}
}

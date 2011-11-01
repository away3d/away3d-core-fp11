/**
 * Author: David Lenaerts
 */
package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class FresnelEnvMapMethod extends ShadingMethodBase
	{
		private var _cubeTexture : CubeTextureBase;
		private var _cubeMapIndex : int;
		private var _data : Vector.<Number>;
		private var _dataIndex : int;

		public function FresnelEnvMapMethod(envMap : CubeTextureBase, alpha : Number = 1)
		{
			super(true, true, false);
			_cubeTexture = envMap;
			_data = new Vector.<Number>(4, true);
			_data[0] = alpha;
			_data[1] = 0;
			_data[2] = 5; // exponent
            _data[3] = 1;
		}

		public function get fresnelPower() : Number
		{
			return _data[2];
		}

		public function set fresnelPower(value : Number) : void
		{
			_data[2] = value;
		}

		arcane override function reset() : void
		{
			super.reset();
			_dataIndex = -1;
			_cubeMapIndex = -1;
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
			return _data[0];
		}

		public function set alpha(value : Number) : void
		{
			_data[0] = value;
		}

		/**
		 * The minimum amount of reflectance, ie the reflectance when the view direction is normal to the surface or light direction.
		 */
		public function get normalReflectance() : Number
		{
			return _data[1];
		}

		public function set normalReflectance(value : Number) : void
		{
			_data[1] = value;
		}

		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _dataIndex, _data, 1);
			stage3DProxy.setTextureAt(_cubeMapIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
		}

//		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
//		{
//			stage3DProxy.setTextureAt(_cubeMapIndex, null);
//		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var dataRegister : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : String = "";
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			_cubeMapIndex = cubeMapReg.index;
			_dataIndex = dataRegister.index;

			// r = V - 2(V.N)*N
			code += "dp3 " + temp + ".w, " + _viewDirFragmentReg + ".xyz, " + _normalFragmentReg + ".xyz		\n" +
					"add " + temp + ".w, " + temp + ".w, " + temp + ".w											\n" +
					"mul " + temp + ".xyz, " + _normalFragmentReg + ".xyz, " + temp + ".w						\n" +
					"sub " + temp + ".xyz, " + _viewDirFragmentReg + ".xyz, " + temp + ".xyz					\n" +
					"neg " + temp + ".xyz, " + temp + ".xyz														\n" +
					"tex " + temp + ", " + temp + ", " + cubeMapReg + " <cube, " + (_smooth? "linear" : "nearest") + ",miplinear,clamp>\n" +
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

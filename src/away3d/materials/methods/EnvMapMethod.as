/**
 * Author: David Lenaerts
 */
package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.CubeTexture3DProxy;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.CubeMap;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class EnvMapMethod extends ShadingMethodBase
	{
		private var _cubeTexture : CubeTexture3DProxy;
		private var _cubeMapIndex : int;
		private var _data : Vector.<Number>;
		private var _dataIndex : int;

		public function EnvMapMethod(envMap : CubeMap, alpha : Number = 1)
		{
			super(true, true, false);
			_cubeTexture = new CubeTexture3DProxy();
			_cubeTexture.cubeMap = envMap;
			_data = new Vector.<Number>(4, true);
			_data[0] = alpha;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose(deep : Boolean) : void
		{
			_cubeTexture.dispose(deep);
		}

		public function get alpha() : Number
		{
			return _data[0];
		}

		public function set alpha(value : Number) : void
		{
			_data[0] = value;
		}

		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _dataIndex, _data, 1);
			stage3DProxy.setTextureAt(_cubeMapIndex, _cubeTexture.getTextureForContext(stage3DProxy));
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
					"tex " + temp.toString() + ", " + temp.toString() + ", " + cubeMapReg + " <cube, " + (_smooth? "linear" : "nearest") + ",clamp>\n" +
					"sub " + temp + ".xyz, " + temp + ".xyz, " + targetReg + ".xyz								\n" +
					"mul " + temp + ".xyz, " + temp + ".xyz, " + dataRegister + ".x								\n" +
					"add " + targetReg + ".xyz, " + targetReg+".xyz, " + temp + ".xyz							\n";

			return code;
		}
	}
}

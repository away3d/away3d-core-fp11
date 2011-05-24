/**
 * Author: David Lenaerts
 */
package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.CubeTexture3DProxy;
	import away3d.materials.utils.AGAL;
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

		arcane override function activate(context : Context3D, contextIndex : uint) : void
		{
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _dataIndex, _data, 1);
			context.setTextureAt(_cubeMapIndex, _cubeTexture.getTextureForContext(context, contextIndex));
		}

		arcane override function deactivate(context : Context3D) : void
		{
			context.setTextureAt(_cubeMapIndex, null);
		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var dataRegister : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : String = "";
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			_cubeMapIndex = cubeMapReg.index;
			_dataIndex = dataRegister.index;

			// r = V - 2(V.N)*N
			code += AGAL.dp3(temp+".w", _viewDirFragmentReg+".xyz", _normalFragmentReg+".xyz");
			code += AGAL.add(temp+".w", temp+".w", temp+".w");
			code += AGAL.mul(temp+".xyz", _normalFragmentReg+".xyz", temp+".w");
			code += AGAL.sub(temp+".xyz", _viewDirFragmentReg+".xyz", temp+".xyz");
			code += AGAL.neg(temp+".xyz", temp+".xyz");
			code += AGAL.sample(temp.toString(), temp.toString(), "cube", cubeMapReg.toString(), _smooth? "bilinear" : "nearestNoMip", "clamp");
			code += AGAL.sub(temp+".xyz", temp+".xyz", targetReg+".xyz");
			code += AGAL.mul(temp+".xyz", temp+".xyz", dataRegister+".x");
			code += AGAL.add(targetReg+".xyz", targetReg+".xyz", temp+".xyz");

			return code;
		}
	}
}

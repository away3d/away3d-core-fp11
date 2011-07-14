package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class FogMethod extends ShadingMethodBase
	{
		private var _fogDistance : Number;
		private var _fogColor : uint;
		private var _fogDataIndex : int;
		private var _fogData : Vector.<Number>;

		public function FogMethod(fogDistance : Number, fogColor : uint = 0x808080)
		{
			super(false, true, false);
			_fogData = new Vector.<Number>(4, true);
			this.fogDistance = fogDistance;
			this.fogColor = fogColor;
		}

		public function get fogDistance() : Number
		{
			return _fogDistance;
		}

		public function set fogDistance(value : Number) : void
		{
			_fogDistance = value;
			_fogData[3] = 1/value;
		}

		public function get fogColor() : uint
		{
			return _fogColor;
		}

		public function set fogColor(value : uint) : void
		{
			_fogColor = value;
			_fogData[0] = ((value >> 16) & 0xff)/0xff;
			_fogData[1] = ((value >> 8) & 0xff)/0xff;
			_fogData[2] = (value & 0xff)/0xff;
		}

		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _fogDataIndex, _fogData, 1);
		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var fogDataRegister : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : String = "";
			_fogDataIndex = fogDataRegister.index;

			code += "dp3 " + temp + ".w, " + _viewDirVaryingReg+".xyz, " + _viewDirVaryingReg + ".xyz		\n" + 	// dist²
					"sqt " + temp + ".w, " + temp + ".w										\n" + 	// dist²
					"mul " + temp + ".w, " + temp + ".w, " + fogDataRegister + ".w			\n" + 			// fogRatio = dist²/maxDist²
					"neg " + temp + ".w, " + temp + ".w										\n" +			// fogRatio = dist²/maxDist²
					"exp " + temp + ".w, " + temp + ".w										\n" + 			// fogRatio = dist²/maxDist²
					"sub " + temp + ".xyz, " + targetReg + ".xyz, " + fogDataRegister + ".xyz\n" + 			// (fogColor- col)
					"mul " + temp + ".xyz, " + temp+".xyz, " + temp + ".w					\n" +			// (fogColor- col)*fogRatio
					"add " + targetReg + ".xyz, " + fogDataRegister + ".xyz, " + temp + ".xyz\n";			// fogRatio*(fogColor- col) + col


			return code;
		}
	}
}

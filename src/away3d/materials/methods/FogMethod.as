package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class FogMethod extends ShadingMethodBase
	{
		private var _minDistance : Number = 0;
		private var _maxDistance : Number = 1000;
		private var _fogColor : uint;
		private var _fogDataIndex : int;
		private var _fogData : Vector.<Number>;

		public function FogMethod(minDistance : Number, maxDistance : Number, fogColor : uint = 0x808080)
		{
			super(false, true, false);
			_fogData = new Vector.<Number>(8, true);
			_fogData[3] = 1;
			this.minDistance = minDistance;
			this.maxDistance = maxDistance;
			this.fogColor = fogColor;
		}

		arcane override function reset() : void
		{
			super.reset();
			_fogDataIndex = -1;
		}

		public function get minDistance() : Number
		{
			return _minDistance;
		}

		public function set minDistance(value : Number) : void
		{
			_minDistance = value;
			_fogData[4] = _minDistance;
			_fogData[5] = 1/(_maxDistance-_minDistance);
		}

		public function get maxDistance() : Number
		{
			return _maxDistance;
		}

		public function set maxDistance(value : Number) : void
		{
			_maxDistance = value;
			_fogData[5] = 1/(_maxDistance-_minDistance);
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
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _fogDataIndex, _fogData, 2);
		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var fogColor : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var fogData : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : String = "";
			_fogDataIndex = fogColor.index;

			code += "dp3 " + temp + ".w, " + _viewDirVaryingReg+".xyz	, " + _viewDirVaryingReg+".xyz\n" + 	// dist²
					"sqt " + temp + ".w, " + temp + ".w										\n" + 	// dist
					"sub " + temp + ".w, " + temp + ".w, " + fogData + ".x					\n" +
					"mul " + temp + ".w, " + temp + ".w, " + fogData + ".y					\n" +
					"sat " + temp + ".w, " + temp + ".w										\n" +
					"sub " + temp + ".xyz, " + fogColor + ".xyz, " + targetReg + ".xyz\n" + 			// (fogColor- col)
					"mul " + temp + ".xyz, " + temp + ".xyz, " + temp + ".w					\n" +			// (fogColor- col)*fogRatio
					"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz\n";			// fogRatio*(fogColor- col) + col


			return code;
		}
	}
}

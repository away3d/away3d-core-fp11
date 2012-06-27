package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class FogMethod extends EffectMethodBase
	{
		private var _minDistance : Number = 0;
		private var _maxDistance : Number = 1000;
		private var _fogColor : uint;
		private var _fogR : Number;
		private var _fogG : Number;
		private var _fogB : Number;

		public function FogMethod(minDistance : Number, maxDistance : Number, fogColor : uint = 0x808080)
		{
			super();
			this.minDistance = minDistance;
			this.maxDistance = maxDistance;
			this.fogColor = fogColor;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsView = true;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			data[index+3] = 1;
			data[index+6] = 0;
			data[index+7] = 0;
		}

		public function get minDistance() : Number
		{
			return _minDistance;
		}

		public function set minDistance(value : Number) : void
		{
			_minDistance = value;
		}

		public function get maxDistance() : Number
		{
			return _maxDistance;
		}

		public function set maxDistance(value : Number) : void
		{
			_maxDistance = value;
		}

		public function get fogColor() : uint
		{
			return _fogColor;
		}

		public function set fogColor(value : uint) : void
		{
			_fogColor = value;
			_fogR = ((value >> 16) & 0xff)/0xff;
			_fogG = ((value >> 8) & 0xff)/0xff;
			_fogB = (value & 0xff)/0xff;
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			data[index] = _fogR;
			data[index+1] = _fogG;
			data[index+2] = _fogB;
			data[index+4] = _minDistance;
			data[index+5] = 1/(_maxDistance-_minDistance);
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var fogColor : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var fogData : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : String = "";
			vo.fragmentConstantsIndex = fogColor.index*4;

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

package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	use namespace arcane;

	/**
	 * FogMethod provides a method to add distance-based fog to a material.
	 */
	public class FogMethod extends EffectMethodBase
	{
		private var _minDistance:Number = 0;
		private var _maxDistance:Number = 1000;
		private var _fogColor:uint;
		private var _fogR:Number;
		private var _fogG:Number;
		private var _fogB:Number;

		/**
		 * Creates a new FogMethod object.
		 * @param minDistance The distance from which the fog starts appearing.
		 * @param maxDistance The distance at which the fog is densest.
		 * @param fogColor The colour of the fog.
		 */
		public function FogMethod(minDistance:Number, maxDistance:Number, fogColor:uint = 0x808080)
		{
			super();
			this.minDistance = minDistance;
			this.maxDistance = maxDistance;
			this.fogColor = fogColor;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			vo.needsProjection = true;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initConstants(vo:MethodVO):void
		{
			var data:Vector.<Number> = vo.fragmentData;
			var index:int = vo.fragmentConstantsIndex;
			data[index + 3] = 1;
			data[index + 6] = 0;
			data[index + 7] = 0;
		}

		/**
		 * The distance from which the fog starts appearing.
		 */
		public function get minDistance():Number
		{
			return _minDistance;
		}
		
		public function set minDistance(value:Number):void
		{
			_minDistance = value;
		}

		/**
		 * The distance at which the fog is densest.
		 */
		public function get maxDistance():Number
		{
			return _maxDistance;
		}
		
		public function set maxDistance(value:Number):void
		{
			_maxDistance = value;
		}

		/**
		 * The colour of the fog.
		 */
		public function get fogColor():uint
		{
			return _fogColor;
		}
		
		public function set fogColor(value:uint):void
		{
			_fogColor = value;
			_fogR = ((value >> 16) & 0xff)/0xff;
			_fogG = ((value >> 8) & 0xff)/0xff;
			_fogB = (value & 0xff)/0xff;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			var data:Vector.<Number> = vo.fragmentData;
			var index:int = vo.fragmentConstantsIndex;
			data[index] = _fogR;
			data[index + 1] = _fogG;
			data[index + 2] = _fogB;
			data[index + 4] = _minDistance;
			data[index + 5] = 1/(_maxDistance - _minDistance);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var fogColor:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var fogData:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code:String = "";
			vo.fragmentConstantsIndex = fogColor.index*4;
			
			code += "sub " + temp2 + ".w, " + _sharedRegisters.projectionFragment + ".z, " + fogData + ".x          \n" +
				"mul " + temp2 + ".w, " + temp2 + ".w, " + fogData + ".y					\n" +
				"sat " + temp2 + ".w, " + temp2 + ".w										\n" +
				"sub " + temp + ", " + fogColor + ", " + targetReg + "\n" + 			// (fogColor- col)
				"mul " + temp + ", " + temp + ", " + temp2 + ".w					\n" +			// (fogColor- col)*fogRatio
				"add " + targetReg + ", " + targetReg + ", " + temp + "\n"; // fogRatio*(fogColor- col) + col
			
			regCache.removeFragmentTempUsage(temp);
			
			return code;
		}
	}
}

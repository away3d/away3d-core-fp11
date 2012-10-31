package away3d.animators.nodes
{
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.states.ParticleFlickerByTimeGlobalState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.ColorTransform;
	
	/**
	 * ...
	 */
	public class ParticleFlickerByTimeGlobalNode extends GlobalParticleNodeBase
	{
		public static const NAME:String = "ParticleFlickerByTimeGlobalNode";
		public static const START_MULTIPLIER_CONSTANT_REGISTER:int = 0;
		public static const DELTA_MULTIPLIER_CONSTANT_REGISTER:int = 1;
		public static const START_OFFSET_CONSTANT_REGISTER:int = 2;
		public static const DELTA_OFFSET_CONSTANT_REGISTER:int = 3;
		public static const CYCLE_CONSTANT_REGISTER:int = 4;
		
		private var _hasMult:Boolean;
		private var _hasOffset:Boolean;
		private var _hasPhaseAngle:Boolean;
		
		private var _minColor:ColorTransform;
		private var _maxColor:ColorTransform;
		private var _cycle:Number;
		private var _phaseAngle:Number;
		
		private var _startMultiplierData:Vector.<Number>;
		private var _deltaMultiplierData:Vector.<Number>;
		private var _startOffsetData:Vector.<Number>;
		private var _deltaOffsetData:Vector.<Number>;
		private var _cycleData:Vector.<Number>;
		
		public function ParticleFlickerByTimeGlobalNode(minColor:ColorTransform, maxColor:ColorTransform, cycle:Number, hasMult:Boolean = true, hasOffset:Boolean = false, phaseAngle:Number = 0)
		{
			super(NAME);
			_stateClass = ParticleFlickerByTimeGlobalState;
			
			_minColor = minColor;
			_maxColor = maxColor;
			_cycle = cycle;
			_hasMult = hasMult;
			_hasOffset = hasOffset;
			if (phaseAngle != 0)
				_hasPhaseAngle = true;
			_phaseAngle = phaseAngle;
			
			reset();
		}
		
		private function reset():void
		{
			_startMultiplierData = Vector.<Number>([(_minColor.redMultiplier + _maxColor.redMultiplier) / 2, (_minColor.greenMultiplier + _maxColor.greenMultiplier) / 2, (_minColor.blueMultiplier + _maxColor.blueMultiplier) / 2, (_minColor.alphaMultiplier + _maxColor.alphaMultiplier) / 2]);
			_deltaMultiplierData = Vector.<Number>([(_maxColor.redMultiplier - _minColor.redMultiplier) / 2, (_maxColor.greenMultiplier - _minColor.greenMultiplier) / 2, (_maxColor.blueMultiplier - _minColor.blueMultiplier) / 2, (_maxColor.alphaMultiplier - _minColor.alphaMultiplier) / 2]);
			_startOffsetData = Vector.<Number>([(_minColor.redOffset + _maxColor.redOffset) / (255 * 2), (_minColor.greenOffset + _maxColor.greenOffset) / (255 * 2), (_minColor.blueOffset + _maxColor.blueOffset) / (255 * 2), (_minColor.alphaOffset + _maxColor.alphaOffset) / (255 * 2)]);
			_deltaOffsetData = Vector.<Number>([(_maxColor.redOffset - _minColor.redOffset) / (255 * 2), (_maxColor.greenOffset - _minColor.greenOffset) / (255 * 2), (_maxColor.blueOffset - _minColor.blueOffset) / (255 * 2), (_maxColor.alphaOffset - _minColor.alphaOffset) / (255 * 2)]);
			_cycleData = Vector.<Number>([Math.PI * 2 / _cycle, _phaseAngle * Math.PI / 180, 0, 0]);
		}
		
		override public function processAnimationSetting(setting:ParticleAnimationSetting):void
		{
			setting.hasColorNode = true;
		}
		
		public function get needMultiple():Boolean
		{
			return _hasMult;
		}
		
		public function get needOffset():Boolean
		{
			return _hasOffset;
		}
		
		public function get startMultiplierData():Vector.<Number>
		{
			return _startMultiplierData;
		}
		
		public function get deltaMultiplierData():Vector.<Number>
		{
			return _deltaMultiplierData;
		}
		
		public function get startOffsetData():Vector.<Number>
		{
			return _startOffsetData;
		}
		
		public function get deltaOffsetData():Vector.<Number>
		{
			return _deltaOffsetData;
		}
		
		public function get cycleData():Vector.<Number>
		{
			return _cycleData;
		}
		
		public function get minColor():ColorTransform
		{
			return _minColor;
		}
		
		public function set minColor(value:ColorTransform):void
		{
			_minColor = value;
			reset();
		}
		
		public function get maxColor():ColorTransform
		{
			return _maxColor;
		}
		
		public function set maxColor(value:ColorTransform):void
		{
			_maxColor = value;
			reset();
		}
		
		public function get cycle():Number
		{
			return _cycle;
		}
		
		public function set cycle(value:Number):void
		{
			_cycle = value;
			reset();
		}
		
		public function get phaseAngle():Number
		{
			return _phaseAngle;
		}
		
		override public function getAGALFragmentCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, animationRegisterCache:AnimationRegisterCache):String
		{
			var code:String = "";
			if (animationRegisterCache.needFragmentAnimation)
			{
				var cycleConst:ShaderRegisterElement = animationRegisterCache.getFreeFragmentConstant();
				animationRegisterCache.setRegisterIndex(this, CYCLE_CONSTANT_REGISTER, cycleConst.index);
				
				var temp:ShaderRegisterElement = animationRegisterCache.getFreeFragmentVectorTemp();
				animationRegisterCache.addFragmentTempUsages(temp,1);
				var sin:ShaderRegisterElement = animationRegisterCache.getFreeFragmentSingleTemp();
				animationRegisterCache.removeFragmentTempUsage(temp);
				
				code += "mul " + sin.toString() + "," + animationRegisterCache.fragmentTime.toString() + "," + cycleConst.toString() + ".x\n";
				if (_hasPhaseAngle)
				{
					code += "add " + sin.toString() + "," + sin.toString() + "," + cycleConst.toString() + ".y\n";
				}
				code += "sin " + sin.toString() + "," + sin.toString() + "\n";
				
				if (_hasMult)
				{
					var startMultiplierConst:ShaderRegisterElement = animationRegisterCache.getFreeFragmentConstant();
					animationRegisterCache.setRegisterIndex(this, START_MULTIPLIER_CONSTANT_REGISTER, startMultiplierConst.index);
					var deltaMultiplierConst:ShaderRegisterElement = animationRegisterCache.getFreeFragmentConstant();
					animationRegisterCache.setRegisterIndex(this, DELTA_MULTIPLIER_CONSTANT_REGISTER, deltaMultiplierConst.index);
				
					code += "mul " + temp.toString() + "," + deltaMultiplierConst.toString() + "," +  sin.toString()+ "\n";
					code += "add " + temp.toString() + "," + temp.toString() + "," + startMultiplierConst.toString() + "\n";
					code += "mul " + animationRegisterCache.colorTarget.toString() +"," + temp.toString() + "," + animationRegisterCache.colorTarget.toString() + "\n";
				}
				if (_hasOffset)
				{
					var startOffsetConst:ShaderRegisterElement = animationRegisterCache.getFreeFragmentConstant();
					animationRegisterCache.setRegisterIndex(this, START_OFFSET_CONSTANT_REGISTER, startOffsetConst.index);
					var deltaOffsetConst:ShaderRegisterElement = animationRegisterCache.getFreeFragmentConstant();
					animationRegisterCache.setRegisterIndex(this, DELTA_OFFSET_CONSTANT_REGISTER, deltaOffsetConst.index);
				
					code += "mul " + temp.toString() + "," + deltaOffsetConst.toString() +"," + sin.toString() + "\n";
					code += "add " + temp.toString() + "," + temp.toString() +"," + startOffsetConst.toString() + "\n";
					code += "add " + animationRegisterCache.colorTarget.toString() +"," +temp.toString() + "," + animationRegisterCache.colorTarget.toString() + "\n";
				}
			}
			return code;
		}
	
	}

}
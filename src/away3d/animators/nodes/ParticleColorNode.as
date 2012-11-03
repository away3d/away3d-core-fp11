package away3d.animators.nodes
{
	import flash.geom.Vector3D;
	import away3d.animators.data.ParticleParameter;
	import away3d.arcane;
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.states.ParticleColorState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.ColorTransform;
	
	
	use namespace arcane;
	
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleColorNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const START_MULTIPLIER_INDEX:uint = 0;
		
		/** @private */
		arcane static const DELTA_MULTIPLIER_INDEX:uint = 1;
		
		/** @private */
		arcane static const START_OFFSET_INDEX:uint = 2;
		
		/** @private */
		arcane static const DELTA_OFFSET_INDEX:uint = 3;
		
		/** @private */
		arcane static const CYCLE_INDEX:uint = 4;
		
		/** @private */
		arcane var _hasMult:Boolean;
		
		/** @private */
		arcane var _hasOffset:Boolean;
		
		/** @private */
		arcane var _hasCycle:Boolean;
		
		/** @private */
		arcane var _startMultiplierData:Vector3D;
		
		/** @private */
		arcane var _deltaMultiplierData:Vector3D;
		
		/** @private */
		arcane var _startOffsetData:Vector3D;
		
		/** @private */
		arcane var _deltaOffsetData:Vector3D;
		
		/** @private */
		arcane var _cycleData:Vector3D;
		
		private var _startColor:ColorTransform;
		private var _endColor:ColorTransform;
		private var _cycleSpeed:Number;
		private var _cyclePhase:Number;
		
		/**
		 * Used to set the color node into local property mode.
		 */
		public static const LOCAL:uint = 0;
		
		/**
		 * Used to set the color node into global property mode.
		 */
		public static const GLOBAL:uint = 1;
				
		/**
		 * Reference for color node properties on a single particle (when in local property mode).
		 * Expects a <code>ColorTransform</code> object representing the color transform applied to the particle.
		 */
		public static const COLOR_COLORTRANSFORM:String = "ColorColorTransform";
		
		/**
		 * Defines the start color transform of the node, when in global mode.
		 */
		public function get startColor():ColorTransform
		{
			return _startColor;
		}
		
		public function set startColor(value:ColorTransform):void
		{
			_startColor = value;
			
			updateColorData();
		}
		
		/**
		 * Defines the end color transform of the node, when in global mode.
		 */
		public function get endColor():ColorTransform
		{
			return _endColor;
		}
		public function set endColor(value:ColorTransform):void
		{
			_endColor = value;
			
			updateColorData();
		}
		
		/**
		 * Defines the cycle speed of the node in revolutions per second, when in global mode. Defaults to zero.
		 */
		public function get cycleSpeed():Number
		{
			return _cycleSpeed;
		}
		public function set cycleSpeed(value:Number):void
		{
			_cycleSpeed = value;
			
			updateColorData();
		}
		
		/**
		 * Defines the cycle phase of the node in degrees, when in global mode. Defaults to zero.
		 */
		public function get cyclePhase():Number
		{
			return _cyclePhase;
		}
		public function set cyclePhase(value:Number):void
		{
			_cyclePhase = value;
			
			updateColorData();
		}
				
		/**
		 * Creates a new <code>ParticleColorNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation defaults to acting on local properties of a particle or global properties of the node.
		 * @param    [optional] startColor      Defines the start color transform of the node, when in global mode.
		 * @param    [optional] endColor        Defines the end color transform of the node, when in global mode.
		 * @param    [optional] cycleSpeed      Defines the cycle speed of the node in revolutions per second, when in global mode. Defaults to zero.
		 * @param    [optional] cyclePhase      Defines the cycle phase of the node in degrees, when in global mode. Defaults to zero.
		 */
		public function ParticleColorNode(mode:uint, startColor:ColorTransform = null, endColor:ColorTransform = null, cycleSpeed:Number = 0, cyclePhase:Number = 0)
		{
			_stateClass = ParticleColorState;
			
			_startColor = startColor || new ColorTransform();
			_endColor = endColor || new ColorTransform();
			_cycleSpeed = cycleSpeed;
			_cyclePhase = cyclePhase;
			
			updateColorData();
			
			//TODO: adjust the data length for local particle properties when only multipliers or offsets are used.
			super("ParticleColorNode" + mode, mode, 8);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):void
		{
			particleAnimationSet.hasColorNode = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var code:String = "";
			if (animationRegisterCache.needFragmentAnimation && _mode == LOCAL)
			{
				if (_hasMult) {
					var multiplierAtt:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
					animationRegisterCache.setRegisterIndex(this, START_MULTIPLIER_INDEX, multiplierAtt.index);
					var multiplierVary:ShaderRegisterElement = animationRegisterCache.getFreeVarying();
					animationRegisterCache.setRegisterIndex(this, DELTA_MULTIPLIER_INDEX, multiplierVary.index);
					
					code += "mov " + multiplierVary + "," + multiplierAtt + "\n";
				} if (_hasOffset) {
					var offsetAtt:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
					animationRegisterCache.setRegisterIndex(this, START_OFFSET_INDEX, offsetAtt.index);
					var offsetVary:ShaderRegisterElement = animationRegisterCache.getFreeVarying();
					animationRegisterCache.setRegisterIndex(this, DELTA_OFFSET_INDEX, offsetVary.index);
					
					code += "mov " + offsetVary + "," + offsetAtt + "\n";
				}
			}
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALFragmentCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var code:String = "";
			if (animationRegisterCache.needFragmentAnimation)
			{
				var temp:ShaderRegisterElement = animationRegisterCache.getFreeFragmentVectorTemp();
				
				if (_mode == LOCAL) {
					if (_hasMult) {
						var multiplierVary:ShaderRegisterElement = new ShaderRegisterElement("v", animationRegisterCache.getRegisterIndex(this, DELTA_MULTIPLIER_INDEX));
						code += "mul " + animationRegisterCache.colorTarget +"," + multiplierVary + "," + animationRegisterCache.colorTarget + "\n";
					}
					
					if (_hasOffset) {
						var offsetVary:ShaderRegisterElement = new ShaderRegisterElement("v", animationRegisterCache.getRegisterIndex(this, DELTA_OFFSET_INDEX));
						code += "add " + animationRegisterCache.colorTarget +"," +offsetVary + "," + animationRegisterCache.colorTarget + "\n";
					}
				} else {
					if (_cycleSpeed) {
						var cycleConst:ShaderRegisterElement = animationRegisterCache.getFreeFragmentConstant();
						animationRegisterCache.setRegisterIndex(this, CYCLE_INDEX, cycleConst.index);
						
						animationRegisterCache.addFragmentTempUsages(temp,1);
						var sin:ShaderRegisterElement = animationRegisterCache.getFreeFragmentSingleTemp();
						animationRegisterCache.removeFragmentTempUsage(temp);
						
						code += "mul " + sin + "," + animationRegisterCache.fragmentTime + "," + cycleConst + ".x\n";
						
						if (_cyclePhase)
							code += "add " + sin + "," + sin + "," + cycleConst + ".y\n";
						
						code += "sin " + sin + "," + sin + "\n";
					}
					
					if (_hasMult) {
						var startMultiplierConst:ShaderRegisterElement = animationRegisterCache.getFreeFragmentConstant();
						var deltaMultiplierConst:ShaderRegisterElement = animationRegisterCache.getFreeFragmentConstant();
						animationRegisterCache.setRegisterIndex(this, START_MULTIPLIER_INDEX, startMultiplierConst.index);
						animationRegisterCache.setRegisterIndex(this, DELTA_MULTIPLIER_INDEX, deltaMultiplierConst.index);
						code += "mul " + temp + "," + deltaMultiplierConst + "," + ((_cycleSpeed)? sin : animationRegisterCache.fragmentLife) + "\n";
						code += "add " + temp + "," + temp + "," + startMultiplierConst + "\n";
						code += "mul " + animationRegisterCache.colorTarget +"," + temp + "," + animationRegisterCache.colorTarget + "\n";
					}
					
					if (_hasOffset) {
						var startOffsetConst:ShaderRegisterElement = animationRegisterCache.getFreeFragmentConstant();
						var deltaOffsetConst:ShaderRegisterElement = animationRegisterCache.getFreeFragmentConstant();
						animationRegisterCache.setRegisterIndex(this, START_OFFSET_INDEX, startOffsetConst.index);
						animationRegisterCache.setRegisterIndex(this, DELTA_OFFSET_INDEX, deltaOffsetConst.index);
						code += "mul " + temp + "," + deltaOffsetConst +"," + ((_cycleSpeed)? sin : animationRegisterCache.fragmentLife) + "\n";
						code += "add " + temp + "," + temp +"," + startOffsetConst + "\n";
						code += "add " + animationRegisterCache.colorTarget +"," +temp + "," + animationRegisterCache.colorTarget + "\n";
					}
				}
			}
			
			return code;
		}
		
		private function updateColorData():void
		{
			_hasMult = !(startColor.redMultiplier == 1 && startColor.greenMultiplier == 1 && startColor.blueMultiplier == 1 && startColor.alphaMultiplier == 1 && endColor.redMultiplier == 1 && endColor.greenMultiplier == 1 && endColor.blueMultiplier == 1 && endColor.alphaMultiplier == 1);
			_hasOffset = !(startColor.redOffset == 0 && startColor.greenOffset == 0 && startColor.blueOffset == 0 && startColor.alphaOffset == 0 && endColor.redOffset == 0 && endColor.greenOffset == 0 && endColor.blueOffset == 0 && endColor.alphaOffset == 0);
			_hasCycle = !(_cycleSpeed == 0);
			
			if (_hasCycle) {
				_cycleData = new Vector3D(Math.PI * 2 / _cycleSpeed, _cyclePhase * Math.PI / 180, 0, 0);
				if (_hasMult) {
					_startMultiplierData = new Vector3D((_startColor.redMultiplier + _endColor.redMultiplier) / 2, (_startColor.greenMultiplier + _endColor.greenMultiplier) / 2, (_startColor.blueMultiplier + _endColor.blueMultiplier) / 2, (_startColor.alphaMultiplier + _endColor.alphaMultiplier) / 2);
					_deltaMultiplierData = new Vector3D((_endColor.redMultiplier - _startColor.redMultiplier) / 2, (_endColor.greenMultiplier - _startColor.greenMultiplier) / 2, (_endColor.blueMultiplier - _startColor.blueMultiplier) / 2, (_endColor.alphaMultiplier - _startColor.alphaMultiplier) / 2);
				}
				
				if (_hasOffset) {
					_startOffsetData = new Vector3D((_startColor.redOffset + _endColor.redOffset) / (255 * 2), (_startColor.greenOffset + _endColor.greenOffset) / (255 * 2), (_startColor.blueOffset + _endColor.blueOffset) / (255 * 2), (_startColor.alphaOffset + _endColor.alphaOffset) / (255 * 2));
					_deltaOffsetData = new Vector3D((_endColor.redOffset - _startColor.redOffset) / (255 * 2), (_endColor.greenOffset - _startColor.greenOffset) / (255 * 2), (_endColor.blueOffset - _startColor.blueOffset) / (255 * 2), (_endColor.alphaOffset - _startColor.alphaOffset) / (255 * 2));
				}
			} else {
				if (_hasMult) {
					_startMultiplierData = new Vector3D(_startColor.redMultiplier , _startColor.greenMultiplier , _startColor.blueMultiplier , _startColor.alphaMultiplier);
					_deltaMultiplierData = new Vector3D((_endColor.redMultiplier - _startColor.redMultiplier) , (_endColor.greenMultiplier - _startColor.greenMultiplier) , (_endColor.blueMultiplier - _startColor.blueMultiplier) , (_endColor.alphaMultiplier - _startColor.alphaMultiplier));
				}
				
				if (_hasOffset) {
					_startOffsetData = new Vector3D(_startColor.redOffset / 255, _startColor.greenOffset / 255, _startColor.blueOffset / 255, _startColor.alphaOffset / 255);
					_deltaOffsetData = new Vector3D((_endColor.redOffset - _startColor.redOffset) / 255, (endColor.greenOffset - _startColor.greenOffset) / 255, (endColor.blueOffset - _startColor.blueOffset ) / 255, (endColor.alphaOffset - startColor.alphaOffset) / 255);
				}
			}
			
			
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			var colorTransform:ColorTransform = param[COLOR_COLORTRANSFORM];
			if (!colorTransform)
				throw(new Error("there is no " + COLOR_COLORTRANSFORM + " in param!"));
			if (_hasMult) {
				_oneData[0] = colorTransform.redMultiplier;
				_oneData[1] = colorTransform.greenMultiplier;
				_oneData[2] = colorTransform.blueMultiplier;
				_oneData[3] = colorTransform.alphaMultiplier;
				if (_hasOffset) {
					_oneData[4] = colorTransform.redOffset / 255;
					_oneData[5] = colorTransform.greenOffset / 255;
					_oneData[6] = colorTransform.blueOffset / 255;
					_oneData[7] = colorTransform.alphaOffset / 255;
				}
			} else {
				_oneData[0] = colorTransform.redOffset / 255;
				_oneData[1] = colorTransform.greenOffset / 255;
				_oneData[2] = colorTransform.blueOffset / 255;
				_oneData[3] = colorTransform.alphaOffset / 255;
			}
			
		}
	}
}
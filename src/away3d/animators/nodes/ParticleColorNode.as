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
		arcane static const VARYING_START_MULTIPLIER_INDEX:uint = 1;
		
		/** @private */
		arcane static const DELTA_MULTIPLIER_INDEX:uint = 2;
		
		/** @private */
		arcane static const VARYING_DELTA_MULTIPLIER_INDEX:uint = 3;
		
		/** @private */
		arcane static const START_OFFSET_INDEX:uint = 4;
		
		/** @private */
		arcane static const VARYING_START_OFFSET_INDEX:uint = 5;
		
		/** @private */
		arcane static const DELTA_OFFSET_INDEX:uint = 6;
		
		/** @private */
		arcane static const VARYING_DELTA_OFFSET_INDEX:uint = 7;
		
		/** @private */
		arcane static const CYCLE_INDEX:uint = 8;
		
		/** @private */
		arcane var _usesMultiplier:Boolean;
		
		/** @private */
		arcane var _usesOffset:Boolean;
		
		/** @private */
		arcane var _usesCycle:Boolean;
		
		/** @private */
		arcane var _usesPhase:Boolean;
		
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
		public static const COLOR_VECTOR_COLORTRANSFORM:String = "ColorVectorColorTransform";
		
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
		 * @param    [optional] usesMultiplier  Defines whether the node uses multiplier data in its color transformations. Defaults to true.
		 * @param    [optional] usesOffset      Defines whether the node uses offset data in its color transformations. Defaults to true.
		 * @param    [optional] usesCycle       Defines whether the node uses cycle data in its color transformations. Defaults to false.
		 * @param    [optional] usesPhase       Defines whether the node uses phase data in its color transformations. Defaults to false.
		 * @param    [optional] startColor      Defines the default start color transform of the node, when in global mode.
		 * @param    [optional] endColor        Defines the default end color transform of the node, when in global mode.
		 * @param    [optional] cycleSpeed      Defines the default cycle speed of the node in revolutions per second, when in global mode. Defaults to 1.
		 * @param    [optional] cyclePhase      Defines the default cycle phase of the node in degrees, when in global mode. Defaults to zero.
		 */
		public function ParticleColorNode(mode:uint, usesMultiplier:Boolean = true, usesOffset:Boolean = true, usesCycle:Boolean = false, usesPhase:Boolean = false, startColor:ColorTransform = null, endColor:ColorTransform = null, cycleSpeed:Number = 1, cyclePhase:Number = 0)
		{
			_stateClass = ParticleColorState;
			
			_usesMultiplier = usesMultiplier;
			_usesOffset = usesOffset;
			_usesCycle = usesCycle;
			_usesPhase = usesPhase;
			
			_startColor = startColor || new ColorTransform();
			_endColor = endColor || new ColorTransform();
			_cycleSpeed = cycleSpeed;
			_cyclePhase = cyclePhase;
			
			updateColorData();
			
			super("ParticleColorNode" + mode, mode, (_usesMultiplier && _usesOffset)? 16 : 8);
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
				if (_usesMultiplier) {
					var startMultiplierAtt:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
					animationRegisterCache.setRegisterIndex(this, START_MULTIPLIER_INDEX, startMultiplierAtt.index);
					var startMultiplierVary:ShaderRegisterElement = animationRegisterCache.getFreeVarying();
					animationRegisterCache.setRegisterIndex(this, VARYING_START_MULTIPLIER_INDEX, startMultiplierVary.index);
					
					var deltaMultiplierAtt:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
					animationRegisterCache.setRegisterIndex(this, DELTA_MULTIPLIER_INDEX, deltaMultiplierAtt.index);
					var deltaMultiplierVary:ShaderRegisterElement = animationRegisterCache.getFreeVarying();
					animationRegisterCache.setRegisterIndex(this, VARYING_DELTA_MULTIPLIER_INDEX, deltaMultiplierVary.index);
					
					code += "mov " + startMultiplierVary + "," + startMultiplierAtt + "\n";
					code += "mov " + deltaMultiplierVary + "," + deltaMultiplierAtt + "\n";
				}
				
				if (_usesOffset) {
					var startOffsetAtt:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
					animationRegisterCache.setRegisterIndex(this, START_OFFSET_INDEX, startOffsetAtt.index);
					var startOffsetVary:ShaderRegisterElement = animationRegisterCache.getFreeVarying();
					animationRegisterCache.setRegisterIndex(this, VARYING_START_OFFSET_INDEX, startOffsetVary.index);
					
					var deltaOffsetAtt:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
					animationRegisterCache.setRegisterIndex(this, DELTA_OFFSET_INDEX, deltaOffsetAtt.index);
					var deltaOffsetVary:ShaderRegisterElement = animationRegisterCache.getFreeVarying();
					animationRegisterCache.setRegisterIndex(this, VARYING_DELTA_OFFSET_INDEX, deltaOffsetVary.index);
					
					code += "mov " + startOffsetVary + "," + startOffsetAtt + "\n";
					code += "mov " + deltaOffsetVary + "," + deltaOffsetAtt + "\n";
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
				
				if (_usesCycle) {
					var cycleConst:ShaderRegisterElement = animationRegisterCache.getFreeFragmentConstant();
					animationRegisterCache.setRegisterIndex(this, CYCLE_INDEX, cycleConst.index);
					
					animationRegisterCache.addFragmentTempUsages(temp,1);
					var sin:ShaderRegisterElement = animationRegisterCache.getFreeFragmentSingleTemp();
					animationRegisterCache.removeFragmentTempUsage(temp);
					
					code += "mul " + sin + "," + animationRegisterCache.fragmentTime + "," + cycleConst + ".x\n";
					
					if (_usesPhase)
						code += "add " + sin + "," + sin + "," + cycleConst + ".y\n";
					
					code += "sin " + sin + "," + sin + "\n";
				}
				
				if (_usesMultiplier) {
					var startMultiplierValue:ShaderRegisterElement = (_mode == LOCAL)? new ShaderRegisterElement("v", animationRegisterCache.getRegisterIndex(this, VARYING_START_MULTIPLIER_INDEX)) : animationRegisterCache.getFreeFragmentConstant();
					var deltaMultiplierValue:ShaderRegisterElement = (_mode == LOCAL)? new ShaderRegisterElement("v", animationRegisterCache.getRegisterIndex(this, VARYING_DELTA_MULTIPLIER_INDEX)) : animationRegisterCache.getFreeFragmentConstant();
					animationRegisterCache.setRegisterIndex(this, START_MULTIPLIER_INDEX, startMultiplierValue.index);
					animationRegisterCache.setRegisterIndex(this, DELTA_MULTIPLIER_INDEX, deltaMultiplierValue.index);
					code += "mul " + temp + "," + deltaMultiplierValue + "," + (_usesCycle? sin : animationRegisterCache.fragmentLife) + "\n";
					code += "add " + temp + "," + temp + "," + startMultiplierValue + "\n";
					code += "mul " + animationRegisterCache.colorTarget +"," + temp + "," + animationRegisterCache.colorTarget + "\n";
				}
				
				if (_usesOffset) {
					var startOffsetValue:ShaderRegisterElement = (_mode == LOCAL)? new ShaderRegisterElement("v", animationRegisterCache.getRegisterIndex(this, VARYING_START_OFFSET_INDEX)) : animationRegisterCache.getFreeFragmentConstant();
					var deltaOffsetValue:ShaderRegisterElement = (_mode == LOCAL)? new ShaderRegisterElement("v", animationRegisterCache.getRegisterIndex(this, VARYING_DELTA_OFFSET_INDEX)) : animationRegisterCache.getFreeFragmentConstant();
					animationRegisterCache.setRegisterIndex(this, START_OFFSET_INDEX, startOffsetValue.index);
					animationRegisterCache.setRegisterIndex(this, DELTA_OFFSET_INDEX, deltaOffsetValue.index);
					code += "mul " + temp + "," + deltaOffsetValue +"," + (_usesCycle? sin : animationRegisterCache.fragmentLife) + "\n";
					code += "add " + temp + "," + temp +"," + startOffsetValue + "\n";
					code += "add " + animationRegisterCache.colorTarget +"," +temp + "," + animationRegisterCache.colorTarget + "\n";
				}
			}
			
			return code;
		}
		
		private function updateColorData():void
		{
			if (_usesCycle) {
				_cycleData = new Vector3D(Math.PI * 2 / _cycleSpeed, _cyclePhase * Math.PI / 180, 0, 0);
				if (_usesMultiplier) {
					_startMultiplierData = new Vector3D((_startColor.redMultiplier + _endColor.redMultiplier) / 2, (_startColor.greenMultiplier + _endColor.greenMultiplier) / 2, (_startColor.blueMultiplier + _endColor.blueMultiplier) / 2, (_startColor.alphaMultiplier + _endColor.alphaMultiplier) / 2);
					_deltaMultiplierData = new Vector3D((_endColor.redMultiplier - _startColor.redMultiplier) / 2, (_endColor.greenMultiplier - _startColor.greenMultiplier) / 2, (_endColor.blueMultiplier - _startColor.blueMultiplier) / 2, (_endColor.alphaMultiplier - _startColor.alphaMultiplier) / 2);
				}
				
				if (_usesOffset) {
					_startOffsetData = new Vector3D((_startColor.redOffset + _endColor.redOffset) / (255 * 2), (_startColor.greenOffset + _endColor.greenOffset) / (255 * 2), (_startColor.blueOffset + _endColor.blueOffset) / (255 * 2), (_startColor.alphaOffset + _endColor.alphaOffset) / (255 * 2));
					_deltaOffsetData = new Vector3D((_endColor.redOffset - _startColor.redOffset) / (255 * 2), (_endColor.greenOffset - _startColor.greenOffset) / (255 * 2), (_endColor.blueOffset - _startColor.blueOffset) / (255 * 2), (_endColor.alphaOffset - _startColor.alphaOffset) / (255 * 2));
				}
			} else {
				if (_usesMultiplier) {
					_startMultiplierData = new Vector3D(_startColor.redMultiplier , _startColor.greenMultiplier , _startColor.blueMultiplier , _startColor.alphaMultiplier);
					_deltaMultiplierData = new Vector3D((_endColor.redMultiplier - _startColor.redMultiplier) , (_endColor.greenMultiplier - _startColor.greenMultiplier) , (_endColor.blueMultiplier - _startColor.blueMultiplier) , (_endColor.alphaMultiplier - _startColor.alphaMultiplier));
				}
				
				if (_usesOffset) {
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
			var colorVector:Vector.<ColorTransform> = param[COLOR_VECTOR_COLORTRANSFORM];
			if (!colorVector)
				throw(new Error("there is no " + COLOR_VECTOR_COLORTRANSFORM + " in param!"));
			
			var i:uint;
			var startColor:ColorTransform = colorVector[0];
			var endColor:ColorTransform = colorVector[1]; 
			
			if (_usesCycle) {
				//multiplier
				if (_usesMultiplier) {
					_oneData[i++] = startColor.redMultiplier;
					_oneData[i++] = startColor.greenMultiplier;
					_oneData[i++] = startColor.blueMultiplier;
					_oneData[i++] = startColor.alphaMultiplier;
					_oneData[i++] = endColor.redMultiplier - startColor.redMultiplier;
					_oneData[i++] = endColor.greenMultiplier - startColor.greenMultiplier;
					_oneData[i++] = endColor.blueMultiplier - startColor.blueMultiplier;
					_oneData[i++] = endColor.alphaMultiplier - startColor.alphaMultiplier;
				}
				
				//offset
				if (_usesOffset) {
					_oneData[i++] = startColor.redOffset / 255;
					_oneData[i++] = startColor.greenOffset / 255;
					_oneData[i++] = startColor.blueOffset / 255;
					_oneData[i++] = startColor.alphaOffset / 255;
					_oneData[i++] = (endColor.redOffset - startColor.redOffset) / 255;
					_oneData[i++] = (endColor.greenOffset - startColor.greenOffset) / 255;
					_oneData[i++] = (endColor.blueOffset - startColor.blueOffset) / 255;
					_oneData[i++] = (endColor.alphaOffset - startColor.alphaOffset) / 255;
				}
			} else {
				//multiplier
				if (_usesMultiplier) {
					_oneData[i++] = (startColor.redMultiplier + endColor.redMultiplier) / 2;
					_oneData[i++] = (startColor.greenMultiplier + endColor.greenMultiplier) / 2;
					_oneData[i++] = (startColor.blueMultiplier + endColor.blueMultiplier) / 2;
					_oneData[i++] = (startColor.alphaMultiplier + endColor.alphaMultiplier) / 2;
					_oneData[i++] = (startColor.redMultiplier - endColor.redMultiplier) / 2;
					_oneData[i++] = (startColor.greenMultiplier - endColor.greenMultiplier) / 2;
					_oneData[i++] = (startColor.blueMultiplier - endColor.blueMultiplier) / 2;
					_oneData[i++] = (startColor.alphaMultiplier - endColor.alphaMultiplier) / 2;
				}
				
				//offset
				if (_usesOffset) {
					_oneData[i++] = (startColor.redOffset + endColor.redOffset) / (255 * 2);
					_oneData[i++] = (startColor.greenOffset + endColor.greenOffset) / (255 * 2);
					_oneData[i++] = (startColor.blueOffset + endColor.blueOffset) / (255 * 2);
					_oneData[i++] = (startColor.alphaOffset + endColor.alphaOffset) / (255 * 2);
					_oneData[i++] = (startColor.redOffset - endColor.redOffset) / (255 * 2);
					_oneData[i++] = (startColor.greenOffset - endColor.greenOffset) / (255 * 2);
					_oneData[i++] = (startColor.blueOffset - endColor.blueOffset) / (255 * 2);
					_oneData[i++] = (startColor.alphaOffset - endColor.alphaOffset) / (255 * 2);
				}
			}
			
		}
	}
}
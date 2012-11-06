package away3d.animators.nodes
{
	import flash.geom.Vector3D;
	import away3d.arcane;
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.states.ParticleSpriteSheetState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	
	use namespace arcane;
	
	/**
	 * Note: to use this class, make sure material::repeat is ture
	 */
	public class ParticleSpriteSheetNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const UV_INDEX_0:uint = 0;
		
		/** @private */
		arcane static const UV_INDEX_1:uint = 1;
		
		/** @private */
		arcane var _spriteSheetData:Vector.<Number>;
		
		private var _cycleDuration:Number;
		private var _looping:Boolean;
		private var _totalFrames:int;
		private var _numColumns:int;
		private var _numRows:int;
		private var _startTime:Number;
		
		/**
		 * Used to set the spritesheet node into global property mode.
		 */
		public static const GLOBAL:uint = 1;
		
		/**
		 * Defines the number of columns in the spritesheet, when in global mode. Defaults to 1.
		 */
		public function get numColumns():Number
		{
			return _numColumns;
		}
		public function set numColumns(value:Number):void
		{
			_numColumns = value;
			
			updateSpriteSheetData();
		}
		
		/**
		 * Defines the number of rows in the spritesheet, when in global mode. Defaults to 1.
		 */
		public function get numRows():Number
		{
			return _numRows;
		}
		public function set numRows(value:Number):void
		{
			_numRows = value;
			
			updateSpriteSheetData();
		}
		
		/**
		 * Defines the start time, when in global mode. Defaults to zero.
		 */
		public function get startTime():Number
		{
			return _startTime;
		}
		public function set startTime(value:Number):void
		{
			_startTime = value;
			
			updateSpriteSheetData();
		}
		
		/**
		 * Defines the frame rate, when in global mode. Defaults to 60.
		 */
		public function get cycleDuration():Number
		{
			return _cycleDuration;
		}
		public function set cycleDuration(value:Number):void
		{
			_cycleDuration = value;
			
			updateSpriteSheetData();
		}
		
		/**
		 * Defines the total number of frames used by the spritesheet, when in global mode. Defaults to the number defined by numColumns and numRows.
		 */
		public function get totalFrames():Number
		{
			return _totalFrames;
		}
		public function set totalFrames(value:Number):void
		{
			_totalFrames = Math.min(value, _numColumns * _numRows);
			
			updateSpriteSheetData();
		}
		
		/**
		 * Defines whether the spritesheet animation is set to loop indefinitely. Defaults to true.
		 */
		public function get looping():Boolean
		{
			return _looping;
		}
		public function set looping(value:Boolean):void
		{
			_looping = value;
			
			updateSpriteSheetData();
		}
		
		/**
		 * Creates a new <code>ParticleSpriteSheetNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation defaults to acting on local properties of a particle or global properties of the node.
		 * @param    [optional] numColumns      Defines the number of columns in the spritesheet, when in global mode. Defaults to 1.
		 * @param    [optional] numRows         Defines the number of rows in the spritesheet, when in global mode. Defaults to 1.
		 * @param    [optional] startTime       Defines the start time, when in global mode. Defaults to zero.
		 * @param    [optional] cycleDurion     Defines the cycle time, when in global mode. Defaults to 1.
		 * @param    [optional] totalFrames     Defines the total number of frames used by the spritesheet, when in global mode. Defaults to the number defined by numColumns and numRows.
		 * @param    [optional] looping         Defines whether the spritesheet animation is set to loop indefinitely. Defaults to true.
		 */
		public function ParticleSpriteSheetNode(mode:uint, numColumns:int = 1, numRows:uint = 1, startTime:Number = 0, cycleDuration:Number = 1, totalFrames:uint = uint.MAX_VALUE, looping:Boolean = true)
		{
			super("ParticleSpriteSheetNode" + mode, mode, 4, ParticleAnimationSet.POST_PRIORITY + 1);
			
			_stateClass = ParticleSpriteSheetState;
			
			_numColumns = numColumns;
			_numRows = numRows;
			_startTime = startTime;
			_cycleDuration = cycleDuration;
			_totalFrames = Math.min(totalFrames, numColumns * numRows);
			_looping = looping;
			
			updateSpriteSheetData();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):void
		{
			particleAnimationSet.hasUVNode = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			//get 2 vc
			var uvParamConst1:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			var uvParamConst2:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, UV_INDEX_0, uvParamConst1.index);
			animationRegisterCache.setRegisterIndex(this, UV_INDEX_1, uvParamConst2.index);
			
			var uSpeed:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "x");
			var uStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "y");
			var vStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "z");
			var cycle:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "w");
			var startTime:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, "x");
			var endThreshold:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, "y");
			
			
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var vOffset:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			temp = new ShaderRegisterElement(temp.regName, temp.index, "z");
			var temp2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "w");
			
			
			var u:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, "x");
			var v:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, "y");
			
			var code:String = "";
			//scale uv
			code += "mul " + u + "," + u + "," + uStep + "\n";
			if (_numRows > 1) code += "mul " + v + "," + v + "," + vStep + "\n";
			
			if (_startTime != 0)
			{
				code += "sub " + time + "," + animationRegisterCache.vertexTime + "," + startTime + "\n";
				code += "max " + time + "," + time + "," + animationRegisterCache.vertexZeroConst + "\n";
			}
			else
			{
				code += "mov " + time +"," + animationRegisterCache.vertexTime + "\n";
			}
			if (!_looping)
			{
				code += "min " + time + "," + time + "," + endThreshold + "\n";
			}
			else
			{
				code += "div " + time + "," + time + "," + cycle + "\n";
				code += "frc " + time + "," + time + "\n";
				code += "mul " + time + "," + time + "," + cycle + "\n";
			}
			
			
			code += "mul " + temp + "," + time + "," + uSpeed + "\n";
			if (_numRows > 1)
			{
				code += "frc " + temp2 + "," + temp + "\n";
				code += "sub " + vOffset + "," + temp + "," + temp2 + "\n";
				code += "mul " + vOffset + "," + vOffset + "," + vStep + "\n";
				code += "add " + v + "," + v + "," + vOffset + "\n";
			}
			code += stepDiv(temp, temp, uStep, temp2);
			code += "add " + u + "," + u + "," + temp + "\n";
			
			return code;
		}
		
		private function stepDiv(destination:ShaderRegisterElement, source1:ShaderRegisterElement, source2:ShaderRegisterElement, temp:ShaderRegisterElement):String
		{
			return "div " + temp + "," + source1 + "," + source2 + "\n" +
					"frc " + destination + "," + temp + "\n"+
					"sub " + temp + "," + temp + "," + destination + "\n" +
					"mul " + destination + "," + temp + "," + source2 + "\n";
		}
		
		private function updateSpriteSheetData():void
		{
			if (_cycleDuration <= 0)
				throw(new Error("the cycle duration must be greater than zero"));
			var uTotal:Number = _totalFrames / _numColumns;
			var uSpeed:Number = uTotal / _cycleDuration;
			var uStep:Number = 1 / _numColumns;
			var vStep:Number = 1 / _numRows;
			var endThreshold:Number = _cycleDuration - _cycleDuration / _totalFrames / 2;
			_spriteSheetData = Vector.<Number>([uSpeed, uStep, vStep, _cycleDuration, _startTime, endThreshold, 0, 0]);
		}
	}
}
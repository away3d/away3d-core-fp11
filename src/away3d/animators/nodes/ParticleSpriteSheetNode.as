package away3d.animators.nodes
{
	import away3d.animators.data.ParticleProperties;
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
		arcane var _usesCycle:Boolean;
		
		/** @private */
		arcane var _usesPhase:Boolean;
		
		/** @private */
		arcane var _spriteSheetData:Vector.<Number>;
		
		private var _cycleDuration:Number;
		private var _totalFrames:int;
		private var _numColumns:int;
		private var _numRows:int;
		private var _phaseTime:Number;
		
		/**
		 * Used to set the spritesheet node into local property mode.
		 */
		public static const LOCAL:uint = 0;
		/**
		 * Used to set the spritesheet node into global property mode.
		 */
		public static const GLOBAL:uint = 1;
		
		/**
		 * Reference for spritesheet node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> representing the cycleDuration (x), optional phaseTime (y).
		 */
		public static const UV_VECTOR3D:String = "UVVector3D";
		
		/**
		 * Defines the number of columns in the spritesheet, when in global mode. Defaults to 1. Read only.
		 */
		public function get numColumns():Number
		{
			return _numColumns;
		}
		
		/**
		 * Defines the number of rows in the spritesheet, when in global mode. Defaults to 1. Read only.
		 */
		public function get numRows():Number
		{
			return _numRows;
		}
		
		/**
		 * Defines the phase time, when in global mode. Defaults to zero.
		 */
		public function get phaseTime():Number
		{
			return _phaseTime;
		}
		public function set phaseTime(value:Number):void
		{
			_phaseTime = value;
			
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
		 * Defines the total number of frames used by the spritesheet, when in global mode. Defaults to the number defined by numColumns and numRows. Read only.
		 */
		public function get totalFrames():Number
		{
			return _totalFrames;
		}
		
		
		/**
		 * Creates a new <code>ParticleSpriteSheetNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
		 * @param    [optional] numColumns      Defines the number of columns in the spritesheet, when in global mode. Defaults to 1.
		 * @param    [optional] numRows         Defines the number of rows in the spritesheet, when in global mode. Defaults to 1.
		 * @param    [optional] phaseTime       Defines the start time, when in global mode. Defaults to zero.
		 * @param    [optional] cycleDurion     Defines the cycle time, when in global mode. Defaults to 1.
		 * @param    [optional] totalFrames     Defines the total number of frames used by the spritesheet, when in global mode. Defaults to the number defined by numColumns and numRows.
		 * @param    [optional] looping         Defines whether the spritesheet animation is set to loop indefinitely. Defaults to true.
		 */
		public function ParticleSpriteSheetNode(mode:uint, usesCycle:Boolean, usesPhase:Boolean, numColumns:int = 1, numRows:uint = 1, cycleDuration:Number = 1, phaseTime:Number = 0, totalFrames:uint = uint.MAX_VALUE)
		{
			var len:int;
			if (usesCycle)
			{
				len = 2;
				if (usesPhase)
					len++;
			}
			super("ParticleSpriteSheetNode" + mode, mode, len, ParticleAnimationSet.POST_PRIORITY + 1);
			
			_stateClass = ParticleSpriteSheetState;
			
			_usesCycle = usesCycle;
			_usesPhase = usesPhase;
			
			_numColumns = numColumns;
			_numRows = numRows;
			_phaseTime = phaseTime;
			_cycleDuration = cycleDuration;
			_totalFrames = Math.min(totalFrames, numColumns * numRows);
			
			_spriteSheetData = new Vector.<Number>(8, true);
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
			var uvParamConst2:ShaderRegisterElement = (_mode == LOCAL)? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, UV_INDEX_0, uvParamConst1.index);
			animationRegisterCache.setRegisterIndex(this, UV_INDEX_1, uvParamConst2.index);
			
			var uTotal:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "x");
			var uStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "y");
			var vStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "z");
			
			var uSpeed:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, "x");
			var cycle:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, "y");
			var phaseTime:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, "z");
			
			
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
			
			if (_usesCycle)
			{
				if (_usesPhase)
					code += "add " + time + "," + animationRegisterCache.vertexTime + "," + phaseTime + "\n";
				else
					code += "mov " + time +"," + animationRegisterCache.vertexTime + "\n";
				code += "div " + time + "," + time + "," + cycle + "\n";
				code += "frc " + time + "," + time + "\n";
				code += "mul " + time + "," + time + "," + cycle + "\n";
				code += "mul " + temp + "," + time + "," + uSpeed + "\n";
			}
			else
			{
				code += "mul " + temp.toString() + "," + animationRegisterCache.vertexLife + "," + uTotal + "\n";
			}
			
			
			
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
			var uTotal:Number = _totalFrames / _numColumns;
			var uStep:Number = 1 / _numColumns;
			var vStep:Number = 1 / _numRows;
			_spriteSheetData[0] = uTotal;
			_spriteSheetData[1] = uStep;
			_spriteSheetData[2] = vStep;
			if (_usesCycle)
			{
				if (_cycleDuration <= 0)
					throw(new Error("the cycle duration must be greater than zero"));
				var uSpeed:Number = uTotal / _cycleDuration;
				_spriteSheetData[4] = uSpeed;
				_spriteSheetData[5] = _cycleDuration;
				if (_usesPhase)
					_spriteSheetData[6] = _phaseTime;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleProperties):void
		{
			if (_usesCycle)
			{
				var uvCycle:Vector3D = param[UV_VECTOR3D];
				if (!uvCycle)
					throw(new Error("there is no " + UV_VECTOR3D + " in param!"));
				if (uvCycle.x <= 0)
					throw(new Error("the cycle duration must be greater than zero"));
				var uTotal:Number = _totalFrames / _numColumns;
				_oneData[0] = uTotal / uvCycle.x;
				_oneData[1] = uvCycle.x;
				if (_usesPhase)
					_oneData[2] = uvCycle.y;
			}
		}
	}
}
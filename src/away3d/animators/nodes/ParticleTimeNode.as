package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.states.ParticleTimeState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	
	use namespace arcane;
	
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleTimeNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const TIME_STREAM_INDEX:uint = 0;
		
		/** @private */
		arcane static const TIME_CONSTANT_INDEX:uint = 1;
		
		protected var _hasDuration:Boolean;
		protected var _hasDelay:Boolean;
		protected var _loop:Boolean;
		
		/**
		 * Defines whether the time track is in loop mode. Defaults to false.
		 */
		public function get loop():Boolean
		{
			return _loop;
		}
		public function set loop(value:Boolean):void
		{
			_loop = value;
			
			if (_loop)
				_hasDuration = true;
			else
				_hasDelay = false;
		}
		
		/**
		 * 
		 */
		public function get hasDuration():Boolean
		{
			return _hasDuration;
		}
		
		public function set hasDuration(value:Boolean):void
		{
			_hasDuration = value;
			if (!_hasDuration) {
				_hasDelay = false;
				_loop = false;
			}
		}
		
		/**
		 * 
		 */
		public function get hasDelay():Boolean
		{
			return _hasDelay;
		}
		
		public function set hasDelay(value:Boolean):void
		{
			_hasDelay = value;
			if (_hasDelay)
			{
				_loop = true;
				_hasDuration = true;
			}
		}
		
		/**
		 * Creates a new <code>ParticleTimeNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation defaults to acting on local properties of a particle or global properties of the node.
		 * @param    [optional] loop            Defines whether the time track is in loop mode. Defaults to false.
		 */
		public function ParticleTimeNode(loop:Boolean = false)
		{
			_stateClass = ParticleTimeState;
			
			_loop = loop;
			
			super("ParticleTimeNode", 0, 4, 0);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var timeStreamRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();//timeStreamRegister.x is start，timeStreamRegister.y is during time
			animationRegisterCache.setRegisterIndex(this, TIME_STREAM_INDEX, timeStreamRegister.index);
			var timeConst:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, TIME_CONSTANT_INDEX, timeConst.index);
			
			var code:String = "";
			code += "sub " + animationRegisterCache.vertexTime + "," + timeConst + "," + timeStreamRegister + ".x\n";
			//if time=0,set the position to zero.
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
			code += "sge " + temp + "," + animationRegisterCache.vertexTime + "," + animationRegisterCache.vertexZeroConst + "\n";
			code += "mul " + animationRegisterCache.scaleAndRotateTarget + "," + animationRegisterCache.scaleAndRotateTarget + "," + temp + "\n";
			if (_hasDuration)
			{
				if (_loop)
				{
					var div:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
					if (_hasDelay)
					{
						code += "div " + div + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".z\n";
						code += "frc " + div + "," + div + "\n";
						code += "mul " + animationRegisterCache.vertexTime + "," +div + "," + timeStreamRegister + ".z\n";
						code += "slt " + div + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".y\n";
						code += "mul " + animationRegisterCache.scaleAndRotateTarget + "," + animationRegisterCache.scaleAndRotateTarget + "," + div + "\n";
					}
					else
					{
						code += "mul " + div + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".w\n";
						code += "frc " + div + "," + div + "\n";
						code += "mul " + animationRegisterCache.vertexTime + "," +div + "," + timeStreamRegister + ".y\n";
					}
				}
				else
				{
					var sge:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
					code += "sge " + sge + "," +  timeStreamRegister + ".y," + animationRegisterCache.vertexTime + "\n";
					code += "mul " + animationRegisterCache.scaleAndRotateTarget + "," + animationRegisterCache.scaleAndRotateTarget + "," + sge + "\n";
				}
			}
			code += "mul " + animationRegisterCache.vertexLife + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".w\n";
			if (animationRegisterCache.needFragmentAnimation && animationRegisterCache.hasColorNode)
			{
				code += "mov " + animationRegisterCache.fragmentTime + "," + animationRegisterCache.vertexTime +"\n";
				code += "mov " + animationRegisterCache.fragmentLife + "," + animationRegisterCache.vertexLife +"\n";
			}
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			_oneData[0] = param.startTime;
			_oneData[1] = param.duration;
			_oneData[2] = param.delay + param.duration;
			_oneData[3] = 1 / param.duration;
			
		}
	}
}
package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleParamter;
	import away3d.animators.states.ParticleTimeState;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleTimeNode extends LocalParticleNodeBase
	{
		public static const NAME:String = "ParticleTimeNode";
		public static const TIME_STREAM_REGISTER:int = 0;
		public static const TIME_CONSTANT_REGISTER:int = 1;
		
		
		private var _tempStartTime:Number;
		private var _tempDuringTime:Number;
		private var _tempSleepTime:Number;
		
		
		protected var _hasDuringTime:Boolean;
		protected var _hasSleepTime:Boolean;
		protected var _loop:Boolean;
		
		
		public function ParticleTimeNode()
		{
			super(NAME, 0);
			_stateClass = ParticleTimeState;
			_dataLenght = 4;
			initOneData();
		}
		
		public function get loop():Boolean
		{
			return _loop;
		}
		public function set loop(value:Boolean):void
		{
			_loop = value;
			if (_loop)
			{
				_hasDuringTime = true;
			}
			else
			{
				_hasSleepTime = false;
			}
		}
		
		public function get hasDuringTime():Boolean
		{
			return _hasDuringTime;
		}
		
		public function set hasDuringTime(value:Boolean):void
		{
			_hasDuringTime = value;
			if (!_hasDuringTime)
			{
				_hasSleepTime = false;
				_loop = false;
			}
		}
		
		public function get hasSleepTime():Boolean
		{
			return _hasSleepTime;
		}
		
		public function set hasSleepTime(value:Boolean):void
		{
			_hasSleepTime = value;
			if (_hasSleepTime)
			{
				_loop = true;
				_hasDuringTime = true;
			}
		}
		
		override public function generatePorpertyOfOneParticle(param:ParticleParamter):void
		{
			_tempStartTime = param.startTime;
			_tempDuringTime = param.duringTime;
			_tempSleepTime = param.sleepTime;
			
			_oneData[0] = _tempStartTime;
			_oneData[1] = _tempDuringTime;
			_oneData[2] = _tempSleepTime + _tempDuringTime;
			_oneData[3] = 1 / _tempDuringTime;
			
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			var timeStreamRegister:ShaderRegisterElement = activatedCompiler.getFreeVertexAttribute();//timeStreamRegister.x is start，timeStreamRegister.y is during time
			activatedCompiler.setRegisterIndex(this, TIME_STREAM_REGISTER, timeStreamRegister.index);
			var timeConst:ShaderRegisterElement = activatedCompiler.getFreeVertexConstant();
			activatedCompiler.setRegisterIndex(this, TIME_CONSTANT_REGISTER, timeConst.index);
			
			var code:String = "";
			code += "sub " + activatedCompiler.vertexTime.toString() + "," + timeConst.toString() + "," + timeStreamRegister.toString() + ".x\n";
			//if time=0,set the position to zero.
			var temp:ShaderRegisterElement = activatedCompiler.getFreeVertexSingleTemp();
			code += "sge " + temp.toString() + "," + activatedCompiler.vertexTime.toString() + "," + activatedCompiler.vertexZeroConst.toString() + "\n";
			code += "mul " + activatedCompiler.scaleAndRotateTarget.toString() + "," + activatedCompiler.scaleAndRotateTarget.toString() + "," + temp.toString() + "\n";
			if (_hasDuringTime)
			{
				if (_loop)
				{
					var div:ShaderRegisterElement = activatedCompiler.getFreeVertexSingleTemp();
					if (_hasSleepTime)
					{
						code += "div " + div.toString() + "," + activatedCompiler.vertexTime.toString() + "," + timeStreamRegister.toString() + ".z\n";
						code += "frc " + div.toString() + "," + div.toString() + "\n";
						code += "mul " + activatedCompiler.vertexTime.toString() + "," +div.toString() + "," + timeStreamRegister.toString() + ".z\n";
						code += "slt " + div.toString() + "," + activatedCompiler.vertexTime.toString() + "," + timeStreamRegister.toString() + ".y\n";
						code += "mul " + activatedCompiler.scaleAndRotateTarget.toString() + "," + activatedCompiler.scaleAndRotateTarget.toString() + "," + div.toString() + "\n";
					}
					else
					{
						code += "mul " + div.toString() + "," + activatedCompiler.vertexTime.toString() + "," + timeStreamRegister.toString() + ".w\n";
						code += "frc " + div.toString() + "," + div.toString() + "\n";
						code += "mul " + activatedCompiler.vertexTime.toString() + "," +div.toString() + "," + timeStreamRegister.toString() + ".y\n";
					}
				}
				else
				{
					var sge:ShaderRegisterElement = activatedCompiler.getFreeVertexSingleTemp();
					code += "sge " + sge.toString() + "," +  timeStreamRegister.toString() + ".y," + activatedCompiler.vertexTime.toString() + "\n";
					code += "mul " + activatedCompiler.scaleAndRotateTarget.toString() + "," + activatedCompiler.scaleAndRotateTarget.toString() + "," + sge.toString() + "\n";
				}
			}
			code += "mul " + activatedCompiler.vertexLife.toString() + "," + activatedCompiler.vertexTime.toString() + "," + timeStreamRegister.toString() + ".w\n";
			if (activatedCompiler.needFragmentAnimation && sharedSetting.hasColorNode)
			{
				code += "mov " + activatedCompiler.fragmentTime.toString() + "," + activatedCompiler.vertexTime.toString() +"\n";
				code += "mov " + activatedCompiler.fragmentLife.toString() + "," + activatedCompiler.vertexLife.toString() +"\n";
			}
			return code;
		}
		
	}

}
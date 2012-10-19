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
		private var _tempEndTime:Number;
		private var _tempSleepTime:Number;
		
		
		public var hasDuringTime:Boolean;
		public var hasSleepTime:Boolean;
		
		private var _loop:Boolean;
		
		public function ParticleTimeNode()
		{
			super(NAME, 0);
			_stateClass = ParticleTimeState;
			_dataLenght = 4;
			initOneData();
		}
		
		
		public function set loop(value:Boolean):void
		{
			_loop = value;
			if (value)
			{
				hasDuringTime = true;
			}
		}
		
		override public function generatePorpertyOfOneParticle(param:ParticleParamter):void
		{
			if (isNaN(param.startTime)) throw("there is no startTime in param!");
			_tempStartTime = param.startTime;
			_tempEndTime = 1000;
			if (hasDuringTime)
			{
				if (isNaN(param.duringTime)) throw("there is no duringTime in param!");
				_tempEndTime = param.duringTime;
			}
			_tempSleepTime = 0;
			if (hasSleepTime)
			{
				if (isNaN(param.sleepTime)) throw("there is no sleepTime in param!");
				_tempSleepTime = param.sleepTime;
			}
			
			_oneData[0] = _tempStartTime;
			_oneData[1] = _tempEndTime;
			_oneData[2] = _tempSleepTime + _tempEndTime;
			_oneData[3] = 1 / _tempEndTime;
			
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			var timeStreamRegister:ShaderRegisterElement = activatedCompiler.getFreeVertexAttribute();//timeStreamRegister.x is start，timeStreamRegister.y is during time
			activatedCompiler.setRegisterIndex(this, TIME_STREAM_REGISTER, timeStreamRegister.index);
			var timeConst:ShaderRegisterElement = activatedCompiler.getFreeVertexConstant();
			activatedCompiler.setRegisterIndex(this, TIME_CONSTANT_REGISTER, timeConst.index);
			
			var code:String = "";
			code += "sub " + activatedCompiler.vertexTime.toString() + "," + timeConst.toString() + "," + timeStreamRegister.toString() + ".x\n";
			code += "max " + activatedCompiler.vertexTime.toString() + "," + activatedCompiler.vertexZeroConst.toString() + "," +  activatedCompiler.vertexTime.toString() + "\n";
			if (hasDuringTime)
			{
				if (_loop)
				{
					var div:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
					if (hasSleepTime)
					{
						code += "div " + div.toString() + ".x," + activatedCompiler.vertexTime.toString() + "," + timeStreamRegister.toString() + ".z\n";
						code += "frc " + div.toString() + ".x," + div.toString() + ".x\n";
						code += "mul " + activatedCompiler.vertexTime.toString() + "," +div.toString() + ".x," + timeStreamRegister.toString() + ".z\n";
						code += "slt " + div.toString() + ".x," + activatedCompiler.vertexTime.toString() + "," + timeStreamRegister.toString() + ".y\n";
						code += "mul " + activatedCompiler.vertexTime.toString() + "," + activatedCompiler.vertexTime.toString() + "," + div.toString() + ".x\n";
					}
					else
					{
						code += "mul " + div.toString() + ".x," + activatedCompiler.vertexTime.toString() + "," + timeStreamRegister.toString() + ".w\n";
						code += "frc " + div.toString() + ".x," + div.toString() + ".x\n";
						code += "mul " + activatedCompiler.vertexTime.toString() + "," +div.toString() + ".x," + timeStreamRegister.toString() + ".y\n";
					}
				}
				else
				{
					var sge:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
					code += "sge " + sge.toString() + ".x," +  timeStreamRegister.toString() + ".y," + activatedCompiler.vertexTime.toString() + "\n";
					code += "mul " + activatedCompiler.vertexTime.toString() + "," +sge.toString() + ".x," + activatedCompiler.vertexTime.toString() + "\n";
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
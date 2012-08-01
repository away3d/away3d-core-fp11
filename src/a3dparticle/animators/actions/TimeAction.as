package a3dparticle.animators.actions
{
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3DVertexBufferFormat;
	
	import away3d.arcane;
	use namespace arcane;
	
	/**
	 * ...
	 * @author ...
	 */
	public class TimeAction extends PerParticleAction
	{
		private var _startTimeFun:Function;
		private var _endTimeFun:Function;
		private var _sleepTimeFun:Function;
		
		private var _tempStartTime:Number;
		private var _tempEndTime:Number;
		private var _tempSleepTime:Number;
		
		
		private var timeAtt:ShaderRegisterElement;
		
		public var hasDuringTime:Boolean;
		public var hasSleepTime:Boolean;
		
		private var _loop:Boolean;
		
		public function TimeAction()
		{
			priority = 0;
			dataLenght = 4;
			_name = "TimeAction";
		}
		
		public function set startTimeFun(fun:Function):void
		{
			_startTimeFun = fun;
		}
		
		public function set duringTimeFun(fun:Function):void
		{
			_endTimeFun = fun;
			hasDuringTime = true;
		}
		
		public function set sleepTimeFun(fun:Function):void
		{
			_sleepTimeFun = fun;
			hasSleepTime = true;
		}
		
		public function set loop(value:Boolean):void
		{
			_loop = value;
			if (value)
			{
				hasDuringTime = true;
			}
		}
		
		override public function genOne(param:ParticleParam):void
		{
			_tempStartTime = 0;
			if (_startTimeFun != null)
			{
				_tempStartTime = _startTimeFun(param);
				param.startTime = _tempStartTime;
			}
			else
			{
				if (isNaN(param.startTime)) throw("there is no startTime in param!");
				_tempStartTime = param.startTime;
			}
			_tempEndTime = 1000;
			if (hasDuringTime)
			{
				if (_endTimeFun != null)
				{
					_tempEndTime = _endTimeFun(param);
					param.duringTime = _tempEndTime;
				}
				else
				{
					if (isNaN(param.duringTime)) throw("there is no duringTime in param!");
					_tempEndTime = param.duringTime;
				}
			}
			_tempSleepTime = 0;
			if (hasSleepTime)
			{
				if (_sleepTimeFun != null)
				{
					_tempSleepTime = _sleepTimeFun(param);
					param.sleepTime = _tempSleepTime;
				}
				else
				{
					if (isNaN(param.sleepTime)) throw("there is no sleepTime in param!");
					_tempSleepTime = param.sleepTime;
				}
			}
			
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(_tempStartTime, _tempEndTime, _tempSleepTime + _tempEndTime, 1 / _tempEndTime);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			timeAtt = shaderRegisterCache.getFreeVertexAttribute();//timeAtt.x is start，timeAtt.y is during time
			
			var code:String = "";
			code += "sub " + _animation.vertexTime.toString() + "," + _animation.timeConst.toString() + ".x," + timeAtt.toString() + ".x\n";
			code += "max " + _animation.vertexTime.toString() + "," + _animation.zeroConst.toString() + "," +  _animation.vertexTime.toString() + "\n";
			if (hasDuringTime)
			{
				if (_loop)
				{
					var div:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
					if (hasSleepTime)
					{
						code += "div " + div.toString() + ".x," + _animation.vertexTime.toString() + "," + timeAtt.toString() + ".z\n";
						code += "frc " + div.toString() + ".x," + div.toString() + ".x\n";
						code += "mul " + _animation.vertexTime.toString() + "," +div.toString() + ".x," + timeAtt.toString() + ".z\n";
						code += "slt " + div.toString() + ".x," + _animation.vertexTime.toString() + "," + timeAtt.toString() + ".y\n";
						code += "mul " + _animation.vertexTime.toString() + "," + _animation.vertexTime.toString() + "," + div.toString() + ".x\n";
					}
					else
					{
						code += "mul " + div.toString() + ".x," + _animation.vertexTime.toString() + "," + timeAtt.toString() + ".w\n";
						code += "frc " + div.toString() + ".x," + div.toString() + ".x\n";
						code += "mul " + _animation.vertexTime.toString() + "," +div.toString() + ".x," + timeAtt.toString() + ".y\n";
					}
				}
				else
				{
					var sge:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
					code += "sge " + sge.toString() + ".x," +  timeAtt.toString() + ".y," + _animation.vertexTime.toString() + "\n";
					code += "mul " + _animation.vertexTime.toString() + "," +sge.toString() + ".x," + _animation.vertexTime.toString() + "\n";
				}
			}
			code += "mul " + _animation.vertexLife.toString() + "," + _animation.vertexTime.toString() + "," + timeAtt.toString() + ".w\n";
			code += "mov " + _animation.fragmentTime.toString() + "," + _animation.vertexTime.toString() +"\n";
			code += "mov " + _animation.fragmentLife.toString() + "," + _animation.vertexLife.toString() +"\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(timeAtt.index, getExtraBuffer(stage3DProxy, SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_4, 0);
		}
		
	}

}
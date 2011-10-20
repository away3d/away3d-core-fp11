package a3dparticle.animators.actions 
{
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
		
		private var hasEndTime:Boolean;
		
		private var _loop:Boolean;
		
		public function TimeAction() 
		{
			priority = 0;
			dataLenght = 3;
		}
		
		public function set startTimeFun(fun:Function):void
		{
			_startTimeFun = fun;
		}
		
		public function set endTimeFun(fun:Function):void
		{
			_endTimeFun = fun;
			hasEndTime = true;
		}
		
		public function set sleepTimeFun(fun:Function):void
		{
			_sleepTimeFun = fun;
		}
		
		public function set loop(value:Boolean):void
		{
			_loop = value;
			if (value)
			{
				hasEndTime = true;
			}
		}
		
		override public function genOne(index:uint):void
		{
			_tempStartTime = 0;
			if (_startTimeFun != null)
			{
				_tempStartTime = _startTimeFun(index);
			}
			_tempEndTime = 1000;
			if (_endTimeFun != null)
			{
				_tempEndTime = _endTimeFun(index);
			}
			_tempSleepTime = 0;
			if (_sleepTimeFun != null)
			{
				_tempSleepTime = _sleepTimeFun(index);
			}
		}
		
		override public function distributeOne(index:int, verticeIndex:uint):void
		{
			_vertices.push(_tempStartTime);
			_vertices.push(_tempEndTime);
			_vertices.push(_tempSleepTime+_tempEndTime);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			timeAtt = shaderRegisterCache.getFreeVertexAttribute();//timeAtt.x is start，timeAtt.y is during time
			
			var code:String = "";
			code += "sub " + _animation.vertexTime.toString() + "," + _animation.timeConst.toString() + ".x," + timeAtt.toString() + ".x\n";
			code += "max " + _animation.vertexTime.toString() + "," + _animation.zeroConst.toString() + "," +  _animation.vertexTime.toString() + "\n";
			if (hasEndTime)
			{
				if (_loop)
				{
					var div:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
					code += "div " + div.toString() + ".x," + _animation.vertexTime.toString() + "," + timeAtt.toString() + ".z\n";
					code += "frc " + div.toString() + ".x," + div.toString() + ".x\n";
					code += "mul " + _animation.vertexTime.toString() + "," +div.toString() + ".x," + timeAtt.toString() + ".z\n";
					code += "slt " + div.toString() + ".x," + _animation.vertexTime.toString() + "," + timeAtt.toString() + ".y\n";
					code += "mul " + _animation.vertexTime.toString() + "," + _animation.vertexTime.toString() + "," + div.toString() + ".x\n";
				}
				else
				{
					var sge:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
					code += "sge " + sge.toString() + ".x," +  timeAtt.toString() + ".y," + _animation.vertexTime.toString() + "\n";
					code += "mul " + _animation.vertexTime.toString() + "," +sge.toString() + ".x," + _animation.vertexTime.toString() + "\n";
				}
			}
			code += "div " + _animation.vertexLife.toString() + "," + _animation.vertexTime.toString() + "," + timeAtt.toString() + ".y\n";
			code += "mov " + _animation.fragmentTime.toString() + "," + _animation.vertexTime.toString() +"\n";
			code += "mov " + _animation.fragmentLife.toString() + "," + _animation.vertexLife.toString() +"\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(timeAtt.index, getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3);
		}
		
	}

}
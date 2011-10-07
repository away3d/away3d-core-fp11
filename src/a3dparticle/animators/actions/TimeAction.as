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
		
		private var _tempStartTime:Number;
		private var _tempEndTime:Number;
		
		
		private var timeConst:ShaderRegisterElement;
		private var vertexTime:ShaderRegisterElement;
		private var vertexLife:ShaderRegisterElement;
		private var timeAtt:ShaderRegisterElement;
		
		private var hasEndTime:Boolean;
		
		private var _loop:Boolean;
		
		public function TimeAction() 
		{
			dataLenght = 2;
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
		}
		
		override public function distributeOne(index:int, verticeIndex:uint):void
		{
			_vertices.push(_tempStartTime);
			_vertices.push(_tempEndTime);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			timeConst = shaderRegisterCache.getFreeVertexConstant();
			var tempTime:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(tempTime, 1);
			vertexTime = new ShaderRegisterElement(tempTime.regName, tempTime.index, "x");
			vertexLife = new ShaderRegisterElement(tempTime.regName, tempTime.index, "y");
			var varyTime:ShaderRegisterElement = shaderRegisterCache.getFreeVarying();
			_animation.fragmentTime = new ShaderRegisterElement(varyTime.regName, varyTime.index, "x");
			_animation.fragmentLife = new ShaderRegisterElement(varyTime.regName, varyTime.index, "y");
			
			_animation.timeConst = timeConst;
			_animation.vertexTime = vertexTime;
			_animation.vertexLife = vertexLife;
			timeAtt = shaderRegisterCache.getFreeVertexAttribute();//timeAtt.x 是开始时间，timeAtt.y是持续时间
			
			var code:String = "";
			code += "sub " + vertexTime.toString() + "," + _animation.timeConst.toString() + ".x," + timeAtt.toString() + ".x\n";
			code += "max " + vertexTime.toString() + "," + _animation.zeroConst.toString() + "," +  vertexTime.toString() + "\n";
			if (hasEndTime)
			{
				if (_loop)
				{
					var div:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
					code += "div " + div.toString() + ".xyz," + vertexTime.toString() + "," + timeAtt.toString() + ".y\n";
					code += "frc " + div.toString() + ".xyz," + div.toString() + ".xyz\n";
					code += "mul " + vertexTime.toString() + "," +div.toString() + ".xyz," + timeAtt.toString() + ".y\n";
				}
				else
				{
					var sge:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
					code += "sge " + sge.toString() + ".x," +  timeAtt.toString() + ".y," + vertexTime.toString() + "\n";
					code += "mul " + vertexTime.toString() + "," +sge.toString() + ".x," + vertexTime.toString() + "\n";
				}
			}
			code += "div " + vertexLife.toString() + "," + vertexTime.toString() + "," + timeAtt.toString() + ".y\n";
			code += "mov " + _animation.fragmentTime.toString() + "," + vertexTime.toString() +"\n";
			code += "mov " + _animation.fragmentLife.toString() + "," + vertexLife.toString() +"\n";
			code += "mov " + varyTime.toString() + ".zw," + _animation.zeroConst.toString() + "\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(timeAtt.index, getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_2);
		}
		
	}

}
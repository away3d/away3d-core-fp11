package a3dparticle.animators.actions.uv
{
	import a3dparticle.animators.actions.AllParticleAction;
	import a3dparticle.animators.ParticleAnimation;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class UVSeqPicByTimeGlobal extends AllParticleAction
	{		
		private var uvParamConst1:ShaderRegisterElement;
		private var uvParamConst2:ShaderRegisterElement;
		
		private var _hasStartTime:Boolean;
		private var _loop:Boolean;
		private var _needV:Boolean;
		
		private var _data:Vector.<Number>;
		
		public function UVSeqPicByTimeGlobal(columns:int, rows:int , cycle:Number, usingNum:int = int.MAX_VALUE, startTime:Number = 0, loop:Boolean = true)
		{
			priority = ParticleAnimation.POST_PRIORITY + 5;
			
			var total:int = Math.min(usingNum, columns * rows);
			if (startTime != 0)_hasStartTime = true;
			_loop = loop;
			if (rows > 1)_needV = true;
			var uTotal:Number = total / columns;
			var uSpeed:Number = uTotal / cycle;
			var uStep:Number = 1 / columns;
			
			var vStep:Number = 1 / rows;
			
			var endThreshold:Number = cycle-cycle / total / 2;
			_data = Vector.<Number>([uSpeed, uStep, vStep, cycle, startTime, endThreshold, 0, 0]);
		}
		
		override public function set animation(value:ParticleAnimation):void
		{
			super.animation = value;
			value.hasUVAction = true;
		}
		
		
		override public function getAGALVertexCode(pass:MaterialPassBase):String
		{
			if (_animation.needUV)
			{
				//get 2 vc
				uvParamConst1 = shaderRegisterCache.getFreeVertexConstant();
				uvParamConst2 = shaderRegisterCache.getFreeVertexConstant();
				
				var uSpeed:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "x");
				var uStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "y");
				var vStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "z");
				var cycle:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "w");
				var startTime:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, "x");
				var endThreshold:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, "y");
				
				
				var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
				var time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
				var vOffset:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
				temp = new ShaderRegisterElement(temp.regName, temp.index, "z");
				var temp2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "w");
				
				
				var u:ShaderRegisterElement = new ShaderRegisterElement(_animation.uvTarget.regName, _animation.uvTarget.index, "x");
				var v:ShaderRegisterElement = new ShaderRegisterElement(_animation.uvTarget.regName, _animation.uvTarget.index, "y");
				
				var code:String = "";
				//scale uv
				code += "mul " + u.toString() + "," + u.toString() + "," + uStep.toString() + "\n";
				if (_needV) code += "mul " + v.toString() + "," + v.toString() + "," + vStep.toString() + "\n";
				
				if (_hasStartTime)
				{
					code += "sub " + time.toString() + "," + _animation.vertexTime.toString() + "," + startTime.toString() + "\n";
					code += "max " + time.toString() + "," + time.toString() + "," + _animation.zeroConst.toString() + "\n";
				}
				else
				{
					code += "mov " + time.toString() +"," + _animation.vertexTime.toString() + "\n";
				}
				if (!_loop)
				{
					code += "min " + time.toString() + "," + time.toString() + "," + endThreshold.toString() + "\n";
				}
				else
				{
					code += "div " + time.toString() + "," + time.toString() + "," + cycle.toString() + "\n";
					code += "frc " + time.toString() + "," + time.toString() + "\n";
					code += "mul " + time.toString() + "," + time.toString() + "," + cycle.toString() + "\n";
				}
				
				
				code += "mul " + temp.toString() + "," + time.toString() + "," + uSpeed.toString() + "\n";
				if (_needV)
				{
					code += "frc " + temp2.toString() + "," + temp.toString() + "\n";
					code += "sub " + vOffset.toString() + "," + temp.toString() + "," + temp2.toString() + "\n";
					code += "mul " + vOffset.toString() + "," + vOffset.toString() + "," + vStep.toString() + "\n";
					code += "add " + v.toString() + "," + v.toString() + "," + vOffset.toString() + "\n";
				}
				code += stepDiv(temp, temp, uStep, temp2);
				code += "add " + u.toString() + "," + u.toString() + "," + temp.toString() + "\n";
				
				return code;
			}
			else
			{
				return "";
			}
		}
		
		private function stepDiv(destination:ShaderRegisterElement, source1:ShaderRegisterElement, source2:ShaderRegisterElement, temp:ShaderRegisterElement):String
		{
			return "div " + temp.toString() + "," + source1.toString() + "," + source2.toString() + "\n" +
					"frc " + destination.toString() + "," + temp.toString() + "\n"+
					"sub " + temp.toString() + "," + temp.toString() + "," + destination.toString() + "\n" +
					"mul " + destination.toString() + "," + temp.toString() + "," + source2.toString() + "\n";
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable):void
		{
			if (_animation.needUV)
			{
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, uvParamConst1.index, _data, 2);
			}
		}
	
	}

}
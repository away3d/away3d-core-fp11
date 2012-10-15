package a3dparticle.animators.actions.uv
{
	import a3dparticle.animators.actions.AllParticleAction;
	import a3dparticle.animators.ParticleAnimation;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3DProgramType;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class UVSeqPicByLifeGlobal extends AllParticleAction
	{		
		private var uvParamConst:ShaderRegisterElement;
		
		private var _needV:Boolean;
		
		private var _data:Vector.<Number>;
		
		public function UVSeqPicByLifeGlobal(columns:int, rows:int , usingNum:int = int.MAX_VALUE)
		{
			priority = ParticleAnimation.POST_PRIORITY + 5;
			
			var total:int = Math.min(usingNum, columns * rows);
			if (rows > 1)_needV = true;
			var uTotal:Number = total / columns;
			var uStep:Number = 1 / columns;
			var vStep:Number = 1 / rows;
			_data = Vector.<Number>([uTotal, uStep, vStep, 0]);
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
				uvParamConst = shaderRegisterCache.getFreeVertexConstant();
				
				var uTotal:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst.regName, uvParamConst.index, "x");
				var uStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst.regName, uvParamConst.index, "y");
				var vStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst.regName, uvParamConst.index, "z");
				
				
				var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
				var vOffset:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
				temp = new ShaderRegisterElement(temp.regName, temp.index, "x");
				var temp2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
				
				
				var u:ShaderRegisterElement = new ShaderRegisterElement(_animation.uvTarget.regName, _animation.uvTarget.index, "x");
				var v:ShaderRegisterElement = new ShaderRegisterElement(_animation.uvTarget.regName, _animation.uvTarget.index, "y");
				
				var code:String = "";
				//scale uv
				code += "mul " + u.toString() + "," + u.toString() + "," + uStep.toString() + "\n";
				if (_needV) code += "mul " + v.toString() + "," + v.toString() + "," + vStep.toString() + "\n";
				
				code += "mul " + temp.toString() + "," + _animation.vertexLife.toString() + "," + uTotal.toString() + "\n";
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
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, uvParamConst.index, _data, 1);
			}
		}
	
	}

}
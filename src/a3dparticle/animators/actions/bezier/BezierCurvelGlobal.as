package a3dparticle.animators.actions.bezier
{
	import a3dparticle.animators.actions.AllParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.compilation.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class BezierCurvelGlobal extends AllParticleAction
	{
		
		private var _controlPoint:Vector3D;
		private var _endPoint:Vector3D;
		
		public function BezierCurvelGlobal(control:Vector3D,end:Vector3D)
		{
			_controlPoint = control;
			_endPoint = end;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var _controlConst:ShaderRegisterElement = shaderRegisterCache.getFreeVertexConstant();
			saveRegisterIndex("_controlConst", _controlConst.index);
			var _endConst:ShaderRegisterElement = shaderRegisterCache.getFreeVertexConstant();
			saveRegisterIndex("_endConst", _endConst.index);
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var rev_time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var time_2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var time_temp:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			shaderRegisterCache.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "xyz");
			shaderRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "sub " + rev_time.toString() + "," + animationRegistersManager.vertexOneConst.toString() + "," + animationRegistersManager.vertexLife.toString() + "\n";
			code += "mul " + time_2.toString() + "," + animationRegistersManager.vertexLife.toString() + "," + animationRegistersManager.vertexLife.toString() + "\n";
			
			code += "mul " + time_temp.toString() + "," + animationRegistersManager.vertexLife.toString() +"," + rev_time.toString() + "\n";
			code += "mul " + time_temp.toString() + "," + time_temp.toString() +"," + animationRegistersManager.vertexTwoConst.toString() + "\n";
			code += "mul " + distance.toString() + "," + time_temp.toString() +"," + _controlConst.toString() + "\n";
			code += "add " + animationRegistersManager.offsetTarget.toString() +".xyz," + distance.toString() + "," + animationRegistersManager.offsetTarget.toString() + ".xyz\n";
			code += "mul " + distance.toString() + "," + time_2.toString() +"," + _endConst.toString() + "\n";
			code += "add " + animationRegistersManager.offsetTarget.toString() +".xyz," + distance.toString() + "," + animationRegistersManager.offsetTarget.toString() + ".xyz\n";
			
			if (_animation.needVelocity)
			{
				code += "mul " + time_2.toString() + "," + animationRegistersManager.vertexLife.toString() + "," + animationRegistersManager.vertexTwoConst.toString() + "\n";
				code += "sub " + time_temp.toString() + "," + animationRegistersManager.vertexOneConst.toString() + "," + time_2.toString() + "\n";
				code += "mul " + time_temp.toString() + "," + animationRegistersManager.vertexTwoConst.toString() + "," + time_temp.toString() + "\n";
				code += "mul " + distance.toString() + "," + _controlConst.toString() + "," + time_temp.toString() + "\n";
				code += "add " + animationRegistersManager.velocityTarget.toString() + ".xyz," + distance.toString() + "," + animationRegistersManager.velocityTarget.toString() + ".xyz\n";
				code += "mul " + distance.toString() + "," + _endConst.toString() + "," + time_2.toString() + "\n";
				code += "add " + animationRegistersManager.velocityTarget.toString() + ".xyz," + distance.toString() + "," + animationRegistersManager.velocityTarget.toString() + ".xyz\n";
			}
			
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, getRegisterIndex("_controlConst"), Vector.<Number>([ _controlPoint.x, _controlPoint.y, _controlPoint.z, 0 ]));
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, getRegisterIndex("_endConst"), Vector.<Number>([ _endPoint.x, _endPoint.y, _endPoint.z, 0 ]));
		}
		
	}

}
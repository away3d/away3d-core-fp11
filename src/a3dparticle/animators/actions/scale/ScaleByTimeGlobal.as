package a3dparticle.animators.actions.scale 
{
	import a3dparticle.animators.actions.AllParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class ScaleByTimeGlobal extends AllParticleAction
	{
		private var _min:Number;
		private var _max:Number;
		private var _time:Number;
		
		private var scaleByTimeConst:ShaderRegisterElement;
		
		public function ScaleByTimeGlobal(min:Number,max:Number,time:Number) 
		{
			priority = 3;
			_min = min;
			_max = max;
			_time = time;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			scaleByTimeConst = shaderRegisterCache.getFreeVertexConstant();
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var frc:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index,"w");
			
			var code:String = "";
			code += "div " + frc.toString() + "," + _animation.vertexTime.toString() + "," + scaleByTimeConst.toString() + ".w\n";
			code += "frc " + frc.toString() + "," + frc.toString() + "\n";
			code += "mul " + frc.toString() + "," + frc.toString() + ","+_animation.piConst.toString()+"\n";
			code += "sin " + frc.toString() + "," + frc.toString() + "\n";
			code += "mul " + frc.toString() + "," + frc.toString() + "," + scaleByTimeConst.toString() + ".y\n";
			code += "add " + frc.toString() + "," + frc.toString() + "," + scaleByTimeConst.toString() + ".x\n";
			
			code += "mul " + _animation.scaleAndRotateTarget.toString() +"," +_animation.scaleAndRotateTarget.toString() + "," + frc.toString() + "\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			var delta:Number = Math.abs(_max - _min) / 2;
			var center:Number = (_min + _max) / 2;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, scaleByTimeConst.index, Vector.<Number>([center,delta,0,_time]));
		}
		
	}

}
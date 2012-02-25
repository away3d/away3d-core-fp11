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
	 * @author liaocheng
	 */
	public class ScaleByTimeGlobal extends AllParticleAction
	{
		
		private var _data:Vector.<Number>;
		
		private var scaleByTimeConst:ShaderRegisterElement;
		
		public function ScaleByTimeGlobal(min:Number,max:Number,time:Number) 
		{
			priority = 3;
			
			var delta:Number = Math.abs(max - min) / 2;
			var center:Number = (max + min) / 2;
			
			_data = Vector.<Number>([center, delta, 0, Math.PI * 2 / time]);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			scaleByTimeConst = shaderRegisterCache.getFreeVertexConstant();
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexSingleTemp();
			
			var code:String = "";
			code += "mul " + temp.toString() + "," + _animation.vertexTime.toString() + "," + scaleByTimeConst.toString() + ".w\n";
			code += "sin " + temp.toString() + "," + temp.toString() + "\n";
			code += "mul " + temp.toString() + "," + temp.toString() + "," + scaleByTimeConst.toString() + ".y\n";
			code += "add " + temp.toString() + "," + temp.toString() + "," + scaleByTimeConst.toString() + ".x\n";
			
			code += "mul " + _animation.scaleAndRotateTarget.toString() +"," +_animation.scaleAndRotateTarget.toString() + "," + temp.toString() + "\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, scaleByTimeConst.index, _data);
		}
		
	}

}
package a3dparticle.animators.actions 
{
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;
	
	
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class AccelerateAction extends AllParticleAction
	{
		private var _acc:Vector3D;
		
		private var accVelConst:ShaderRegisterElement;
		
		public function AccelerateAction(acc:Vector3D) 
		{
			_acc = acc;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			accVelConst = shaderRegisterCache.getFreeVertexConstant();
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			
			var accDistance:ShaderRegisterElement = new ShaderRegisterElement(temp.regName,temp.index,"xyz");
			var squDeltaTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName,temp.index,"w");
			var code:String = "";
			code += "mul " + squDeltaTime.toString() +"," + _animation.vertexTime.toString() + "," + _animation.vertexTime.toString() + "\n";
			code += "mul " + accDistance.toString() +"," + squDeltaTime.toString() + "," + accVelConst.toString() + "\n";
			code += "add " + _animation.postionTarget.toString() +".xyz," + accDistance.toString() + "," + _animation.postionTarget.toString() + ".xyz\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, accVelConst.index, Vector.<Number>([ _acc.x/2, _acc.y/2, _acc.z/2, 0 ]));
		}
		
	}

}
package a3dparticle.animators.actions.acceleration 
{
	import a3dparticle.animators.actions.AllParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class AccelerateGlobal extends AllParticleAction
	{
		private var _acc:Vector3D;
		
		private var accVelConst:ShaderRegisterElement;
		
		public function AccelerateGlobal(acc:Vector3D) 
		{
			_acc = acc;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			accVelConst = shaderRegisterCache.getFreeVertexConstant();
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp,1);
			var code:String = "";
			code += "mul " + temp.toString() +"," + _animation.vertexTime.toString() + "," + accVelConst.toString() + "\n";
			
			if (_animation.needVelocity)
			{
				var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
				code += "mul " + temp2.toString() + "," + temp.toString() + "," + _animation.TwoConst.toString() + "\n";
				code += "add " + _animation.velocityTarget.toString() + ".xyz," + temp2.toString() + ".xyz," + _animation.velocityTarget.toString() + "\n";
			}
			shaderRegisterCache.removeVertexTempUsage(temp);
			
			code += "mul " + temp.toString() +"," + temp.toString() + "," + _animation.vertexTime.toString() + "\n";
			code += "add " + _animation.offsetTarget.toString() +".xyz," + temp.toString() + "," + _animation.offsetTarget.toString() + ".xyz\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, accVelConst.index, Vector.<Number>([ _acc.x/2, _acc.y/2, _acc.z/2, 0 ]));
		}
		
	}

}
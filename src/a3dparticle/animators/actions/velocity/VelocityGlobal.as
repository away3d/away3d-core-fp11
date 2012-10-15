package a3dparticle.animators.actions.velocity 
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
	public class VelocityGlobal extends AllParticleAction
	{
		private var _velocity:Vector3D;
		
		private var velocityConst:ShaderRegisterElement;
		
		public function VelocityGlobal(velocity:Vector3D) 
		{
			_velocity = velocity;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			velocityConst = shaderRegisterCache.getFreeVertexConstant();
			var distance:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var code:String = "";
			code += "mul " + distance.toString() + "," + _animation.vertexTime.toString() + "," + velocityConst.toString() + "\n";
			code += "add " + _animation.offsetTarget.toString() +"," + distance.toString() + "," + _animation.offsetTarget.toString() + "\n";
			if (_animation.needVelocity)
			{
				code += "add " + _animation.velocityTarget.toString() + ".xyz," + velocityConst.toString() + ".xyz," + _animation.velocityTarget.toString() + "\n";
			}
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, velocityConst.index, Vector.<Number>([ _velocity.x, _velocity.y, _velocity.z, 0 ]));
		}
		
	}

}
package a3dparticle.animators.actions.velocity
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
	 * @author ...
	 */
	public class VelocityGlobal extends AllParticleAction
	{
		private var _velocity:Vector3D;
		
		
		public function VelocityGlobal(velocity:Vector3D)
		{
			_velocity = velocity;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var velocityConst:ShaderRegisterElement = shaderRegisterCache.getFreeVertexConstant();
			saveRegisterIndex("velocityConst", velocityConst.index);
			var distance:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var code:String = "";
			code += "mul " + distance.toString() + "," + animationRegistersManager.vertexTime.toString() + "," + velocityConst.toString() + "\n";
			code += "add " + animationRegistersManager.offsetTarget.toString() +"," + distance.toString() + "," + animationRegistersManager.offsetTarget.toString() + "\n";
			if (_animation.needVelocity)
			{
				code += "add " + animationRegistersManager.velocityTarget.toString() + ".xyz," + velocityConst.toString() + ".xyz," + animationRegistersManager.velocityTarget.toString() + "\n";
			}
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, getRegisterIndex("velocityConst"), Vector.<Number>([ _velocity.x, _velocity.y, _velocity.z, 0 ]));
		}
		
	}

}
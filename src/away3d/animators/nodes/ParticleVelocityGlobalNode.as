package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.states.ParticleVelocityGlobalState;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleVelocityGlobalNode extends GlobalParticleNodeBase
	{
		
		public static const NAME:String = "ParticleVelocityGlobalNode";
		public static const VELOCITY_STREAM_REGISTER:int = 0;
		
		private var _velocity:Vector3D;
		
		public function ParticleVelocityGlobalNode(velocity:Vector3D)
		{
			super(NAME);
			_stateClass = ParticleVelocityGlobalState;
			
			_velocity = velocity.clone();
		}
		
		public function get velocity():Vector3D
		{
			return _velocity;
		}
		
		public function set velocity(value:Vector3D):void
		{
			_velocity = value.clone();
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			var velocityConst:ShaderRegisterElement = activatedCompiler.getFreeVertexConstant();
			activatedCompiler.setRegisterIndex(this, VELOCITY_STREAM_REGISTER, velocityConst.index);

			var distance:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			var code:String = "";
			code += "mul " + distance.toString() + "," + activatedCompiler.vertexTime.toString() + "," + velocityConst.toString() + "\n";
			code += "add " + activatedCompiler.offsetTarget.toString() +"," + distance.toString() + "," + activatedCompiler.offsetTarget.toString() + "\n";
			if (sharedSetting.needVelocity)
			{
				code += "add " + activatedCompiler.velocityTarget.toString() + ".xyz," + velocityConst.toString() + ".xyz," + activatedCompiler.velocityTarget.toString() + "\n";
			}
			return code;
		}
		
	}

}
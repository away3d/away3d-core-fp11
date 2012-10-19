package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleParamter;
	import away3d.animators.states.ParticleVelocityLocalState;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleVelocityLocalNode extends LocalParticleNodeBase
	{
		public static const NAME:String = "ParticleVelocityLocalNode";
		public static const VELOCITY_STREAM_REGISTER:int = 0;
		
		public function ParticleVelocityLocalNode()
		{
			super(NAME);
			_stateClass = ParticleVelocityLocalState;
			_dataLenght = 3;
			initOneData();
		}
		
		override public function generatePorpertyOfOneParticle(param:ParticleParamter):void
		{
			var _tempVelocity:Vector3D = param[NAME];
			if (!_tempVelocity) throw new Error("there is no " + NAME + " in param!");
			
			_oneData[0] = _tempVelocity.x;
			_oneData[1] = _tempVelocity.y;
			_oneData[2] = _tempVelocity.z;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			
			var distance:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			distance = new ShaderRegisterElement(distance.regName, distance.index, "xyz");
			
			var velocityAttribute:ShaderRegisterElement = activatedCompiler.getFreeVertexAttribute();
			activatedCompiler.setRegisterIndex(this, VELOCITY_STREAM_REGISTER, velocityAttribute.index);
			
			var code:String = "";
			code += "mul " + distance.toString() + "," + activatedCompiler.vertexTime.toString() + "," + velocityAttribute.toString() + "\n";
			code += "add " + activatedCompiler.offsetTarget.toString() +"," + distance.toString() + "," + activatedCompiler.offsetTarget.toString() + "\n";
			if (sharedSetting.needVelocity)
			{
				code += "add " + activatedCompiler.velocityTarget.toString() + ".xyz," + velocityAttribute.toString() + ".xyz," + activatedCompiler.velocityTarget.toString() + "\n";
			}
			return code;
		}
		
	}

}
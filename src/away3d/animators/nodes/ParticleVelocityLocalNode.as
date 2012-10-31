package away3d.animators.nodes
{
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.states.ParticleVelocityLocalState;
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
		
		override public function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			var _tempVelocity:Vector3D = param[NAME];
			if (!_tempVelocity) throw new Error("there is no " + NAME + " in param!");
			
			_oneData[0] = _tempVelocity.x;
			_oneData[1] = _tempVelocity.y;
			_oneData[2] = _tempVelocity.z;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			
			var distance:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			distance = new ShaderRegisterElement(distance.regName, distance.index, "xyz");
			
			var velocityAttribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, VELOCITY_STREAM_REGISTER, velocityAttribute.index);
			
			var code:String = "";
			code += "mul " + distance.toString() + "," + animationRegisterCache.vertexTime.toString() + "," + velocityAttribute.toString() + "\n";
			code += "add " + animationRegisterCache.offsetTarget.toString() +"," + distance.toString() + "," + animationRegisterCache.offsetTarget.toString() + "\n";
			if (animationRegisterCache.needVelocity)
			{
				code += "add " + animationRegisterCache.velocityTarget.toString() + ".xyz," + velocityAttribute.toString() + ".xyz," + animationRegisterCache.velocityTarget.toString() + "\n";
			}
			return code;
		}
		
	}

}
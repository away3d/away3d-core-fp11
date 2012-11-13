package away3d.animators.nodes
{
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.data.ParticleProperties;
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.states.ParticleVelocityState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleVelocityNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const VELOCITY_INDEX:int = 0;
		
		/** @private */
		arcane var _velocity:Vector3D;
		
		/**
		 * Reference for velocity node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> object representing the direction of movement on the particle.
		 */
		public static const VELOCITY_VECTOR3D:String = "VelocityVector3D";
		
		/**
		 * Creates a new <code>ParticleVelocityNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
		 * @param    [optional] velocity        Defines the default velocity vector of the node, used when in global mode.
		 */
		public function ParticleVelocityNode(mode:uint, velocity:Vector3D = null)
		{
			super("ParticleVelocityNode" + mode, mode, 3);
			
			_stateClass = ParticleVelocityState;
			
			_velocity = velocity || new Vector3D();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var velocityValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, VELOCITY_INDEX, velocityValue.index);

			var distance:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var code:String = "";
			code += "mul " + distance + "," + animationRegisterCache.vertexTime + "," + velocityValue + "\n";
			code += "add " + animationRegisterCache.positionTarget +"," + distance + "," + animationRegisterCache.positionTarget + "\n";
			
			if (animationRegisterCache.needVelocity)
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + velocityValue + ".xyz," + animationRegisterCache.velocityTarget + "\n";
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleProperties):void
		{
			var _tempVelocity:Vector3D = param[VELOCITY_VECTOR3D];
			if (!_tempVelocity)
				throw new Error("there is no " + VELOCITY_VECTOR3D + " in param!");
			
			_oneData[0] = _tempVelocity.x;
			_oneData[1] = _tempVelocity.y;
			_oneData[2] = _tempVelocity.z;
		}
	}
}
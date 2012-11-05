package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.states.ParticleAccelerationState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleAccelerationNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const ACCELERATION_INDEX:int = 0;
		
		/** @private */
		arcane var _halfAcceleration:Vector3D;
		
		private var _acceleration:Vector3D;
		
		/**
		 * Used to set the acceleration node into local property mode.
		 */
		public static const LOCAL:uint = 0;
		
		/**
		 * Used to set the acceleration node into global property mode.
		 */
		public static const GLOBAL:uint = 1;
		
		/**
		 * Reference for acceleration node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> object representing the direction of acceleration on the particle.
		 */
		public static const ACCELERATION_VECTOR3D:String = "AccelerationVector3D";
		
		/**
		 * Defines the default acceleration vector of the node, used when in global mode.
		 */
		public function get acceleration():Vector3D
		{
			return _acceleration;
		}
		
		public function set acceleration(value:Vector3D):void
		{
			_acceleration.x = value.x;
			_acceleration.y = value.y;
			_acceleration.z = value.z;
			_halfAcceleration.x = value.x / 2;
			_halfAcceleration.y = value.y / 2;
			_halfAcceleration.z = value.z / 2;
		}
		
		/**
		 * Creates a new <code>ParticleAccelerationNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation defaults to acting on local properties of a particle or global properties of the node.
		 * @param    [optional] acceleration    Defines the default acceleration vector of the node, used when in global mode.
		 */
		public function ParticleAccelerationNode(mode:uint, acceleration:Vector3D = null)
		{
			super("ParticleAccelerationNode" + mode, mode, 3);
			
			_stateClass = ParticleAccelerationState;
			
			_acceleration = acceleration || new Vector3D();
			
			_halfAcceleration = _acceleration.clone();
			_halfAcceleration.scaleBy(0.5);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var accelerationValue:ShaderRegisterElement = (_mode == LOCAL)? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, ACCELERATION_INDEX, accelerationValue.index);
			
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(temp,1);
			
			
			var code:String = "mul " + temp +"," + animationRegisterCache.vertexTime + "," + accelerationValue + "\n";
			
			if (animationRegisterCache.needVelocity)
			{
				var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				code += "mul " + temp2 + "," + temp + "," + animationRegisterCache.vertexTwoConst + "\n";
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + temp2 + ".xyz," + animationRegisterCache.velocityTarget + "\n";
			}
			animationRegisterCache.removeVertexTempUsage(temp);
			
			code += "mul " + temp +"," + temp + "," + animationRegisterCache.vertexTime + "\n";
			code += "add " + animationRegisterCache.positionTarget +".xyz," + temp + "," + animationRegisterCache.positionTarget + ".xyz\n";
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			var tempAcceleration:Vector3D = param[ACCELERATION_VECTOR3D];
			if (!tempAcceleration)
				throw new Error("there is no " + ACCELERATION_VECTOR3D + " in param!");
			
			_oneData[0] = tempAcceleration.x / 2;
			_oneData[1] = tempAcceleration.y / 2;
			_oneData[2] = tempAcceleration.z / 2;
		}
	}
}
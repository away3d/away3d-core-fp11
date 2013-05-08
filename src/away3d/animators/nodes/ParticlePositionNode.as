package away3d.animators.nodes
{
	import flash.geom.*;
	
	import away3d.*;
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.states.*;
	import away3d.materials.compilation.*;
	import away3d.materials.passes.*;
	
	use namespace arcane;
	
	/**
	 * A particle animation node used to set the starting position of a particle.
	 */
	public class ParticlePositionNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const POSITION_INDEX:uint = 0;
		
		/** @private */
		arcane var _position:Vector3D;
		
		/**
		 * Reference for position node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> object representing position of the particle.
		 */
		public static const POSITION_VECTOR3D:String = "PositionVector3D";
		
		/**
		 * Creates a new <code>ParticlePositionNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
		 * @param    [optional] position        Defines the default position of the particle when in global mode. Defaults to 0,0,0.
		 */
		public function ParticlePositionNode(mode:uint, position:Vector3D = null)
		{
			super("ParticlePosition", mode, 3);
			
			_stateClass = ParticlePositionState;
			
			_position = position || new Vector3D();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			pass=pass;
			var positionAttribute:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, POSITION_INDEX, positionAttribute.index);
			
			return "add " + animationRegisterCache.positionTarget +".xyz," + positionAttribute + ".xyz," + animationRegisterCache.positionTarget + ".xyz\n";
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):ParticlePositionState
		{
			return animator.getAnimationState(this) as ParticlePositionState;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleProperties):void
		{
			var offset:Vector3D = param[POSITION_VECTOR3D];
			if (!offset)
				throw(new Error("there is no " + POSITION_VECTOR3D + " in param!"));
			
			_oneData[0] = offset.x;
			_oneData[1] = offset.y;
			_oneData[2] = offset.z;
		}
	}
}
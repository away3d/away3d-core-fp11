package away3d.animators.nodes
{
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.states.ParticlePositionState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 * @author ...
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
			super("ParticlePositionNode" + mode, mode, 3);
			
			_stateClass = ParticlePositionState;
			
			_position = position || new Vector3D();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var positionAttribute:ShaderRegisterElement = (_mode == ParticlePropertiesMode.LOCAL)? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, POSITION_INDEX, positionAttribute.index);
			
			return "add " + animationRegisterCache.positionTarget +"," + positionAttribute + ".xyz," + animationRegisterCache.positionTarget + "\n";
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
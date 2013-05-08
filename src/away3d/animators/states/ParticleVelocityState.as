package away3d.animators.states
{
	import flash.utils.Dictionary;
	import away3d.animators.data.ParticlePropertiesMode;
	import flash.display3D.Context3DVertexBufferFormat;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleVelocityNode;
	import away3d.animators.ParticleAnimator;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleVelocityState extends ParticleStateBase
	{
		private var _particleVelocityNode:ParticleVelocityNode;
		private var _velocity:Vector3D;
		
		/**
		 * Defines the default velocity vector of the state, used when in global mode.
		 */
		public function get velocity():Vector3D
		{
			return _velocity;
		}
		
		public function set velocity(value:Vector3D):void
		{
			_velocity = value;
		}
		
		/**
		 *
		 */
		public function getVelocities():Vector.<Vector3D>
		{
			return _dynamicProperties;
		}
		
		public function setVelocities(value:Vector.<Vector3D>):void
		{
			_dynamicProperties = value;
			
			_dynamicPropertiesDirty = new Dictionary(true);
		}
		
		public function ParticleVelocityState(animator:ParticleAnimator, particleVelocityNode:ParticleVelocityNode)
		{
			super(animator, particleVelocityNode);
			
			_particleVelocityNode = particleVelocityNode;
			_velocity = _particleVelocityNode._velocity;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			if (_particleVelocityNode.mode == ParticlePropertiesMode.LOCAL_DYNAMIC && !_dynamicPropertiesDirty[animationSubGeometry])
				updateDynamicProperties(animationSubGeometry);
			
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleVelocityNode.VELOCITY_INDEX);
			
			if (_particleVelocityNode.mode == ParticlePropertiesMode.GLOBAL)
				animationRegisterCache.setVertexConst(index, _velocity.x, _velocity.y, _velocity.z);
			else
				animationSubGeometry.activateVertexBuffer(index, _particleVelocityNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		}
	}
}
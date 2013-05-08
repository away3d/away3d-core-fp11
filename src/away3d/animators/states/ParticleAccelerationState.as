package away3d.animators.states
{
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.arcane;
	import flash.display3D.Context3DVertexBufferFormat;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleAccelerationNode;
	import away3d.animators.ParticleAnimator;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleAccelerationState extends ParticleStateBase
	{
		private var _particleAccelerationNode:ParticleAccelerationNode;
		private var _acceleration:Vector3D;
		private var _halfAcceleration:Vector3D;
		
		/**
		 * Defines the acceleration vector of the state, used when in global mode.
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
			
			updateAccelerationData();
		}
		
		public function ParticleAccelerationState(animator:ParticleAnimator, particleAccelerationNode:ParticleAccelerationNode)
		{
			super(animator, particleAccelerationNode);
			
			_particleAccelerationNode = particleAccelerationNode;
			_acceleration = _particleAccelerationNode._acceleration;
			
			updateAccelerationData();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			// TODO: not used
			renderable=renderable;
			camera=camera;
			
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleAccelerationNode.ACCELERATION_INDEX);
			
			if (_particleAccelerationNode.mode == ParticlePropertiesMode.LOCAL_STATIC) {
				animationSubGeometry.activateVertexBuffer(index, _particleAccelerationNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			} else {
				animationRegisterCache.setVertexConst(index, _halfAcceleration.x, _halfAcceleration.y, _halfAcceleration.z);
			}
		}
		
		private function updateAccelerationData():void
		{
			if (_particleAccelerationNode.mode == ParticlePropertiesMode.GLOBAL)
				_halfAcceleration = new Vector3D(_acceleration.x / 2, _acceleration.y / 2, _acceleration.z / 2);
		}
	}

}
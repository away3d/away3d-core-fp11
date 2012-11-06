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
		
		public function ParticleAccelerationState(animator:ParticleAnimator, particleAccelerationNode:ParticleAccelerationNode)
		{
			super(animator, particleAccelerationNode);
			
			_particleAccelerationNode = particleAccelerationNode;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleAccelerationNode.ACCELERATION_INDEX);
			
			if (_particleAccelerationNode.mode == ParticlePropertiesMode.LOCAL) {
				animationSubGeometry.activateVertexBuffer(index, _particleAccelerationNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			} else {
				var halfAcceleration:Vector3D = _particleAccelerationNode._halfAcceleration;
				animationRegisterCache.setVertexConst(index, halfAcceleration.x, halfAcceleration.y, halfAcceleration.z);
			}
		}
		
	}

}
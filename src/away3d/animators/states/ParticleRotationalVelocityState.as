package away3d.animators.states
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleRotationalVelocityNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleRotationalVelocityState extends ParticleStateBase
	{
		private var _particleRotationalVelocityNode:ParticleRotationalVelocityNode;
		
		public function ParticleRotationalVelocityState(animator:ParticleAnimator, particleRotationNode:ParticleRotationalVelocityNode)
		{
			super(animator, particleRotationNode);
			
			_particleRotationalVelocityNode = particleRotationNode;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleRotationalVelocityNode.ROTATIONALVELOCITY_INDEX);
			if (_particleRotationalVelocityNode.mode == ParticleRotationalVelocityNode.LOCAL)
				animationSubGeometry.activateVertexBuffer(index, _particleRotationalVelocityNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
			else
			{
				var rotationVelocityData:Vector3D = _particleRotationalVelocityNode._rotationVelocityData;
				animationRegisterCache.setVertexConst(index, rotationVelocityData.x, rotationVelocityData.y, rotationVelocityData.z, rotationVelocityData.w);
			}
		}
	}
}
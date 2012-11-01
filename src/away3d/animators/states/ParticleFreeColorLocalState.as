package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleFreeColorLocalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;

	/**
	 * ...
	 */
	public class ParticleFreeColorLocalState extends ParticleStateBase
	{
		private var _particleFreeColorLocalState:ParticleFreeColorLocalNode;
		
		public function ParticleFreeColorLocalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleFreeColorLocalState = particleNode as ParticleFreeColorLocalNode;
		}
			
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			if (animationRegisterCache.needFragmentAnimation)
			{
				var index:int;
				if (_particleFreeColorLocalState.hasMult)
				{
					index = animationRegisterCache.getRegisterIndex(particleNode, ParticleFreeColorLocalNode.COLOR_MULTIPLE_STREAM_REGISTER);
					animationSubGeometry.activateVertexBuffer(index, _particleFreeColorLocalState.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
					if (_particleFreeColorLocalState.hasOffset)
					{
						index = animationRegisterCache.getRegisterIndex(particleNode, ParticleFreeColorLocalNode.COLOR_OFFSET_STREAM_REGISTER);
						animationSubGeometry.activateVertexBuffer(index, _particleFreeColorLocalState.dataOffset + 4, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
					}
				}
				else
				{
					index = animationRegisterCache.getRegisterIndex(particleNode, ParticleFreeColorLocalNode.COLOR_OFFSET_STREAM_REGISTER);
					animationSubGeometry.activateVertexBuffer(index, _particleFreeColorLocalState.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
				}
			}
		}
		
	}

}
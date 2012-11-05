package away3d.animators.states
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleOscillatorNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleOscillatorState extends ParticleStateBase
	{
		private var _particleOscillatorNode:ParticleOscillatorNode;
		
		public function ParticleOscillatorState(animator:ParticleAnimator, particleOscillatorNode:ParticleOscillatorNode)
		{
			super(animator, particleOscillatorNode);
			
			_particleOscillatorNode = particleOscillatorNode;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleOscillatorNode.OSCILLATOR_INDEX), _particleOscillatorNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
		}
	}
}
package away3d.animators.states
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleSpriteSheetNode;
	import away3d.animators.ParticleAnimator;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleSpriteSheetState extends ParticleStateBase
	{
		
		private var _particleSpriteSheetNode:ParticleSpriteSheetNode;

		public function ParticleSpriteSheetState(animator:ParticleAnimator, particleSpriteSheetNode:ParticleSpriteSheetNode)
		{
			super(animator, particleSpriteSheetNode);
			
			_particleSpriteSheetNode = particleSpriteSheetNode;
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			if (animationRegisterCache.needUVAnimation)
			{
				var data:Vector.<Number> = _particleSpriteSheetNode._spriteSheetData;
				animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSpriteSheetNode.UV_INDEX_0), data[0], data[1], data[2], data[3]);
				animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSpriteSheetNode.UV_INDEX_1), data[4], data[5]);
			}
		}
	
	}

}
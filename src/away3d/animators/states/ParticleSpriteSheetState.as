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
	import flash.display3D.Context3DVertexBufferFormat;
	
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
				if (_particleSpriteSheetNode._usesCycle)
				{
					var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleSpriteSheetNode.UV_INDEX_1);
					if(_particleSpriteSheetNode.mode == ParticleSpriteSheetNode.GLOBAL)
						animationRegisterCache.setVertexConst(index, data[4], data[5]);
					else
					{
						if (_particleSpriteSheetNode._usesPhase)
							animationSubGeometry.activateVertexBuffer(index, _particleSpriteSheetNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
						else
							animationSubGeometry.activateVertexBuffer(index, _particleSpriteSheetNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_2);
					}
				}
			}
		}
	
	}

}
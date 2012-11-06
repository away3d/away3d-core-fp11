package away3d.animators.states
{
	import flash.geom.Vector3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleScaleNode;
	import away3d.animators.ParticleAnimator;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleScaleState extends ParticleStateBase
	{
		private var _particleScaleNode:ParticleScaleNode;
		
		public function ParticleScaleState(animator:ParticleAnimator, particleScaleNode:ParticleScaleNode)
		{
			super(animator, particleScaleNode);
			
			_particleScaleNode = particleScaleNode;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleScaleNode.SCALE_INDEX);
			
			if (_particleScaleNode.mode == ParticleScaleNode.LOCAL)
			{
				if (_particleScaleNode._usesCycle)
				{
					if(_particleScaleNode._usesPhase)
						animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
					else
						animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
				}
				else
					animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_2);
			} else {
				var data:Vector3D = _particleScaleNode._scaleData;
				animationRegisterCache.setVertexConst(index, data.x, data.y, data.z, data.w);
			}
		}
		
	}
}
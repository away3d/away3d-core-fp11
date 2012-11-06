package away3d.animators.states
{
	import flash.geom.Vector3D;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleOrbitNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleOrbitState extends ParticleStateBase
	{
		private var _particleOrbitNode:ParticleOrbitNode;
		
		public function ParticleOrbitState(animator:ParticleAnimator, particleOrbitNode:ParticleOrbitNode)
		{
			super(animator, particleOrbitNode);
			
			_particleOrbitNode = particleOrbitNode;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleOrbitNode.ORBIT_INDEX);
			
			if (_particleOrbitNode.mode == ParticleOrbitNode.LOCAL)
			{
				if(_particleOrbitNode._usesPhase)
					animationSubGeometry.activateVertexBuffer(index, _particleOrbitNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
				else
					animationSubGeometry.activateVertexBuffer(index, _particleOrbitNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			} else {
				var data:Vector3D = _particleOrbitNode._orbitData;
				animationRegisterCache.setVertexConst(index, data.x, data.y, data.z, data.w);
			}
			
			index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleOrbitNode.EULERS_INDEX);
			animationRegisterCache.setVertexConstFromMatrix(index, _particleOrbitNode._eulersMatrix);
		}
	}

}
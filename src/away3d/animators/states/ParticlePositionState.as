package away3d.animators.states
{
	import flash.geom.Vector3D;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticlePositionNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	
	use namespace arcane;
	
	/**
	 * ...
	 * @author ...
	 */
	public class ParticlePositionState extends ParticleStateBase
	{
		private var _particlePositionNode:ParticlePositionNode;
		
		public function ParticlePositionState(animator:ParticleAnimator, particlePositionNode:ParticlePositionNode)
		{
			super(animator, particlePositionNode);
			
			_particlePositionNode = particlePositionNode;
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticlePositionNode.POSITION_INDEX);
			
			if (_particlePositionNode.mode == ParticlePropertiesMode.LOCAL) {
				animationSubGeometry.activateVertexBuffer(index, _particlePositionNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			} else {
				var position:Vector3D = _particlePositionNode._position;
				animationRegisterCache.setVertexConst(index, position.x, position.y, position.z);
			}
		}
	}
}
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
	import away3d.animators.nodes.ParticleBezierCurveNode;
	import away3d.animators.ParticleAnimator;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleBezierCurveState extends ParticleStateBase
	{
		private var _particleBezierCurveNode:ParticleBezierCurveNode;
		
		public function ParticleBezierCurveState(animator:ParticleAnimator, particleBezierCurveNode:ParticleBezierCurveNode)
		{
			super(animator, particleBezierCurveNode);
			
			_particleBezierCurveNode = particleBezierCurveNode;
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleBezierCurveNode.BEZIER_INDEX);
			
			if (_particleBezierCurveNode.mode == ParticlePropertiesMode.LOCAL) {
				animationSubGeometry.activateVertexBuffer(index, _particleBezierCurveNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
				animationSubGeometry.activateVertexBuffer(index + 1, _particleBezierCurveNode.dataOffset + 3, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			} else {
				var temp:Vector3D = _particleBezierCurveNode.controlPoint;
				animationRegisterCache.setVertexConst(index, temp.x, temp.y, temp.z);
				temp = _particleBezierCurveNode.endPoint;
				animationRegisterCache.setVertexConst(index + 1, temp.x, temp.y, temp.z);
			}
		}
	}
}
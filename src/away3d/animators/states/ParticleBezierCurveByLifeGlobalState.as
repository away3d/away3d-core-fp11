package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleBezierCurveByLifeGlobalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleBezierCurveByLifeGlobalState extends ParticleStateBase
	{
		private var _particleBezierCurveByLifeGlobalNode:ParticleBezierCurveByLifeGlobalNode;
		
		public function ParticleBezierCurveByLifeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleBezierCurveByLifeGlobalNode = particleNode as ParticleBezierCurveByLifeGlobalNode;
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleBezierCurveByLifeGlobalNode.BEZIER_CONSTANT_REGISTER);
			var temp:Vector3D = _particleBezierCurveByLifeGlobalNode.controlPoint;
			animationRegisterCache.setVertexConst(index, temp.x, temp.y, temp.z);
			temp = _particleBezierCurveByLifeGlobalNode.endPoint;
			animationRegisterCache.setVertexConst(index + 1, temp.x, temp.y, temp.z);
		}
		
	}

}
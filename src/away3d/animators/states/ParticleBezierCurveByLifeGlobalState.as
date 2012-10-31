package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleBezierCurveByLifeGlobalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleBezierCurveByLifeGlobalState extends ParticleStateBase
	{
		private var _particleBezierCurveByLifeGlobalState:ParticleBezierCurveByLifeGlobalNode;
		
		public function ParticleBezierCurveByLifeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			_particleBezierCurveByLifeGlobalState = particleNode as ParticleBezierCurveByLifeGlobalNode;
		}
		
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleBezierCurveByLifeGlobalNode.BEZIER_CONSTANT_REGISTER);
			var temp:Vector3D = _particleBezierCurveByLifeGlobalState.controlPoint;
			parameter.animationRegisterCache.setVertexConst(index, temp.x, temp.y, temp.z);
			temp = _particleBezierCurveByLifeGlobalState.endPoint;
			parameter.animationRegisterCache.setVertexConst(index + 1, temp.x, temp.y, temp.z);
		}
		
	}

}
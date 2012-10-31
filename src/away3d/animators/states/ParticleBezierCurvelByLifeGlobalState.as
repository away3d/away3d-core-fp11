package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleBezierCurvelByLifeGlobalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleBezierCurvelByLifeGlobalState extends ParticleStateBase
	{
		private var bzeierNode:ParticleBezierCurvelByLifeGlobalNode;
		public function ParticleBezierCurvelByLifeGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
			bzeierNode = particleNode as ParticleBezierCurvelByLifeGlobalNode;
		}
		
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.activatedCompiler.getRegisterIndex(particleNode, ParticleBezierCurvelByLifeGlobalNode.BEZIER_CONSTANT_REGISTER);
			var temp:Vector3D = bzeierNode.controlPoint;
			parameter.activatedCompiler.setVertexConst(index, temp.x, temp.y, temp.z);
			temp = bzeierNode.endPoint;
			parameter.activatedCompiler.setVertexConst(index + 1, temp.x, temp.y, temp.z);
		}
		
	}

}
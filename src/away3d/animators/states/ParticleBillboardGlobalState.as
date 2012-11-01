package away3d.animators.states
{
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleBillboardGlobalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import away3d.core.math.MathConsts;
	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleBillboardGlobalState extends ParticleStateBase
	{
		private var matrix:Matrix3D = new Matrix3D;
		
		public function ParticleBillboardGlobalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			matrix.copyFrom( renderable.sceneTransform);
			matrix.append(camera.inverseSceneTransform);
			var comps : Vector.<Vector3D> = matrix.decompose(Orientation3D.AXIS_ANGLE);
			matrix.identity();
			matrix.appendRotation( -comps[1].w * MathConsts.RADIANS_TO_DEGREES, comps[1]);
			var index:int = animationRegisterCache.getRegisterIndex(particleNode, ParticleBillboardGlobalNode.MATRIX_CONSTANT_REGISTER);
			animationRegisterCache.setVertexConstFromMatrix(index, matrix);
		}
		
	}

}
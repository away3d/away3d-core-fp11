package away3d.animators.states
{
	import away3d.animators.ParticleAnimator;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.nodes.ParticleBillboardNode;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.MathConsts;
	
	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleBillboardState extends ParticleStateBase
	{
		private var _matrix:Matrix3D = new Matrix3D;
		
		private var _billboardAxis:Vector3D;
		
		/**
		 *
		 */
		public function ParticleBillboardState(animator:ParticleAnimator, particleNode:ParticleBillboardNode)
		{
			super(animator, particleNode);
			billboardAxis = particleNode._billboardAxis;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			// TODO: not used
			animationSubGeometry = animationSubGeometry;
			
			var comps:Vector.<Vector3D>;
			if (_billboardAxis) {
				var pos:Vector3D = renderable.sceneTransform.position;
				var look:Vector3D = camera.sceneTransform.position.subtract(pos);
				var right:Vector3D = look.crossProduct(_billboardAxis);
				right.normalize();
				look = _billboardAxis.crossProduct(right);
				look.normalize();
				
				//create a quick inverse projection matrix
				_matrix.copyFrom(renderable.sceneTransform);
				comps = _matrix.decompose(Orientation3D.AXIS_ANGLE);
				_matrix.copyColumnFrom(0, right);
				_matrix.copyColumnFrom(1, _billboardAxis);
				_matrix.copyColumnFrom(2, look);
				_matrix.copyColumnFrom(3, pos);
				_matrix.appendRotation(-comps[1].w*MathConsts.RADIANS_TO_DEGREES, comps[1]);
			} else {
				//create a quick inverse projection matrix
				_matrix.copyFrom(renderable.sceneTransform);
				_matrix.append(camera.inverseSceneTransform);
				
				//decompose using axis angle rotations
				comps = _matrix.decompose(Orientation3D.AXIS_ANGLE);
				
				//recreate the matrix with just the rotation data
				_matrix.identity();
				_matrix.appendRotation(-comps[1].w*MathConsts.RADIANS_TO_DEGREES, comps[1]);
			}
			
			//set a new matrix transform constant
			animationRegisterCache.setVertexConstFromMatrix(animationRegisterCache.getRegisterIndex(_animationNode, ParticleBillboardNode.MATRIX_INDEX), _matrix);
		}
		
		/**
		 * Defines the billboard axis.
		 */
		public function get billboardAxis():Vector3D
		{
			return _billboardAxis;
		}
		
		public function set billboardAxis(value:Vector3D):void
		{
			_billboardAxis = value? value.clone() : null;
			if (_billboardAxis)
				_billboardAxis.normalize();
		}
	
	}

}

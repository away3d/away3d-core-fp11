package away3d.animators.states
{
	import away3d.*;
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	import away3d.cameras.*;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	
	import flash.display3D.*;
	import flash.geom.*;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleRotateToPositionState extends ParticleStateBase
	{
		private var _particleRotateToPositionNode:ParticleRotateToPositionNode;
		private var _position:Vector3D;
		private var _matrix:Matrix3D = new Matrix3D;
		private var _offset:Vector3D;
		
		/**
		 * Defines the position of the point the particle will rotate to face when in global mode. Defaults to 0,0,0.
		 */
		public function get position():Vector3D
		{
			return _position;
		}
		
		public function set position(value:Vector3D):void
		{
			_position = value;
		}
		
		public function ParticleRotateToPositionState(animator:ParticleAnimator, particleRotateToPositionNode:ParticleRotateToPositionNode)
		{
			super(animator, particleRotateToPositionNode);
			
			_particleRotateToPositionNode = particleRotateToPositionNode;
			_position = _particleRotateToPositionNode._position;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleRotateToPositionNode.POSITION_INDEX);
			
			if (animationRegisterCache.hasBillboard) {
				_matrix.copyFrom(renderable.sceneTransform);
				_matrix.append(camera.inverseSceneTransform);
				animationRegisterCache.setVertexConstFromMatrix(animationRegisterCache.getRegisterIndex(_animationNode, ParticleRotateToPositionNode.MATRIX_INDEX), _matrix);
			}
			
			if (_particleRotateToPositionNode.mode == ParticlePropertiesMode.GLOBAL) {
				_offset = renderable.inverseSceneTransform.transformVector(_position);
				animationRegisterCache.setVertexConst(index, _offset.x, _offset.y, _offset.z);
			} else
				animationSubGeometry.activateVertexBuffer(index, _particleRotateToPositionNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		
		}
	
	}

}

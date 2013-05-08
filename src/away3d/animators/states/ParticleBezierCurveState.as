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
		private var _controlPoint:Vector3D;
		private var _endPoint:Vector3D;
		
		/**
		 * Defines the default control point of the node, used when in global mode.
		 */
		public function get controlPoint():Vector3D
		{
			return _controlPoint;
		}
		
		public function set controlPoint(value:Vector3D):void
		{
			_controlPoint = value;
		}
		
		/**
		 * Defines the default end point of the node, used when in global mode.
		 */
		public function get endPoint():Vector3D
		{
			return _endPoint;
		}
		
		public function set endPoint(value:Vector3D):void
		{
			_endPoint = value;
		}
		
		public function ParticleBezierCurveState(animator:ParticleAnimator, particleBezierCurveNode:ParticleBezierCurveNode)
		{
			super(animator, particleBezierCurveNode);
			
			_particleBezierCurveNode = particleBezierCurveNode;
			_controlPoint = _particleBezierCurveNode._controlPoint;
			_endPoint = _particleBezierCurveNode._endPoint;
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			// TODO: not used
			renderable=renderable;
			camera=camera;

			var controlIndex:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleBezierCurveNode.BEZIER_CONTROL_INDEX);
			var endIndex:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleBezierCurveNode.BEZIER_END_INDEX);
			
			if (_particleBezierCurveNode.mode == ParticlePropertiesMode.LOCAL_STATIC) {
				animationSubGeometry.activateVertexBuffer(controlIndex, _particleBezierCurveNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
				animationSubGeometry.activateVertexBuffer(endIndex, _particleBezierCurveNode.dataOffset + 3, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			} else {
				animationRegisterCache.setVertexConst(controlIndex, _controlPoint.x, _controlPoint.y, _controlPoint.z);
				animationRegisterCache.setVertexConst(endIndex, _endPoint.x, _endPoint.y, _endPoint.z);
			}
		}
	}
}
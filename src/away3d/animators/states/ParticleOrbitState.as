package away3d.animators.states
{
	import flash.geom.Matrix3D;
	import away3d.animators.data.ParticlePropertiesMode;
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
		private var _usesEulers:Boolean;
		private var _usesCycle:Boolean;
		private var _usesPhase:Boolean;
		private var _radius:Number;
		private var _cycleDuration:Number;
		private var _cyclePhase:Number;
		private var _eulers:Vector3D;
		private var _orbitData:Vector3D;
		private var _eulersMatrix:Matrix3D;
		
		/**
		 * Defines the radius of the orbit when in global mode. Defaults to 100.
		 */
		public function get radius():Number
		{
			return _radius;
		}
		public function set radius(value:Number):void
		{
			_radius = value;
			
			updateOrbitData();
		}
		
		/**
		 * Defines the duration of the orbit in seconds, used as a period independent of particle duration when in global mode. Defaults to 1.
		 */
		public function get cycleDuration():Number
		{
			return _cycleDuration;
		}
		public function set cycleDuration(value:Number):void
		{
			_cycleDuration = value;
			
			updateOrbitData();
		}
		
		/**
		 * Defines the phase of the orbit in degrees, used as the starting offset of the cycle when in global mode. Defaults to 0.
		 */
		public function get cyclePhase():Number
		{
			return _cyclePhase;
		}
		public function set cyclePhase(value:Number):void
		{
			_cyclePhase = value;
			
			updateOrbitData();
		}
		
		/**
		 * Defines the euler rotation in degrees, applied to the orientation of the orbit when in global mode.
		 */
		public function get eulers():Vector3D
		{
			return _eulers;
		}
		
		public function set eulers(value:Vector3D):void
		{
			_eulers = value;
			
			updateOrbitData();
			
		}
		
		public function ParticleOrbitState(animator:ParticleAnimator, particleOrbitNode:ParticleOrbitNode)
		{
			super(animator, particleOrbitNode);
			
			_particleOrbitNode = particleOrbitNode;
			_usesEulers = _particleOrbitNode._usesEulers;
			_usesCycle = _particleOrbitNode._usesCycle;
			_usesPhase = _particleOrbitNode._usesPhase;
			_eulers = _particleOrbitNode._eulers;
			_radius = _particleOrbitNode._radius;
			_cycleDuration = _particleOrbitNode._cycleDuration;
			_cyclePhase = _particleOrbitNode._cyclePhase;
			updateOrbitData();
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleOrbitNode.ORBIT_INDEX);
			
			if (_particleOrbitNode.mode == ParticlePropertiesMode.LOCAL_STATIC) {
				if(_usesPhase)
					animationSubGeometry.activateVertexBuffer(index, _particleOrbitNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
				else
					animationSubGeometry.activateVertexBuffer(index, _particleOrbitNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			} else {
				animationRegisterCache.setVertexConst(index, _orbitData.x, _orbitData.y, _orbitData.z, _orbitData.w);
			}
			
			if(_usesEulers)
				animationRegisterCache.setVertexConstFromMatrix(animationRegisterCache.getRegisterIndex(_animationNode, ParticleOrbitNode.EULERS_INDEX), _eulersMatrix);
		}
		
		private function updateOrbitData():void
		{
			if (_usesEulers) {
					_eulersMatrix = new Matrix3D();
					_eulersMatrix.appendRotation(_eulers.x, Vector3D.X_AXIS);
					_eulersMatrix.appendRotation(_eulers.y, Vector3D.Y_AXIS);
					_eulersMatrix.appendRotation(_eulers.z, Vector3D.Z_AXIS);
			}
			if (_particleOrbitNode.mode == ParticlePropertiesMode.GLOBAL)
			{
				_orbitData = new Vector3D(_radius, 0, _radius * Math.PI * 2, _cyclePhase * Math.PI / 180);
				if (_usesCycle)
				{
					if (_cycleDuration <= 0)
						throw(new Error("the cycle duration must be greater than zero"));
					_orbitData.y = Math.PI * 2 / _cycleDuration;
				}
				else
					_orbitData.y = Math.PI * 2;
			}
		}
	}
}
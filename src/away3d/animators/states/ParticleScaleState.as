package away3d.animators.states
{
	import away3d.animators.data.ParticlePropertiesMode;
	
	import flash.geom.Vector3D;
	import flash.display3D.Context3DVertexBufferFormat;
	
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleScaleNode;
	import away3d.animators.ParticleAnimator;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleScaleState extends ParticleStateBase
	{
		private var _particleScaleNode:ParticleScaleNode;
		private var _usesCycle:Boolean;
		private var _usesPhase:Boolean;
		private var _minScale:Number;
		private var _maxScale:Number;
		private var _cycleDuration:Number;
		private var _cyclePhase:Number;
		private var _scaleData:Vector3D;
		
		/**
		 * Defines the end scale of the state, when in global mode. Defaults to 1.
		 */
		public function get minScale():Number
		{
			return _minScale;
		}
		
		public function set minScale(value:Number):void
		{
			_minScale = value;
			
			updateScaleData();
		}
		
		/**
		 * Defines the end scale of the state, when in global mode. Defaults to 1.
		 */
		public function get maxScale():Number
		{
			return _maxScale;
		}
		
		public function set maxScale(value:Number):void
		{
			_maxScale = value;
			
			updateScaleData();
		}
		
		/**
		 * Defines the duration of the animation in seconds, used as a period independent of particle duration when in global mode. Defaults to 1.
		 */
		public function get cycleDuration():Number
		{
			return _cycleDuration;
		}
		
		public function set cycleDuration(value:Number):void
		{
			_cycleDuration = value;
			
			updateScaleData();
		}
		
		/**
		 * Defines the phase of the cycle in degrees, used as the starting offset of the cycle when in global mode. Defaults to 0.
		 */
		public function get cyclePhase():Number
		{
			return _cyclePhase;
		}
		
		public function set cyclePhase(value:Number):void
		{
			_cyclePhase = value;
			
			updateScaleData();
		}
		
		public function ParticleScaleState(animator:ParticleAnimator, particleScaleNode:ParticleScaleNode)
		{
			super(animator, particleScaleNode);
			
			_particleScaleNode = particleScaleNode;
			_usesCycle = _particleScaleNode._usesCycle;
			_usesPhase = _particleScaleNode._usesPhase;
			_minScale = _particleScaleNode._minScale;
			_maxScale = _particleScaleNode._maxScale;
			_cycleDuration = _particleScaleNode._cycleDuration;
			_cyclePhase = _particleScaleNode._cyclePhase;
			
			updateScaleData();
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleScaleNode.SCALE_INDEX);
			
			if (_particleScaleNode.mode == ParticlePropertiesMode.LOCAL_STATIC) {
				if (_usesCycle) {
					if (_usesPhase)
						animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
					else
						animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
				} else
					animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_2);
			} else
				animationRegisterCache.setVertexConst(index, _scaleData.x, _scaleData.y, _scaleData.z, _scaleData.w);
		}
		
		private function updateScaleData():void
		{
			if (_particleScaleNode.mode == ParticlePropertiesMode.GLOBAL) {
				if (_usesCycle) {
					if (_cycleDuration <= 0)
						throw(new Error("the cycle duration must be greater than zero"));
					_scaleData = new Vector3D((_minScale + _maxScale)/2, Math.abs(_minScale - _maxScale)/2, Math.PI*2/_cycleDuration, _cyclePhase*Math.PI/180);
				} else
					_scaleData = new Vector3D(_minScale, _maxScale - _minScale, 0, 0);
			}
		}
	}
}

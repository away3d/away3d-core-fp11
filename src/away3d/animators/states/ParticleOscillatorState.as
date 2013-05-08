package away3d.animators.states
{
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleOscillatorNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleOscillatorState extends ParticleStateBase
	{
		private var _particleOscillatorNode:ParticleOscillatorNode;
		private var _oscillator:Vector3D;
		private var _oscillatorData:Vector3D;
		
		/**
		 * Defines the default oscillator axis (x, y, z) and cycleDuration (w) of the state, used when in global mode.
		 */
		public function get oscillator():Vector3D
		{
			return _oscillator;
		}
		
		public function set oscillator(value:Vector3D):void
		{
			_oscillator = value;
			
			updateOscillatorData();
		}
		
		public function ParticleOscillatorState(animator:ParticleAnimator, particleOscillatorNode:ParticleOscillatorNode)
		{
			super(animator, particleOscillatorNode);
			
			_particleOscillatorNode = particleOscillatorNode;
			_oscillator = _particleOscillatorNode._oscillator;
			
			updateOscillatorData();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleOscillatorNode.OSCILLATOR_INDEX);
			
			if (_particleOscillatorNode.mode == ParticlePropertiesMode.LOCAL_STATIC)
				animationSubGeometry.activateVertexBuffer(index, _particleOscillatorNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
			else
				animationRegisterCache.setVertexConst(index, _oscillatorData.x, _oscillatorData.y, _oscillatorData.z, _oscillatorData.w);
		}
		
		private function updateOscillatorData():void
		{
			if (_particleOscillatorNode.mode == ParticlePropertiesMode.GLOBAL)
			{
				if (_oscillator.w <= 0)
					throw(new Error("the cycle duration must greater than zero"));
				_oscillatorData ||= new Vector3D;
				_oscillatorData.x = _oscillator.x;
				_oscillatorData.y = _oscillator.y;
				_oscillatorData.z = _oscillator.z;
				_oscillatorData.w = Math.PI * 2 / _oscillator.w;
			}
		}
	}
}
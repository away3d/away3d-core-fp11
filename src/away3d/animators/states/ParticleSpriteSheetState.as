package away3d.animators.states
{
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleSpriteSheetNode;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleSpriteSheetState extends ParticleStateBase
	{
		private var _particleSpriteSheetNode:ParticleSpriteSheetNode;
		private var _usesCycle:Boolean;
		private var _usesPhase:Boolean;
		private var _totalFrames:int;
		private var _numColumns:int;
		private var _numRows:int;
		private var _cycleDuration:Number;
		private var _cyclePhase:Number;
		private var _spriteSheetData:Vector.<Number>;
		
		/**
		 * Defines the cycle phase, when in global mode. Defaults to zero.
		 */
		public function get cyclePhase():Number
		{
			return _cyclePhase;
		}
		public function set cyclePhase(value:Number):void
		{
			_cyclePhase = value;
			
			updateSpriteSheetData();
		}
		
		/**
		 * Defines the cycle duration in seconds, when in global mode. Defaults to 1.
		 */
		public function get cycleDuration():Number
		{
			return _cycleDuration;
		}
		public function set cycleDuration(value:Number):void
		{
			_cycleDuration = value;
			
			updateSpriteSheetData();
		}
		
		public function ParticleSpriteSheetState(animator:ParticleAnimator, particleSpriteSheetNode:ParticleSpriteSheetNode)
		{
			super(animator, particleSpriteSheetNode);
			
			_particleSpriteSheetNode = particleSpriteSheetNode;
			
			_usesCycle = _particleSpriteSheetNode._usesCycle;
			_usesPhase = _particleSpriteSheetNode._usesPhase;
			_totalFrames = _particleSpriteSheetNode._totalFrames;
			_numColumns = _particleSpriteSheetNode._numColumns;
			_numRows = _particleSpriteSheetNode._numRows;
			_cycleDuration = _particleSpriteSheetNode._cycleDuration;
			_cyclePhase = _particleSpriteSheetNode._cyclePhase;
			
			updateSpriteSheetData();
		}
		
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			if (animationRegisterCache.needUVAnimation) {
				animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSpriteSheetNode.UV_INDEX_0), _spriteSheetData[0], _spriteSheetData[1], _spriteSheetData[2], _spriteSheetData[3]);
				if (_usesCycle) {
					var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleSpriteSheetNode.UV_INDEX_1);
					if(_particleSpriteSheetNode.mode == ParticlePropertiesMode.LOCAL_STATIC) {
						if (_usesPhase)
							animationSubGeometry.activateVertexBuffer(index, _particleSpriteSheetNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
						else
							animationSubGeometry.activateVertexBuffer(index, _particleSpriteSheetNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_2);
					} else {
						animationRegisterCache.setVertexConst(index, _spriteSheetData[4], _spriteSheetData[5]);
					}
				}
			}
		}
		
		private function updateSpriteSheetData():void
		{
			_spriteSheetData = new Vector.<Number>(8, true);
			
			var uTotal:Number = _totalFrames / _numColumns;
			
			_spriteSheetData[0] = uTotal;
			_spriteSheetData[1] = 1 / _numColumns;
			_spriteSheetData[2] = 1 / _numRows;
			
			if (_usesCycle) {
				if (_cycleDuration <= 0)
					throw(new Error("the cycle duration must be greater than zero"));
				_spriteSheetData[4] = uTotal / _cycleDuration;
				_spriteSheetData[5] = _cycleDuration;
				if (_usesPhase)
					_spriteSheetData[6] = _cyclePhase;
			}
		}
	}
}
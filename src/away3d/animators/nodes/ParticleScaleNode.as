package away3d.animators.nodes
{
	import away3d.animators.data.ParticleParameter;
	import flash.geom.Vector3D;
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.states.ParticleScaleState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleScaleNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const SCALE_INDEX:uint = 0;
		
		/** @private */
		arcane var _minScale:Number;
		
		/** @private */
		arcane var _usesCycle:Boolean;
		
		/** @private */
		arcane var _usesPhase:Boolean;
		
		/** @private */
		arcane var _scaleData:Vector3D;
		
		private var _maxScale:Number;
		private var _cycleSpeed:Number;
		private var _cyclePhase:Number;
		
		/**
		 * Used to set the scale node into local property mode.
		 */
		public static const LOCAL:uint = 0;
		
		/**
		 * Used to set the scale node into global property mode.
		 */
		public static const GLOBAL:uint = 1;
				
		/**
		 * Reference for scale node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> representing the start scale (x), end scale(y), optional cycle speed (z) and phase offset (w) applied to the particle.
		 */
		public static const SCALE_VECTOR3D:String = "ScaleVector3D";
		
		/**
		 * Defines the end scale of the node, when in global mode.
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
		 * Defines the end scale of the node, when in global mode.
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
		 * Defines the cycle speed of the node in revolutions per second, when in global mode. Defaults to zero.
		 */
		public function get cycleSpeed():Number
		{
			return _cycleSpeed;
		}
		public function set cycleSpeed(value:Number):void
		{
			_cycleSpeed = value;
			
			updateScaleData();
		}
		
		/**
		 * Defines the cycle phase of the node in degrees, when in global mode. Defaults to zero.
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
				
		/**
		 * Creates a new <code>ParticleScaleNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation defaults to acting on local properties of a particle or global properties of the node.
		 * @param    [optional] usesCycle       Defines whether the node uses cycle data in its scale transformations. Defaults to false.
		 * @param    [optional] usesPhase       Defines whether the node uses phase data in its scale transformations. Defaults to false.
		 * @param    [optional] minScale        Defines the min scale transform of the node, when in global mode.
		 * @param    [optional] maxScale        Defines the max color transform of the node, when in global mode.
		 * @param    [optional] cycleSpeed      Defines the cycle speed of the node in revolutions per second, when in global mode. Defaults to zero.
		 * @param    [optional] cyclePhase      Defines the cycle phase of the node in degrees, when in global mode. Defaults to zero.
		 */
		public function ParticleScaleNode(mode:uint, usesCycle:Boolean, usesPhase:Boolean, minScale:Number = 1, maxScale:Number = 1, cycleSpeed:Number = 1, cyclePhase:Number = 0)
		{
			var len:int = 2;
			if (usesCycle)
				len++;
			if (usesPhase)
				len++;
			super("ParticleScaleNode" + mode, mode, len, 3);
			
			_stateClass = ParticleScaleState;
			
			_usesCycle = usesCycle;
			_usesPhase = usesPhase;
			
			_minScale = minScale;
			_maxScale = maxScale;
			_cycleSpeed = cycleSpeed;
			_cyclePhase = cyclePhase;
			
			updateScaleData();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var code:String = "";
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
			
			var scaleRegister:ShaderRegisterElement = (_mode == LOCAL)? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, SCALE_INDEX, scaleRegister.index);
			
			if (_usesCycle) {
				code += "mul " + temp + "," + animationRegisterCache.vertexTime + "," + scaleRegister + ".z\n";
				
				if (_usesPhase)
					code += "add " + temp + "," + temp + "," + scaleRegister + ".w\n";
				
				code += "sin " + temp + "," + temp + "\n";
			}
			
			code += "mul " + temp + "," + scaleRegister + ".y," + ((_usesCycle)? temp : animationRegisterCache.vertexLife) + "\n";
			code += "add " + temp + "," + scaleRegister + ".x," + temp + "\n";
			code += "mul " + animationRegisterCache.scaleAndRotateTarget +"," +animationRegisterCache.scaleAndRotateTarget + "," + temp + "\n";
			
			return code;
		}
		
		private function updateScaleData():void
		{
			if (_usesCycle) {
				_scaleData = new Vector3D((_minScale + _maxScale) / 2, Math.abs(_minScale - _maxScale) / 2, Math.PI * 2 / _cycleSpeed, _cyclePhase * Math.PI / 180);
			} else {
				_scaleData = new Vector3D(_minScale, _maxScale - _minScale, 0, 0);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			var scale:Vector3D = param[SCALE_VECTOR3D];
			if (!scale)
				throw(new Error("there is no " + SCALE_VECTOR3D + " in param!"));
			
			if (_usesCycle)
			{
				_oneData[0] = (scale.x + scale.y) / 2;
				_oneData[1] = Math.abs(_minScale - _maxScale) / 2;
				_oneData[2] = Math.PI * 2 / (scale.z || cycleSpeed);
				if (_usesPhase)
					_oneData[3] = scale.w * Math.PI / 180;
			}
			else
			{
				_oneData[0] = scale.x;
				_oneData[1] = scale.y - scale.x;
			}
			
		}
	}

}
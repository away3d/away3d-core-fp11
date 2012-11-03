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
		arcane var _startScale:Number;
		
		/** @private */
		arcane var _hasCycle:Boolean;
		
		/** @private */
		arcane var _scaleData:Vector3D;
		
		private var _endScale:Number;
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
		 * Expects a <code>Vector3D</code> representing the start scale (x) and end scale(y) applied to the particle.
		 */
		public static const SCALE_VECTOR3D:String = "ScaleVector3D";
		
		/**
		 * Defines the end scale of the node, when in global mode.
		 */
		public function get startScale():Number
		{
			return _startScale;
		}
		
		public function set startScale(value:Number):void
		{
			_startScale = value;
			
			updateScaleData();
		}
		
		/**
		 * Defines the end scale of the node, when in global mode.
		 */
		public function get endScale():Number
		{
			return _endScale;
		}
		public function set endScale(value:Number):void
		{
			_endScale = value;
			
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
		 * @param    [optional] startScale      Defines the start scale transform of the node, when in global mode.
		 * @param    [optional] endScale        Defines the end color transform of the node, when in global mode.
		 * @param    [optional] cycleSpeed      Defines the cycle speed of the node in revolutions per second, when in global mode. Defaults to zero.
		 * @param    [optional] cyclePhase      Defines the cycle phase of the node in degrees, when in global mode. Defaults to zero.
		 */
		public function ParticleScaleNode(mode:uint, startScale:Number = 1, endScale:Number = 1, cycleSpeed:Number = 0, cyclePhase:Number = 0)
		{
			super("ParticleScaleNode" + mode, mode, 3, 2);
			
			_stateClass = ParticleScaleState;
			
			_startScale = startScale;
			_endScale = endScale;
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
			
			if (_mode == LOCAL) {
				var scaleAttribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
				animationRegisterCache.setRegisterIndex(this, SCALE_INDEX, scaleAttribute.index);
				
				
				code += "mul " + temp + "," + animationRegisterCache.vertexLife + "," + scaleAttribute + ".y\n";
				code += "add " + temp + "," + temp + "," + scaleAttribute + ".x\n";
				code += "mul " + animationRegisterCache.scaleAndRotateTarget +"," +animationRegisterCache.scaleAndRotateTarget + "," + temp + "\n";
			} else {
				var scaleConstant:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.setRegisterIndex(this, SCALE_INDEX, scaleConstant.index);
				
				if (_cycleSpeed) {
					code += "mul " + temp + "," + animationRegisterCache.vertexTime + "," + scaleConstant + ".z\n";
					
					if (_cyclePhase)
						code += "add " + temp + "," + temp + "," + scaleConstant + ".w\n";
					
					code += "sin " + temp + "," + temp + "\n";
				}
				
				code += "mul " + temp + "," + scaleConstant + ".y," + ((_cycleSpeed)? temp : animationRegisterCache.vertexLife) + "\n";
				code += "add " + temp + "," + scaleConstant + ".x," + temp + "\n";
				code += "mul " + animationRegisterCache.scaleAndRotateTarget +"," +animationRegisterCache.scaleAndRotateTarget + "," + temp + "\n";				
			}
			return code;
		}
		
		private function updateScaleData():void
		{
			if (_hasCycle) {
				_scaleData = new Vector3D((_startScale + _endScale) / 2, Math.abs(_startScale - _endScale) / 2, Math.PI * 2 / _cycleSpeed, _cyclePhase * Math.PI / 180);
			} else {
				_scaleData = new Vector3D(_startScale, _endScale - _startScale, Math.PI * 2 / _cycleSpeed, _cyclePhase * Math.PI / 180);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			var offset:Vector3D = param[SCALE_VECTOR3D];
			if (!offset)
				throw(new Error("there is no " + SCALE_VECTOR3D + " in param!"));
			
			_oneData[0] = offset.x;
			_oneData[1] = offset.y;
		}
	}

}
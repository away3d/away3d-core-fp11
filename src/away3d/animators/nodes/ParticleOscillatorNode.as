package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.states.ParticleOscillatorState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleOscillatorNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const OSCILLATOR_INDEX:uint = 0;
		
		arcane var _oscillatorData:Vector3D;
				
		private var _oscillator:Vector3D;
		
		/**
		 * Used to set the circle node into local property mode.
		 */
		public static const LOCAL:uint = 0;
		
		/**
		 * Used to set the circle node into global property mode.
		 */
		public static const GLOBAL:uint = 1;
		
		/**
		 * Defines the default oscillator of the node, used when in global mode.
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
		/**
		 * Reference for ocsillator node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> object representing the axis (x,y,z) and cycle speed (w) of the motion on the particle.
		 */
		public static const OSCILLATOR_VECTOR3D:String = "OscillatorVector3D";
				
		/**
		 * Creates a new <code>ParticleOscillatorNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation defaults to acting on local properties of a particle or global properties of the node.
		 */
		public function ParticleOscillatorNode(mode:uint, oscillator:Vector3D = null)
		{
			super("ParticleOscillatorNode" + mode, mode, 4);
			
			_stateClass = ParticleOscillatorState;
			
			_oscillator = oscillator;
			_oscillatorData = new Vector3D;
			updateOscillatorData();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var oscillatorRegister:ShaderRegisterElement = (_mode == LOCAL)? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, OSCILLATOR_INDEX, oscillatorRegister.index);
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var dgree:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			animationRegisterCache.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "xyz");
			animationRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "mul " + dgree + "," + animationRegisterCache.vertexTime + "," + oscillatorRegister + ".w\n";
			code += "sin " + sin + "," + dgree + "\n";
			code += "mul " + distance + "," + sin + "," + oscillatorRegister + ".xyz\n";
			code += "add " + animationRegisterCache.positionTarget +"," + distance + "," + animationRegisterCache.positionTarget + "\n";
			
			if (animationRegisterCache.needVelocity)
			{	code += "cos " + cos + "," + dgree + "\n";
				code += "mul " + distance + "," + cos + "," + oscillatorRegister + ".xyz\n";
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + distance + "," + animationRegisterCache.velocityTarget + ".xyz\n";
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			//(Vector3D.x,Vector3D.y,Vector3D.z) is oscillator axis, Vector3D.w is oscillator cycle duration
			var drift:Vector3D = param[OSCILLATOR_VECTOR3D];
			if (!drift)
				throw(new Error("there is no " + OSCILLATOR_VECTOR3D + " in param!"));
			
			_oneData[0] = drift.x;
			_oneData[1] = drift.y;
			_oneData[2] = drift.z;
			if (drift.w <= 0)
				throw(new Error("the cycle duration must greater than zero"));
			_oneData[3] = Math.PI * 2 / drift.w;
		}
		
		private function updateOscillatorData():void
		{
			if (mode == GLOBAL)
			{
				if (_oscillator.w <= 0)
					throw(new Error("the cycle duration must greater than zero"));
				_oscillatorData.x = _oscillator.x;
				_oscillatorData.y = _oscillator.y;
				_oscillatorData.z = _oscillator.z;
				_oscillatorData.w = Math.PI * 2 / _oscillator.w;
			}
		}
		
	}
}
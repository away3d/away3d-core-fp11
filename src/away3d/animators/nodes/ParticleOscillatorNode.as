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
				
		/**
		 * Used to set the circle node into local property mode.
		 */
		public static const LOCAL:uint = 0;
		
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
		public function ParticleOscillatorNode(mode:uint)
		{
			super("ParticleOscillatorNode" + mode, mode, 4);
			
			_stateClass = ParticleOscillatorState;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var driftAttribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, OSCILLATOR_INDEX, driftAttribute.index);
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var dgree:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			animationRegisterCache.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "xyz");
			animationRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "mul " + dgree + "," + animationRegisterCache.vertexTime + "," + driftAttribute + ".w\n";
			code += "sin " + sin + "," + dgree + "\n";
			code += "mul " + distance + "," + sin + "," + driftAttribute + ".xyz\n";
			code += "add " + animationRegisterCache.positionTarget +"," + distance + "," + animationRegisterCache.positionTarget + "\n";
			
			if (animationRegisterCache.needVelocity)
			{	code += "cos " + cos + "," + dgree + "\n";
				code += "mul " + distance + "," + cos + "," + driftAttribute + ".xyz\n";
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + distance + "," + animationRegisterCache.velocityTarget + ".xyz\n";
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			//(Vector3D.x,Vector3D.y,Vector3D.z) is oscillator axis, Vector3D.w is oscillator cycle speed
			var drift:Vector3D = param[OSCILLATOR_VECTOR3D];
			if (!drift)
				throw(new Error("there is no " + OSCILLATOR_VECTOR3D + " in param!"));
			
			_oneData[0] = drift.x;
			_oneData[1] = drift.y;
			_oneData[2] = drift.z;
			_oneData[3] = Math.PI * 2 / drift.w;
		}
	}
}
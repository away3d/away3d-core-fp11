package away3d.animators.nodes
{
	import flash.geom.*;
	
	import away3d.*;
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.states.*;
	import away3d.materials.compilation.*;
	import away3d.materials.passes.*;
	
	use namespace arcane;
	
	/**
	 * A particle animation node used to control the position of a particle over time using simple harmonic motion.
	 */
	public class ParticleOscillatorNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const OSCILLATOR_INDEX:uint = 0;
		
		/** @private */
		arcane var _oscillator:Vector3D;
		
		/**
		 * Reference for ocsillator node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> object representing the axis (x,y,z) and cycle speed (w) of the motion on the particle.
		 */
		public static const OSCILLATOR_VECTOR3D:String = "OscillatorVector3D";
				
		/**
		 * Creates a new <code>ParticleOscillatorNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
		 * @param    [optional] oscillator      Defines the default oscillator axis (x, y, z) and cycleDuration (w) of the node, used when in global mode.
		 */
		public function ParticleOscillatorNode(mode:uint, oscillator:Vector3D = null)
		{
			super("ParticleOscillator", mode, 4);
			
			_stateClass = ParticleOscillatorState;
			
			_oscillator = oscillator || new Vector3D();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			pass=pass;
			var oscillatorRegister:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, OSCILLATOR_INDEX, oscillatorRegister.index);
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var dgree:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 2);
			animationRegisterCache.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index);
			animationRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "mul " + dgree + "," + animationRegisterCache.vertexTime + "," + oscillatorRegister + ".w\n";
			code += "sin " + sin + "," + dgree + "\n";
			code += "mul " + distance + ".xyz," + sin + "," + oscillatorRegister + ".xyz\n";
			code += "add " + animationRegisterCache.positionTarget +".xyz," + distance + ".xyz," + animationRegisterCache.positionTarget + ".xyz\n";
			
			if (animationRegisterCache.needVelocity)
			{	code += "cos " + cos + "," + dgree + "\n";
				code += "mul " + distance + ".xyz," + cos + "," + oscillatorRegister + ".xyz\n";
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.velocityTarget + ".xyz\n";
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):ParticleOscillatorState
		{
			return animator.getAnimationState(this) as ParticleOscillatorState;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleProperties):void
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
	}
}
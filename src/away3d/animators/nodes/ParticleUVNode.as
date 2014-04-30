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
	 * A particle animation node used to control the UV offset and scale of a particle over time.
	 */
	public class ParticleUVNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const UV_INDEX:uint = 0;
		
		/** @private */
		arcane var _uvData:Vector3D;
		
		/**
		 * Used to set the time node into global property mode.
		 */
		public static const GLOBAL:uint = 1;
		
		/**
		 *
		 */
		public static const U_AXIS:String = "x";
		
		/**
		 *
		 */
		public static const V_AXIS:String = "y";
		
		
		public static const LINEAR_EASE:int = 1;
		public static const SINE_EASE:int = 2;
		
		public static const UV_CYCLE:String = "UVCycle";
		public static const UV_SCALE:String = "UVSclae";
		
		arcane var _cycle:Number;
		arcane var _scale:Number;
		arcane var _axis:String;
		arcane var _formula:int;
		
		/**
		 * Creates a new <code>ParticleTimeNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
		 * @param    [optional] cycle           Defines the time in a loop when in global mode. Defaults to 1.
		 * @param    [optional] scale           Defines scale when in global mode. Defaults to 1. If you want to use scale in local mode, set it a value other than 1.
		 * @param    [optional] axis            Defines the axis. Defaults to x.
		 * @param    [optional] formula         Defines the formula. Defaults to 1.
		 */
		public function ParticleUVNode(mode:uint, cycle:Number = 1, scale:Number = 1, axis:String = "x", formula:int = 1)
		{
			super("ParticleUV", mode, 2, ParticleAnimationSet.POST_PRIORITY + 1);
			
			_stateClass = ParticleUVState;
			
			_cycle = cycle;
			_scale = scale;
			_axis = axis;
			_formula = formula;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			pass = pass;
			var code:String = "";
			
			if (animationRegisterCache.needUVAnimation) {
				var UVValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
				animationRegisterCache.setRegisterIndex(this, UV_INDEX, UVValue.index);
				
				var axisIndex:Number = _axis == "x"? 0 :
					_axis == "y"? 1 :
					2;
				var target:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, axisIndex);
				
				var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
				
				if (_scale != 1)
					code += "mul " + target + "," + target + "," + UVValue + ".y\n";
				
				switch(_formula)
				{
					case SINE_EASE:
						code += "mul " + temp + "," + animationRegisterCache.vertexTime + "," + UVValue + ".x\n";
						code += "sin " + temp + "," + temp + "\n";
						break;
					case LINEAR_EASE:
					default:
						code += "mul " + temp + "," + animationRegisterCache.vertexTime + "," + UVValue + ".x\n";
				}
				code += "add " + target + "," + target + "," + temp + "\n";
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):ParticleUVState
		{
			return animator.getAnimationState(this) as ParticleUVState;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):void
		{
			particleAnimationSet.hasUVNode = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleProperties):void
		{
			if (!param.hasOwnProperty(UV_CYCLE) || !(param[UV_CYCLE] is Number))
				throw new Error("there is no " + UV_CYCLE + " in param!");
			var cycle:Number = param[UV_CYCLE];
			var scale:Number = 1;
			if (param.hasOwnProperty(UV_SCALE) && (param[UV_SCALE] is Number))
				scale = param[UV_SCALE];
				
			switch(_formula)
			{
				case SINE_EASE:
					_oneData[0] = Math.PI * 2 / cycle;
					break;
				case LINEAR_EASE:
				default:
					_oneData[0] = 1 / cycle;
			}
			_oneData[1] = scale;
		}
	}
}

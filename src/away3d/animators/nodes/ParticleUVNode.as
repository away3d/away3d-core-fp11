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
		
		private var _cycle:Number;
		private var _scale:Number;
		private var _axis:String;
		
		/**
		 * Creates a new <code>ParticleTimeNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
		 * @param    [optional] cycle           Defines whether the time track is in loop mode. Defaults to false.
		 * @param    [optional] scale           Defines whether the time track is in loop mode. Defaults to false.
		 * @param    [optional] axis            Defines whether the time track is in loop mode. Defaults to false.
		 */
		public function ParticleUVNode(mode:uint, cycle:Number = 1, scale:Number = 1, axis:String = "x")
		{
			super("ParticleUV", mode, 4, ParticleAnimationSet.POST_PRIORITY + 1);
			
			_stateClass = ParticleUVState;
			
			_cycle = cycle;
			_scale = scale;
			_axis = axis;
			
			updateUVData();
		}
		
		/**
		 *
		 */
		public function get cycle():Number
		{
			return _cycle;
		}
		
		public function set cycle(value:Number):void
		{
			_cycle = value;
			
			updateUVData();
		}
		
		/**
		 *
		 */
		public function get scale():Number
		{
			return _scale;
		}
		
		public function set scale(value:Number):void
		{
			_scale = value;
			
			updateUVData();
		}
		
		/**
		 *
		 */
		public function get axis():String
		{
			return _axis;
		}
		
		public function set axis(value:String):void
		{
			_axis = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			pass = pass;
			var code:String = "";
			
			if (animationRegisterCache.needUVAnimation) {
				var uvConst:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.setRegisterIndex(this, UV_INDEX, uvConst.index);
				
				var axisIndex:Number = _axis == "x"? 0 :
					_axis == "y"? 1 :
					2;
				var target:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, axisIndex);
				
				var sin:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
				
				if (_scale != 1)
					code += "mul " + target + "," + target + "," + uvConst + ".y\n";
				
				code += "mul " + sin + "," + animationRegisterCache.vertexTime + "," + uvConst + ".x\n";
				code += "sin " + sin + "," + sin + "\n";
				code += "add " + target + "," + target + "," + sin + "\n";
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
		
		private function updateUVData():void
		{
			_uvData = new Vector3D(Math.PI*2/_cycle, _scale, 0, 0);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):void
		{
			particleAnimationSet.hasUVNode = true;
		}
	}
}

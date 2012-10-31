package away3d.animators.nodes
{
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.states.ParticleFreeColorLocalState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.ColorTransform;

	/**
	 * ...
	 */
	public class ParticleFreeColorLocalNode extends LocalParticleNodeBase
	{
		public static const NAME:String = "ParticleFreeColorLocalNode";
		public static const COLOR_MULTIPLE_STREAM_REGISTER:int = 0;
		public static const COLOR_OFFSET_STREAM_REGISTER:int = 1;
		public static const COLOR_MULTIPLE_VARYING_REGISTER:int = 2;
		public static const COLOR_OFFSET_VARYING_REGISTER:int = 3;
		
		private var _hasMult:Boolean;
		private var _hasOffset:Boolean;
		
		public function ParticleFreeColorLocalNode(hasMult:Boolean = true, hasOffset:Boolean = false)
		{
			super(NAME);
			_stateClass = ParticleFreeColorLocalState;
			
			_hasMult = hasMult;
			_hasOffset = hasOffset;
			
			if (!_hasMult && !_hasOffset)
				throw("no need to use this node");
				
			if (_hasMult && _hasOffset)
				_dataLenght = 8;
			else
				_dataLenght = 4;
				
			initOneData();
		}
		
		public function get hasMult():Boolean
		{
			return _hasMult;
		}
		
		public function get hasOffset():Boolean
		{
			return _hasOffset;
		}
		
		override public function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			var colorTransform:ColorTransform = param[NAME];
			if (!colorTransform)
				throw(new Error("there is no " + NAME + " in param!"));
			if (_hasMult)
			{
				_oneData[0] = colorTransform.redMultiplier;
				_oneData[1] = colorTransform.greenMultiplier;
				_oneData[2] = colorTransform.blueMultiplier;
				_oneData[3] = colorTransform.alphaMultiplier;
				if (_hasOffset)
				{
					_oneData[4] = colorTransform.redOffset / 255;
					_oneData[5] = colorTransform.greenOffset / 255;
					_oneData[6] = colorTransform.blueOffset / 255;
					_oneData[7] = colorTransform.alphaOffset / 255;
				}
			}
			else
			{
				_oneData[0] = colorTransform.redOffset / 255;
				_oneData[1] = colorTransform.greenOffset / 255;
				_oneData[2] = colorTransform.blueOffset / 255;
				_oneData[3] = colorTransform.alphaOffset / 255;
			}
			
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var code:String = "";
			if (animationRegisterCache.needFragmentAnimation)
			{
				if (_hasMult)
				{
					var multiplierAtt:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
					animationRegisterCache.setRegisterIndex(this, COLOR_MULTIPLE_STREAM_REGISTER, multiplierAtt.index);
					var multiplierVary:ShaderRegisterElement = animationRegisterCache.getFreeVarying();
					animationRegisterCache.setRegisterIndex(this, COLOR_MULTIPLE_VARYING_REGISTER, multiplierVary.index);
					
					code += "mov " + multiplierVary.toString() + "," + multiplierAtt.toString() + "\n";
				}
				if (_hasOffset)
				{
					var offsetAtt:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
					animationRegisterCache.setRegisterIndex(this, COLOR_OFFSET_STREAM_REGISTER, offsetAtt.index);
					var offsetVary:ShaderRegisterElement = animationRegisterCache.getFreeVarying();
					animationRegisterCache.setRegisterIndex(this, COLOR_OFFSET_VARYING_REGISTER, offsetVary.index);
					
					code += "mov " + offsetVary.toString() + "," + offsetAtt.toString() + "\n";
				}
			}
			return code;
		}
		
		override public function getAGALFragmentCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			
			var code:String = "";
			if (animationRegisterCache.needFragmentAnimation)
			{
				var varIndex:int;
				if (_hasMult)
				{
					varIndex = animationRegisterCache.getRegisterIndex(this, COLOR_MULTIPLE_VARYING_REGISTER);
					var multiplierVary:ShaderRegisterElement = new ShaderRegisterElement("v", varIndex);
					code += "mul " + animationRegisterCache.colorTarget.toString() +"," + multiplierVary.toString() + "," + animationRegisterCache.colorTarget.toString() + "\n";
				}
				if (_hasOffset)
				{
					varIndex = animationRegisterCache.getRegisterIndex(this, COLOR_OFFSET_VARYING_REGISTER);
					var offsetVary:ShaderRegisterElement = new ShaderRegisterElement("v", varIndex);
					code += "add " + animationRegisterCache.colorTarget.toString() +"," +offsetVary.toString() + "," + animationRegisterCache.colorTarget.toString() + "\n";
				}
			}
			return code;
		}
		
		
	}

}
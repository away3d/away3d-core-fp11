package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleParamter;
	import away3d.animators.states.ParticleFreeColorLocalState;
	import away3d.animators.utils.ParticleAnimationCompiler;
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
		
		override public function generatePorpertyOfOneParticle(param:ParticleParamter):void
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
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			var code:String = "";
			if (activatedCompiler.needFragmentAnimation)
			{
				if (_hasMult)
				{
					var multiplierAtt:ShaderRegisterElement = activatedCompiler.getFreeVertexAttribute();
					activatedCompiler.setRegisterIndex(this, COLOR_MULTIPLE_STREAM_REGISTER, multiplierAtt.index);
					var multiplierVary:ShaderRegisterElement = activatedCompiler.getFreeVarying();
					activatedCompiler.setRegisterIndex(this, COLOR_MULTIPLE_VARYING_REGISTER, multiplierVary.index);
					
					code += "mov " + multiplierVary.toString() + "," + multiplierAtt.toString() + "\n";
				}
				if (_hasOffset)
				{
					var offsetAtt:ShaderRegisterElement = activatedCompiler.getFreeVertexAttribute();
					activatedCompiler.setRegisterIndex(this, COLOR_OFFSET_STREAM_REGISTER, offsetAtt.index);
					var offsetVary:ShaderRegisterElement = activatedCompiler.getFreeVarying();
					activatedCompiler.setRegisterIndex(this, COLOR_OFFSET_VARYING_REGISTER, offsetVary.index);
					
					code += "mov " + offsetVary.toString() + "," + offsetAtt.toString() + "\n";
				}
			}
			return code;
		}
		
		override public function getAGALFragmentCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			
			var code:String = "";
			if (activatedCompiler.needFragmentAnimation)
			{
				var varIndex:int
				if (_hasMult)
				{
					varIndex = activatedCompiler.getRegisterIndex(this, COLOR_MULTIPLE_VARYING_REGISTER);
					var multiplierVary:ShaderRegisterElement = new ShaderRegisterElement("v", varIndex);
					code += "mul " + activatedCompiler.colorTarget.toString() +"," + multiplierVary.toString() + "," + activatedCompiler.colorTarget.toString() + "\n";
				}
				if (_hasOffset)
				{
					varIndex = activatedCompiler.getRegisterIndex(this, COLOR_OFFSET_VARYING_REGISTER);
					var offsetVary:ShaderRegisterElement = new ShaderRegisterElement("v", varIndex);
					code += "add " + activatedCompiler.colorTarget.toString() +"," +offsetVary.toString() + "," + activatedCompiler.colorTarget.toString() + "\n";
				}
			}
			return code;
		}
		
		
	}

}
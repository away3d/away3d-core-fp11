package away3d.animators.nodes
{
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.states.ParticleScaleByLifeGlobalState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	/**
	 * ...
	 */
	public class ParticleScaleByLifeGlobalNode extends GlobalParticleNodeBase
	{
		public static const NAME:String = "ParticleScaleByLifeGlobalNode";
		public static const SCALE_CONSTANT_REGISTER:int = 0;
		
		private var _startScale:Number;
		private var _endScale:Number;
		private var _delta:Number;
		
		
		public function ParticleScaleByLifeGlobalNode(startScale:Number,endScale:Number)
		{
			super(NAME, 2);
			_stateClass = ParticleScaleByLifeGlobalState;
			
			_startScale = startScale;
			_endScale = endScale;
			_delta = _endScale - _startScale;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var scaleByLifeConst:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, SCALE_CONSTANT_REGISTER, scaleByLifeConst.index);
			
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var scale:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index,"w");
			
			var code:String = "";
			code += "mul " + scale.toString() + "," + animationRegisterCache.vertexLife.toString() + "," + scaleByLifeConst.toString() + ".y\n";
			code += "add " + scale.toString() + "," + scale.toString() + "," + scaleByLifeConst.toString() + ".x\n";
			code += "mul " + animationRegisterCache.scaleAndRotateTarget.toString() +"," +animationRegisterCache.scaleAndRotateTarget.toString() + "," + scale.toString() + "\n";
			return code;
		}
		
		public function get startScale():Number
		{
			return _startScale;
		}
		
		public function set startScale(value:Number):void
		{
			_startScale = value;
			_delta = _endScale - _startScale;
		}
		
		public function get endScale():Number
		{
			return _endScale;
		}
		
		public function set endScale(value:Number):void
		{
			_endScale = value;
			_delta = _endScale - _startScale;
		}
		
		public function get delta():Number
		{
			return _delta;
		}
		
	}

}
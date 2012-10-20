package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.states.ParticleScaleByTimeGlobalState;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	/**
	 * ...
	 */
	public class ParticleScaleByTimeGlobalNode extends GlobalParticleNodeBase
	{
		public static const NAME:String = "ParticleScaleByTimeGlobalNode";
		public static const SCALE_CONSTANT_REGISTER:int = 0;
		
		private var _data:Vector.<Number>;
		
		private var _minScale:Number;
		private var _maxScale:Number;
		private var _scaleCycle:Number;
		
		
		public function ParticleScaleByTimeGlobalNode(min:Number,max:Number,cycle:Number)
		{
			super(NAME, 2);
			_stateClass = ParticleScaleByTimeGlobalState;
			
			_minScale = min;
			_maxScale = max;
			_scaleCycle = cycle;
			_data = new Vector.<Number>(4, true);
			reset();
		}
		
		public function get data():Vector.<Number>
		{
			return _data;
		}
		
		public function get minScale():Number
		{
			return _minScale;
		}
		public function set minScale(value:Number):void
		{
			_minScale = value;
			reset();
		}
		
		public function get maxScale():Number
		{
			return _maxScale;
		}
		public function set maxScale(value:Number):void
		{
			_maxScale = value;
			reset();
		}
		
		public function get scaleCycle():Number
		{
			return _scaleCycle;
		}
		public function set scaleCycle(value:Number):void
		{
			_scaleCycle = value;
			reset();
		}
		
		private function reset():void
		{
			_data[0] = (_maxScale + _minScale) / 2;
			_data[1] = Math.abs(_maxScale - _minScale) / 2;
			_data[3] = Math.PI * 2 / _scaleCycle;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			var scaleByTimeConst:ShaderRegisterElement = activatedCompiler.getFreeVertexConstant();
			activatedCompiler.setRegisterIndex(this, SCALE_CONSTANT_REGISTER, scaleByTimeConst.index);
			
			var temp:ShaderRegisterElement = activatedCompiler.getFreeVertexSingleTemp();
			
			var code:String = "";
			code += "mul " + temp.toString() + "," + activatedCompiler.vertexTime.toString() + "," + scaleByTimeConst.toString() + ".w\n";
			code += "sin " + temp.toString() + "," + temp.toString() + "\n";
			code += "mul " + temp.toString() + "," + temp.toString() + "," + scaleByTimeConst.toString() + ".y\n";
			code += "add " + temp.toString() + "," + temp.toString() + "," + scaleByTimeConst.toString() + ".x\n";
			
			code += "mul " + activatedCompiler.scaleAndRotateTarget.toString() +"," +activatedCompiler.scaleAndRotateTarget.toString() + "," + temp.toString() + "\n";
			return code;
		}
		
	}

}
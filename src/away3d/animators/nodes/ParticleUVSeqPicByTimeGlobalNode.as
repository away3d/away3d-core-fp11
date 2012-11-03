package away3d.animators.nodes
{
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.states.ParticleUVSeqPicByTimeGlobalState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	/**
	 * Note: to use this class, make sure material::repeat is ture
	 */
	public class ParticleUVSeqPicByTimeGlobalNode extends GlobalParticleNodeBase
	{
		public static const NAME:String = "ParticleUVSeqPicByTimeGlobalNode";
		public static const UV_CONSTANT_REGISTER_0:int = 0;
		public static const UV_CONSTANT_REGISTER_1:int = 1;
		
		private var _hasStartTime:Boolean;
		private var _loop:Boolean;
		private var _needV:Boolean;
		private var _total:int;
		
		private var _data:Vector.<Number>;
		private var _cycle:Number;
		private var _columns:int;
		private var _rows:int;
		private var _startTime:Number;
		
		
		public function ParticleUVSeqPicByTimeGlobalNode(columns:int, rows:int , cycle:Number, usingNum:int = int.MAX_VALUE, startTime:Number = 0, loop:Boolean = true)
		{
			super(NAME, ParticleAnimationSet.POST_PRIORITY + 1);
			_stateClass = ParticleUVSeqPicByTimeGlobalState;
			
			_total = Math.min(usingNum, columns * rows);
			if (startTime != 0)
				_hasStartTime = true;
			_loop = loop;
			if (rows > 1)_needV = true;
			_cycle = cycle;
			_columns = columns;
			_rows = rows;
			_startTime = startTime;
			reset();
		}
		
		public function get renderData():Vector.<Number>
		{
			return _data;
		}
		
		public function get cycle():Number
		{
			return _cycle;
		}
		public function set cycle(value:Number):void
		{
			_cycle = value;
			reset();
		}
		
		public function get columns():int
		{
			return _columns;
		}
		public function get rows():int
		{
			return _rows;
		}
		public function get total():int
		{
			return _total;
		}
		public function get startTime():Number
		{
			return _startTime;
		}
		
		private function reset():void
		{
			var uTotal:Number = _total / _columns;
			var uSpeed:Number = uTotal / _cycle;
			var uStep:Number = 1 / _columns;
			var vStep:Number = 1 / _rows;
			var endThreshold:Number = _cycle - _cycle / _total / 2;
			_data = Vector.<Number>([uSpeed, uStep, vStep, _cycle, _startTime, endThreshold, 0, 0]);
		}
		
		override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):void
		{
			particleAnimationSet.hasUVNode = true;
		}
		
		
		override public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			//get 2 vc
			var uvParamConst1:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			var uvParamConst2:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, UV_CONSTANT_REGISTER_0, uvParamConst1.index);
			animationRegisterCache.setRegisterIndex(this, UV_CONSTANT_REGISTER_1, uvParamConst2.index);
			
			var uSpeed:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "x");
			var uStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "y");
			var vStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "z");
			var cycle:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, "w");
			var startTime:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, "x");
			var endThreshold:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, "y");
			
			
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var vOffset:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			temp = new ShaderRegisterElement(temp.regName, temp.index, "z");
			var temp2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "w");
			
			
			var u:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, "x");
			var v:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, "y");
			
			var code:String = "";
			//scale uv
			code += "mul " + u + "," + u + "," + uStep + "\n";
			if (_needV) code += "mul " + v + "," + v + "," + vStep + "\n";
			
			if (_hasStartTime)
			{
				code += "sub " + time + "," + animationRegisterCache.vertexTime + "," + startTime + "\n";
				code += "max " + time + "," + time + "," + animationRegisterCache.vertexZeroConst + "\n";
			}
			else
			{
				code += "mov " + time +"," + animationRegisterCache.vertexTime + "\n";
			}
			if (!_loop)
			{
				code += "min " + time + "," + time + "," + endThreshold + "\n";
			}
			else
			{
				code += "div " + time + "," + time + "," + cycle + "\n";
				code += "frc " + time + "," + time + "\n";
				code += "mul " + time + "," + time + "," + cycle + "\n";
			}
			
			
			code += "mul " + temp + "," + time + "," + uSpeed + "\n";
			if (_needV)
			{
				code += "frc " + temp2 + "," + temp + "\n";
				code += "sub " + vOffset + "," + temp + "," + temp2 + "\n";
				code += "mul " + vOffset + "," + vOffset + "," + vStep + "\n";
				code += "add " + v + "," + v + "," + vOffset + "\n";
			}
			code += stepDiv(temp, temp, uStep, temp2);
			code += "add " + u + "," + u + "," + temp + "\n";
			
			return code;
		}
		
		private function stepDiv(destination:ShaderRegisterElement, source1:ShaderRegisterElement, source2:ShaderRegisterElement, temp:ShaderRegisterElement):String
		{
			return "div " + temp + "," + source1 + "," + source2 + "\n" +
					"frc " + destination + "," + temp + "\n"+
					"sub " + temp + "," + temp + "," + destination + "\n" +
					"mul " + destination + "," + temp + "," + source2 + "\n";
		}
	
	}

}
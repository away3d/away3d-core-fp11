package away3d.animators.utils
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Cheng Liao
	 */
	public class ParticleAnimationCompiler
	{
		//vertex
		public var positionAttribute:ShaderRegisterElement;
		public var uvAttribute:ShaderRegisterElement;
		public var offsetTarget:ShaderRegisterElement;
		public var scaleAndRotateTarget:ShaderRegisterElement
		public var velocityTarget:ShaderRegisterElement;
		public var vertexTime:ShaderRegisterElement;
		public var vertexLife:ShaderRegisterElement;
		public var vertexZeroConst:ShaderRegisterElement;
		public var vertexOneConst:ShaderRegisterElement;
		public var vertexTwoConst:ShaderRegisterElement;
		public var cameraPosConst:ShaderRegisterElement;
		public var uvTarget:ShaderRegisterElement;
		//vary
		public var varyTime:ShaderRegisterElement;
		public var fragmentTime:ShaderRegisterElement;
		public var fragmentLife:ShaderRegisterElement;

		//fragment
		public var colorTarget:ShaderRegisterElement;
		public var uvVar:ShaderRegisterElement;
		public var fragmentZeroConst:ShaderRegisterElement;
		public var fragmentOneConst:ShaderRegisterElement;
		public var fragmentMinConst:ShaderRegisterElement;
		public var fadeFactorConst:ShaderRegisterElement;
		
		//these are targets only need to rotate ( normal and tangent )
		public var rotationRegisters:Array;
		
		
		public var shaderRegisterCache:ShaderRegisterCache = new ShaderRegisterCache();
		
		
		
		public var needFragmentAnimation:Boolean;
		public var needUVAnimation:Boolean;
		
		public var sourceRegisters:Array;
		public var targetRegisters:Array;
		
		private var indexDictionary:Dictionary = new Dictionary(true);
		
		private var _sharedSetting:ParticleAnimationSetting;
		
		
		public function ParticleAnimationCompiler()
		{
			
		}
		
		public function reset(sharedSetting:ParticleAnimationSetting):void
		{
			this._sharedSetting = sharedSetting;
			rotationRegisters = [];
			positionAttribute = getRegisterFromString(sourceRegisters[0]);
			scaleAndRotateTarget = getRegisterFromString(targetRegisters[0]);
			shaderRegisterCache.addVertexTempUsages(scaleAndRotateTarget, 1);
			
			for (var i:int = 1; i < targetRegisters.length; i++)
			{
				rotationRegisters.push(getRegisterFromString(targetRegisters[i]));
				shaderRegisterCache.addVertexTempUsages(rotationRegisters[i - 1], 1);
			}
			
			scaleAndRotateTarget = new ShaderRegisterElement(scaleAndRotateTarget.regName, scaleAndRotateTarget.index, "xyz");//only use xyz, w is used as vertexLife

			//allot const register
			
			vertexZeroConst = shaderRegisterCache.getFreeVertexConstant();
			vertexZeroConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, "x");
			vertexOneConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, "y");
			vertexTwoConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, "z");
			
			if (needFragmentAnimation && _sharedSetting.hasColorNode)
			{
				fragmentZeroConst = shaderRegisterCache.getFreeFragmentConstant();
				fragmentZeroConst = new ShaderRegisterElement(fragmentZeroConst.regName, fragmentZeroConst.index, "x");
				fragmentOneConst = new ShaderRegisterElement(fragmentZeroConst.regName, fragmentZeroConst.index, "y");
				fragmentMinConst = new ShaderRegisterElement(fragmentZeroConst.regName, fragmentZeroConst.index, "z");
				
				varyTime = shaderRegisterCache.getFreeVarying();
				fragmentTime = new ShaderRegisterElement(varyTime.regName, varyTime.index, "x");
				fragmentLife = new ShaderRegisterElement(varyTime.regName, varyTime.index, "y");
			}

			//allot temp register
			offsetTarget = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(offsetTarget, 1);
			offsetTarget = new ShaderRegisterElement(offsetTarget.regName, offsetTarget.index, "xyz");

			if (_sharedSetting.needVelocity)
			{
				velocityTarget = shaderRegisterCache.getFreeVertexVectorTemp();
				shaderRegisterCache.addVertexTempUsages(velocityTarget, 1);
				velocityTarget = new ShaderRegisterElement(velocityTarget.regName, velocityTarget.index, "xyz");
				vertexTime = new ShaderRegisterElement(velocityTarget.regName, velocityTarget.index, "w");
				vertexLife = new ShaderRegisterElement(offsetTarget.regName, velocityTarget.index, "w");
			}
			else
			{
				var tempTime:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
				shaderRegisterCache.addVertexTempUsages(tempTime, 1);
				vertexTime = new ShaderRegisterElement(tempTime.regName, tempTime.index, "x");
				vertexLife = new ShaderRegisterElement(tempTime.regName, tempTime.index, "y");
			}
			
		}
		
		public function setShadedTarget(shadedTarget:String):void
		{
			colorTarget = getRegisterFromString(shadedTarget);
			shaderRegisterCache.addFragmentTempUsages(colorTarget,1);
		}
		
		public function setUVSourceAndTarget(UVAttribute : String, UVVaring:String):void
		{
			uvVar = getRegisterFromString(UVVaring);
			uvAttribute = getRegisterFromString(UVAttribute);
			//uv action is processed after normal actions,so use offsetTarget as uvTarget
			uvTarget = new ShaderRegisterElement(offsetTarget.regName, offsetTarget.index, "xy");
		}
		
		public function setRegisterIndex(node:Object, parameterIndex:int, registerIndex:int):void
		{
			//8 should be enough for any node.
			var t:Vector.<int> = indexDictionary[node] ||= new Vector.<int>(8, true);
			t[parameterIndex] = registerIndex;
		}
		
		public function getRegisterIndex(node:Object, parameterIndex:int):int
		{
			return indexDictionary[node][parameterIndex];
		}
		
		public function getInitCode():String
		{
			var len:int = sourceRegisters.length;
			var code:String = "";
			for (var i:int = 0; i < len; i++)
			{
				code += "mov " + targetRegisters[i] + "," + sourceRegisters[i] + "\n";
			}
			
			code += "mov " + offsetTarget.toString() + "," + vertexZeroConst.toString() + "\n";
			
			if (_sharedSetting.needVelocity)
			{
				code += "mov " + velocityTarget.toString() + "," + vertexZeroConst.toString() + "\n";
			}
			if (needFragmentAnimation&&_sharedSetting.hasColorNode)
			{
				code += "mov " + varyTime.toString() + ".zw," + vertexZeroConst.toString() + "\n";
			}
			
			return code;
		}
		
		public function getCombinationCode():String
		{
			return "add " + scaleAndRotateTarget.toString() +"," + scaleAndRotateTarget.toString() + "," + offsetTarget.toString() + "\n";
		}
		
		public function getCheckingTimeCode():String
		{
			//if time=0,set the final position to zero.
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexSingleTemp();
			var code:String = "neg " + temp.toString() + "," + vertexTime.toString() + "\n";
			code += "slt " + temp.toString() + "," + temp.toString() + "," + vertexZeroConst.toString() + "\n";
			code += "mul " + scaleAndRotateTarget.toString() + "," + scaleAndRotateTarget.toString() + "," + temp.toString() + "\n";
			return code;
		}
		
		public function getFreeVertexAttribute():ShaderRegisterElement
		{
			return shaderRegisterCache.getFreeVertexAttribute();
		}
		public function getFreeVertexConstant():ShaderRegisterElement
		{
			return shaderRegisterCache.getFreeVertexConstant();
		}
		public function getFreeVertexVectorTemp():ShaderRegisterElement
		{
			return shaderRegisterCache.getFreeVertexVectorTemp();
		}
		public function getFreeVertexSingleTemp():ShaderRegisterElement
		{
			return shaderRegisterCache.getFreeVertexSingleTemp();
		}
		public function getFreeFragmentVectorTemp():ShaderRegisterElement
		{
			return shaderRegisterCache.getFreeFragmentVectorTemp();
		}
		public function getFreeFragmentSingleTemp():ShaderRegisterElement
		{
			return shaderRegisterCache.getFreeFragmentSingleTemp();
		}
		public function getFreeFragmentConstant():ShaderRegisterElement
		{
			return shaderRegisterCache.getFreeFragmentConstant();
		}
		public function getFreeVarying():ShaderRegisterElement
		{
			return shaderRegisterCache.getFreeVarying();
		}
		public function addFragmentTempUsages(register:ShaderRegisterElement, usageCount:uint):void
		{
			shaderRegisterCache.addFragmentTempUsages(register,usageCount);
		}
		public function addVertexTempUsages(register:ShaderRegisterElement, usageCount:uint):void
		{
			shaderRegisterCache.addVertexTempUsages(register,usageCount);
		}
		public function removeVertexTempUsage(register:ShaderRegisterElement):void
		{
			shaderRegisterCache.removeVertexTempUsage(register);
		}
		public function removeFragmentTempUsage(register:ShaderRegisterElement):void
		{
			shaderRegisterCache.removeFragmentTempUsage(register);
		}
		
		
		private function getRegisterFromString(code:String):ShaderRegisterElement
		{
			var temp:Array = code.split(/(\d+)/);
			return new ShaderRegisterElement(temp[0], temp[1]);
		}
	}

}
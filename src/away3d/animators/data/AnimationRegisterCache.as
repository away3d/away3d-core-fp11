package away3d.animators.data
{
	import away3d.animators.nodes.AnimationNodeBase;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 */
	public class AnimationRegisterCache extends ShaderRegisterCache
	{
		//vertex
		public var positionAttribute:ShaderRegisterElement;
		public var uvAttribute:ShaderRegisterElement;
		public var positionTarget:ShaderRegisterElement;
		public var scaleAndRotateTarget:ShaderRegisterElement;
		public var velocityTarget:ShaderRegisterElement;
		public var vertexTime:ShaderRegisterElement;
		public var vertexLife:ShaderRegisterElement;
		public var vertexZeroConst:ShaderRegisterElement;
		public var vertexOneConst:ShaderRegisterElement;
		public var vertexTwoConst:ShaderRegisterElement;
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
		
		//these are targets only need to rotate ( normal and tangent )
		public var rotationRegisters:Vector.<ShaderRegisterElement>;
		
		
		
		public var needFragmentAnimation:Boolean;
		public var needUVAnimation:Boolean;
		
		public var sourceRegisters:Vector.<String>;
		public var targetRegisters:Vector.<String>;
		
		private var indexDictionary:Dictionary = new Dictionary(true);
		
		//set true if has an node which will change UV
		public var hasUVNode:Boolean;
		//set true if has an node which will change color
		public var hasColorNode:Boolean;
		//set if the other nodes need to access the velocity
		public var needVelocity:Boolean;
		//set if has a billboard node.
		public var hasBillboard:Boolean;
		
		
		public function AnimationRegisterCache()
		{
			
		}
		
		override public function reset():void
		{
			super.reset();
			
			rotationRegisters = new Vector.<ShaderRegisterElement>();
			positionAttribute = getRegisterFromString(sourceRegisters[0]);
			scaleAndRotateTarget = getRegisterFromString(targetRegisters[0]);
			addVertexTempUsages(scaleAndRotateTarget, 1);
			
			for (var i:int = 1; i < targetRegisters.length; i++)
			{
				rotationRegisters.push(getRegisterFromString(targetRegisters[i]));
				addVertexTempUsages(rotationRegisters[i - 1], 1);
			}
			
			scaleAndRotateTarget = new ShaderRegisterElement(scaleAndRotateTarget.regName, scaleAndRotateTarget.index, "xyz");//only use xyz, w is used as vertexLife

			//allot const register
			
			vertexZeroConst = getFreeVertexConstant();
			vertexZeroConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, "x");
			vertexOneConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, "y");
			vertexTwoConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, "z");
			
			if (needFragmentAnimation && hasColorNode)
			{
				fragmentZeroConst = getFreeFragmentConstant();
				fragmentZeroConst = new ShaderRegisterElement(fragmentZeroConst.regName, fragmentZeroConst.index, "x");
				fragmentOneConst = new ShaderRegisterElement(fragmentZeroConst.regName, fragmentZeroConst.index, "y");
				
				varyTime = getFreeVarying();
				fragmentTime = new ShaderRegisterElement(varyTime.regName, varyTime.index, "x");
				fragmentLife = new ShaderRegisterElement(varyTime.regName, varyTime.index, "y");
			}

			//allot temp register
			positionTarget = getFreeVertexVectorTemp();
			addVertexTempUsages(positionTarget, 1);
			positionTarget = new ShaderRegisterElement(positionTarget.regName, positionTarget.index, "xyz");

			if (needVelocity)
			{
				velocityTarget = getFreeVertexVectorTemp();
				addVertexTempUsages(velocityTarget, 1);
				velocityTarget = new ShaderRegisterElement(velocityTarget.regName, velocityTarget.index, "xyz");
				vertexTime = new ShaderRegisterElement(velocityTarget.regName, velocityTarget.index, "w");
				vertexLife = new ShaderRegisterElement(positionTarget.regName, positionTarget.index, "w");
			}
			else
			{
				var tempTime:ShaderRegisterElement = getFreeVertexVectorTemp();
				addVertexTempUsages(tempTime, 1);
				vertexTime = new ShaderRegisterElement(tempTime.regName, tempTime.index, "x");
				vertexLife = new ShaderRegisterElement(tempTime.regName, tempTime.index, "y");
			}
			
		}
		
		public function setShadedTarget(shadedTarget:String):void
		{
			colorTarget = getRegisterFromString(shadedTarget);
			addFragmentTempUsages(colorTarget,1);
		}
		
		public function setUVSourceAndTarget(UVAttribute : String, UVVaring:String):void
		{
			uvVar = getRegisterFromString(UVVaring);
			uvAttribute = getRegisterFromString(UVAttribute);
			//uv action is processed after normal actions,so use offsetTarget as uvTarget
			uvTarget = new ShaderRegisterElement(positionTarget.regName, positionTarget.index, "xy");
		}
		
		public function setRegisterIndex(node:AnimationNodeBase, parameterIndex:int, registerIndex:int):void
		{
			//9 should be enough for any node. (see color node)
			var t:Vector.<int> = indexDictionary[node] ||= new Vector.<int>(9, true);
			t[parameterIndex] = registerIndex;
		}
		
		public function getRegisterIndex(node:AnimationNodeBase, parameterIndex:int):int
		{
			return indexDictionary[node][parameterIndex];
		}
		
		public function getInitCode():String
		{
			var len:int = sourceRegisters.length;
			var code:String = "";
			for (var i:int = 0; i < len; i++)
				code += "mov " + targetRegisters[i] + "," + sourceRegisters[i] + "\n";
			
			code += "mov " + positionTarget.toString() + "," + vertexZeroConst.toString() + "\n";
			
			if (needVelocity)
				code += "mov " + velocityTarget.toString() + "," + vertexZeroConst.toString() + "\n";
			
			if (needFragmentAnimation&&hasColorNode)
				code += "mov " + varyTime.toString() + ".zw," + vertexZeroConst.toString() + "\n";
			
			
			return code;
		}
		
		public function getCombinationCode():String
		{
			return "add " + scaleAndRotateTarget.toString() +"," + scaleAndRotateTarget.toString() + "," + positionTarget.toString() + "\n";
		}
		
		private function getRegisterFromString(code:String):ShaderRegisterElement
		{
			var temp:Array = code.split(/(\d+)/);
			return new ShaderRegisterElement(temp[0], temp[1]);
		}
		
		public var vertexConstantData : Vector.<Number> = new Vector.<Number>();
		public var fragmentConstantData : Vector.<Number> = new Vector.<Number>();
		
		private var _numVertexConstant:int;
		private var _numFragmentConstant:int;
		
		public function get numVertexConstant():int
		{
			return _numVertexConstant;
		}
		public function get numFragmentConstant():int
		{
			return _numFragmentConstant;
		}
		
		public function setDataLength():void
		{
			_numVertexConstant = _numUsedVertexConstants - _vertexConstantOffset;
			_numFragmentConstant = _numUsedFragmentConstants - _fragmentConstantOffset;
			vertexConstantData.length = _numVertexConstant * 4;
			fragmentConstantData.length = _numFragmentConstant * 4;
		}
		
		public function setVertexConst(index:int, x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 0):void
		{
			var _index:int = (index - _vertexConstantOffset) * 4;
			vertexConstantData[_index++] = x;
			vertexConstantData[_index++] = y;
			vertexConstantData[_index++] = z;
			vertexConstantData[_index] = w;
		}
		
		public function setVertexConstFromMatrix(index:int, matrix:Matrix3D):void
		{
			var rawData:Vector.<Number> = matrix.rawData;
			var _index:int = (index - _vertexConstantOffset) * 4;
			vertexConstantData[_index++] = rawData[0];
			vertexConstantData[_index++] = rawData[4];
			vertexConstantData[_index++] = rawData[8];
			vertexConstantData[_index++] = rawData[12];
			vertexConstantData[_index++] = rawData[1];
			vertexConstantData[_index++] = rawData[5];
			vertexConstantData[_index++] = rawData[9];
			vertexConstantData[_index++] = rawData[13];
			vertexConstantData[_index++] = rawData[2];
			vertexConstantData[_index++] = rawData[6];
			vertexConstantData[_index++] = rawData[10];
			vertexConstantData[_index++] = rawData[14];
			vertexConstantData[_index++] = rawData[3];
			vertexConstantData[_index++] = rawData[7];
			vertexConstantData[_index++] = rawData[11];
			vertexConstantData[_index] = rawData[15];
			
		}
		public function setFragmentConst(index:int, x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 0):void
		{
			var _index:int = (index - _fragmentConstantOffset) * 4;
			fragmentConstantData[_index++] = x;
			fragmentConstantData[_index++] = y;
			fragmentConstantData[_index++] = z;
			fragmentConstantData[_index] = w;
		}
	}

}
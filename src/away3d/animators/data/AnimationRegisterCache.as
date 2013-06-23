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
		public var colorAddTarget:ShaderRegisterElement;
		public var colorMulTarget:ShaderRegisterElement;
		//vary
		public var colorAddVary:ShaderRegisterElement;
		public var colorMulVary:ShaderRegisterElement;
		
		//fragment
		
		public var uvVar:ShaderRegisterElement;
		
		//these are targets only need to rotate ( normal and tangent )
		public var rotationRegisters:Vector.<ShaderRegisterElement>;
		
		public var needFragmentAnimation:Boolean;
		public var needUVAnimation:Boolean;
		
		public var sourceRegisters:Vector.<String>;
		public var targetRegisters:Vector.<String>;
		
		private var indexDictionary:Dictionary = new Dictionary(true);
		
		//set true if has an node which will change UV
		public var hasUVNode:Boolean;
		//set if the other nodes need to access the velocity
		public var needVelocity:Boolean;
		//set if has a billboard node.
		public var hasBillboard:Boolean;
		//set if has an node which will apply color multiple operation
		public var hasColorMulNode:Boolean;
		//set if has an node which will apply color add operation
		public var hasColorAddNode:Boolean;
		
		public function AnimationRegisterCache(profile:String)
		{
			super(profile);
		}
		
		override public function reset():void
		{
			super.reset();
			
			rotationRegisters = new Vector.<ShaderRegisterElement>();
			positionAttribute = getRegisterFromString(sourceRegisters[0]);
			scaleAndRotateTarget = getRegisterFromString(targetRegisters[0]);
			addVertexTempUsages(scaleAndRotateTarget, 1);
			
			for (var i:int = 1; i < targetRegisters.length; i++) {
				rotationRegisters.push(getRegisterFromString(targetRegisters[i]));
				addVertexTempUsages(rotationRegisters[i - 1], 1);
			}
			
			scaleAndRotateTarget = new ShaderRegisterElement(scaleAndRotateTarget.regName, scaleAndRotateTarget.index); //only use xyz, w is used as vertexLife
			
			//allot const register
			
			vertexZeroConst = getFreeVertexConstant();
			vertexZeroConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, 0);
			vertexOneConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, 1);
			vertexTwoConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, 2);
			
			//allot temp register
			positionTarget = getFreeVertexVectorTemp();
			addVertexTempUsages(positionTarget, 1);
			positionTarget = new ShaderRegisterElement(positionTarget.regName, positionTarget.index);
			
			if (needVelocity) {
				velocityTarget = getFreeVertexVectorTemp();
				addVertexTempUsages(velocityTarget, 1);
				velocityTarget = new ShaderRegisterElement(velocityTarget.regName, velocityTarget.index);
				vertexTime = new ShaderRegisterElement(velocityTarget.regName, velocityTarget.index, 3);
				vertexLife = new ShaderRegisterElement(positionTarget.regName, positionTarget.index, 3);
			} else {
				var tempTime:ShaderRegisterElement = getFreeVertexVectorTemp();
				addVertexTempUsages(tempTime, 1);
				vertexTime = new ShaderRegisterElement(tempTime.regName, tempTime.index, 0);
				vertexLife = new ShaderRegisterElement(tempTime.regName, tempTime.index, 1);
			}
		
		}
		
		public function setUVSourceAndTarget(UVAttribute:String, UVVaring:String):void
		{
			uvVar = getRegisterFromString(UVVaring);
			uvAttribute = getRegisterFromString(UVAttribute);
			//uv action is processed after normal actions,so use offsetTarget as uvTarget
			uvTarget = new ShaderRegisterElement(positionTarget.regName, positionTarget.index);
		}
		
		public function setRegisterIndex(node:AnimationNodeBase, parameterIndex:int, registerIndex:int):void
		{
			//8 should be enough for any node.
			var t:Vector.<int> = indexDictionary[node] ||= new Vector.<int>(8, true);
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
			
			code += "mov " + positionTarget + ".xyz," + vertexZeroConst.toString() + "\n";
			
			if (needVelocity)
				code += "mov " + velocityTarget + ".xyz," + vertexZeroConst.toString() + "\n";
			
			return code;
		}
		
		public function getCombinationCode():String
		{
			return "add " + scaleAndRotateTarget + ".xyz," + scaleAndRotateTarget + ".xyz," + positionTarget + ".xyz\n";
		}
		
		public function initColorRegisters():String
		{
			var code:String = "";
			if (hasColorMulNode) {
				colorMulTarget = getFreeVertexVectorTemp();
				addVertexTempUsages(colorMulTarget, 1);
				colorMulVary = getFreeVarying();
				code += "mov " + colorMulTarget + "," + vertexOneConst + "\n";
			}
			if (hasColorAddNode) {
				colorAddTarget = getFreeVertexVectorTemp();
				addVertexTempUsages(colorAddTarget, 1);
				colorAddVary = getFreeVarying();
				code += "mov " + colorAddTarget + "," + vertexZeroConst + "\n";
			}
			return code;
		}
		
		public function getColorPassCode():String
		{
			var code:String = "";
			if (needFragmentAnimation && (hasColorAddNode || hasColorMulNode)) {
				if (hasColorMulNode)
					code += "mov " + colorMulVary + "," + colorMulTarget + "\n";
				if (hasColorAddNode)
					code += "mov " + colorAddVary + "," + colorAddTarget + "\n";
			}
			return code;
		}
		
		public function getColorCombinationCode(shadedTarget:String):String
		{
			var code:String = "";
			if (needFragmentAnimation && (hasColorAddNode || hasColorMulNode)) {
				var colorTarget:ShaderRegisterElement = getRegisterFromString(shadedTarget);
				addFragmentTempUsages(colorTarget, 1);
				if (hasColorMulNode)
					code += "mul " + colorTarget + "," + colorTarget + "," + colorMulVary + "\n";
				if (hasColorAddNode)
					code += "add " + colorTarget + "," + colorTarget + "," + colorAddVary + "\n";
			}
			return code;
		}
		
		private function getRegisterFromString(code:String):ShaderRegisterElement
		{
			var temp:Array = code.split(/(\d+)/);
			return new ShaderRegisterElement(temp[0], temp[1]);
		}
		
		public var vertexConstantData:Vector.<Number> = new Vector.<Number>();
		public var fragmentConstantData:Vector.<Number> = new Vector.<Number>();
		
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
			vertexConstantData.length = _numVertexConstant*4;
			fragmentConstantData.length = _numFragmentConstant*4;
		}
		
		public function setVertexConst(index:int, x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 0):void
		{
			var _index:int = (index - _vertexConstantOffset)*4;
			vertexConstantData[_index++] = x;
			vertexConstantData[_index++] = y;
			vertexConstantData[_index++] = z;
			vertexConstantData[_index] = w;
		}
		
		public function setVertexConstFromVector(index:int, data:Vector.<Number>):void
		{
			var _index:int = (index - _vertexConstantOffset)*4;
			for (var i:int = 0; i < data.length; i++)
				vertexConstantData[_index++] = data[i];
		}
		
		public function setVertexConstFromMatrix(index:int, matrix:Matrix3D):void
		{
			var rawData:Vector.<Number> = matrix.rawData;
			var _index:int = (index - _vertexConstantOffset)*4;
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
			var _index:int = (index - _fragmentConstantOffset)*4;
			fragmentConstantData[_index++] = x;
			fragmentConstantData[_index++] = y;
			fragmentConstantData[_index++] = z;
			fragmentConstantData[_index] = w;
		}
	}

}

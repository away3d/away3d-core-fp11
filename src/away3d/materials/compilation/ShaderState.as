package away3d.materials.compilation {
	public class ShaderState {
		public var numVaryings:uint = 0;
		public var numAttributes:uint = 0;
		public var numVertexConstants:uint = 0;
		public var numFragmentConstants:uint = 0;
		public var numTextureRegisters:uint = 0;

		private var varyingsMap:Object = {};
		private var attributesMap:Object = {};
		private var vertexConstantsMap:Object = {};
		private var vertexConstantsStride:Object = {};
		private var fragmentConstantsMap:Object = {};
		private var fragmentConstantsStride:Object = {};
		private var textureMap:Object = {};
		//
		private var vertexTemps:Vector.<int> = new Vector.<int>(26, true);
		private var fragmentTemps:Vector.<int> = new Vector.<int>(16, true);

		public function clear():void {
			varyingsMap = {};
			attributesMap = {};
			vertexConstantsMap = {};
			fragmentConstantsMap = {};
			textureMap = {};
			vertexConstantsStride = {};
			fragmentConstantsStride = {};

			numVaryings = 0;
			numAttributes = 0;
			numVertexConstants = 0;
			numFragmentConstants = 0;
			numTextureRegisters = 0;

			var i:int = 0;
			for (i = 0; i < 26; i++) {
				vertexTemps[i] = 0;
			}
			for (i = 0; i < 16; i++) {
				fragmentTemps[i] = 0;
			}
		}

		public function getVarying(type:String):int {
			if (varyingsMap[type] != undefined) {
				return varyingsMap[type];
			}
			var result:int = numVaryings;
			varyingsMap[type] = numVaryings;
			numVaryings++;
			return result;
		}

		public function getFreeVertexTemp():int {
			var i:int = 0;
			while (vertexTemps[i] != 0) {
				i++;
			}
			vertexTemps[i] = 1;
			return i;
		}

		public function addVertexTempUsage(i:int, count:int = 1):void {
			vertexTemps[i] += count;
		}

		public function removeVertexTempUsage(i:int):void {
			var usageCount:int = vertexTemps[i] - 1;
			if (usageCount < -1) usageCount = 0;
			vertexTemps[i] = usageCount;
		}

		public function getFreeFragmentTemp():int {
			var i:int = 0;
			while (fragmentTemps[i] != 0) {
				i++;
			}
			fragmentTemps[i] = 1;
			return i;
		}

		public function addFragmentTempUsage(i:int, count:int = 1):void {
			fragmentTemps[i] += count;
		}

		public function removeFragmentTempUsage(i:int):void {
			var usageCount:int = fragmentTemps[i] - 1;
			if (usageCount < -1) usageCount = 0;
			fragmentTemps[i] = usageCount;
		}

		public function getAttribute(type:String):int {
			if (attributesMap[type] != undefined) {
				return attributesMap[type];
			}
			var result:int = numAttributes;
			attributesMap[type] = numAttributes;
			numAttributes++;
			return result;
		}

		public function getVertexConstant(type:String, numRegisters:int = 1):int {
			if (vertexConstantsMap[type] != undefined) {
				return vertexConstantsMap[type];
			}
			var result:int = numVertexConstants;
			vertexConstantsStride[type] = numRegisters;
			vertexConstantsMap[type] = numVertexConstants;
			numVertexConstants += numRegisters;
			return result;
		}

		public function getFragmentConstant(type:String, numRegisters:int = 1):int {
			if (fragmentConstantsMap[type] != undefined) {
				return fragmentConstantsMap[type];
			}
			var result:int = numFragmentConstants;
			fragmentConstantsStride[type] = numRegisters;
			fragmentConstantsMap[type] = numFragmentConstants;
			numFragmentConstants += numRegisters;
			return result;
		}

		public function getTexture(type:String):int {
			if (textureMap[type] != undefined) {
				return textureMap[type];
			}
			var result:int = numTextureRegisters;
			textureMap[type] = numTextureRegisters;
			numTextureRegisters++;
			return result;
		}

		public function hasTexture(type:String):Boolean {
			return textureMap[type] != undefined;
		}

		public function hasVertexConstant(type:String):Boolean {
			return vertexConstantsMap[type] != undefined;
		}

		public function getVertexConstantStride(type:String):int {
			return vertexConstantsStride[type];
		}

		public function hasFragmentConstant(type:String):Boolean {
			return fragmentConstantsMap[type] != undefined;
		}

		public function getFragmentConstantStride(type:String):int {
			return fragmentConstantsStride[type];
		}

		public function hasAttribute(type:String):Boolean {
			return attributesMap[type] != undefined;
		}

		public function hasVarying(type:String):Boolean {
			return varyingsMap[type] != undefined;
		}
	}
}

package away3d.materials.compilation {
	public class ShaderState {
		public var numVaryings:uint = 0;
		public var numAttributes:uint = 0;
		public var numVertexConstants:uint = 0;
		public var numFragmentConstants:uint = 0;
		public var numFragmentTemps:uint = 0;
		public var numVertexTemps:uint = 0;
		public var numTextureRegisters:uint = 0;

		private var varyingsMap:Object = {};
		private var attributesMap:Object = {};
		private var vertexConstantsMap:Object = {};
		private var vertexConstantsStride:Object = {};
		private var fragmentConstantsMap:Object = {};
		private var fragmentConstantsStride:Object = {};
		private var textureMap:Object = {};

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
			numFragmentTemps = 0;
			numVertexTemps = 0;
			numTextureRegisters = 0;
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
			return numVertexTemps++;
		}

		public function freeLastVertexTemp():void {
			numVertexTemps--;
			if (numVertexTemps < 0) numVertexTemps = 0;
		}

		public function getFreeFragmentTemp():int {
			return numFragmentTemps++;
		}

		public function freeLastFragmentTemp():void {
			numFragmentTemps--;
			if (numFragmentTemps < 0) numFragmentTemps = 0;
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

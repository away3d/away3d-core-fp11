package away3d.materials.compilation
{
	public class UVCodeCompiler
	{
		// input
		public var animateUVs : Boolean;
		public var registerCache : ShaderRegisterCache;
		public var sharedRegisters : ShaderRegisterData;
		public var vertexConstantsOffset : int;
		public var secondaryUVs : Boolean;

		// output
		public var uvBufferIndex : int = -1;
		public var uvTransformIndex : int = -1;

		public function UVCodeCompiler(registerCache : ShaderRegisterCache, sharedRegisters : ShaderRegisterData)
		{
			this.registerCache = registerCache;
			this.sharedRegisters = sharedRegisters;
		}

		public function getVertexCode() : String
		{
			var uvAttributeReg : ShaderRegisterElement = registerCache.getFreeVertexAttribute();
			uvBufferIndex = uvAttributeReg.index;

			var varying : ShaderRegisterElement = registerCache.getFreeVarying();

			if (secondaryUVs)
				sharedRegisters.secondaryUVVarying = varying;
			else
				sharedRegisters.uvVarying = varying;

			if (animateUVs) {
				// a, b, 0, tx
				// c, d, 0, ty
				var uvTransform1 : ShaderRegisterElement = registerCache.getFreeVertexConstant();
				var uvTransform2 : ShaderRegisterElement = registerCache.getFreeVertexConstant();
				uvTransformIndex = (uvTransform1.index - vertexConstantsOffset)*4;

				return	"dp4 " + varying + ".x, " + uvAttributeReg + ", " + uvTransform1 + "\n" +
						"dp4 " + varying + ".y, " + uvAttributeReg + ", " + uvTransform2 + "\n" +
						"mov " + varying + ".zw, " + uvAttributeReg + ".zw \n";
			}
			else {
				uvTransformIndex = -1;
				return "mov " + varying + ", " + uvAttributeReg + "\n";
			}
		}
	}
}

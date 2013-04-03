package away3d.materials.compilation
{
	public class ShaderRegisterData
	{
		public var normalVarying : ShaderRegisterElement;
		public var tangentVarying : ShaderRegisterElement;
		public var bitangentVarying : ShaderRegisterElement;
		public var uvVarying : ShaderRegisterElement;
		public var secondaryUVVarying : ShaderRegisterElement;
		public var viewDirVarying : ShaderRegisterElement;
		public var shadedTarget : ShaderRegisterElement;
		public var globalPositionVertex : ShaderRegisterElement;
		public var globalPositionVarying : ShaderRegisterElement;
		public var localPosition : ShaderRegisterElement;
		public var normalInput : ShaderRegisterElement;
		public var tangentInput : ShaderRegisterElement;
		public var animatedNormal : ShaderRegisterElement;
		public var animatedTangent : ShaderRegisterElement;
		public var commons : ShaderRegisterElement;
		public var projectionFragment : ShaderRegisterElement;
		public var normalFragment : ShaderRegisterElement;
		public var viewDirFragment : ShaderRegisterElement;
		public var bitangent : ShaderRegisterElement;
	
	
		public function ShaderRegisterData() {
		
		}
	}	
}

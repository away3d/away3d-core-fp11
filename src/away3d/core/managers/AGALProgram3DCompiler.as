package away3d.core.managers
{
	import away3d.animators.data.AnimationBase;
	import away3d.arcane;
	import away3d.debug.Debug;
	import away3d.events.Stage3DEvent;
	import away3d.materials.passes.MaterialPassBase;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3DProgramType;

	import flash.display3D.Program3D;
	import flash.utils.ByteArray;

	use namespace arcane;

	public class AGALProgram3DCompiler
	{
		private var _vertexCode : String;
		private var _fragmentCode : String;

		public function AGALProgram3DCompiler()
		{
		}

		public function get vertexCode() : String
		{
			return _vertexCode;
		}

		public function get fragmentCode() : String
		{
			return _fragmentCode;
		}

		/**
		 * Compiles the fragment and vertex code for "default" DefaultMaterialBase material passes.
		 * @param pass The pass for which to compile the source code.
		 * @param animation The animation which will provide the gpu code, if possible.
		 * @param polyOffsetReg An optional register that contains an offset register, to push the polygons out. This is used by some depth renderers.
		 */
		public function compile(pass : MaterialPassBase, animation : AnimationBase, polyOffsetReg : String = null) : void
		{
			var targetRegisters : Array = pass.getAnimationTargetRegisters();
			var animationVertexCode : String = animation.getAGALVertexCode(pass);
			var materialVertexCode : String = pass.getVertexCode();
			_fragmentCode = pass.getFragmentCode();
			var projectionVertexCode : String = getProjectionCode(targetRegisters[uint(0)], pass.getProjectedTargetRegister(), polyOffsetReg, targetRegisters.length > 1? targetRegisters[1] : null);
			_vertexCode = animationVertexCode+projectionVertexCode+materialVertexCode;

			if (Debug.active) {
				trace (_vertexCode);
				trace ("------");
				trace (_fragmentCode);
			}
		}

		private function getProjectionCode(positionRegister : String, projectionRegister : String, polyOffsetReg : String, normalRegister : String) : String
		{
			var code : String = "";
			var pos : String;

			if (polyOffsetReg && normalRegister) {
				pos = "vt7";
				code += "mul vt7, "+normalRegister+", "+polyOffsetReg+"\n";
				code += "add vt7, vt7, "+positionRegister+"\n";
				code += "mov vt7.w, "+positionRegister+".w\n";
			}
			else {
				pos = positionRegister;
			}

			if (projectionRegister) {
				code += "m44 "+projectionRegister+", " + pos + ", vc0		\n" +
						"mov vt7, " + projectionRegister + "\n" +
						"mul op, vt7, vc4\n";
			}
			else {
				code += "m44 vt7, "+pos+", vc0		\n" +
						"mul op, vt7, vc4\n";	// 4x4 matrix transform from stream 0 to output clipspace
			}
			return code;
		}
	}
}
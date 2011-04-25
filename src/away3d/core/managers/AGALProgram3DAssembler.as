package away3d.core.managers
{
	import away3d.arcane;
	import away3d.animators.data.AnimationBase;
	import away3d.debug.Debug;
	import away3d.materials.passes.MaterialPassBase;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.utils.ByteArray;

	use namespace arcane;

	/**
	 * AGALProgram3DAssembler provides a singleton class that assembles the AGAL code provided by the animation and the
	 * material into a single Program3D instance, adding projection code.
	 */
	public class AGALProgram3DAssembler extends Program3DAssemblerBase
	{
		private static var _instance : AGALProgram3DAssembler;

		/**
		 * Creates a new AGALProgram3DAssembler object. Should not be used directly.
		 * @private
		 */
		public function AGALProgram3DAssembler(se : SE)
		{
		}

		/**
		 * Gets the instance for the AGALProgram3DAssembler.
		 */
		public static function get instance() : AGALProgram3DAssembler
		{
			return _instance ||= new AGALProgram3DAssembler(new SE());
		}

		/**
		 * @inheritDoc
		 */
		override public function assemble(context : Context3D, pass : MaterialPassBase, animation : AnimationBase, program : Program3D, polyOffsetReg : String = null) : void
		{
			var targetRegisters : Array = pass.getAnimationTargetRegisters();
			var animationVertexCode : String = animation.getAGALVertexCode(pass);
			var materialVertexCode : String = pass.getVertexCode();
			var materialFragmentCode : String = pass.getFragmentCode();
			var projectionVertexCode : String = getProjectionCode(targetRegisters[uint(0)], pass.getProjectedTargetRegister(), polyOffsetReg, targetRegisters.length > 1? targetRegisters[1] : null);

//			trace (animationVertexCode+projectionVertexCode+materialVertexCode);
//			trace ("---");
//			trace (materialFragmentCode);
//			trace ("---");
			var vertexCode : ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, animationVertexCode+projectionVertexCode+materialVertexCode);
			var fragmentCode : ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, materialFragmentCode);
			program.upload(vertexCode, fragmentCode);
		}

		/**
		 * Gets the projection code which will multiply the requested vertex registers by the MVP matrix.
		 * @param positionRegister The source register to be transformed.
		 * @param projectionRegister The register which will contain the projected position.
		 * @param polyOffsetReg The name of an optional offset register, containing a vector by which will cause the geometry to be "inflated" along the normal. This is typically used when rendering single object depth maps.
		 * @param normalRegister The name of the normal register which will be used as the normal to inflate against.
		 * @return
		 */
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
				code += "m44 "+projectionRegister+", " + pos + ", vc0		\n";
				code += "mov op, " + projectionRegister + "\n";
			}
			else {
				code += "m44 op, "+pos+", vc0		\n";	// 4x4 matrix transform from stream 0 to output clipspace
			}
			return code;
		}
	}
}

class SE {}
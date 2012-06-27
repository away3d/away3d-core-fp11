package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;
	import flash.geom.ColorTransform;

	use namespace arcane;

	/**
	 * ColorTransformMethod provides a shading method that changes the colour of a material according to a ColorTransform
	 * object.
	 */
	public class ColorTransformMethod extends EffectMethodBase
	{
		private var _colorTransform : ColorTransform;

		/**
		 * Creates a new ColorTransformMethod.
		 */
		public function ColorTransformMethod()
		{
			super();
		}

		/**
		 * The ColorTransform object to transform the colour of the material with.
		 */
		public function get colorTransform() : ColorTransform
		{
			return _colorTransform;
		}

		public function set colorTransform(value : ColorTransform) : void
		{
			_colorTransform = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var colorMultReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var colorOffsReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			vo.fragmentConstantsIndex = colorMultReg.index*4;
			code += "mul " + targetReg + ", " + targetReg.toString() + ", " + colorMultReg + "\n" +
					"add " + targetReg + ", " + targetReg.toString() + ", " + colorOffsReg + "\n";
			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var inv : Number = 1/0xff;
			var index : int = vo.fragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index] = _colorTransform.redMultiplier;
			data[index+1] = _colorTransform.greenMultiplier;
			data[index+2] = _colorTransform.blueMultiplier;
			data[index+3] = _colorTransform.alphaMultiplier;
			data[index+4] = _colorTransform.redOffset*inv;
			data[index+5] = _colorTransform.greenOffset*inv;
			data[index+6] = _colorTransform.blueOffset*inv;
			data[index+7] = _colorTransform.alphaOffset*inv;
		}
	}
}

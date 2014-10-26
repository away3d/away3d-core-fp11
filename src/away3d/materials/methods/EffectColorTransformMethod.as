package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
	
	import flash.geom.ColorTransform;
	
	use namespace arcane;
	
	/**
	 * ColorTransformMethod provides a shading method that changes the colour of a material analogous to a
	 * ColorTransform object.
	 */
	public class EffectColorTransformMethod extends EffectMethodBase
	{
		private var _colorTransform:ColorTransform;
		
		/**
		 * Creates a new ColorTransformMethod.
		 */
		public function EffectColorTransformMethod()
		{
			super();
		}
		
		/**
		 * The ColorTransform object to transform the colour of the material with.
		 */
		public function get colorTransform():ColorTransform
		{
			return _colorTransform;
		}
		
		public function set colorTransform(value:ColorTransform):void
		{
			_colorTransform = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String = "";
			var colorMultReg:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
			var colorOffsReg:ShaderRegisterElement = registerCache.getFreeFragmentConstant();
			methodVO.fragmentConstantsIndex = colorMultReg.index*4;
			code += "mul " + targetReg + ", " + targetReg.toString() + ", " + colorMultReg + "\n" +
				"add " + targetReg + ", " + targetReg.toString() + ", " + colorOffsReg + "\n";
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(shaderObject:ShaderObjectBase, vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			var inv:Number = 1/0xff;
			var index:int = vo.fragmentConstantsIndex;
			var data:Vector.<Number> = shaderObject.fragmentConstantData;
			data[index] = _colorTransform.redMultiplier;
			data[index + 1] = _colorTransform.greenMultiplier;
			data[index + 2] = _colorTransform.blueMultiplier;
			data[index + 3] = _colorTransform.alphaMultiplier;
			data[index + 4] = _colorTransform.redOffset*inv;
			data[index + 5] = _colorTransform.greenOffset*inv;
			data[index + 6] = _colorTransform.blueOffset*inv;
			data[index + 7] = _colorTransform.alphaOffset*inv;
		}
	}
}

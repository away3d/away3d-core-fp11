package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.filters.ColorMatrixFilter;

	use namespace arcane;

	/**
	 * ColorMatrixMethod provides a shading method that changes the colour of a material according to a ColorMatrixFilter
	 * object.
	 */
	public class ColorMatrixMethod extends EffectMethodBase
	{
		private var _data:Vector.<Number>;
		private var _filter:ColorMatrixFilter;

		/**
		 * Creates a new ColorTransformMethod.
		 */
		public function ColorMatrixMethod()
		{
			super();
			
			_data = new Vector.<Number>(20, true);
		}
		
		/**
		 * The ColorMatrixFilter object to transform the color of the material.
		 */		
		public function get colorMatrixFilter():ColorMatrixFilter
		{
			return _filter;
		}
		
		public function set colorMatrixFilter(filter:ColorMatrixFilter):void
		{
			_filter = filter;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var colorMultReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			regCache.getFreeFragmentConstant();
			regCache.getFreeFragmentConstant();
			regCache.getFreeFragmentConstant();
			var colorOffsetReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			
			vo.fragmentConstantsIndex = colorMultReg.index;

			code += "m44 " + targetReg + ", " + targetReg + ", " + colorMultReg + "\n" +
					"add " + targetReg + ", " + targetReg + ", " + colorOffsetReg + "\n";
			
			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			var matrix:Array = _filter.matrix;
			// r
			_data[0] = matrix[0];
			_data[1] = matrix[1];
			_data[2] = matrix[2];
			_data[3] = matrix[3];

			// g
			_data[4] = matrix[5];
			_data[5] = matrix[6];
			_data[6] = matrix[7];
			_data[7] = matrix[8];

			// b
			_data[8] = matrix[10];
			_data[9] = matrix[11];
			_data[10] = matrix[12];
			_data[11] = matrix[13];

			// a
			_data[12] = matrix[15];
			_data[13] = matrix[16];
			_data[14] = matrix[17];
			_data[15] = matrix[18];

			// rgba offset
			_data[16] = matrix[4];
			_data[17] = matrix[9];
			_data[18] = matrix[14];
			_data[19] = matrix[19];
			
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, vo.fragmentConstantsIndex, _data, 5);
		}
	}
}

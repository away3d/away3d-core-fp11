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
	public class ColorMatrixMethod extends ShadingMethodBase
	{
		private var _colors:Vector.<Number>; 
		private var _offset:Vector.<Number>;
		private var _colorIndex:int;
		private var _offsetIndex:int;
		private var _filter:ColorMatrixFilter;

		/**
		 * Creates a new ColorTransformMethod.
		 */
		public function ColorMatrixMethod()
		{
			super(false, false, false);
			
			_colors = new Vector.<Number>(16, true);	
			_offset = new Vector.<Number>(4, true);
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
		arcane override function reset() : void
		{
			super.reset();
			_offsetIndex = _colorIndex = -1;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var colorMultReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			regCache.getFreeFragmentConstant();
			regCache.getFreeFragmentConstant();
			regCache.getFreeFragmentConstant();
			var colorOffsetReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			
			_colorIndex = colorMultReg.index;
			_offsetIndex = colorOffsetReg.index;

			code += "m44 " + targetReg + ", " + targetReg + ", " + colorMultReg + "\n" +
					"add " + targetReg + ", " + targetReg + ", " + colorOffsetReg + "\n";
			
			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			var matrix:Array = _filter.matrix;
			// r
			_colors[0] = matrix[0];
			_colors[1] = matrix[1];
			_colors[2] = matrix[2];
			_colors[3] = matrix[3];
			_offset[0] = matrix[4];
			// g
			_colors[4] = matrix[5];
			_colors[5] = matrix[6];
			_colors[6] = matrix[7];
			_colors[7] = matrix[8];
			_offset[1] = matrix[9];
			// b
			_colors[8] = matrix[10];
			_colors[9] = matrix[11];
			_colors[10] = matrix[12];
			_colors[11] = matrix[13];
			_offset[2] = matrix[14];
			// a
			_colors[12] = matrix[15];
			_colors[13] = matrix[16];
			_colors[14] = matrix[17];
			_colors[15] = matrix[18];
			_offset[3] = matrix[19];
			
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _offsetIndex, _offset, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _colorIndex, _colors, 4);
		}
	}
}

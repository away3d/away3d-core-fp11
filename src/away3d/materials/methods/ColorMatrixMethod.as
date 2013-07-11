package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	use namespace arcane;
	
	/**
	 * ColorMatrixMethod provides a shading method that changes the colour of a material analogous to a ColorMatrixFilter.
	 */
	public class ColorMatrixMethod extends EffectMethodBase
	{
		private var _matrix:Array;
		
		/**
		 * Creates a new ColorTransformMethod.
		 *
		 * @param matrix An array of 20 items for 4 x 5 color transform.
		 */
		public function ColorMatrixMethod(matrix:Array)
		{
			super();
			if (matrix.length != 20)
				throw new Error("Matrix length must be 20!");
			
			_matrix = matrix;
		}
		
		/**
		 * The 4 x 5 matrix to transform the color of the material.
		 */
		public function get colorMatrix():Array
		{
			return _matrix;
		}
		
		public function set colorMatrix(value:Array):void
		{
			_matrix = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String = "";
			var colorMultReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			regCache.getFreeFragmentConstant();
			regCache.getFreeFragmentConstant();
			regCache.getFreeFragmentConstant();
			var colorOffsetReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			
			vo.fragmentConstantsIndex = colorMultReg.index*4;
			
			code += "m44 " + targetReg + ", " + targetReg + ", " + colorMultReg + "\n" +
				"add " + targetReg + ", " + targetReg + ", " + colorOffsetReg + "\n";
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			var matrix:Array = _matrix;
			var index:int = vo.fragmentConstantsIndex;
			var data:Vector.<Number> = vo.fragmentData;
			// r
			data[index] = matrix[0];
			data[index + 1] = matrix[1];
			data[index + 2] = matrix[2];
			data[index + 3] = matrix[3];
			
			// g
			data[index + 4] = matrix[5];
			data[index + 5] = matrix[6];
			data[index + 6] = matrix[7];
			data[index + 7] = matrix[8];
			
			// b
			data[index + 8] = matrix[10];
			data[index + 9] = matrix[11];
			data[index + 10] = matrix[12];
			data[index + 11] = matrix[13];
			
			// a
			data[index + 12] = matrix[15];
			data[index + 13] = matrix[16];
			data[index + 14] = matrix[17];
			data[index + 15] = matrix[18];
			
			// rgba offset
			data[index + 16] = matrix[4];
			data[index + 17] = matrix[9];
			data[index + 18] = matrix[14];
			data[index + 19] = matrix[19];
		}
	}
}

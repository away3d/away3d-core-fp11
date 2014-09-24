package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderLightingObject;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterData;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	use namespace arcane;
	
	/**
	 * CelDiffuseMethod provides a shading method to add diffuse cel (cartoon) shading.
	 */
	public class DiffuseCelMethod extends DiffuseCompositeMethod
	{
		private var _levels:uint;
		private var _dataReg:ShaderRegisterElement;
		private var _smoothness:Number = .1;
		
		/**
		 * Creates a new CelDiffuseMethod object.
		 * @param levels The amount of shadow gradations.
		 * @param baseDiffuseMethod An optional diffuse method on which the cartoon shading is based. If omitted, BasicDiffuseMethod is used.
		 */
		public function DiffuseCelMethod(levels:uint = 3, baseDiffuseMethod:DiffuseBasicMethod = null)
		{
			super(clampDiffuse, baseDiffuseMethod);
			
			_levels = levels;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initConstants(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			var data:Vector.<Number> = shaderObject.fragmentConstantData;
			var index:int = methodVO.secondaryFragmentConstantsIndex;
			super.initConstants(shaderObject, methodVO);
			data[index + 1] = 1;
			data[index + 2] = 0;
		}

		/**
		 * The amount of shadow gradations.
		 */
		public function get levels():uint
		{
			return _levels;
		}
		
		public function set levels(value:uint):void
		{
			_levels = value;
		}
		
		/**
		 * The smoothness of the edge between 2 shading levels.
		 */
		public function get smoothness():Number
		{
			return _smoothness;
		}
		
		public function set smoothness(value:Number):void
		{
			_smoothness = value;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData():void
		{
			super.cleanCompilationData();
			_dataReg = null;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
            _dataReg = registerCache.getFreeFragmentConstant();
            methodVO.secondaryFragmentConstantsIndex = _dataReg.index*4;

            return super.getFragmentPreLightingCode(shaderObject, methodVO, registerCache, sharedRegisters);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
			super.activate(shaderObject, methodVO, stage);
			var data:Vector.<Number> = shaderObject.fragmentConstantData;
			var index:int = methodVO.secondaryFragmentConstantsIndex;
			data[index] = _levels;
			data[index + 3] = _smoothness;
		}
		
		/**
		 * Snaps the diffuse shading of the wrapped method to one of the levels.
		 * @param vo The MethodVO used to compile the current shader.
		 * @param targetReg The register containing the diffuse strength in the "w" component.
		 * @param regCache The register cache used for the shader compilation.
		 * @param sharedRegisters The shared register data for this shader.
		 * @return The AGAL fragment code for the method.
		 */
        private function clampDiffuse(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			return "mul " + targetReg + ".w, " + targetReg + ".w, " + _dataReg + ".x\n" +
				"frc " + targetReg + ".z, " + targetReg + ".w\n" +
				"sub " + targetReg + ".y, " + targetReg + ".w, " + targetReg + ".z\n" +
				"mov " + targetReg + ".x, " + _dataReg + ".x\n" +
				"sub " + targetReg + ".x, " + targetReg + ".x, " + _dataReg + ".y\n" +
				"rcp " + targetReg + ".x," + targetReg + ".x\n" +
				"mul " + targetReg + ".w, " + targetReg + ".y, " + targetReg + ".x\n" +
				
				// previous clamped strength
				"sub " + targetReg + ".y, " + targetReg + ".w, " + targetReg + ".x\n" +
				
				// fract/epsilon (so 0 - epsilon will become 0 - 1)
				"div " + targetReg + ".z, " + targetReg + ".z, " + _dataReg + ".w\n" +
				"sat " + targetReg + ".z, " + targetReg + ".z\n" +
				
				"mul " + targetReg + ".w, " + targetReg + ".w, " + targetReg + ".z\n" +
				// 1-z
				"sub " + targetReg + ".z, " + _dataReg + ".y, " + targetReg + ".z\n" +
				"mul " + targetReg + ".y, " + targetReg + ".y, " + targetReg + ".z\n" +
				"add " + targetReg + ".w, " + targetReg + ".w, " + targetReg + ".y\n" +
				"sat " + targetReg + ".w, " + targetReg + ".w\n";
		}
	}
}

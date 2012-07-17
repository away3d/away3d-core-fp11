package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * CelDiffuseMethod provides a shading method to add specular cel (cartoon) shading.
	 */
	public class CelDiffuseMethod extends CompositeDiffuseMethod
	{
		private var _levels : uint;
		private var _dataReg : ShaderRegisterElement;
		private var _smoothness : Number = .1;

		/**
		 * Creates a new CelDiffuseMethod object.
		 * @param levels The amount of shadow gradations.
		 * @param baseDiffuseMethod An optional diffuse method on which the cartoon shading is based. If ommitted, BasicDiffuseMethod is used.
		 */
		public function CelDiffuseMethod(levels : uint = 3, baseDiffuseMethod : BasicDiffuseMethod = null)
		{
			super(clampDiffuse, baseDiffuseMethod);

			_levels = levels;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.secondaryFragmentConstantsIndex;
			super.initConstants(vo);
			data[index+1] = 1;
			data[index+2] = 0;
		}

		public function get levels() : uint
		{
			return _levels;
		}

		public function set levels(value : uint) : void
		{
			_levels = value;
		}

		/**
		 * The smoothness of the edge between 2 shading levels.
		 */
		public function get smoothness() : Number
		{
			return _smoothness;
		}

		public function set smoothness(value : Number) : void
		{
			_smoothness = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_dataReg = null;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			_dataReg = regCache.getFreeFragmentConstant();
			vo.secondaryFragmentConstantsIndex = _dataReg.index*4;
			return super.getFragmentPreLightingCode(vo, regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);
			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.secondaryFragmentConstantsIndex;
			data[index] =_levels;
			data[index+3] = _smoothness;
		}

		/**
		 * Snaps the diffuse shading of the wrapped method to one of the levels.
		 * @param t The register containing the diffuse strength in the "w" component.
		 * @param regCache The register cache used for the shader compilation.
		 * @return The AGAL fragment code for the method.
		 */
		private function clampDiffuse(vo : MethodVO, t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			return 	"mul " + t+".w, " + t+".w, " + _dataReg+".x\n" +
					"frc " + t+".z, " + t+".w\n" +
					"sub " + t+".y, " +  t+".w, " + t+".z\n" +
					"mov " + t+".x, " + _dataReg+".x\n" +
					"sub " + t+".x, " + t+".x, " + _dataReg+".y\n" +
					"rcp " + t+".x," + t+".x\n" +
					"mul " + t+".w, " + t+".y, " + t+".x\n" +

			// previous clamped strength
					"sub "  + t+".y, " + t+".w, " + t+".x\n" +

			// fract/epsilon (so 0 - epsilon will become 0 - 1)
					"div " + t+".z, " + t+".z, " + _dataReg+".w\n" +
					"sat " + t+".z, " + t+".z\n" +

					"mul " + t+".w, " + t+".w, " + t+".z\n" +
			// 1-z
					"sub " + t+".z, " + _dataReg+".y, " + t+".z\n" +
					"mul " + t+".y, " + t+".y, " + t+".z\n" +
					"add " + t+".w, " + t+".w, " + t+".y\n" +
					"sat " + t+".w, " + t+".w\n";
		}
	}
}

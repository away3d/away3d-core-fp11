package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.materials.utils.AGAL;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * CelDiffuseMethod provides a shading method to add specular cel (cartoon) shading.
	 */
	public class CelDiffuseMethod extends WrapDiffuseMethod
	{
		private var _levels : uint;
		private var _dataReg : ShaderRegisterElement;
		private var _dataIndex : int;
		private var _data : Vector.<Number>;

		/**
		 * Creates a new CelDiffuseMethod object.
		 * @param levels The amount of shadow gradations.
		 * @param baseDiffuseMethod An optional diffuse method on which the cartoon shading is based. If ommitted, BasicDiffuseMethod is used.
		 */
		public function CelDiffuseMethod(levels : uint = 3, baseDiffuseMethod : BasicDiffuseMethod = null)
		{
			super(clampDiffuse, baseDiffuseMethod);

			_levels = levels;
			_data = Vector.<Number>([levels, 1, 0, .1]);
		}


		public function get levels() : uint
		{
			return _levels;
		}

		public function set levels(value : uint) : void
		{
			_levels = value;
			_data[0] = value;
		}

		/**
		 * The smoothness of the edge between 2 shading levels.
		 */
		public function get smoothness() : Number
		{
			return _data[3];
		}

		public function set smoothness(value : Number) : void
		{
			_data[3] = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentAGALPreLightingCode(regCache : ShaderRegisterCache) : String
		{
			_dataReg = regCache.getFreeFragmentConstant();
			_dataIndex = _dataReg.index;
			return super.getFragmentAGALPreLightingCode(regCache);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(context : Context3D, contextIndex : uint) : void
		{
			super.activate(context, contextIndex);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _dataIndex, _data, 1);
		}

		/**
		 * Snaps the diffuse shading of the wrapped method to one of the levels.
		 * @param t The register containing the diffuse strength in the "w" component.
		 * @param regCache The register cache used for the shader compilation.
		 * @return The AGAL fragment code for the method.
		 */
		private function clampDiffuse(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";

			code += AGAL.mul(t+".w", t+".w", _dataReg+".x");
			code += AGAL.fract(t+".z", t+".w");
			code += AGAL.sub(t+".y", t+".w", t+".z");
			code += AGAL.mov(t+".x", _dataReg+".x");
			code += AGAL.sub(t+".x", t+".x", _dataReg+".y");
			code += AGAL.rcp(t+".x", t+".x");
			code += AGAL.mul(t+".w", t+".y", t+".x");

			// previous clamped strength
			code += AGAL.sub(t+".y", t+".w", t+".x");

			// fract/epsilon (so 0 - epsilon will become 0 - 1)
			code += AGAL.div(t+".z", t+".z", _dataReg+".w");
			code += AGAL.sat(t+".z", t+".z");

			code += AGAL.mul(t+".w", t+".w", t+".z");
			// 1-z
			code += AGAL.sub(t+".z", _dataReg+".y", t+".z");
			code += AGAL.mul(t+".y", t+".y", t+".z");
			code += AGAL.add(t+".w", t+".w", t+".y");
			code += AGAL.sat(t+".w", t+".w");

			return code;
		}
	}
}

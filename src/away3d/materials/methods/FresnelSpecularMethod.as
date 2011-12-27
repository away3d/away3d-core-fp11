package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * FresnelSpecularMethod provides a specular shading method that is stronger on shallow view angles.
	 */
	public class FresnelSpecularMethod extends CompositeSpecularMethod
	{
		private var _dataReg : ShaderRegisterElement;
		private var _dataIndex : int;
		private var _data : Vector.<Number>;
        private var _incidentLight : Boolean;

		/**
		 * Creates a new FresnelSpecularMethod object.
		 * @param basedOnSurface Defines whether the fresnel effect should be based on the view angle on the surface (if true), or on the angle between the light and the view.
		 * @param baseSpecularMethod
		 */
		public function FresnelSpecularMethod(basedOnSurface : Boolean = true, baseSpecularMethod : BasicSpecularMethod = null)
		{
            // may want to offer diff speculars
			super(modulateSpecular, baseSpecularMethod);
			_data = new Vector.<Number>(4, true);
            _data[0] = .028; // skin
            _data[1] = 5; // exponent
            _data[2] = 1;
            _incidentLight = !basedOnSurface;
		}

		public function get fresnelPower() : Number
		{
			return _data[1];
		}

		public function set fresnelPower(value : Number) : void
		{
			_data[1] = value;
		}

		arcane override function reset() : void
		{
			super.reset();
			_dataIndex = -1;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_dataReg = null;
		}

		/**
		 * The minimum amount of reflectance, ie the reflectance when the view direction is normal to the surface or light direction.
		 */
		public function get normalReflectance() : Number
		{
			return _data[0];
		}

		public function set normalReflectance(value : Number) : void
		{
			_data[0] = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy) : void
		{
			super.activate(stage3DProxy);
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _dataIndex, _data, 1);
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
		 * Applies the fresnel effect to the specular strength.
		 *
		 * @param target The register containing the specular strength in the "w" component, and the half-vector/reflection vector in "xyz".
		 * @param regCache The register cache used for the shader compilation.
		 * @return The AGAL fragment code for the method.
		 */
		private function modulateSpecular(target : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			// TODO: not used
			regCache = regCache;			
			var code : String = "";

			// use view dir and normal fragment .w as temp
            // use normal or half vector? :s
            code += "dp3 " + _viewDirFragmentReg+".w, " + _viewDirFragmentReg+".xyz, " + (_incidentLight? target+".xyz\n" : _normalFragmentReg+".xyz\n") +   // dot(V, H)
            		"sub " + _viewDirFragmentReg+".w, " + _dataReg+".z, " + _viewDirFragmentReg+".w\n" +             // base = 1-dot(V, H)

            		"mul " + _normalFragmentReg+".w, " + _viewDirFragmentReg+".w, " + _viewDirFragmentReg+".w\n" +             // exp = pow(base, 2)
					"mul " + _normalFragmentReg+".w, " + _normalFragmentReg+".w, " + _normalFragmentReg+".w\n" +             // exp = pow(base, 4)
					"mul " + _viewDirFragmentReg+".w, " + _normalFragmentReg+".w, " + _viewDirFragmentReg+".w\n" +             // exp = pow(base, 5)

					"sub " + _normalFragmentReg+".w, " + _dataReg+".z, " + _viewDirFragmentReg+".w\n" +             // 1 - exp
					"mul " + _normalFragmentReg+".w, " + _dataReg+".x, " + _normalFragmentReg+".w\n" +             // f0*(1 - exp)
					"add " + _viewDirFragmentReg+".w, " + _viewDirFragmentReg+".w, " + _normalFragmentReg+".w\n" +          // exp + f0*(1 - exp)
					"mul " + target+".w, " + target+".w, " + _viewDirFragmentReg+".w\n";
//            code += AGAL.sat(target+".w", target+".w");

			return code;
		}

	}
}

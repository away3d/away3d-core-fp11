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
        private var _incidentLight : Boolean;
        private var _fresnelPower : Number = 5;
		private var _normalReflectance : Number = .028;	// default value for skin

		/**
		 * Creates a new FresnelSpecularMethod object.
		 * @param basedOnSurface Defines whether the fresnel effect should be based on the view angle on the surface (if true), or on the angle between the light and the view.
		 * @param baseSpecularMethod
		 */
		public function FresnelSpecularMethod(basedOnSurface : Boolean = true, baseSpecularMethod : BasicSpecularMethod = null)
		{
            // may want to offer diff speculars
			super(modulateSpecular, baseSpecularMethod);
            _incidentLight = !basedOnSurface;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var index : int = vo.secondaryFragmentConstantsIndex;
			vo.fragmentData[index+2] = 1;
			vo.fragmentData[index+3] = 0;
		}

		public function get fresnelPower() : Number
		{
			return _fresnelPower;
		}

		public function set fresnelPower(value : Number) : void
		{
			_fresnelPower = value;
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
			return _normalReflectance;
		}

		public function set normalReflectance(value : Number) : void
		{
			_normalReflectance = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);
			var fragmentData : Vector.<Number> = vo.fragmentData;
			var index : int = vo.secondaryFragmentConstantsIndex;
			fragmentData[index] = _normalReflectance;
			fragmentData[index+1] = _fresnelPower;
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
		 * Applies the fresnel effect to the specular strength.
		 *
		 * @param target The register containing the specular strength in the "w" component, and the half-vector/reflection vector in "xyz".
		 * @param regCache The register cache used for the shader compilation.
		 * @return The AGAL fragment code for the method.
		 */
		private function modulateSpecular(vo : MethodVO, target : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";

			// use view dir and normal fragment .w as temp
            // use normal or half vector? :s
            code += "dp3 " + _viewDirFragmentReg+".w, " + _viewDirFragmentReg+".xyz, " + (_incidentLight? target+".xyz\n" : _normalFragmentReg+".xyz\n") +   // dot(V, H)
            		"sub " + _viewDirFragmentReg+".w, " + _dataReg+".z, " + _viewDirFragmentReg+".w\n" +             // base = 1-dot(V, H)
            		"pow " + _normalFragmentReg+".w, " + _viewDirFragmentReg+".w, " + _dataReg+".y\n" +             // exp = pow(base, 5)
					"sub " + _viewDirFragmentReg+".w, " + _dataReg+".z, " + _normalFragmentReg+".w\n" +             // 1 - exp
					"mul " + _viewDirFragmentReg+".w, " + _dataReg+".x, " + _viewDirFragmentReg+".w\n" +             // f0*(1 - exp)
					"add " + _viewDirFragmentReg+".w, " + _normalFragmentReg+".w, " + _viewDirFragmentReg+".w\n" +          // exp + f0*(1 - exp)
					"mul " + target+".w, " + target+".w, " + _viewDirFragmentReg+".w\n";

			return code;
		}

	}
}

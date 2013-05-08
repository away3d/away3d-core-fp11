package away3d.materials.methods {
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterData;
	import away3d.materials.compilation.ShaderRegisterElement;

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
		
		/**
		 * Defines whether the fresnel effect should be based on the view angle on the surface (if true), or on the angle between the light and the view.
		 */
		public function get basedOnSurface() : Boolean
		{
			return !_incidentLight;
		}
		
		public function set basedOnSurface(value : Boolean) : void
		{
			if (_incidentLight != value)
				return;
			
			_incidentLight = !value;
			
			invalidateShaderProgram();
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
		private function modulateSpecular(vo : MethodVO, target : ShaderRegisterElement, regCache : ShaderRegisterCache, sharedRegisters : ShaderRegisterData) : String
		{
			vo=vo;
			regCache=regCache;
			
			var code : String;

            code = 	"dp3 " + target+".y, " + sharedRegisters.viewDirFragment+".xyz, " + (_incidentLight? target+".xyz\n" : sharedRegisters.normalFragment+".xyz\n") +   // dot(V, H)
            		"sub " + target+".y, " + _dataReg+".z, " + target+".y\n" +             // base = 1-dot(V, H)
            		"pow " + target+".x, " + target+".y, " + _dataReg+".y\n" +             // exp = pow(base, 5)
					"sub " + target+".y, " + _dataReg+".z, " + target+".y\n" +             // 1 - exp
					"mul " + target+".y, " + _dataReg+".x, " + target+".y\n" +             // f0*(1 - exp)
					"add " + target+".y, " + target+".x, " + target+".y\n" +          // exp + f0*(1 - exp)
					"mul " + target+".w, " + target+".w, " + target+".y\n";

			return code;
		}

	}
}

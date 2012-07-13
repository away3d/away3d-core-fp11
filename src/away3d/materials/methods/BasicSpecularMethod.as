package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * BasicSpecularMethod provides the default shading method for Blinn-Phong specular highlights.
	 */
	public class BasicSpecularMethod extends LightingMethodBase
	{
		protected var _useTexture : Boolean;
		protected var _totalLightColorReg : ShaderRegisterElement;
		protected var _specularTextureRegister : ShaderRegisterElement;
		protected var _specularTexData : ShaderRegisterElement;
		protected var _specularDataRegister : ShaderRegisterElement;

		private var _texture : Texture2DBase;

		private var _gloss : int = 50;
		private var _specular : Number = 1;
		private var _specularColor : uint = 0xffffff;
		arcane var _specularR : Number = 1, _specularG : Number = 1, _specularB : Number = 1;
		private var _shadowRegister : ShaderRegisterElement;
		private var _shadingModel:String;

		
		/**
		 * Creates a new BasicSpecularMethod object.
		 */
		public function BasicSpecularMethod()
		{
			super();
			_shadingModel = SpecularShadingModel.BLINN_PHONG;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsUV = _useTexture;
			vo.needsNormals = vo.numLights > 0;
			vo.needsView = vo.numLights > 0;
		}

		/**
		 * The sharpness of the specular highlight.
		 */
		public function get gloss() : Number
		{
			return _gloss;
		}

		public function set gloss(value : Number) : void
		{
			_gloss = value;
		}

		/**
		 * The overall strength of the specular highlights.
		 */
		public function get specular() : Number
		{
			return _specular;
		}

		public function set specular(value : Number) : void
		{
			if (value == _specular) return;

			_specular = value;
			updateSpecular();
		}
		
		/**
		 * The model used by the specular shader
		 * 
		 * @see away3d.materials.methods.SpecularShadingModel
		 */
		public function get shadingModel() : String
		{
			return _shadingModel;
		}
		
		public function set shadingModel(value : String) : void
		{
			if (value == _shadingModel) return;
			
			_shadingModel = value;
			
			invalidateShaderProgram();
		}
		
		/**
		 * The colour of the specular reflection of the surface.
		 */
		public function get specularColor() : uint
		{
			return _specularColor;
		}

		public function set specularColor(value : uint) : void
		{
			if (_specularColor == value) return;

			// specular is now either enabled or disabled
			if (_specularColor == 0 || value == 0) invalidateShaderProgram();
			_specularColor = value;
			updateSpecular();
		}

		/**
		 * The bitmapData that encodes the specular highlight strength per texel in the red channel, and the sharpness
		 * in the green channel. You can use SpecularBitmapTexture if you want to easily set specular and gloss maps
		 * from greyscale images, but prepared images are preffered.
		 */
		public function get texture() : Texture2DBase
		{
			return _texture;
		}

		public function set texture(value : Texture2DBase) : void
		{
			if (!value || !_useTexture) invalidateShaderProgram();
			_useTexture = Boolean(value);
			_texture = value;
		}

		/**
		 * Copies the state from a BasicSpecularMethod object into the current object.
		 */
		override public function copyFrom(method : ShadingMethodBase) : void
		{
			var spec : BasicSpecularMethod = BasicSpecularMethod(method);
			texture = spec.texture;
			specular = spec.specular;
			specularColor = spec.specularColor;
			gloss = spec.gloss;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_shadowRegister = null;
			_totalLightColorReg = null;
			_specularTextureRegister = null;
			_specularTexData = null;
			_specularDataRegister = null;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";

			if (vo.numLights > 0) {
				_specularDataRegister = regCache.getFreeFragmentConstant();
				vo.fragmentConstantsIndex = _specularDataRegister.index*4;

				if (_useTexture) {
					_specularTexData = regCache.getFreeFragmentVectorTemp();
					regCache.addFragmentTempUsages(_specularTexData, 1);
					_specularTextureRegister = regCache.getFreeTextureReg();
					vo.texturesIndex = _specularTextureRegister.index;
					code = getTexSampleCode(vo, _specularTexData, _specularTextureRegister);
				}
				else
					_specularTextureRegister = null;

				_totalLightColorReg = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(_totalLightColorReg, 1);
			}

			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCodePerLight(vo : MethodVO, lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var t : ShaderRegisterElement;
			
			if (lightIndex > 0) {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			else t = _totalLightColorReg;
			
			switch (_shadingModel) {
				case SpecularShadingModel.BLINN_PHONG:
					
					// half vector
					code += "add " + t + ".xyz, " + lightDirReg + ".xyz, " + _viewDirFragmentReg + ".xyz\n" +
							"nrm " + t + ".xyz, " + t + ".xyz\n" +
							"dp3 " + t + ".w, " + _normalFragmentReg + ".xyz, " + t + ".xyz\n" +
							"sat " + t + ".w, " + t + ".w\n";
					
					break;
				case SpecularShadingModel.PHONG:
					
					// phong model
					code += "dp3 " + t + ".w, " + lightDirReg + ".xyz, " + _normalFragmentReg + ".xyz\n" + // sca1 = light.normal
					
							//find the reflected light vector R
							"add " + t + ".w, " + t + ".w, " + t + ".w\n" + // sca1 = sca1*2
							"mul " + t + ".xyz, " + _normalFragmentReg + ".xyz, " + t + ".w\n" + // vec1 = normal*sca1
							"sub " + t + ".xyz, " + t + ".xyz, " + lightDirReg + ".xyz\n" + // vec1 = vec1 - light (light vector is negative)
							
							//smooth the edge as incidence angle approaches 90
							"add" + t + ".w, " + t + ".w, " + _normalFragmentReg + ".w\n" + // sca1 = sca1 + smoothtep;
							//"div" + t + ".w, " + t + ".w, " + _specularDataRegister2 + ".z\n" + // sca1 = sca1/smoothtep;
							"sat " + t + ".w, " + t + ".w\n" + // sca1 range 0 - 1
							"mul " + t + ".xyz, " + t + ".xyz, " + t + ".w\n" + // vec1 = vec1*sca1
							
							//find the dot product between R and V
							"dp3 " + t + ".w, " + t + ".xyz, " + _viewDirFragmentReg + ".xyz\n" + // sca1 = vec1.view
							"sat " + t + ".w, " + t + ".w\n";
					
					break;
				default:
			}
			
			if (_useTexture) {
				// apply gloss modulation from texture
				code += "mul " + _specularTexData + ".w, " + _specularTexData + ".y, " + _specularDataRegister + ".w\n" +
						"pow " + t + ".w, " + t + ".w, " + _specularTexData + ".w\n";
			}
			else
				code += "pow " + t + ".w, " + t + ".w, " + _specularDataRegister + ".w\n";
			
			// attenuate
			code += "mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";

			if (_modulateMethod != null) code += _modulateMethod(vo, t, regCache);

			code += "mul " + t + ".xyz, " + lightColReg + ".xyz, " + t + ".w\n";
				
			if (lightIndex > 0) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + t + ".xyz\n";
				regCache.removeFragmentTempUsage(t);
			}

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerProbe(vo : MethodVO, lightIndex : int, cubeMapReg : ShaderRegisterElement, weightRegister : String, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var t : ShaderRegisterElement;

			// todo: add property that defines the indexing mode of the probe map: through view vector or reflectance vector

			// write in temporary if not first light, so we can add to total diffuse colour
			if (lightIndex > 0) {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			else {
				t = _totalLightColorReg;
			}

			code += "tex " + t + ", " + _viewDirFragmentReg + ", " + cubeMapReg + " <cube,linear,miplinear>\n" +
					"mul " + t + ", " + t + ", " + weightRegister + "\n";

			if (lightIndex > 0) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + t + ".xyz\n";
				regCache.removeFragmentTempUsage(t);
			}

			return code;
		}


		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";

			if (vo.numLights == 0)
				return code;

			if (_shadowRegister)
				code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + _shadowRegister + ".w\n";

			if (_useTexture) {
				// apply strength modulation from texture
				code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + _specularTexData + ".x\n";
				regCache.removeFragmentTempUsage(_specularTexData);
			}

			// apply material's specular reflection
			code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + _specularDataRegister + ".xyz\n" +
					"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + _totalLightColorReg + ".xyz\n";
			regCache.removeFragmentTempUsage(_totalLightColorReg);

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var context : Context3D = stage3DProxy._context3D;

			if (vo.numLights == 0) return;

			if (_useTexture) stage3DProxy.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			var index : int = vo.fragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index] = _specularR;
			data[index+1] = _specularG;
			data[index+2] = _specularB;
			data[index+3] = _gloss;
		}

		/**
		 * Updates the specular color data used by the render state.
		 */
		private function updateSpecular() : void
		{
			_specularR = ((_specularColor >> 16) & 0xff) / 0xff * _specular;
			_specularG = ((_specularColor >> 8) & 0xff) / 0xff * _specular;
			_specularB = (_specularColor & 0xff) / 0xff * _specular;
		}

		arcane function set shadowRegister(shadowReg : ShaderRegisterElement) : void
		{
			_shadowRegister = shadowReg;
		}
	}
}

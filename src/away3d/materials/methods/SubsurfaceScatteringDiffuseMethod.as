package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterData;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.passes.SingleObjectDepthPass;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;

	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;

	use namespace arcane;

	/**
	 * SubsurfaceScatteringDiffuseMethod provides a depth map-based diffuse shading method that mimics the scattering of
	 * light inside translucent surfaces. It allows light to shine through an object and to soften the diffuse shading.
	 * It can be used for candle wax, ice, skin, ...
	 */
	public class SubsurfaceScatteringDiffuseMethod extends CompositeDiffuseMethod
	{
		private var _depthPass : SingleObjectDepthPass;
		private var _lightProjVarying : ShaderRegisterElement;
		private var _propReg : ShaderRegisterElement;
		private var _scattering : Number;
		private var _translucency : Number = 1;
		private var _lightColorReg : ShaderRegisterElement;
		private var _scatterColor : uint = 0xffffff;
		private var _colorReg : ShaderRegisterElement;
        private var _decReg : ShaderRegisterElement;
		private var _scatterR : Number = 1.0;
		private var _scatterG : Number = 1.0;
		private var _scatterB : Number = 1.0;
		private var _targetReg : ShaderRegisterElement;

		/**
		 * Creates a new SubsurfaceScatteringDiffuseMethod object.
		 * @param depthMapSize The size of the depth map used.
		 * @param depthMapOffset The amount by which the rendered object will be inflated, to prevent depth map rounding errors.
		 */
		public function SubsurfaceScatteringDiffuseMethod(depthMapSize : int = 512, depthMapOffset : Number = 15)
		{
			super(scatterLight);
			_passes = new Vector.<MaterialPassBase>();
			_depthPass = new SingleObjectDepthPass(depthMapSize, depthMapOffset);
			_passes.push(_depthPass);
			_scattering = 0.2;
			_translucency = 1;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			super.initConstants(vo);
			var data : Vector.<Number> = vo.vertexData;
			var index : int = vo.secondaryVertexConstantsIndex;
			data[index] = .5;
			data[index+1] = -.5;
			data[index+2] = 0;
			data[index+3] = 1;

			data = vo.fragmentData;
			index = vo.secondaryFragmentConstantsIndex;
			data[index+3] = 1.0;
			data[index+4] = 1.0;
			data[index+5] = 1/255;
			data[index+6] = 1/65025;
			data[index+7] = 1/16581375;
			data[index+10] = .5;
			data[index+11] = -.1;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();

			_lightProjVarying = null;
			_propReg = null;
			_lightColorReg = null;
			_colorReg = null;
			_decReg = null;
			_targetReg = null;
		}

		/**
		 * The amount by which the light scatters. It can be used to set the translucent surface's thickness. Use low
		 * values for skin.
		 */
		public function get scattering() : Number
		{
			return _scattering;
		}

		public function set scattering(value : Number) : void
		{
			_scattering = value;
		}

		/**
		 * The translucency of the object.
		 */
		public function get translucency() : Number
		{
			return _translucency;
		}

		public function set translucency(value : Number) : void
		{
			_translucency = value;
		}

		/**
		 * The colour the light becomes inside the object.
		 */
		public function get scatterColor() : uint
		{
			return _scatterColor;
		}

		public function set scatterColor(scatterColor : uint) : void
		{
			_scatterColor = scatterColor;
			_scatterR = ((scatterColor >> 16) & 0xff) / 0xff;
			_scatterG = ((scatterColor >> 8) & 0xff) / 0xff;
			_scatterB = (scatterColor & 0xff) / 0xff;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			var code : String = super.getVertexCode(vo, regCache);
			var lightProjection : ShaderRegisterElement;
			var toTexRegister : ShaderRegisterElement;
			var temp : ShaderRegisterElement = regCache.getFreeVertexVectorTemp();

			toTexRegister = regCache.getFreeVertexConstant();
			vo.secondaryVertexConstantsIndex = toTexRegister.index*4;

			_lightProjVarying = regCache.getFreeVarying();
			lightProjection = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();

			code += "m44 " + temp+ ", vt0, " + lightProjection + "\n" +
					"div " + temp+".xyz, " + temp+".xyz, " + temp+".w\n" +
					"mul " + temp+".xy, " + temp+".xy, " + toTexRegister+".xy\n" +
					"add " + temp+".xy, " + temp+".xy, " + toTexRegister+".xx\n" +
					"mov " + _lightProjVarying + ".xyz, " + temp+".xyz\n" +
					"mov " + _lightProjVarying + ".w, va0.w\n";

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			_colorReg = regCache.getFreeFragmentConstant();
            _decReg = regCache.getFreeFragmentConstant();
			_propReg = regCache.getFreeFragmentConstant();
			vo.secondaryFragmentConstantsIndex = _colorReg.index*4;

			return super.getFragmentPreLightingCode(vo, regCache);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerLight(vo : MethodVO, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			_isFirstLight = true;
			_lightColorReg = lightColReg;
			return super.getFragmentCodePerLight(vo, lightDirReg, lightColReg, regCache);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = super.getFragmentPostLightingCode(vo, regCache, targetReg);
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

			code += "mul " + temp+".xyz, " + _lightColorReg+".xyz, " + _targetReg+".w\n" +
					"mul " + temp+".xyz, " + temp+".xyz, " + _colorReg+".xyz\n" +
					"add " + targetReg+".xyz, " + targetReg+".xyz, " + temp+".xyz\n";

			if(_targetReg != _sharedRegisters.viewDirFragment)
				regCache.removeFragmentTempUsage(targetReg);

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);

			var index : int = vo.secondaryFragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index] = _scatterR;
			data[index+1] = _scatterG;
			data[index+2] = _scatterB;
			data[index+8] = _scattering;
			data[index+9] = _translucency;
		}

		arcane override function setRenderState(vo : MethodVO, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var depthMap : Texture = _depthPass.getDepthMap(renderable, stage3DProxy);
			var projection : Matrix3D = _depthPass.getProjection(renderable);

			stage3DProxy._context3D.setTextureAt(vo.secondaryTexturesIndex, depthMap);
			projection.copyRawDataTo(vo.vertexData, vo.secondaryVertexConstantsIndex+4, true);
		}

		/**
		 * Generates the code for this method
		 */
		private function scatterLight(vo : MethodVO, targetReg : ShaderRegisterElement, regCache : ShaderRegisterCache, sharedRegisters : ShaderRegisterData) : String
		{
			// only scatter first light
			if (!_isFirstLight) return "";
			_isFirstLight = false;

			var code : String = "";
			var depthReg : ShaderRegisterElement = regCache.getFreeTextureReg();


			if (sharedRegisters.viewDirFragment) {
				_targetReg = sharedRegisters.viewDirFragment;
			}
			else {
				_targetReg = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(_targetReg, 1);
			}

			vo.secondaryTexturesIndex = depthReg.index;

			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			code += "tex " + temp + ", " + _lightProjVarying + ", " + depthReg +  " <2d,nearest,clamp>\n" +
			// reencode RGBA
					"dp4 " + targetReg+".z, " + temp + ", " + _decReg + "\n";
			// currentDistanceToLight - closestDistanceToLight
			code +=	"sub " + targetReg+".z, " + _lightProjVarying+".z, " + targetReg+".z\n" +

					"sub " + targetReg+".z, " + _propReg+".x, " + targetReg+".z\n" +
					"mul " + targetReg+".z, " + _propReg+".y, " + targetReg+".z\n" +
					"sat " + targetReg+".z, " + targetReg+".z\n" +

			// targetReg.x contains dot(lightDir, normal)
			// modulate according to incident light angle (scatter = scatter*(-.5*dot(light, normal) + .5)
					"neg " + targetReg+".y, " + targetReg+".x\n" +
					"mul " + targetReg+".y, " + targetReg+".y, " + _propReg+".z\n" +
					"add " + targetReg+".y, " + targetReg+".y, " + _propReg+".z\n" +
					"mul " + _targetReg+".w, " + targetReg+".z, " + targetReg+".y\n" +

			// blend diffuse: d' = (1-s)*d + s*1
					"sub " + targetReg+".y, " + _colorReg+".w, " + _targetReg+".w\n" +
					"mul " + targetReg+".w, " + targetReg+".w, " + targetReg+".y\n";

			return code;
		}
	}
}
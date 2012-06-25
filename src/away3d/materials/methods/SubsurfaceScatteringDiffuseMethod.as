package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.passes.SingleObjectDepthPass;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
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
		private var _commonProps : Vector.<Number>;
		private var _toTexRegister : ShaderRegisterElement;
		private var _invRegister : ShaderRegisterElement;
		private var _scattering : Number;
		private var _translucency : Number = 1;
		private var _lightIndex : int;
		private var _totalScatterColorReg : ShaderRegisterElement;
		private var _lightColorReg : ShaderRegisterElement;
		private var _scatterColor : uint = 0xffffff;
		private var _data : Vector.<Number>;
		private var _colorReg : ShaderRegisterElement;
        private var _decReg : ShaderRegisterElement;

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
			_commonProps = Vector.<Number>([.5, -.5, 0, 1.0]);
			_data = Vector.<Number>([1.0, 1.0, 1.0, 1.0, 1.0, 1/255.0, 1/65025.0, 1/16581375.0, 0, 0, .5, -.1]);
			scattering = 0.2;
			translucency = 1;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();

			_lightProjVarying = null;
			_toTexRegister = null;
			_invRegister = null;
			_totalScatterColorReg = null;
			_lightColorReg = null;
			_colorReg = null;
			_decReg = null;
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
			_data[8] = value;
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
			_data[9] = value;
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
			_data[0] = ((scatterColor >> 16) & 0xff) / 0xff;
			_data[1] = ((scatterColor >> 8) & 0xff) / 0xff;
			_data[2] = (scatterColor & 0xff) / 0xff;
			_data[3] = 1;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function reset() : void
		{
			_lightIndex = 0;
			super.reset();
		}


		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			var code : String = super.getVertexCode(vo, regCache);
			var lightProjection : ShaderRegisterElement;
			var temp : ShaderRegisterElement = regCache.getFreeVertexVectorTemp();

			_toTexRegister = regCache.getFreeVertexConstant();
			vo.vertexConstantsIndex = _toTexRegister.index;

			_lightProjVarying = regCache.getFreeVarying();
			lightProjection = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();

			code += "m44 " + temp+ ", vt0, " + lightProjection + "\n" +
					"rcp " + temp+".w, " + temp+".w\n" +
					"mul " + temp+".xyz, " + temp+".xyz, " + temp+".w\n" +
					"mul " + temp+".xy, " + temp+".xy, " + _toTexRegister+".xy\n" +
					"add " + temp+".xy, " + temp+".xy, " + _toTexRegister+".xx\n" +
					"mov " + _lightProjVarying + ".xyz, " + temp+".xyz\n" +
					"mov " + _lightProjVarying + ".w, va0.w\n";

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentAGALPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : String
		{
			_totalScatterColorReg = regCache.getFreeFragmentVectorTemp();
			_colorReg = regCache.getFreeFragmentConstant();
            _decReg = regCache.getFreeFragmentConstant();
			_invRegister = regCache.getFreeFragmentConstant();
			vo.secondaryFragmentConstantsIndex = _colorReg.index;

			regCache.addFragmentTempUsages(_totalScatterColorReg, 1);
			return super.getFragmentAGALPreLightingCode(vo, regCache);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerLight(vo : MethodVO, lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			_lightColorReg = lightColReg;
			_lightIndex = lightIndex;
			return super.getFragmentCodePerLight(vo, lightIndex, lightDirReg, lightColReg, regCache);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = super.getFragmentPostLightingCode(vo, regCache, targetReg);
			code += "add " + targetReg+".xyz, " + targetReg+".xyz, " + _totalScatterColorReg+".xyz\n";
			regCache.removeFragmentTempUsage(_totalScatterColorReg);
			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var context : Context3D = stage3DProxy._context3D;

			super.activate(vo, stage3DProxy);

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vo.vertexConstantsIndex, _commonProps, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, vo.secondaryFragmentConstantsIndex, _data, 3);
		}

		arcane override function setRenderState(vo : MethodVO, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			var depthMaps : Vector.<Texture> = _depthPass.getDepthMaps(renderable, stage3DProxy);
			var projections : Vector.<Matrix3D> = _depthPass.getProjections(renderable);

			stage3DProxy.setTextureAt(vo.secondaryTexturesIndex, depthMaps[0]);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, vo.vertexConstantsIndex+1, projections[0], true);
		}

		/**
		 * Generates the code for this method
		 */
		private function scatterLight(vo : MethodVO, targetReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var depthReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var projReg : ShaderRegisterElement = _lightProjVarying;

			// only scatter first light
			if (_lightIndex > 0) return "";

			vo.secondaryTexturesIndex = depthReg.index;

//			temp = regCache.getFreeFragmentVectorTemp();
			code += "tex " + _totalScatterColorReg + ", " + projReg + ", " + depthReg +  " <2d,nearest,clamp>\n" +
			// reencode RGBA
					"dp4 " + _totalScatterColorReg+".z, " + _totalScatterColorReg + ", " + _decReg + "\n" +
			// currentDistanceToLight - closestDistanceToLight
					"sub " + _totalScatterColorReg+".w, " + projReg+".z, " + _totalScatterColorReg+".z\n" +

					"sub " + _totalScatterColorReg+".w, " + _invRegister+".x, " + _totalScatterColorReg+".w\n" +
					"mul " + _totalScatterColorReg+".w, " + _invRegister+".y, " + _totalScatterColorReg+".w\n" +
					"sat " + _totalScatterColorReg+".w, " + _totalScatterColorReg+".w\n" +

			// targetReg.x contains dot(lightDir, normal)
			// modulate according to incident light angle (scatter = scatter*(-.5*dot(light, normal) + .5)
					"neg " + targetReg+".y, " + targetReg+".x\n" +
					"mul " + targetReg+".y, " + targetReg+".y, " + _invRegister+".z\n" +
					"add " + targetReg+".y, " + targetReg+".y, " + _invRegister+".z\n" +
					"mul " + _totalScatterColorReg+".w, " + _totalScatterColorReg+".w, " + targetReg+".y\n" +

			// blend diffuse: d' = (1-s)*d + s*1
					"sub " + _totalScatterColorReg+".y, " + _colorReg+".w, " + _totalScatterColorReg+".w\n" +
					"mul " + targetReg+".w, " + targetReg+".w, " + _totalScatterColorReg+".y\n" +

					"mul " + _totalScatterColorReg+".xyz, " + _lightColorReg+".xyz, " + _totalScatterColorReg+".w\n" +
					"mul " + _totalScatterColorReg+".xyz, " + _totalScatterColorReg+".xyz, " + _colorReg+".xyz\n";

			return code;
		}
	}
}
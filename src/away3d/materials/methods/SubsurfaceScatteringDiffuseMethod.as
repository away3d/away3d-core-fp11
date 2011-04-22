package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.lights.LightBase;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.passes.SingleObjectDepthPass;
	import away3d.materials.utils.AGAL;
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
	public class SubsurfaceScatteringDiffuseMethod extends WrapDiffuseMethod
	{
		private var _depthPass : SingleObjectDepthPass;
		private var _depthMapRegs : Vector.<uint>;
		private var _lightProjVaryings : Vector.<ShaderRegisterElement>;
		private var _lightMatrixsConstsIndex : int;
		private var _commonProps : Vector.<Number>;
		private var _fragmentProps : Vector.<Number>;
		private var _toTexIndex : int;
		private var _invIndex : int;
		private var _toTexRegister : ShaderRegisterElement;
		private var _invRegister : ShaderRegisterElement;
		private var _scattering : Number;
		private var _translucency : Number = 1;
		private var _lightIndex : int;
		private var _totalScatterColorReg : ShaderRegisterElement;
		private var _lightColorReg : ShaderRegisterElement;
		private var _scatterColor : uint = 0xffffff;
		private var _scatterColorData : Vector.<Number>;
		private var _colorIndex : int;
		private var _colorReg : ShaderRegisterElement;
		private var _dec : Vector.<Number>;
		private var _decIndex : uint;
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
			_scatterColorData = Vector.<Number>([1.0, 1.0, 1.0, 1.0]);
			_dec = Vector.<Number>([1.0, 1/255.0, 1/65025.0, 1/16581375.0]);
			_fragmentProps = new Vector.<Number>(4, true);
			_fragmentProps[2] = .5;
			_fragmentProps[3] = -.1;
			scattering = 0.2;
			translucency = 1;
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
			_fragmentProps[0] = value;
		}

		/**
		 * The translucency of the object.
		 */
		public function get translucency() : Number
		{
			return translucency;
		}

		public function set translucency(value : Number) : void
		{
			_translucency = value;
			_fragmentProps[1] = value;
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
			_scatterColorData[0] = ((scatterColor >> 16) & 0xff) / 0xff;
			_scatterColorData[1] = ((scatterColor >> 8) & 0xff) / 0xff;
			_scatterColorData[2] = (scatterColor & 0xff) / 0xff;
			_scatterColorData[3] = 1;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function reset() : void
		{
			_lightMatrixsConstsIndex = -1;
			_depthMapRegs = new Vector.<uint>(_numLights, true);
			_toTexIndex = -1;
			_invIndex = -1;
			_lightIndex = 0;
			super.reset();
		}


		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode(regCache : ShaderRegisterCache) : String
		{
			var code : String = super.getVertexCode(regCache);
			var lightProjection : Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>(4, true);
			var temp : ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
			_lightProjVaryings = new Vector.<ShaderRegisterElement>(_numLights, true);

			_toTexRegister = regCache.getFreeVertexConstant();
			_toTexIndex = _toTexRegister.index;


			for (var i : int = 0; i < _numLights; ++i) {
				_lightProjVaryings[i] = regCache.getFreeVarying();
				lightProjection[0] = regCache.getFreeVertexConstant();
				lightProjection[1] = regCache.getFreeVertexConstant();
				lightProjection[2] = regCache.getFreeVertexConstant();
				lightProjection[3] = regCache.getFreeVertexConstant();
				if (_lightMatrixsConstsIndex < 0) _lightMatrixsConstsIndex = lightProjection[0].index;

				code += AGAL.m44(temp.toString(), "vt0", lightProjection[0].toString());
				code += AGAL.rcp(temp+".w", temp+".w");
				code += AGAL.mul(temp+".xyz", temp+".xyz", temp+".w");
				code += AGAL.mul(temp+".xy", temp+".xy", _toTexRegister+".xy");
				code += AGAL.add(temp+".xy", temp+".xy", _toTexRegister+".xx");
				code += AGAL.mov(_lightProjVaryings[i]+".xyz", temp+".xyz");
				code += AGAL.mov(_lightProjVaryings[i]+".w", "va0.w");
			}

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentAGALPreLightingCode(regCache : ShaderRegisterCache) : String
		{
			_totalScatterColorReg = regCache.getFreeFragmentVectorTemp();
			_colorReg = regCache.getFreeFragmentConstant();
			_colorIndex = _colorReg.index;
            _decReg = regCache.getFreeFragmentConstant();
            _decIndex = _decReg.index;
			regCache.addFragmentTempUsages(_totalScatterColorReg, 1);
			return super.getFragmentAGALPreLightingCode(regCache);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerLight(lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			_lightColorReg = lightColReg;
			return super.getFragmentCodePerLight(lightIndex, lightDirReg, lightColReg, regCache);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = super.getFragmentPostLightingCode(regCache, targetReg);
			code += AGAL.add(targetReg+".xyz", targetReg+".xyz", _totalScatterColorReg+".xyz");
//			code += AGAL.mov(targetReg+".xyz", _totalScatterColorReg+".xyz");
			regCache.removeFragmentTempUsage(_totalScatterColorReg);
			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(context : Context3D, contextIndex : uint) : void
		{
			context.setRenderToBackBuffer();
			super.activate(context, contextIndex);

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _toTexIndex, _commonProps, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _invIndex, _fragmentProps, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _colorIndex, _scatterColorData, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _decIndex, _dec, 1);
		}

		arcane override function setRenderState(renderable : IRenderable, context : Context3D, contextIndex : uint, camera : Camera3D, lights : Vector.<LightBase>) : void
		{
			var depthMaps : Vector.<Texture> = _depthPass.getDepthMaps(renderable, contextIndex);
			var projections : Vector.<Matrix3D> = _depthPass.getProjections(renderable);

			for (var i : int = 0; i < 1; ++i) {
				context.setTextureAt(_depthMapRegs[i], depthMaps[i]);
				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _lightMatrixsConstsIndex+i*4, projections[i], true);
			}
		}


		/**
		 * @inheritDoc
		 */
		arcane override function deactivate(context : Context3D) : void
		{
			super.deactivate(context);

			for (var i : int = 0; i < 1; ++i)
				context.setTextureAt(_depthMapRegs[i], null);
		}

		/**
		 * Generates the code for this method
		 */
		private function scatterLight(targetReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var depthReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var projReg : ShaderRegisterElement = _lightProjVaryings[_lightIndex];

			// only scatter first light
			if (_lightIndex > 0) return "";

			_depthMapRegs[_lightIndex] = depthReg.index;

			if (_invIndex == -1) {
				_invRegister = regCache.getFreeFragmentConstant();
				_invIndex = _invRegister.index;
			}

//			temp = regCache.getFreeFragmentVectorTemp();
			code += AGAL.sample(_totalScatterColorReg.toString(), projReg.toString(), "2d", depthReg.toString(), "bilinear", "clamp");
			// reencode RGBA
			code += AGAL.dp4(_totalScatterColorReg+".z", _totalScatterColorReg.toString(), _decReg.toString());
			// currentDistanceToLight - closestDistanceToLight
			code += AGAL.sub(_totalScatterColorReg+".w", projReg+".z", _totalScatterColorReg+".z");
//			code += AGAL.sat(temp+".w", temp+".w");
			code += AGAL.sub(_totalScatterColorReg+".w", _invRegister+".x", _totalScatterColorReg+".w");
			code += AGAL.mul(_totalScatterColorReg+".w", _invRegister+".y", _totalScatterColorReg+".w");
			code += AGAL.sat(_totalScatterColorReg+".w", _totalScatterColorReg+".w");

			// targetReg.x contains dot(lightDir, normal)
			// modulate according to incident light angle (scatter = scatter*(-.5*dot(light, normal) + .5)
			code += AGAL.neg(targetReg+".y", targetReg+".x");
			code += AGAL.mul(targetReg+".y", targetReg+".y", _invRegister+".z");
			code += AGAL.add(targetReg+".y", targetReg+".y", _invRegister+".z");
			code += AGAL.mul(_totalScatterColorReg+".w", _totalScatterColorReg+".w", targetReg+".y");

			// blend diffuse: d' = (1-s)*d + s*1
			code += AGAL.sub(_totalScatterColorReg+".y", _colorReg+".w", _totalScatterColorReg+".w");
			code += AGAL.mul(targetReg+".w", targetReg+".w", _totalScatterColorReg+".y");

			code += AGAL.mul(_totalScatterColorReg+".xyz", _lightColorReg+".xyz", _totalScatterColorReg+".w");
			code += AGAL.mul(_totalScatterColorReg+".xyz", _totalScatterColorReg+".xyz", _colorReg+".xyz");

			++_lightIndex;

			return code;
		}
	}
}
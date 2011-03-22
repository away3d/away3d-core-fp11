package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.lights.LightBase;
	import away3d.materials.utils.AGAL;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;

	use namespace arcane;

	/**
	 * BasicDiffuseMethod provides the default shading method for Lambert (dot3) diffuse lighting.
	 *
	 * todo: provide abstract DiffuseMethodBase and rename this to DefaultDiffuseMethod
	 */
	public class FilteredShadowMapMethod extends ShadingMethodBase
	{
		private var _castingLight : LightBase;
		private var _depthMapIndex : int;
		private var _depthMapVar : ShaderRegisterElement;
		private var _depthProjIndex : int;
		private var _offsetData : Vector.<Number> = Vector.<Number>([.5, -.5, 1.0, 1.0]);
		private var _toTexIndex : int;
		private var _data : Vector.<Number>;
		private var _decIndex : uint;
		private var _projMatrix : Matrix3D = new Matrix3D();
		private var _stepSize : Number;

		/**
		 * Creates a new BasicDiffuseMethod object.
		 *
		 * @param castingLight The light casting the shadow
		 */
		public function FilteredShadowMapMethod(castingLight : LightBase)
		{
			super(false, true, false);
			_stepSize = stepSize;
			castingLight.castsShadows = true;
			_castingLight = castingLight;
			_data = Vector.<Number>([1.0, 1/255.0, 1/65025.0, 1/160581375.0, -.003, .5, castingLight.shadowMapper.depthMapSize, 1/castingLight.shadowMapper.depthMapSize]);
		}

		public function get epsilon() : Number
		{
			return -_data[4];
		}

		public function set epsilon(value : Number) : void
		{
			_data[4] = -value;
		}

		public function get stepSize() : Number
		{
			return _stepSize;
		}

		public function set stepSize(value : Number) : void
		{
			_stepSize = value;
			_data[6] = _stepSize;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set numLights(value : int) : void
		{
			_needsNormals = value > 0;
			super.numLights = value;
		}

		arcane override function getVertexCode(regCache : ShaderRegisterCache) : String
		{
			var code : String = "";
			var toTexReg : ShaderRegisterElement = regCache.getFreeVertexConstant();
			var temp : ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
			var depthMapProj : ShaderRegisterElement = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			_depthProjIndex = depthMapProj.index;
			_depthMapVar = regCache.getFreeVarying();
			_toTexIndex = toTexReg.index;

			code += AGAL.m44(temp.toString(), "vt0", depthMapProj.toString());
			code += AGAL.rcp(temp+".w", temp+".w");
			code += AGAL.mul(temp+".xyz", temp+".xyz", temp+".w");
			code += AGAL.mul(temp+".xy", temp+".xy", toTexReg+".xy");
			code += AGAL.add(temp+".xy", temp+".xy", toTexReg+".xx");
			code += AGAL.mov(_depthMapVar+".xyz", temp+".xyz");
			code += AGAL.mov(_depthMapVar+".w", "va0.w");

			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg : ShaderRegisterElement;
			var code : String = "";
            _decIndex = decReg.index;

			regCache.addFragmentTempUsages(depthCol, 1);

			uvReg = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uvReg, 1);

			code += AGAL.mov(uvReg.toString(), _depthMapVar.toString());

			code += AGAL.sample(depthCol.toString(), _depthMapVar.toString(), "2d", depthMapRegister.toString(), "nearest", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.sub(depthCol+".z", depthCol+".z", dataReg+".x");	// offset by epsilon
			code += AGAL.lessThan(uvReg+".z", _depthMapVar+".z", depthCol+".z");   // 0 if in shadow

			code += AGAL.add(uvReg+".x", _depthMapVar+".x", dataReg+".w");	// (1, 0)
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), "nearest", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.sub(depthCol+".z", depthCol+".z", dataReg+".x");	// offset by epsilon
			code += AGAL.lessThan(uvReg+".w", _depthMapVar+".z", depthCol+".z");   // 0 if in shadow

			code += AGAL.div(depthCol+".x", _depthMapVar+".x", dataReg+".w");
			code += AGAL.fract(depthCol+".x", depthCol+".x");
			code += AGAL.sub(uvReg+".w", uvReg+".w", uvReg+".z");
			code += AGAL.mul(uvReg+".w", uvReg+".w", depthCol+".x");
			code += AGAL.add(targetReg+".w", uvReg+".z", uvReg+".w");

			code += AGAL.mov(uvReg+".x", _depthMapVar+".x");
			code += AGAL.add(uvReg+".y", _depthMapVar+".y", dataReg+".w");	// (0, 1)
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), "nearest", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.sub(depthCol+".z", depthCol+".z", dataReg+".x");	// offset by epsilon
			code += AGAL.lessThan(uvReg+".z", _depthMapVar+".z", depthCol+".z");   // 0 if in shadow

			code += AGAL.add(uvReg+".x", _depthMapVar+".x", dataReg+".w");	// (1, 1)
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), "nearest", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.sub(depthCol+".z", depthCol+".z", dataReg+".x");	// offset by epsilon
			code += AGAL.lessThan(uvReg+".w", _depthMapVar+".z", depthCol+".z");   // 0 if in shadow

			// recalculate fraction, since we ran out of registers :(
			code += AGAL.mul(depthCol+".x", _depthMapVar+".x", dataReg+".z");
			code += AGAL.fract(depthCol+".x", depthCol+".x");
			code += AGAL.sub(uvReg+".w", uvReg+".w", uvReg+".z");
			code += AGAL.mul(uvReg+".w", uvReg+".w", depthCol+".x");
			code += AGAL.add(uvReg+".w", uvReg+".z", uvReg+".w");

			code += AGAL.mul(depthCol+".x", _depthMapVar+".y", dataReg+".z");
			code += AGAL.fract(depthCol+".x", depthCol+".x");
			code += AGAL.sub(uvReg+".w", uvReg+".w", targetReg+".w");
			code += AGAL.mul(uvReg+".w", uvReg+".w", depthCol+".x");
			code += AGAL.add(targetReg+".w", targetReg+".w", uvReg+".w");

			regCache.removeFragmentTempUsage(depthCol);
			regCache.removeFragmentTempUsage(uvReg);

			_depthMapIndex = depthMapRegister.index;

			return code;
		}

		arcane override function setRenderState(renderable : IRenderable, context : Context3D, contextIndex : uint, camera : Camera3D, lights : Vector.<LightBase>) : void
		{
			_projMatrix.copyFrom(_castingLight.shadowMapper.depthProjection);
			_projMatrix.prepend(renderable.sceneTransform);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _depthProjIndex, _projMatrix, true);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(context : Context3D, contextIndex : uint) : void
		{
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _toTexIndex, _offsetData, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _decIndex, _data, 2);
			context.setTextureAt(_depthMapIndex, _castingLight.shadowMapper.getDepthMap(contextIndex));
		}

		arcane override function deactivate(context : Context3D) : void
		{
			context.setTextureAt(_depthMapIndex, null);
		}
	}
}

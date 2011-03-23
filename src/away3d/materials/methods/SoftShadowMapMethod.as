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

	public class SoftShadowMapMethod extends ShadingMethodBase
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
		 */
		public function SoftShadowMapMethod(castingLight : LightBase, stepSize : Number = .00025)
		{
			super(false, false, false);
			_stepSize = stepSize;
			castingLight.castsShadows = true;
			_castingLight = castingLight;
			_data = Vector.<Number>([1.0, 1/255.0, 1/65025.0, 1/160581375.0, -.003, 1/9, stepSize, 0]);
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
			code += AGAL.mov(uvReg.toString(), _depthMapVar.toString());

			code += AGAL.sample(depthCol.toString(), _depthMapVar.toString(), "2d", depthMapRegister.toString(), "bilinear", "clamp");
			code += AGAL.add(uvReg+".z", _depthMapVar+".z", dataReg+".x");    // offset by epsilon
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(targetReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow

			code += AGAL.sub(uvReg+".x", _depthMapVar+".x", dataReg+".z");	// (-1, 0)
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), "bilinear", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(targetReg+".w", targetReg+".w", uvReg+".w");

			code += AGAL.add(uvReg+".x", _depthMapVar+".x", dataReg+".z");		// (1, 0)
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), "bilinear", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(targetReg+".w", targetReg+".w", uvReg+".w");

			code += AGAL.mov(uvReg+".x", _depthMapVar+".x");
			code += AGAL.sub(uvReg+".y", _depthMapVar+".y", dataReg+".z");	// (0, -1)
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), "bilinear", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(targetReg+".w", targetReg+".w", uvReg+".w");

			code += AGAL.add(uvReg+".y", _depthMapVar+".y", dataReg+".z");	// (0, 1)
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), "bilinear", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(targetReg+".w", targetReg+".w", uvReg+".w");

			code += AGAL.sub(uvReg+".xy", _depthMapVar+".xy", dataReg+".zz"); // (0, -1)
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), "bilinear", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(targetReg+".w", targetReg+".w", uvReg+".w");

			code += AGAL.add(uvReg+".y", _depthMapVar+".y", dataReg+".z");	// (-1, 1)
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), "bilinear", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(targetReg+".w", targetReg+".w", uvReg+".w");

			code += AGAL.add(uvReg+".xy", _depthMapVar+".xy", dataReg+".zz");  // (1, 1)
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), "bilinear", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(targetReg+".w", targetReg+".w", uvReg+".w");

			code += AGAL.sub(uvReg+".y", _depthMapVar+".y", dataReg+".z");	// (1, -1)
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), "bilinear", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(targetReg+".w", targetReg+".w", uvReg+".w");

			regCache.removeFragmentTempUsage(depthCol);
			code += AGAL.mul(targetReg+".w", targetReg+".w", dataReg+".y");   // average

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

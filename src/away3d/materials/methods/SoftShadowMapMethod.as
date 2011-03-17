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
		private var _shadowColor : uint;
		private var _dither : Boolean;

		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function SoftShadowMapMethod(castingLight : LightBase, shadowColor : uint = 0x808080, dither : Boolean = true, stepSize : Number = .00025)
		{
			super(false, false, false);
			_stepSize = stepSize;
			castingLight.castsShadows = true;
			_castingLight = castingLight;
			_data = Vector.<Number>([1.0, 1/255.0, 1/65025.0, 1/160581375.0, -.003, 1/9, stepSize, 10000, 0, 0, 0, 1]);
			this.shadowColor = shadowColor;
			_needsUV = true;
			_dither = dither;
		}

		public function get dither() : Boolean
		{
			return _dither;
		}

		public function set dither(value : Boolean) : void
		{
			if (_dither == value) return;
			_dither = value;
			invalidateShaderProgram();
		}

		public function get shadowColor() : uint
		{
			return _shadowColor;
		}

		public function set shadowColor(value : uint) : void
		{
			_data[8] = ((value >> 16) & 0xff)/0xff;
			_data[9] = ((value >> 8) & 0xff)/0xff;
			_data[10] = (value & 0xff)/0xff;
			_shadowColor = value;
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
			code += AGAL.div(temp.toString(), temp.toString(), temp+".w");
			code += AGAL.mul(temp+".xy", temp+".xy", toTexReg+".xy");
			code += AGAL.add(temp+".xy", temp+".xy", toTexReg+".xx");
			code += AGAL.mov(_depthMapVar.toString(), temp.toString());

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
			var colReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg : ShaderRegisterElement;
			var code : String = "";
			var shadow : ShaderRegisterElement;
			var mode : String = "nearestNoMip";

            _decIndex = decReg.index;

			regCache.addFragmentTempUsages(depthCol, 1);

			uvReg = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uvReg, 1);
			shadow = regCache.getFreeFragmentVectorTemp();
			code += AGAL.mov(uvReg.toString(), _depthMapVar.toString());

			if (_dither) {
				// pseudorandom dither
				code += AGAL.mul(shadow+".xy", _uvFragmentReg+".xy", dataReg+".w");
				code += AGAL.cos(shadow+".xy", shadow+".xy");
				code += AGAL.mul(shadow+".xy", shadow+".xy", dataReg+".w");
				code += AGAL.fract(shadow+".xy", shadow+".xy");
				code += AGAL.sin(shadow+".xy", shadow+".xy");
				code += AGAL.mul(shadow+".xy", shadow+".xy", dataReg+".z");
			}

			if (_dither) {
				code += AGAL.add(uvReg+".xy", _depthMapVar+".xy", shadow+".xy");
				code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), mode, "clamp");
			}
			else
				code += AGAL.sample(depthCol.toString(), _depthMapVar.toString(), "2d", depthMapRegister.toString(), mode, "clamp");

			code += AGAL.add(uvReg+".z", _depthMapVar+".z", dataReg+".x");    // offset by epsilon
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(shadow+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow

			code += AGAL.sub(uvReg+".x", _depthMapVar+".x", dataReg+".z");	// (-1, 0)
			if (_dither) code += AGAL.add(uvReg+".x", uvReg+".x", shadow+".x");
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), mode, "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(shadow+".w", shadow+".w", uvReg+".w");

			code += AGAL.add(uvReg+".x", _depthMapVar+".x", dataReg+".z");		// (1, 0)
			if (_dither) code += AGAL.add(uvReg+".x", uvReg+".x", shadow+".x");
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), mode, "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(shadow+".w", shadow+".w", uvReg+".w");

			code += AGAL.mov(uvReg+".x", _depthMapVar+".x");
			code += AGAL.sub(uvReg+".y", _depthMapVar+".y", dataReg+".z");	// (0, -1)
			if (_dither) code += AGAL.add(uvReg+".xy", uvReg+".xy", shadow+".xy");
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), mode, "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(shadow+".w", shadow+".w", uvReg+".w");

			code += AGAL.add(uvReg+".y", _depthMapVar+".y", dataReg+".z");	// (0, 1)
			if (_dither) code += AGAL.add(uvReg+".y", uvReg+".y", shadow+".y");
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), mode, "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(shadow+".w", shadow+".w", uvReg+".w");

			code += AGAL.sub(uvReg+".xy", _depthMapVar+".xy", dataReg+".zz"); // (-1, -1)
			if (_dither) code += AGAL.add(uvReg+".xy", uvReg+".xy", shadow+".xy");
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), mode, "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(shadow+".w", shadow+".w", uvReg+".w");

			code += AGAL.add(uvReg+".y", _depthMapVar+".y", dataReg+".z");	// (-1, 1)
			if (_dither) code += AGAL.add(uvReg+".y", uvReg+".y", shadow+".y");
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), mode, "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(shadow+".w", shadow+".w", uvReg+".w");

			code += AGAL.add(uvReg+".xy", _depthMapVar+".xy", dataReg+".zz");  // (1, 1)
			if (_dither) code += AGAL.add(uvReg+".xy", uvReg+".xy", shadow+".xy");
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), mode, "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(shadow+".w", shadow+".w", uvReg+".w");

			code += AGAL.sub(uvReg+".y", _depthMapVar+".y", dataReg+".z");	// (1, -1)
			if (_dither) code += AGAL.add(uvReg+".y", uvReg+".y", shadow+".y");
			code += AGAL.sample(depthCol.toString(), uvReg.toString(), "2d", depthMapRegister.toString(), mode, "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.lessThan(uvReg+".w", uvReg+".z", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(shadow+".w", shadow+".w", uvReg+".w");

			code += AGAL.mul(shadow+".w", shadow+".w", dataReg+".y");   // average
			code += AGAL.add(depthCol+".xyz", colReg+".xyz", shadow+".www");
			code += AGAL.sat(depthCol+".xyz", depthCol+".xyz");
			code += AGAL.mul(targetReg+".xyz", targetReg+".xyz", depthCol+".xyz");

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
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _decIndex, _data, 3);
			context.setTextureAt(_depthMapIndex, _castingLight.shadowMapper.getDepthMap(contextIndex));
		}

		arcane override function deactivate(context : Context3D) : void
		{
			context.setTextureAt(_depthMapIndex, null);
		}
	}
}

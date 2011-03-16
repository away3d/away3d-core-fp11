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
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class HardShadowMapMethod extends ShadingMethodBase
	{
		private var _castingLight : LightBase;
		private var _depthMapIndex : int;
		private var _depthMapVar : ShaderRegisterElement;
		private var _depthProjIndex : int;
		private var _offsetData : Vector.<Number> = Vector.<Number>([.5, -.5, 1.0, 1.0]);
		private var _toTexIndex : int;
		private var _dec : Vector.<Number>;
		private var _decIndex : uint;
		private var _projMatrix : Matrix3D = new Matrix3D();
		private var _shadowColor : uint;

		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function HardShadowMapMethod(castingLight : LightBase, shadowColor : uint = 0x808080)
		{
			super(false, false, false);
			castingLight.castsShadows = true;
			_castingLight = castingLight;
			_dec = Vector.<Number>([1.0, 1/255.0, 1/65025.0, 1/160581375.0, -.003, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0]);
			this.shadowColor = shadowColor;
		}

		public function get shadowColor() : uint
		{
			return _shadowColor;
		}

		public function set shadowColor(value : uint) : void
		{
			_dec[8] = ((value >> 16) & 0xff)/0xff;
			_dec[9] = ((value >> 8) & 0xff)/0xff;
			_dec[10] = (value & 0xff)/0xff;
			_shadowColor = value;
		}

		public function get epsilon() : Number
		{
			return -_dec[4];
		}

		public function set epsilon(value : Number) : void
		{
			_dec[4] = -value;
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
			var epsReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var colReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : String = "";

			_decIndex = decReg.index;
			_depthMapIndex = depthMapRegister.index;

			code += AGAL.sample(depthCol.toString(), _depthMapVar.toString(), "2d", depthMapRegister.toString(), "nearestNoMip", "clamp");
			code += AGAL.dp4(depthCol+".z", depthCol.toString(), decReg.toString());
			code += AGAL.add(depthCol+".w", _depthMapVar+".z", epsReg+".x");    // offset by epsilon

			code += AGAL.lessThan(depthCol+".w", depthCol+".w", depthCol+".z");   // 0 if in shadow
			code += AGAL.add(depthCol+".xyz", colReg+".xyz", depthCol+".www");
			code += AGAL.sat(depthCol+".xyz", depthCol+".xyz");
			code += AGAL.mul(targetReg+".xyz", targetReg+".xyz", depthCol+".xyz");

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
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _decIndex, _dec, 3);
			context.setTextureAt(_depthMapIndex, _castingLight.shadowMapper.getDepthMap(contextIndex));
		}

		arcane override function deactivate(context : Context3D) : void
		{
			context.setTextureAt(_depthMapIndex, null);
		}
	}
}

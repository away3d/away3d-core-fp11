package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.DirectionalLight;
	import away3d.lights.PointLight;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.BitmapTexture;

	import flash.display.BitmapData;

	use namespace arcane;

	public class DitheredShadowMapMethod extends ShadowMapMethodBase
	{
		private static var _grainTexture : BitmapTexture;
		private static var _grainUsages : int;
		private static var _grainBitmapData : BitmapData;
		private var _grainMapIndex : int;
		private var _highRes : Boolean;
		private var _depthMapSize : int;
		private var _range : Number = 1;

		/**
		 * Creates a new DitheredShadowMapMethod object.
		 */
		public function DitheredShadowMapMethod(castingLight : DirectionalLight, highRes : Boolean = false)
		{
			// todo: implement for point lights
			super(castingLight);

			_data[5] = highRes? 1/8 : 1/4;
			// area to sample in texture space
			_depthMapSize = castingLight.shadowMapper.depthMapSize;
			_data[6] = _range/_depthMapSize;
			_data[7] = .5;

			_highRes = highRes;

			++_grainUsages;

			if (!_grainTexture) {
				initGrainTexture();
			}
		}

		public function get range() : Number
		{
			return _range;
		}

		public function set range(value : Number) : void
		{
			_range = value;
			_data[6] = _range/_depthMapSize;
		}

		private function initGrainTexture() : void
		{
			_grainBitmapData = new BitmapData(64, 64, false);
			var vec : Vector.<uint> = new Vector.<uint>();
			var len : uint = 4096;
			var step : Number = 1/(_depthMapSize*_range);
			var inv : Number = 1-step;
			var r : Number,  g : Number;

			for (var i : uint = 0; i < len; ++i) {
				r = 2*(Math.random() - .5)*inv;
				g = 2*(Math.random() - .5)*inv;
				if (r < 0) r -= step;
				else r += step;
				if (g < 0) g -= step;
				else g += step;

				vec[i] = (((r*.5 + .5)*0xff) << 16) | (((g*.5 + .5)*0xff) << 8);
			}

			_grainBitmapData.setVector(_grainBitmapData.rect, vec);
			_grainTexture = new BitmapTexture(_grainBitmapData);
		}

		override public function dispose() : void
		{
			if (--_grainUsages == 0) {
				_grainTexture.dispose();
				_grainBitmapData.dispose();
				_grainTexture = null;
			}
		}

		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			super.activate(stage3DProxy);
            stage3DProxy.setTextureAt(_grainMapIndex, _grainTexture.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		override protected function getPlanarFragmentCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var grainRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg : ShaderRegisterElement;
			var code : String = "";

            _decIndex = decReg.index;

			regCache.addFragmentTempUsages(depthCol, 1);

			uvReg = regCache.getFreeFragmentVectorTemp();

			code += // keep grain in uvReg.xy
					"div " + uvReg + ", " + _depthMapCoordReg + ", " + dataReg + ".z\n" +
					"tex " + uvReg + ", " + uvReg + ", " + grainRegister + " <2d,nearest,repeat,mipnone>\n" +
					"sub " + uvReg + ".xy, " + uvReg + ".xy, " + dataReg + ".ww\n" + 	// uv-.5
					"add " + uvReg + ".xy, " + uvReg + ".xy, " + uvReg + ".xy\n" +      // 2*(uv-.5)
					"mul " + uvReg + ".xy, " + uvReg + ".xy, " + dataReg + ".z\n" +

//					"tex " + depthCol + ", " + _depthMapCoordReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
//					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"add " + uvReg+".z, " + _depthMapCoordReg+".z, " + dataReg+".x\n" +     // offset by epsilon
//					"slt " + targetReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow

					"add " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + targetReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
					"sub " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +

					"neg " + uvReg+".xy, " + uvReg+".xy\n" +
					"add " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +
					"sub " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +

					"mov " + uvReg+".xy, " + uvReg+".yx\n" +
					"neg " + uvReg+".x, " + uvReg+".x\n" +

					"add " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +
					"sub " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +

					"neg " + uvReg+".xy, " + uvReg+".xy\n" +
					"add " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +
					"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
					"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
					"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
					"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";

			if (_highRes) {
					// reseed
				code +=	"div " + uvReg + ".xy, " + _depthMapCoordReg + ".xy, " + dataReg + ".z\n" +
						"tex " + uvReg + ", " + uvReg + ", " + grainRegister + " <2d,nearest,repeat,mipnone>\n" +
						"sub " + uvReg + ".xy, " + uvReg + ".xy, " + dataReg + ".ww\n" +
						"add " + uvReg + ".xy, " + uvReg + ".xy, " + uvReg + ".xy\n" +
						"mul " + uvReg + ".xy, " + uvReg + ".xy, " + dataReg + ".z\n" +
						"add " + uvReg+".z, " + _depthMapCoordReg+".z, " + dataReg+".x\n" +     // offset by epsilon

						"add " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +
						"sub " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +

						"neg " + uvReg+".xy, " + uvReg+".xy\n" +
						"add " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +
						"sub " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +

						"mov " + uvReg+".xy, " + uvReg+".yx\n" +
						"neg " + uvReg+".x, " + uvReg+".x\n" +

						"add " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n" +
						"sub " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +

						"neg " + uvReg+".xy, " + uvReg+".xy\n" +
						"add " + uvReg+".xy, " + uvReg+".xy, " + _depthMapCoordReg+".xy\n" +
						"tex " + depthCol + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
						"dp4 " + depthCol+".z, " + depthCol + ", " + decReg + "\n" +
						"slt " + uvReg+".w, " + uvReg+".z, " + depthCol+".z\n" +    // 0 if in shadow
						"add " + targetReg+".w, " + targetReg+".w, " + uvReg+".w\n";
			}

			regCache.removeFragmentTempUsage(depthCol);

			code += "mul " + targetReg+".w, " + targetReg+".w, " + dataReg+".y\n";  // average

			_depthMapIndex = depthMapRegister.index;
			_grainMapIndex = grainRegister.index;

			return code;
		}
	}
}
package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.DirectionalLight;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.BitmapTexture;
	
	import flash.display.BitmapData;
	
	use namespace arcane;
	
	/**
	 * DitheredShadowMapMethod provides a soft shadowing technique by randomly distributing sample points differently for each fragment.
	 */
	public class DitheredShadowMapMethod extends SimpleShadowMapMethodBase
	{
		private static var _grainTexture:BitmapTexture;
		private static var _grainUsages:int;
		private static var _grainBitmapData:BitmapData;
		private var _depthMapSize:int;
		private var _range:Number = 1;
		private var _numSamples:int;
		
		/**
		 * Creates a new DitheredShadowMapMethod object.
		 * @param castingLight The light casting the shadows
		 * @param numSamples The amount of samples to take for dithering. Minimum 1, maximum 24.
		 */
		public function DitheredShadowMapMethod(castingLight:DirectionalLight, numSamples:int = 4)
		{
			super(castingLight);
			
			_depthMapSize = _castingLight.shadowMapper.depthMapSize;
			
			this.numSamples = numSamples;
			
			++_grainUsages;
			
			if (!_grainTexture)
				initGrainTexture();
		}

		/**
		 * The amount of samples to take for dithering. Minimum 1, maximum 24. The actual maximum may depend on the
		 * complexity of the shader.
		 */
		public function get numSamples():int
		{
			return _numSamples;
		}
		
		public function set numSamples(value:int):void
		{
			_numSamples = value;
			if (_numSamples < 1)
				_numSamples = 1;
			else if (_numSamples > 24)
				_numSamples = 24;
			invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			super.initVO(vo);
			vo.needsProjection = true;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initConstants(vo:MethodVO):void
		{
			super.initConstants(vo);
			
			var fragmentData:Vector.<Number> = vo.fragmentData;
			var index:int = vo.fragmentConstantsIndex;
			fragmentData[index + 8] = 1/_numSamples;
		}

		/**
		 * The range in the shadow map in which to distribute the samples.
		 */
		public function get range():Number
		{
			return _range*2;
		}
		
		public function set range(value:Number):void
		{
			_range = value/2;
		}

		/**
		 * Creates a texture containing the dithering noise texture.
		 */
		private function initGrainTexture():void
		{
			_grainBitmapData = new BitmapData(64, 64, false);
			var vec:Vector.<uint> = new Vector.<uint>();
			var len:uint = 4096;
			var step:Number = 1/(_depthMapSize*_range);
			var r:Number, g:Number;
			
			for (var i:uint = 0; i < len; ++i) {
				r = 2*(Math.random() - .5);
				g = 2*(Math.random() - .5);
				if (r < 0)
					r -= step;
				else
					r += step;
				if (g < 0)
					g -= step;
				else
					g += step;
				if (r > 1)
					r = 1;
				else if (r < -1)
					r = -1;
				if (g > 1)
					g = 1;
				else if (g < -1)
					g = -1;
				vec[i] = (int((r*.5 + .5)*0xff) << 16) | (int((g*.5 + .5)*0xff) << 8);
			}
			
			_grainBitmapData.setVector(_grainBitmapData.rect, vec);
			_grainTexture = new BitmapTexture(_grainBitmapData);
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			if (--_grainUsages == 0) {
				_grainTexture.dispose();
				_grainBitmapData.dispose();
				_grainTexture = null;
			}
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			super.activate(vo, stage3DProxy);
			var data:Vector.<Number> = vo.fragmentData;
			var index:uint = vo.fragmentConstantsIndex;
			data[index + 9] = (stage3DProxy.width - 1)/63;
			data[index + 10] = (stage3DProxy.height - 1)/63;
			data[index + 11] = 2*_range/_depthMapSize;
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex + 1, _grainTexture.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		override protected function getPlanarFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var depthMapRegister:ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var customDataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();

			vo.fragmentConstantsIndex = decReg.index*4;
			vo.texturesIndex = depthMapRegister.index;

			return getSampleCode(regCache, customDataReg, depthMapRegister, decReg, targetReg);
		}

		/**
		 * Get the actual shader code for shadow mapping
		 * @param regCache The register cache managing the registers.
		 * @param depthMapRegister The texture register containing the depth map.
		 * @param decReg The register containing the depth map decoding data.
		 * @param targetReg The target register to add the shadow coverage.
		 */
		private function getSampleCode(regCache:ShaderRegisterCache, customDataReg:ShaderRegisterElement, depthMapRegister:ShaderRegisterElement, decReg:ShaderRegisterElement, targetReg:ShaderRegisterElement):String
		{
			var code:String = "";
			var grainRegister:ShaderRegisterElement = regCache.getFreeTextureReg();
			var uvReg:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var numSamples:int = _numSamples;
			regCache.addFragmentTempUsages(uvReg, 1);
			
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			
			var projectionReg:ShaderRegisterElement = _sharedRegisters.projectionFragment;
			
			code += "div " + uvReg + ", " + projectionReg + ", " + projectionReg + ".w\n" +
				"mul " + uvReg + ".xy, " + uvReg + ".xy, " + customDataReg + ".yz\n";
			
			while (numSamples > 0) {
				if (numSamples == _numSamples)
					code += "tex " + uvReg + ", " + uvReg + ", " + grainRegister + " <2d,nearest,repeat,mipnone>\n";
				else
					code += "tex " + uvReg + ", " + uvReg + ".zwxy, " + grainRegister + " <2d,nearest,repeat,mipnone>\n";
				
				// keep grain in uvReg.zw
				code += "sub " + uvReg + ".zw, " + uvReg + ".xy, fc0.xx\n" + // uv-.5
					"mul " + uvReg + ".zw, " + uvReg + ".zw, " + customDataReg + ".w\n"; // (tex unpack scale and tex scale in one)
				
				// first sample
				
				if (numSamples == _numSamples) {
					// first sample
					code += "add " + uvReg + ".xy, " + uvReg + ".zw, " + _depthMapCoordReg + ".xy\n" +
						"tex " + temp + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
						"dp4 " + temp + ".z, " + temp + ", " + decReg + "\n" +
						"slt " + targetReg + ".w, " + _depthMapCoordReg + ".z, " + temp + ".z\n"; // 0 if in shadow
				} else
					code += addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
				
				if (numSamples > 4) {
					code += "add " + uvReg + ".xy, " + uvReg + ".xy, " + uvReg + ".zw\n" +
						addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
				}
				
				if (numSamples > 1) {
					code += "sub " + uvReg + ".xy, " + _depthMapCoordReg + ".xy, " + uvReg + ".zw\n" +
						addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
				}
				
				if (numSamples > 5) {
					code += "sub " + uvReg + ".xy, " + uvReg + ".xy, " + uvReg + ".zw\n" +
						addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
				}
				
				if (numSamples > 2) {
					code += "neg " + uvReg + ".w, " + uvReg + ".w\n"; // will be rotated 90 degrees when being accessed as wz
					
					code += "add " + uvReg + ".xy, " + uvReg + ".wz, " + _depthMapCoordReg + ".xy\n" +
						addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
				}
				
				if (numSamples > 6) {
					code += "add " + uvReg + ".xy, " + uvReg + ".xy, " + uvReg + ".wz\n" +
						addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
				}
				
				if (numSamples > 3) {
					code += "sub " + uvReg + ".xy, " + _depthMapCoordReg + ".xy, " + uvReg + ".wz\n" +
						addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
				}
				
				if (numSamples > 7) {
					code += "sub " + uvReg + ".xy, " + uvReg + ".xy, " + uvReg + ".wz\n" +
						addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
				}
				
				numSamples -= 8;
			}
			
			regCache.removeFragmentTempUsage(uvReg);
			code += "mul " + targetReg + ".w, " + targetReg + ".w, " + customDataReg + ".x\n"; // average
			return code;
		}

		/**
		 * Adds the code for another tap to the shader code.
		 * @param uvReg The uv register for the tap.
		 * @param depthMapRegister The texture register containing the depth map.
		 * @param decReg The register containing the depth map decoding data.
		 * @param targetReg The target register to add the tap comparison result.
		 * @param regCache The register cache managing the registers.
		 * @return
		 */
		private function addSample(uvReg:ShaderRegisterElement, depthMapRegister:ShaderRegisterElement, decReg:ShaderRegisterElement, targetReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
		{
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			return "tex " + temp + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
				"dp4 " + temp + ".z, " + temp + ", " + decReg + "\n" +
				"slt " + temp + ".z, " + _depthMapCoordReg + ".z, " + temp + ".z\n" + // 0 if in shadow
				"add " + targetReg + ".w, " + targetReg + ".w, " + temp + ".z\n";
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activateForCascade(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			var data:Vector.<Number> = vo.fragmentData;
			var index:uint = vo.secondaryFragmentConstantsIndex;
			data[index] = 1/_numSamples;
			data[index + 1] = (stage3DProxy.width - 1)/63;
			data[index + 2] = (stage3DProxy.height - 1)/63;
			data[index + 3] = 2*_range/_depthMapSize;
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex + 1, _grainTexture.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getCascadeFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, decodeRegister:ShaderRegisterElement, depthTexture:ShaderRegisterElement, depthProjection:ShaderRegisterElement, targetRegister:ShaderRegisterElement):String
		{
			_depthMapCoordReg = depthProjection;
			
			var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			vo.secondaryFragmentConstantsIndex = dataReg.index*4;
			
			return getSampleCode(regCache, dataReg, depthTexture, decodeRegister, targetRegister);
		}
	}
}

package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.PlanarReflectionTexture;
	
	use namespace arcane;
	
	/**
	 * FresnelPlanarReflectionMethod provides a method to add fresnel-based planar reflections from a
	 * PlanarReflectionTexture object.to a surface, which get stronger as the viewing angle becomes more grazing. This
	 * method can be used for (near-)planar objects such as mirrors or water.
	 *
	 * @see away3d.textures.PlanarReflectionTexture
	 */
	public class FresnelPlanarReflectionMethod extends EffectMethodBase
	{
		private var _texture:PlanarReflectionTexture;
		private var _alpha:Number = 1;
		private var _normalDisplacement:Number = 0;
		private var _normalReflectance:Number = 0;
		private var _fresnelPower:Number = 5;

		/**
		 * Creates a new FresnelPlanarReflectionMethod object.
		 * @param texture The PlanarReflectionTexture containing a render of the mirrored scene.
		 * @param alpha The maximum reflectivity of the surface.
		 *
		 * @see away3d.textures.PlanarReflectionTexture
		 */
		public function FresnelPlanarReflectionMethod(texture:PlanarReflectionTexture, alpha:Number = 1)
		{
			super();
			_texture = texture;
			_alpha = alpha;
		}

		/**
		 * The reflectivity of the surface.
		 */
		public function get alpha():Number
		{
			return _alpha;
		}
		
		public function set alpha(value:Number):void
		{
			_alpha = value;
		}

		/**
		 * The power used in the Fresnel equation. Higher values make the fresnel effect more pronounced. Defaults to 5.
		 */
		public function get fresnelPower():Number
		{
			return _fresnelPower;
		}
		
		public function set fresnelPower(value:Number):void
		{
			_fresnelPower = value;
		}
		
		/**
		 * The minimum amount of reflectance, ie the reflectance when the view direction is normal to the surface or light direction.
		 */
		public function get normalReflectance():Number
		{
			return _normalReflectance;
		}
		
		public function set normalReflectance(value:Number):void
		{
			_normalReflectance = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			vo.needsProjection = true;
			vo.needsNormals = true;
			vo.needsView = true;
		}

		/**
		 * The PlanarReflectionTexture containing a render of the mirrored scene.
		 *
		 * @see away3d.textures.PlanarReflectionTexture
		 */
		public function get texture():PlanarReflectionTexture
		{
			return _texture;
		}
		
		public function set texture(value:PlanarReflectionTexture):void
		{
			_texture = value;
		}

		/**
		 * The amount of displacement caused by per-pixel normals.
		 */
		public function get normalDisplacement():Number
		{
			return _normalDisplacement;
		}
		
		public function set normalDisplacement(value:Number):void
		{
			if (_normalDisplacement == value)
				return;
			if (_normalDisplacement == 0 || value == 0)
				invalidateShaderProgram();
			_normalDisplacement = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			vo.fragmentData[vo.fragmentConstantsIndex] = _texture.textureRatioX*.5;
			vo.fragmentData[vo.fragmentConstantsIndex + 1] = _texture.textureRatioY*.5;
			vo.fragmentData[vo.fragmentConstantsIndex + 3] = _alpha;
			vo.fragmentData[vo.fragmentConstantsIndex + 4] = _normalReflectance;
			vo.fragmentData[vo.fragmentConstantsIndex + 5] = _fresnelPower;
			if (_normalDisplacement > 0) {
				vo.fragmentData[vo.fragmentConstantsIndex + 2] = _normalDisplacement;
				vo.fragmentData[vo.fragmentConstantsIndex + 6] = .5 + _texture.textureRatioX*.5 - 1/_texture.width;
				vo.fragmentData[vo.fragmentConstantsIndex + 7] = .5 - _texture.textureRatioX*.5 + 1/_texture.width;
			}
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var textureReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			
			var filter:String = vo.useSmoothTextures? "linear" : "nearest";
			var code:String;
			vo.texturesIndex = textureReg.index;
			vo.fragmentConstantsIndex = dataReg.index*4;
			// fc0.x = .5
			
			var projectionReg:ShaderRegisterElement = _sharedRegisters.projectionFragment;
			var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;
			var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;
			
			code = "div " + temp + ", " + projectionReg + ", " + projectionReg + ".w\n" +
				"mul " + temp + ", " + temp + ", " + dataReg + ".xyww\n" +
				"add " + temp + ".xy, " + temp + ".xy, fc0.xx\n";
			
			if (_normalDisplacement > 0) {
				code += "add " + temp + ".w, " + projectionReg + ".w, " + "fc0.w\n" +
					"sub " + temp + ".z, fc0.w, " + normalReg + ".y\n" +
					"div " + temp + ".z, " + temp + ".z, " + temp + ".w\n" +
					"mul " + temp + ".z, " + dataReg + ".z, " + temp + ".z\n" +
					"add " + temp + ".x, " + temp + ".x, " + temp + ".z\n" +
					"min " + temp + ".x, " + temp + ".x, " + dataReg2 + ".z\n" +
					"max " + temp + ".x, " + temp + ".x, " + dataReg2 + ".w\n";
			}
			
			code += "tex " + temp + ", " + temp + ", " + textureReg + " <2d," + filter + ">\n" +
				"sub " + viewDirReg + ".w, " + temp + ".w,  fc0.x\n" +
				"kil " + viewDirReg + ".w\n";
			
			// calculate fresnel term
			code += "dp3 " + viewDirReg + ".w, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" +   // dot(V, H)
				"sub " + viewDirReg + ".w, fc0.w, " + viewDirReg + ".w\n" +             // base = 1-dot(V, H)
				
				"pow " + viewDirReg + ".w, " + viewDirReg + ".w, " + dataReg2 + ".y\n" +             // exp = pow(base, 5)
				
				"sub " + normalReg + ".w, fc0.w, " + viewDirReg + ".w\n" +             // 1 - exp
				"mul " + normalReg + ".w, " + dataReg2 + ".x, " + normalReg + ".w\n" +             // f0*(1 - exp)
				"add " + viewDirReg + ".w, " + viewDirReg + ".w, " + normalReg + ".w\n" +          // exp + f0*(1 - exp)
				
				// total alpha
				"mul " + viewDirReg + ".w, " + dataReg + ".w, " + viewDirReg + ".w\n" +
				
				"sub " + temp + ", " + temp + ", " + targetReg + "\n" +
				"mul " + temp + ", " + temp + ", " + viewDirReg + ".w\n" +
				
				"add " + targetReg + ", " + targetReg + ", " + temp + "\n";
			
			return code;
		}
	}
}

package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;
	
	/**
	 * BasicAmbientMethod provides the default shading method for uniform ambient lighting.
	 */
	public class BasicAmbientMethod extends ShadingMethodBase
	{
		protected var _useTexture:Boolean;
		private var _texture:Texture2DBase;
		
		protected var _ambientInputRegister:ShaderRegisterElement;
		
		private var _ambientColor:uint = 0xffffff;
		private var _ambientR:Number = 0, _ambientG:Number = 0, _ambientB:Number = 0;
		private var _ambient:Number = 1;
		arcane var _lightAmbientR:Number = 0;
		arcane var _lightAmbientG:Number = 0;
		arcane var _lightAmbientB:Number = 0;
		
		/**
		 * Creates a new BasicAmbientMethod object.
		 */
		public function BasicAmbientMethod()
		{
			super();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			vo.needsUV = _useTexture;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initConstants(vo:MethodVO):void
		{
			vo.fragmentData[vo.fragmentConstantsIndex + 3] = 1;
		}
		
		/**
		 * The strength of the ambient reflection of the surface.
		 */
		public function get ambient():Number
		{
			return _ambient;
		}
		
		public function set ambient(value:Number):void
		{
			_ambient = value;
		}
		
		/**
		 * The colour of the ambient reflection of the surface.
		 */
		public function get ambientColor():uint
		{
			return _ambientColor;
		}
		
		public function set ambientColor(value:uint):void
		{
			_ambientColor = value;
		}
		
		/**
		 * The bitmapData to use to define the diffuse reflection color per texel.
		 */
		public function get texture():Texture2DBase
		{
			return _texture;
		}
		
		public function set texture(value:Texture2DBase):void
		{
			if (Boolean(value) != _useTexture ||
				(value && _texture && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format))) {
				invalidateShaderProgram();
			}
			_useTexture = Boolean(value);
			_texture = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function copyFrom(method:ShadingMethodBase):void
		{
			var diff:BasicAmbientMethod = BasicAmbientMethod(method);
			ambient = diff.ambient;
			ambientColor = diff.ambientColor;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData():void
		{
			super.cleanCompilationData();
			_ambientInputRegister = null;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String = "";
			
			if (_useTexture) {
				_ambientInputRegister = regCache.getFreeTextureReg();
				vo.texturesIndex = _ambientInputRegister.index;
				code += getTex2DSampleCode(vo, targetReg, _ambientInputRegister, _texture) +
					// apparently, still needs to un-premultiply :s
					"div " + targetReg + ".xyz, " + targetReg + ".xyz, " + targetReg + ".w\n";
			} else {
				_ambientInputRegister = regCache.getFreeFragmentConstant();
				vo.fragmentConstantsIndex = _ambientInputRegister.index*4;
				code += "mov " + targetReg + ", " + _ambientInputRegister + "\n";
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			if (_useTexture)
				stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		}
		
		/**
		 * Updates the ambient color data used by the render state.
		 */
		private function updateAmbient():void
		{
			_ambientR = ((_ambientColor >> 16) & 0xff)/0xff*_ambient*_lightAmbientR;
			_ambientG = ((_ambientColor >> 8) & 0xff)/0xff*_ambient*_lightAmbientG;
			_ambientB = (_ambientColor & 0xff)/0xff*_ambient*_lightAmbientB;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			updateAmbient();
			
			if (!_useTexture) {
				var index:int = vo.fragmentConstantsIndex;
				var data:Vector.<Number> = vo.fragmentData;
				data[index] = _ambientR;
				data[index + 1] = _ambientG;
				data[index + 2] = _ambientB;
			}
		}
	}
}

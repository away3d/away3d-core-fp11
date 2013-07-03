package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;

	/**
	 * SimpleWaterNormalMethod provides a basic normal map method to create water ripples by translating two wave normal maps.
	 */
	public class SimpleWaterNormalMethod extends BasicNormalMethod
	{
		private var _texture2:Texture2DBase;
		private var _normalTextureRegister2:ShaderRegisterElement;
		private var _useSecondNormalMap:Boolean;
		private var _water1OffsetX:Number = 0;
		private var _water1OffsetY:Number = 0;
		private var _water2OffsetX:Number = 0;
		private var _water2OffsetY:Number = 0;

		/**
		 * Creates a new SimpleWaterNormalMethod object.
		 * @param waveMap1 A normal map containing one layer of a wave structure.
		 * @param waveMap2 A normal map containing a second layer of a wave structure.
		 */
		public function SimpleWaterNormalMethod(waveMap1:Texture2DBase, waveMap2:Texture2DBase)
		{
			super();
			normalMap = waveMap1;
			secondaryNormalMap = waveMap2;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initConstants(vo:MethodVO):void
		{
			var index:int = vo.fragmentConstantsIndex;
			vo.fragmentData[index] = .5;
			vo.fragmentData[index + 1] = 0;
			vo.fragmentData[index + 2] = 0;
			vo.fragmentData[index + 3] = 1;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			super.initVO(vo);
			
			_useSecondNormalMap = normalMap != secondaryNormalMap;
		}

		/**
		 * The translation of the first wave layer along the X-axis.
		 */
		public function get water1OffsetX():Number
		{
			return _water1OffsetX;
		}
		
		public function set water1OffsetX(value:Number):void
		{
			_water1OffsetX = value;
		}

		/**
		 * The translation of the first wave layer along the Y-axis.
		 */
		public function get water1OffsetY():Number
		{
			return _water1OffsetY;
		}
		
		public function set water1OffsetY(value:Number):void
		{
			_water1OffsetY = value;
		}

		/**
		 * The translation of the second wave layer along the X-axis.
		 */
		public function get water2OffsetX():Number
		{
			return _water2OffsetX;
		}
		
		public function set water2OffsetX(value:Number):void
		{
			_water2OffsetX = value;
		}

		/**
		 * The translation of the second wave layer along the Y-axis.
		 */
		public function get water2OffsetY():Number
		{
			return _water2OffsetY;
		}
		
		public function set water2OffsetY(value:Number):void
		{
			_water2OffsetY = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function set normalMap(value:Texture2DBase):void
		{
			if (!value)
				return;
			super.normalMap = value;
		}

		/**
		 * A second normal map that will be combined with the first to create a wave-like animation pattern.
		 */
		public function get secondaryNormalMap():Texture2DBase
		{
			return _texture2;
		}
		
		public function set secondaryNormalMap(value:Texture2DBase):void
		{
			_texture2 = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData():void
		{
			super.cleanCompilationData();
			_normalTextureRegister2 = null;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			_texture2 = null;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			super.activate(vo, stage3DProxy);
			
			var data:Vector.<Number> = vo.fragmentData;
			var index:int = vo.fragmentConstantsIndex;
			
			data[index + 4] = _water1OffsetX;
			data[index + 5] = _water1OffsetY;
			data[index + 6] = _water2OffsetX;
			data[index + 7] = _water2OffsetY;
			
			if (_useSecondNormalMap >= 0)
				stage3DProxy._context3D.setTextureAt(vo.texturesIndex + 1, _texture2.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			_normalTextureRegister = regCache.getFreeTextureReg();
			_normalTextureRegister2 = _useSecondNormalMap? regCache.getFreeTextureReg() : _normalTextureRegister;
			vo.texturesIndex = _normalTextureRegister.index;
			
			vo.fragmentConstantsIndex = dataReg.index*4;
			return "add " + temp + ", " + _sharedRegisters.uvVarying + ", " + dataReg2 + ".xyxy\n" +
				getTex2DSampleCode(vo, targetReg, _normalTextureRegister, normalMap, temp) +
				"add " + temp + ", " + _sharedRegisters.uvVarying + ", " + dataReg2 + ".zwzw\n" +
				getTex2DSampleCode(vo, temp, _normalTextureRegister2, _texture2, temp) +
				"add " + targetReg + ", " + targetReg + ", " + temp + "		\n" +
				"mul " + targetReg + ", " + targetReg + ", " + dataReg + ".x	\n" +
				"sub " + targetReg + ".xyz, " + targetReg + ".xyz, " + _sharedRegisters.commons + ".xxx	\n" +
				"nrm " + targetReg + ".xyz, " + targetReg + ".xyz							\n";
		
		}
	}
}

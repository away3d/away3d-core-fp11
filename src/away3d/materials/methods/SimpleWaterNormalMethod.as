package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class SimpleWaterNormalMethod extends BasicNormalMethod
	{
		private var _texture2 : Texture2DBase;
		private var _normalTextureRegister2 : ShaderRegisterElement;
		private var _useSecondNormalMap : Boolean;
		private var _water1OffsetX : Number = 0;
		private var _water1OffsetY : Number = 0;
		private var _water2OffsetX : Number = 0;
		private var _water2OffsetY : Number = 0;

		public function SimpleWaterNormalMethod(waveMap1 : Texture2DBase, waveMap2 : Texture2DBase)
		{
			super();
			normalMap = waveMap1;
			secondaryNormalMap = waveMap2;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var index : int = vo.fragmentConstantsIndex;
			vo.fragmentData[index] = .5;
			vo.fragmentData[index+1] = 0;
			vo.fragmentData[index+2] = 0;
			vo.fragmentData[index+3] = 1;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			super.initVO(vo);
			if (normalMap == secondaryNormalMap)
				_useSecondNormalMap = false;
		}

		public function get water1OffsetX() : Number
		{
			return _water1OffsetX;
		}

		public function set water1OffsetX(value : Number) : void
		{
			_water1OffsetX = value;
		}

		public function get water1OffsetY() : Number
		{
			return _water1OffsetY;
		}

		public function set water1OffsetY(value : Number) : void
		{
			_water1OffsetY = value;
		}

		public function get water2OffsetX() : Number
		{
			return _water2OffsetX;
		}

		public function set water2OffsetX(value : Number) : void
		{
			_water2OffsetX = value;
		}

		public function get water2OffsetY() : Number
		{
			return _water2OffsetY;
		}

		public function set water2OffsetY(value : Number) : void
		{
			_water2OffsetY = value;
		}

		override public function set normalMap(value : Texture2DBase) : void
		{
			if (!value) return;
			super.normalMap = value;
		}

		public function get secondaryNormalMap() : Texture2DBase
		{
			return _texture2;
		}

		public function set secondaryNormalMap(value : Texture2DBase) : void
		{
			_texture2 = value;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_normalTextureRegister2 = null;
		}

		override public function dispose() : void
		{
			super.dispose();
			_texture2 = null;
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);

			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;

			data[index+4] = _water1OffsetX;
			data[index+5] = _water1OffsetY;
			data[index+6] = _water2OffsetX;
			data[index+7] = _water2OffsetY;

			if (_useSecondNormalMap >= 0) {
				stage3DProxy.setTextureAt(vo.texturesIndex+1, _texture2.getTextureForStage3D(stage3DProxy));
			}
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg2 : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			_normalTextureRegister = regCache.getFreeTextureReg();
			_normalTextureRegister2 = _useSecondNormalMap? regCache.getFreeTextureReg() : _normalTextureRegister;
			vo.texturesIndex = _normalTextureRegister.index;

			vo.fragmentConstantsIndex = dataReg.index*4;
			return	 "add " + temp + ", " + _uvFragmentReg + ", " + dataReg2 + ".xyxy\n" +
					getTexSampleCode(vo, targetReg, _normalTextureRegister, temp) +
					"add " + temp + ", " + _uvFragmentReg + ", " + dataReg2 + ".zwzw\n" +
					getTexSampleCode(vo, temp, _normalTextureRegister2, temp) +
					"add " + targetReg + ", " + targetReg + ", " + temp + "		\n" +
					"mul " + targetReg + ", " + targetReg + ", " + dataReg + ".x	\n";
		}
	}
}

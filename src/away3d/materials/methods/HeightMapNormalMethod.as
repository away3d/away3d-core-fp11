package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class HeightMapNormalMethod extends BasicNormalMethod
	{
		private var _dataRegIndex : int;
		private var _data : Vector.<Number>;

		public function HeightMapNormalMethod(heightMap : Texture2DBase, worldWidth : Number, worldHeight : Number, worldDepth : Number)
		{
			super();
			normalMap = heightMap;
			_data = new Vector.<Number>(8, true);
			_data[0] = 1/heightMap.width;
			_data[1] = 1/heightMap.height;
			_data[2] = 0;
			_data[3] = 1;
			_data[4] = worldWidth/worldHeight;
			_data[5] = worldDepth/worldHeight;
		}


		override arcane function get tangentSpace() : Boolean
		{
			return false;
		}

		override arcane function activate(stage3DProxy : Stage3DProxy) : void
		{
			super.activate(stage3DProxy);
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _dataRegIndex, _data, 2);
		}

		override public function copyFrom(method : ShadingMethodBase) : void
		{
		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg2 : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			_normalTextureRegister = regCache.getFreeTextureReg();
			_normalMapIndex = _normalTextureRegister.index;

			_dataRegIndex = dataReg.index;
			return	getTexSampleCode(targetReg, _normalTextureRegister, _uvFragmentReg, "clamp") +

					"add " + temp + ", " + _uvFragmentReg + ", " + dataReg + ".xzzz\n" +
					getTexSampleCode(temp, _normalTextureRegister, temp, "clamp") +
					"sub " + targetReg + ".x, " + targetReg + ".x, " + temp + ".x\n" +

					"add " + temp + ", " + _uvFragmentReg + ", " + dataReg + ".zyzz\n" +
					getTexSampleCode(temp, _normalTextureRegister, temp, "clamp") +
					"sub " + targetReg + ".z, " + targetReg + ".z, " + temp + ".x\n" +

					"mov " + targetReg + ".y, " + dataReg + ".w\n" +
					"mul " + targetReg + ".xz, " + targetReg + ".xz, " + dataReg2 + ".xy\n" +
					"nrm " + targetReg + ".xyz, " + targetReg + ".xyz\n";
		}
	}
}

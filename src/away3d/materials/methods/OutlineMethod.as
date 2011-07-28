package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class OutlineMethod extends ShadingMethodBase
	{
		private var _outlineColor : uint = 0x000000;

		public function OutlineMethod(fogDistance : Number, fogColor : uint = 0x808080)
		{
			super(false, true, false);
		}

		arcane override function reset() : void
		{
			super.reset();
		}

		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
		}

		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			return "";
		}
	}
}

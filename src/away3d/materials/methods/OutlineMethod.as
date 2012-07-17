package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.passes.OutlinePass;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	public class OutlineMethod extends ShadingMethodBase
	{
		private var _outlinePass : OutlinePass;

		public function OutlineMethod(outlineColor : uint = 0x000000,  outlineSize : Number = 1, showInnerLines : Boolean = true, dedicatedMeshes : Boolean = false)
		{
			super(true, false, false);
			_passes = new Vector.<MaterialPassBase>();
			_outlinePass = new OutlinePass(outlineColor, outlineSize, showInnerLines, dedicatedMeshes);
			_passes.push(_outlinePass);
		}

		public function get showInnerLines() : Boolean
		{
			return _outlinePass.showInnerLines;
		}

		public function set showInnerLines(value : Boolean) : void
		{
			_outlinePass.showInnerLines = value;
		}

		public function get outlineColor() : uint
		{
			return _outlinePass.outlineColor;
		}

		public function set outlineColor(value : uint) : void
		{
			_outlinePass.outlineColor = value;
		}

		public function get outlineSize() : Number
		{
			return _outlinePass.outlineSize;
		}

		public function set outlineSize(value : Number) : void
		{
			_outlinePass.outlineSize = value;
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
			// TODO: not used
			regCache = regCache;
			targetReg = targetReg;			
			return "";
		}
	}
}

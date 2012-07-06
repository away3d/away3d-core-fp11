package away3d.animators
{
	import away3d.library.assets.AssetType;
	import away3d.library.assets.NamedAssetBase;
	import away3d.library.assets.IAsset;
	import away3d.arcane;
	
	use namespace arcane;
	
	/**
	 * @author robbateman
	 */
	public class AnimationLibraryBase extends NamedAssetBase implements IAsset
	{
		arcane var _usesCPU:Boolean;
		
		/**
		 * Retrieves a temporary register that's still free.
		 * @param exclude An array of non-free temporary registers
		 * @param excludeAnother An additional register that's not free
		 * @return A temporary register that can be used
		 */
		protected function findTempReg(exclude : Array, excludeAnother : String = null) : String
		{
			var i : uint;
			var reg : String;

			while (true) {
				reg = "vt" + i;
				if (exclude.indexOf(reg) == -1 && excludeAnother != reg) return reg;
				++i;
			}

			// can't be reached
			return null;
		}
				
		public function get usesCPU() : Boolean
		{
			return _usesCPU;
		}
		
		public function resetGPUCompatibility() : void
        {
            _usesCPU = false;
        }
		
		public function get assetType() : String
		{
			return AssetType.ANIMATION_LIBRARY;
		}
		
		/**
		 * Cleans up any resources used by the current object.
		 */
		public function dispose() : void
		{
		}
	}
}

package away3d.library.strategies
{
	import away3d.errors.AbstractMethodError;
	import away3d.library.assets.IAsset;

	public class NamingStrategyBase
	{
		// Helper constants used by concrete naming strategies
		protected static const PERFORMED_RENAME : Boolean = true;
		protected static const NAMES_UNTOUCHED : Boolean = false;
		
		public static const PREFER_OLD : String = 'preferOld';
		public static const PREFER_NEW : String = 'preferNew';
		
		public function NamingStrategyBase()
		{
		}
		
		
		public function handleRename(changedAsset : IAsset, oldAsset : IAsset, assetsDictionary : Object, preference : String) : Boolean
		{
			throw new AbstractMethodError();
		}
	}
}
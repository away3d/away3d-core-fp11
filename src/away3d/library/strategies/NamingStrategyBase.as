package away3d.library.strategies
{
	import away3d.errors.AbstractMethodError;
	import away3d.library.assets.IAsset;

	public class NamingStrategyBase
	{
		public static const PREFER_OLD : String = 'preferOld';
		public static const PREFER_NEW : String = 'preferNew';
		
		public function NamingStrategyBase()
		{
		}
		
		
		public function resolveConflict(changedAsset : IAsset, oldAsset : IAsset, assetsDictionary : Object, preference : String) : void
		{
			throw new AbstractMethodError();
		}
		
		
		protected function updateNames(ns : String, nonConflictingName : String, oldAsset : IAsset, newAsset : IAsset, assetsDictionary : Object, preference : String) : void
		{
			var winner : IAsset, loser : IAsset;
			
			winner = (preference==PREFER_NEW)? newAsset : oldAsset;
			loser =  (preference==PREFER_NEW)? oldAsset : newAsset;
			
			assetsDictionary[winner.name] = winner
			assetsDictionary[nonConflictingName] = loser;
			loser.resetAssetPath(nonConflictingName, ns, false);
		}
	}
}
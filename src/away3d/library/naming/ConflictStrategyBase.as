package away3d.library.naming
{
	import away3d.errors.AbstractMethodError;
	import away3d.library.assets.IAsset;

	public class ConflictStrategyBase
	{
		
		public function ConflictStrategyBase()
		{
		}
		
		
		public function resolveConflict(changedAsset : IAsset, oldAsset : IAsset, assetsDictionary : Object, preference : String) : void
		{
			throw new AbstractMethodError();
		}
		
		
		public function create() : ConflictStrategyBase
		{
			throw new AbstractMethodError();
		}
		
		
		protected function updateNames(ns : String, nonConflictingName : String, oldAsset : IAsset, newAsset : IAsset, assetsDictionary : Object, preference : String) : void
		{
			var winner : IAsset, loser : IAsset;
			
			winner = (preference==ConflictPrecedence.FAVOR_NEW)? newAsset : oldAsset;
			loser =  (preference==ConflictPrecedence.FAVOR_NEW)? oldAsset : newAsset;
			
			assetsDictionary[winner.name] = winner
			assetsDictionary[nonConflictingName] = loser;
			loser.resetAssetPath(nonConflictingName, ns, false);
		}
	}
}
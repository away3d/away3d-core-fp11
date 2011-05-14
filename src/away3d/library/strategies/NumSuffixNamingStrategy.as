package away3d.library.strategies
{
	import away3d.arcane;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;

	use namespace arcane;
	
	public class NumSuffixNamingStrategy extends NamingStrategyBase
	{
		public function NumSuffixNamingStrategy()
		{
			super();
		}
		
		
		public override function handleRename(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:Object, preference:String) : Boolean
		{
			if (!oldAsset)
				return NAMES_UNTOUCHED;
			
			/*
			NamedAssetBase(oldAsset).resetAssetPath(oldAsset.name+'-old', oldAsset.assetNamespace, false);
			assetsDictionary[changedAsset.assetNamespace][changedAsset.name] = changedAsset;
			assetsDictionary[oldAsset.assetNamespace][oldAsset.name] = oldAsset;
			
			trace('RENAME COLLISION HANDLED!');
			trace('old:', oldAsset.assetFullPath);
			trace('new:', changedAsset.assetFullPath);
			*/
			
			return NAMES_UNTOUCHED;
		}
	}
}
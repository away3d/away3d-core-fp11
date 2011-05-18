package away3d.library.strategies
{
	import away3d.library.assets.IAsset;

	public class ErrorNamingStrategy extends NamingStrategyBase
	{
		public function ErrorNamingStrategy()
		{
			super();
		}
		
		public override function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:Object, preference:String):void
		{
			throw new Error('Asset name collision while AssetLibrary.namingStrategy set to AssetLibrary.THROW_ERROR. Asset path: ' + changedAsset.assetFullPath);
		}
		
		
		public override function create():NamingStrategyBase
		{
			return new ErrorNamingStrategy();
		}
	}
}
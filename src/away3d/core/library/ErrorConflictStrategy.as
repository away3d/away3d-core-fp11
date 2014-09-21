package away3d.core.library
{
	public class ErrorConflictStrategy extends ConflictStrategyBase
	{
		public function ErrorConflictStrategy()
		{
			super();
		}

		public override function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:Object, precedence:String):void
		{
			throw new Error('Asset name collision while AssetLibrary.namingStrategy set to AssetLibrary.THROW_ERROR. Asset path: ' + changedAsset.assetFullPath);
		}

		public override function create():ConflictStrategyBase
		{
			return new ErrorConflictStrategy();
		}
	}
}

package away3d.library.naming
{
	import away3d.library.assets.IAsset;

	public class IgnoreConflictStrategy extends ConflictStrategyBase
	{
		public function IgnoreConflictStrategy()
		{
			super();
		}
		
		
		public override function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:Object, precedence:String):void
		{
			// Do nothing, ignore the fact that there is a conflict.
			return;
		}
		
		
		public override function create():ConflictStrategyBase
		{
			return new IgnoreConflictStrategy();
		}
	}
}
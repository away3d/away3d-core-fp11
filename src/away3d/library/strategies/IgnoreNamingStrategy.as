package away3d.library.strategies
{
	import away3d.library.assets.IAsset;

	public class IgnoreNamingStrategy extends NamingStrategyBase
	{
		public function IgnoreNamingStrategy()
		{
			super();
		}
		
		
		public override function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:Object, preference:String):void
		{
			// Do nothing, ignore the fact that there is a conflict.
			return;
		}
		
		
		public override function create():NamingStrategyBase
		{
			return new IgnoreNamingStrategy();
		}
	}
}
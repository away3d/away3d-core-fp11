package away3d.animators.nodes
{
	import away3d.library.assets.AssetType;
	import away3d.library.assets.NamedAssetBase;
	import away3d.library.assets.IAsset;
	import away3d.animators.nodes.IAnimationNode;

	/**
	 * @author robbateman
	 */
	public class AnimationNodeBase extends NamedAssetBase implements IAsset
	{
		/**
		 * Cleans up any resources used by the current object.
		 */
		public function dispose() : void
		{
		}
		
		public function get assetType() : String
		{
			return AssetType.ANIMATION_NODE;
		}
	}
}

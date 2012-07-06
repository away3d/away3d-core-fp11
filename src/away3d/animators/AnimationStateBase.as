package away3d.animators
{
	import away3d.animators.nodes.IAnimationNode;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.NamedAssetBase;
	import away3d.library.assets.IAsset;

	/**
	 * @author robbateman
	 */
	public class AnimationStateBase extends NamedAssetBase implements IAsset
	{
		private var _rootNode:IAnimationNode;
		private var _owner:IAnimationLibrary;
		private var _stateName:String;
		
		public function get rootNode():IAnimationNode
		{	
			return _rootNode;
		}
		
		public function get stateName():String
		{
			return _stateName;
		}
		
		public function AnimationStateBase(rootNode:IAnimationNode)
		{
			_rootNode = rootNode;
		}
		
		public function dispose():void
		{
		}

		public function get assetType():String
		{
			return AssetType.ANIMATION_STATE;
		}
		
		public function addOwner(owner:IAnimationLibrary, stateName:String):void
		{
			_owner = owner;
			_stateName = stateName;
		}
	}
}

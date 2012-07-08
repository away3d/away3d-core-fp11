package away3d.animators.nodes
{
	import away3d.errors.AbstractMethodError;
	import flash.geom.Vector3D;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.NamedAssetBase;
	import away3d.library.assets.IAsset;

	/**
	 * @author robbateman
	 */
	public class AnimationNodeBase extends NamedAssetBase implements IAsset
	{
		protected var _time:Number;
		protected var _rootDelta : Vector3D = new Vector3D();
		protected var _rootDeltaDirty : Boolean;
		protected var _looping:Boolean = true;
		

		
		public function get looping():Boolean
		{	
			return _looping;
		}
		
		public function set looping(value:Boolean):void
		{	
			if (_looping == value)
				return;
			
			_looping = value;
			
			updateTime(_time);
		}
				
		public function get rootDelta() : Vector3D
		{
			if (_rootDeltaDirty)
				updateRootDelta();
			
			return _rootDelta;
		}
		
		public function AnimationNodeBase()
		{
		}
		
		public function update(time:Number):void
		{
			if (_time == time)
				return;
			
			updateTime(time);
		}
		
		public function dispose():void
		{
		}
		
		public function get assetType() : String
		{
			return AssetType.ANIMATION_NODE;
		}

		/**
		 * Updates the node's root delta position
		 */
		protected function updateRootDelta() : void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Updates the node's root delta position
		 */
		protected function updateTime(time:Number) : void
		{
			_time = time;
			
			_rootDeltaDirty = true;
		}
	}
}

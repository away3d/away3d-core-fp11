package away3d.animators.nodes
{
	import away3d.library.assets.*;
	import away3d.errors.*;
	
	import flash.geom.*;
	
	/**
	 * Provides an abstract base class for nodes in an animation blend tree.
	 */
	public class AnimationNodeBase extends NamedAssetBase implements IAsset
	{
		private var _startTime:int = 0;
		
		protected var _time:int;
		protected var _totalDuration : uint = 0;
		protected var _rootDelta : Vector3D = new Vector3D();
		protected var _rootDeltaDirty : Boolean = true;
		protected var _looping:Boolean = true;
		
		/**
		 * Determines whether the contents of the animation node have looping characteristics enabled.
		 */
		public function get looping():Boolean
		{	
			return _looping;
		}
		
		public function set looping(value:Boolean):void
		{
			if (_looping == value)
				return;
			
			_looping = value;
			updateLooping();
		}
		
		/**
		 * Returns a 3d vector representing the translation delta of the animating entity for the current timestep of animation
		 */		
		public function get rootDelta() : Vector3D
		{
			if (_rootDeltaDirty)
				updateRootDelta();
			
			return _rootDelta;
		}
		
		/**
		 * Creates a new <code>AnimationNodeBase</code> object.
		 */
		public function AnimationNodeBase()
		{
		}
		
		/**
		 * Resets the configuration of the node to its default state.
		 * 
		 * @param time The absolute time (in milliseconds) of the animator's playhead position.
		 */
		public function reset(time:int):void
		{
			if (!_looping)
				_startTime = time;
			
			update(time);
			
			updateRootDelta();
		}
		
		/**
		 * Updates the configuration of the node to its current state.
		 * 
		 * @param time The absolute time (in milliseconds) of the animator's play head position.
		 * 
		 * @see away3d.animators.AnimatorBase#update()
		 */		
		public function update(time:int):void
		{
			if (!_looping && time > _startTime + _totalDuration)
				time = _startTime + _totalDuration;
				
			if (_time == time - _startTime)
				return;
			
			updateTime(time - _startTime);
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function get assetType() : String
		{
			return AssetType.ANIMATION_NODE;
		}

		/**
		 * Updates the node's root delta position
		 * 
		 * @see #rootDelta
		 */
		protected function updateRootDelta() : void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Updates the node's internal playhead position.
		 * 
		 * @param time The local time (in milliseconds) of the node's playhead position.
		 */
		protected function updateTime(time:int) : void
		{
			_time = time;
			
			_rootDeltaDirty = true;
		}
		
		/**
		 * Updates the node's looping state
		 * 
		 * @see #looping
		 */
		protected function updateLooping():void
		{
			updateTime(_time);
		}
	}
}

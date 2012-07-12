package away3d.animators
{
	import away3d.errors.AnimationSetError;
	import flash.utils.Dictionary;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.NamedAssetBase;
	import away3d.library.assets.IAsset;
	import away3d.arcane;
	
	use namespace arcane;
	
	/**
	 * Provides an abstract base class for data set classes that hold animation data for use in animator classes.
	 *
	 * @see away3d.animators.AnimatorBase
	 */
	public class AnimationSetBase extends NamedAssetBase implements IAsset
	{
		arcane var _usesCPU:Boolean;
		private var _states:Vector.<IAnimationState> = new Vector.<IAnimationState>();
		private var _stateDictionary:Dictionary = new Dictionary(true);
		
		/**
		 * Retrieves a temporary GPU register that's still free.
		 * 
		 * @param exclude An array of non-free temporary registers.
		 * @param excludeAnother An additional register that's not free.
		 * @return A temporary register that can be used.
		 */
		protected function findTempReg(exclude : Array, excludeAnother : String = null) : String
		{
			var i : uint;
			var reg : String;

			while (true) {
				reg = "vt" + i;
				if (exclude.indexOf(reg) == -1 && excludeAnother != reg) return reg;
				++i;
			}

			// can't be reached
			return null;
		}
		
		/**
		 * Indicates whether the properties of the animation data contained within the set combined with
		 * the vertex registers aslready in use on shading materials allows the animation data to utilise
		 * GPU calls.
		 */
		public function get usesCPU() : Boolean
		{
			return _usesCPU;
		}
		
		/**
		 * Called by the material to reset the GPU indicator before testing whether register space in the shader
		 * is available for running GPU-based animation code.
		 * 
		 * @private
		 */
		public function resetGPUCompatibility() : void
        {
            _usesCPU = false;
        }
		
		/**
		 * @inheritDoc
		 */
		public function get assetType() : String
		{
			return AssetType.ANIMATION_SET;
		}
		
		/**
		 * Returns a vector of animation state objects that make up the contents of the animation data set.
		 */
		public function get states():Vector.<IAnimationState>
		{
			return _states;
		}
		
		/**
		 * Check to determine whether a state is registered in the animation set under the given name.
		 * 
		 * @param stateName The name of the animation state object to be checked.
		 */
		public function hasState(stateName:String):Boolean
		{
			return _stateDictionary[stateName] != null;
		}
		
		/**
		 * Retrieves the animation state object registered in the animation data set under the given name.
		 * 
		 * @param stateName The name of the animation state object to be retrieved.
		 */
		public function getState(stateName:String):IAnimationState
		{
			return _stateDictionary[stateName];
		}
		
		
		/**
		 * Adds an animation state object to the aniamtion data set under the given name.
		 * 
		 * @param stateName The name under which the animation state object will be stored.
		 * @param animationState The animation state object to be staored in the set.
		 */
		public function addState(stateName:String, animationState:IAnimationState):void
		{
			if (_stateDictionary[stateName])
				throw new AnimationSetError("Animation state name already exists in the set");
			
			_stateDictionary[stateName] = animationState;
			
			_states.push(animationState);
		}
		
		/**
		 * Cleans up any resources used by the current object.
		 */
		public function dispose() : void
		{
		}
	}
}

package away3d.animators {
	import away3d.animators.nodes.*;
	import away3d.errors.*;
	import away3d.library.assets.*;

	import flash.utils.*;
	
	/**
	 * Provides an abstract base class for data set classes that hold animation data for use in animator classes.
	 *
	 * @see away3d.animators.AnimatorBase
	 */
	public class AnimationSetBase extends NamedAssetBase implements IAsset
	{
		private var _usesCPU:Boolean;
		private var _animations:Vector.<AnimationNodeBase> = new Vector.<AnimationNodeBase>();
		private var _animationNames:Vector.<String> = new Vector.<String>();
		private var _animationDictionary:Dictionary = new Dictionary(true);
		
		public function AnimationSetBase() {
			
		}
		
		/**
		 * Retrieves a temporary GPU register that's still free.
		 *
		 * @param exclude An array of non-free temporary registers.
		 * @param excludeAnother An additional register that's not free.
		 * @return A temporary register that can be used.
		 */
		protected function findTempReg(exclude : Vector.<String>, excludeAnother : String = null) : String
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
		
		public function cancelGPUCompatibility() : void
        {
            _usesCPU = true;
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
		public function get animations():Vector.<AnimationNodeBase>
		{
			return _animations;
		}
		
		/**
		 * Returns a vector of animation state objects that make up the contents of the animation data set.
		 */
		public function get animationNames():Vector.<String>
		{
			return _animationNames;
		}
		
		/**
		 * Check to determine whether a state is registered in the animation set under the given name.
		 *
		 * @param stateName The name of the animation state object to be checked.
		 */
		public function hasAnimation(name:String):Boolean
		{
			return _animationDictionary[name] != null;
		}
		
		/**
		 * Retrieves the animation state object registered in the animation data set under the given name.
		 *
		 * @param stateName The name of the animation state object to be retrieved.
		 */
		public function getAnimation(name:String):AnimationNodeBase
		{
			return _animationDictionary[name];
		}
		
		
		/**
		 * Adds an animation state object to the aniamtion data set under the given name.
		 *
		 * @param stateName The name under which the animation state object will be stored.
		 * @param animationState The animation state object to be staored in the set.
		 */
		public function addAnimation(node:AnimationNodeBase):void
		{
			if (_animationDictionary[node.name])
				throw new AnimationSetError("root node name '" + node.name + "' already exists in the set");
			
			_animationDictionary[node.name] = node;
			
			_animations.push(node);
			
			_animationNames.push(node.name);
		}
		
		/**
		 * Cleans up any resources used by the current object.
		 */
		public function dispose() : void
		{
		}
	}
}

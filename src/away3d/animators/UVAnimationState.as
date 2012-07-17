package away3d.animators
{
	import away3d.arcane;
	import away3d.animators.nodes.*;
	
	use namespace arcane;
	
	/**
	 * The animation state class used by uv-based animation data sets to store uv animation node data.
	 * 
	 * @see away3d.animators.UVAnimator
	 * @see away3d.animators.UVAnimationSet
	 */
	public class UVAnimationState extends AnimationStateBase implements IAnimationState
	{
		private var _vertexAnimationSet:UVAnimationSet;
		
		/**
		 * Creates a new <code>UVAnimationState</code> object.
		 * 
		 * @param rootNode Sets the root animation node used by the state for determining the output pose of the uv animation node data.
		 */
		public function UVAnimationState(rootNode:UVClipNode)
		{
			super(rootNode);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function addOwner(owner:IAnimationSet, stateName:String):void
		{
			if (!(owner is UVAnimationSet))
				throw new Error("A UV animation state can only be added to a UV animation set");
			
			super.addOwner(owner, stateName);
						
			_vertexAnimationSet = owner as UVAnimationSet;
		}
	}
}

package away3d.animators
{
	import away3d.arcane;
	import away3d.animators.nodes.*;
	
	use namespace arcane;
	
	/**
	 * The animation state class used by vertex-based animation data sets to store vertex animation node data.
	 * 
	 * @see away3d.animators.VertexAnimator
	 * @see away3d.animators.VertexAnimationSet
	 */
	public class VertexAnimationState extends AnimationStateBase implements IAnimationState
	{
		private var _vertexAnimationSet:VertexAnimationSet;
		
		/**
		 * Creates a new <code>VertexAnimationState</code> object.
		 * 
		 * @param rootNode Sets the root animation node used by the state for determining the output pose of the vertex animation node data.
		 */
		public function VertexAnimationState(rootNode:VertexClipNode)
		{
			super(rootNode);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function addOwner(owner:IAnimationSet, stateName:String):void
		{
			if (!(owner is VertexAnimationSet))
				throw new Error("A vertex animation state can only be added to a vertex animation set");
			
			super.addOwner(owner, stateName);
						
			_vertexAnimationSet = owner as VertexAnimationSet;
		}
	}
}

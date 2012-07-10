package away3d.animators
{
	import away3d.arcane;
	import away3d.animators.nodes.*;
	
	use namespace arcane;
	
	/**
	 * @author robbateman
	 */
	public class VertexAnimationState extends AnimationStateBase implements IAnimationState
	{
		private var _vertexAnimationSet:VertexAnimationSet;
		
		public function VertexAnimationState(rootNode:VertexClipNode)
		{
			super(rootNode);
		}
		
		override public function addOwner(owner:IAnimationSet, stateName:String):void
		{
			if (!(owner is VertexAnimationSet))
				throw new Error("A skeleton animation state can only be added to a skeleton animation set");
			
			super.addOwner(owner, stateName);
						
			_vertexAnimationSet = owner as VertexAnimationSet;
		}
	}
}

package away3d.animators
{
	import away3d.arcane;
	import away3d.animators.nodes.*;
	
	use namespace arcane;
	
	/**
	 * @author robbateman
	 */
	public class UVAnimationState extends AnimationStateBase implements IAnimationState
	{
		private var _vertexAnimationSet:UVAnimationSet;
		
		public function UVAnimationState(rootNode:UVClipNode)
		{
			super(rootNode);
		}
		
		override public function addOwner(owner:IAnimationSet, stateName:String):void
		{
			if (!(owner is UVAnimationSet))
				throw new Error("A UV animation state can only be added to a UV animation set");
			
			super.addOwner(owner, stateName);
						
			_vertexAnimationSet = owner as UVAnimationSet;
		}
	}
}

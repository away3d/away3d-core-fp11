package away3d.animators.nodes
{
	import away3d.animators.skeleton.*;
	import away3d.errors.*;

	/**
	 * @author robbateman
	 */
	public class SkeletonNodeBase extends AnimationNodeBase
	{
		protected var _skeletonPose : SkeletonPose = new SkeletonPose();
		protected var _skeletonPoseDirty : Boolean;

		
		public function getSkeletonPose(skeleton:Skeleton):SkeletonPose
		{
			if (_skeletonPoseDirty)
				updateSkeletonPose(skeleton);
			
			return _skeletonPose;
		}
		
		override protected function updateTime(time:Number):void
		{
			super.updateTime(time);
			
			_skeletonPoseDirty = true;
		}
		
		/**
		 * Updates the node's skeleton pose
		 */
		protected function updateSkeletonPose(skeleton:Skeleton) : void
		{
			throw new AbstractMethodError();
		}
	}
}

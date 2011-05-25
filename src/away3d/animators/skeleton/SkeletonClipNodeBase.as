/**
 * Author: David Lenaerts
 */
package away3d.animators.skeleton
{
	import away3d.arcane;

	import flash.geom.Vector3D;
	import away3d.animators.data.SkeletonAnimationSequence;

	use namespace arcane;

	/**
	 * SkeletonClipNodeBase provides an abstract base class for animation blend tree nodes containing a clip.
	 */
	public class SkeletonClipNodeBase extends SkeletonTreeNode
	{
		/**
		 * The animation clip.
		 */
		protected var _clip : SkeletonAnimationSequence;
		protected var _rootPos : Vector3D;
		protected var _highQuality : Boolean;

		/**
		 * Creates a new SkeletonPhaseClipNode object.
		 * @param numJoints The amount of joints in the target skeleton.
		 */
		public function SkeletonClipNodeBase()
		{
			super();
			_rootPos = new Vector3D();
		}

		/**
		 * Defines whether to use spherical (true) or regular (false) linear interpolation for the joint orientations.
		 */
		public function get highQuality() : Boolean
		{
			return _highQuality;
		}

		public function set highQuality(value : Boolean) : void
		{
			_highQuality = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function get duration() : Number
		{
			return _clip.duration;
		}

		public function get clip() : SkeletonAnimationSequence
		{
			return _clip;
		}

		public function set clip(value : SkeletonAnimationSequence) : void
		{
			_clip = value;
			_rootPos.x = 0;
			_rootPos.y = 0;
			_rootPos.z = 0;
		}
	}
}

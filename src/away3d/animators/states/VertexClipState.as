package away3d.animators.states
{
	import away3d.animators.AnimatorBase;
	import away3d.animators.VertexAnimator;
	import away3d.animators.nodes.VertexClipNode;
	import away3d.core.base.Geometry;

	/**
	 *
	 */
	public class VertexClipState extends AnimationClipState implements IVertexAnimationState
	{
		private var _frames:Vector.<Geometry>;
		private var _vertexClipNode:VertexClipNode;
		private var _currentGeometry:Geometry;
		private var _nextGeometry:Geometry;
		
		/**
		 * @inheritDoc
		 */
		public function get currentGeometry():Geometry
		{
			if (_framesDirty)
				updateFrames();
			
			return _currentGeometry;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get nextGeometry():Geometry
		{
			if (_framesDirty)
				updateFrames();
			
			return _nextGeometry;
		}
		
		function VertexClipState(animator:AnimatorBase, vertexClipNode:VertexClipNode)
		{
			super(animator, vertexClipNode);
			
			_vertexClipNode = vertexClipNode;
			_frames = _vertexClipNode.frames;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateFrames():void
		{
			super.updateFrames();
			
			_currentGeometry = _frames[_currentFrame];
			
			if (_vertexClipNode.looping && _nextFrame >= _vertexClipNode.lastFrame) {
				_nextGeometry = _frames[0];
				VertexAnimator(_animator).dispatchCycleEvent();
			} else
				_nextGeometry = _frames[_nextFrame];
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updatePositionDelta():void
		{
			//TODO:implement positiondelta functionality for vertex animations
		}
	}
}

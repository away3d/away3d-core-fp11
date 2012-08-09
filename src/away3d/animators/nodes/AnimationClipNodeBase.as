package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.nodes.*;
	
	import flash.geom.*;
	
	use namespace arcane;
	
	/**
	 * Provides an abstract base class for nodes with time-based animation data in an animation blend tree.
	 */
	public class AnimationClipNodeBase extends AnimationNodeBase
	{
		protected var _looping:Boolean = true;
		protected var _totalDuration : uint = 0;
		protected var _lastFrame : uint;
		
		protected var _stitchDirty:Boolean = true;
		protected var _stitchFinalFrame:Boolean = false;
		protected var _numFrames : uint = 0;
		
		protected var _durations : Vector.<uint> = new Vector.<uint>();
		protected var _totalDelta : Vector3D = new Vector3D();
		
		public var fixedFrameRate:Boolean = true;
		
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
			
			_stitchDirty = true;
		}
		
		/**
		 * Defines if looping content blends the final frame of animation data with the first (true) or works on the
		 * assumption that both first and last frames are identical (false). Defaults to false.
		 */
		public function get stitchFinalFrame() : Boolean
		{
			return _stitchFinalFrame;
		}
		
		public function set stitchFinalFrame(value:Boolean):void
		{
			if (_stitchFinalFrame == value)
				return;
			
			_stitchFinalFrame = value;
			
			_stitchDirty = true;
		}
		
		public function get totalDuration():uint
		{
			if (_stitchDirty)
				updateStitch();
			
			return _totalDuration;
		}
		
		public function get totalDelta():Vector3D
		{
			if (_stitchDirty)
				updateStitch();
			
			return _totalDelta;
		}
		
		public function get lastFrame():uint
		{
			if (_stitchDirty)
				updateStitch();
			
			return _lastFrame;
		}
		
		/**
		 * Returns a vector of time values representing the duration (in milliseconds) of each animation frame in the clip.
		 */
		public function get durations():Vector.<uint>
		{
			return _durations;
		}
		
		/**
		 * Creates a new <code>AnimationClipNodeBase</code> object.
		 */
		public function AnimationClipNodeBase()
		{
			super();
		}
		
		/**
		 * Updates the node's final frame stitch state.
		 * 
		 * @see #stitchFinalFrame
		 */
		protected function updateStitch():void
		{
			_stitchDirty = false;
			
			_lastFrame = (_stitchFinalFrame)? _numFrames : _numFrames - 1;
			
			_totalDuration = 0;
			_totalDelta.x = 0;
			_totalDelta.y = 0;
			_totalDelta.z = 0;
		}
	}
}

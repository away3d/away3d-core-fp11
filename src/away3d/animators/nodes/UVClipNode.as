package away3d.animators.nodes
{
	import away3d.animators.states.*;
	import away3d.animators.data.*;

	/**
	 * A uv animation node containing time-based animation data as individual uv animation frames.
	 */
	public class UVClipNode extends AnimationClipNodeBase
	{
		private var _frames : Vector.<UVAnimationFrame> = new Vector.<UVAnimationFrame>();
		
		/**
		 * Returns a vector of UV frames representing the uv values of each animation frame in the clip.
		 */
		public function get frames():Vector.<UVAnimationFrame>
		{
			return _frames;
		}
		
		/**
		 * Creates a new <code>UVClipNode</code> object.
		 */
		public function UVClipNode()
		{
			_stateClass = UVClipState;
		}
		
		/**
		 * Adds a UV frame object to the internal timeline of the animation node.
		 * 
		 * @param uvFrame The uv frame object to add to the timeline of the node.
		 * @param duration The specified duration of the frame in milliseconds.
		 */
		public function addFrame(uvFrame : UVAnimationFrame, duration : uint) : void
		{
			_frames.push(uvFrame);
			_durations.push(duration);
			_numFrames = _durations.length;

			_stitchDirty = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateStitch():void
		{
			super.updateStitch();
			var i:uint;

			if(_durations.length>0) {

				i = _numFrames  - 1;
				while (i--) {
					_totalDuration += _durations[i];
				}

				if (_stitchFinalFrame || !_looping) {
					_totalDuration += _durations[_numFrames - 1];
				}
			} 
			
		
		}
	}
}
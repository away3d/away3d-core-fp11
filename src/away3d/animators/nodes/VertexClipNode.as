package away3d.animators.nodes
{
	import away3d.core.base.*;

	import flash.geom.*;
	

	/**
	 * A vertex animation node containing time-based animation data as individual geometry obejcts.
	 */
	public class VertexClipNode extends AnimationClipNodeBase implements IVertexAnimationNode
	{
		private var _frames : Vector.<Geometry> = new Vector.<Geometry>();
		private var _translations : Vector.<Vector3D> = new Vector.<Vector3D>();
		private var _currentGeometry : Geometry;
		private var _nextGeometry : Geometry;
		
		/**
		 * @inheritDoc
		 */
		public function get currentGeometry() : Geometry
		{
			if (_framesDirty)
				updateFrames();
			
			return _currentGeometry;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get nextGeometry() : Geometry
		{
			if (_framesDirty)
				updateFrames();
			
			return _nextGeometry;
		}
		
		/**
		 * Returns a vector of geometry frames representing the vertex values of each animation frame in the clip.
		 */
		public function get frames():Vector.<Geometry>
		{
			return _frames;
		}
		
		/**
		 * Creates a new <code>VertexClipNode</code> object.
		 */
		public function VertexClipNode()
		{
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateRootDelta() : void
		{
			//TODO:implement rootdelta functionality for vertex animations
		}
		
		/**
		 * Adds a geometry object to the internal timeline of the animation node.
		 * 
		 * @param geometry The geometry object to add to the timeline of the node.
		 * @param duration The specified duration of the frame in milliseconds.
		 * @param translation The absolute translation of the frame, used in root delta calculations for mesh movement.
		 */
		public function addFrame(geometry : Geometry, duration : uint, translation:Vector3D = null) : void
		{
			_frames.push(geometry);
			_durations.push(duration);
			_translations.push(translation || new Vector3D());
			
			_numFrames = _durations.length;
			
			_stitchDirty = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateTime(time:int):void
		{
			super.updateTime(time);
			
			_framesDirty = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateFrames() : void
		{
			super.updateFrames();
			
			_currentGeometry = _frames[_currentFrame];
			
			if (_looping && _nextFrame >= _lastFrame)
				_nextGeometry = _frames[0];
			else
				_nextGeometry = _frames[_nextFrame];
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateStitch():void
		{
			super.updateStitch();
			
			var i:uint = _numFrames - 1;
			var p1 : Vector3D, p2 : Vector3D, delta : Vector3D;
			while (i--) {
				_totalDuration += _durations[i];
				p1 = _translations[i];
				p2 = _translations[i+1];
				delta = p2.subtract(p1);
				_totalDelta.x += delta.x;
				_totalDelta.y += delta.y;
				_totalDelta.z += delta.z;
			}
			
			if (_stitchFinalFrame || !_looping) {
				_totalDuration += _durations[_numFrames - 1];
				p1 = _translations[0];
				p2 = _translations[1];
				delta = p2.subtract(p1);
				_totalDelta.x += delta.x;
				_totalDelta.y += delta.y;
				_totalDelta.z += delta.z;
			}
		}
	}
}

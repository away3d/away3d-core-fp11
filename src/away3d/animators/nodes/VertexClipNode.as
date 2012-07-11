package away3d.animators.nodes
{
	import flash.geom.Vector3D;
	import away3d.core.base.*;
	import away3d.library.assets.*;

	/**
	 * @author robbateman
	 */
	public class VertexClipNode extends AnimationClipNodeBase implements IVertexAnimationNode
	{
		private var _frames : Vector.<Geometry> = new Vector.<Geometry>();
		private var _translations : Vector.<Vector3D> = new Vector.<Vector3D>();
		private var _currentGeometry : Geometry;
		private var _nextGeometry : Geometry;
		
		public function get currentGeometry() : Geometry
		{
			if (_framesDirty)
				updateFrames();
			
			return _currentGeometry;
		}
		
		
		public function get nextGeometry() : Geometry
		{
			if (_framesDirty)
				updateFrames();
			
			return _nextGeometry;
		}
		
		public function VertexClipNode()
		{
		}
		
		public function addFrame(geometry : Geometry, duration : Number, translation:Vector3D = null) : void
		{
			_frames.push(geometry);
			_durations.push(duration);
			_translations.push(translation || new Vector3D());
			
			_numFrames = _durations.length;
			
			_stitchDirty = true;
		}
		
		override protected function updateTime(time:Number):void
		{
			super.updateTime(time);
			
			_framesDirty = true;
		}

		override protected function updateFrames() : void
		{
			super.updateFrames();
			
			_currentGeometry = _frames[_currentFrame];
			
			if (_looping && _nextFrame >= _lastFrame)
				_nextGeometry = _frames[0];
			else
				_nextGeometry = _frames[_nextFrame];
		}
		
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

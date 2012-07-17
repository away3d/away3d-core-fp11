package away3d.filters
{
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.tasks.Filter3DHDepthOfFFieldTask;

	import flash.geom.Vector3D;

	public class HDepthOfFieldFilter3D extends Filter3DBase
	{
		private var _dofTask : Filter3DHDepthOfFFieldTask;
		private var _focusTarget : ObjectContainer3D;

		/**
		 * Creates a new HDepthOfFieldFilter3D object
		 * @param amount The amount of blur to apply in pixels
		 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
		 */
		public function HDepthOfFieldFilter3D(maxBlur : uint = 3, stepSize : int = -1)
		{
			super();
			_dofTask = new Filter3DHDepthOfFFieldTask(maxBlur, stepSize);
			addTask(_dofTask);
		}

		public function get focusTarget() : ObjectContainer3D
		{
			return _focusTarget;
		}

		public function set focusTarget(value : ObjectContainer3D) : void
		{
			_focusTarget = value;
		}

		public function get focusDistance() : Number
		{
			return _dofTask.focusDistance;
		}

		public function set focusDistance(value : Number) : void
		{
			_dofTask.focusDistance = value;
		}

		public function get range() : Number
		{
			return _dofTask.range;
		}

		public function set range(value : Number) : void
		{
			_dofTask.range = value;
		}

		public function get maxBlur() : uint
		{
			return _dofTask.maxBlur;
		}

		public function set maxBlur(value : uint) : void
		{
			_dofTask.maxBlur = value;
		}

		override public function update(stage : Stage3DProxy, camera : Camera3D) : void
		{
			if (_focusTarget)
				updateFocus(camera);
		}

		private function updateFocus(camera : Camera3D) : void
		{
			var target : Vector3D = camera.inverseSceneTransform.transformVector(_focusTarget.scenePosition);
			_dofTask.focusDistance = target.z;
		}
	}
}

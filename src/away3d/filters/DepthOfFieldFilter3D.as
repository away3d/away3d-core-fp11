package away3d.filters
{
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.tasks.Filter3DDepthOfFFieldTask;

	import flash.geom.Vector3D;

	public class DepthOfFieldFilter3D extends Filter3DBase
	{
		private var _dofTask : Filter3DDepthOfFFieldTask;
		private var _focusTarget : ObjectContainer3D;

		public function DepthOfFieldFilter3D(maxBlurX : uint = 3, maxBlurY : uint = 3)
		{
			super();
			_dofTask = new Filter3DDepthOfFFieldTask(maxBlurX, maxBlurY);
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

		public function get maxBlurX() : uint
		{
			return _dofTask.maxBlurX;
		}

		public function set maxBlurX(value : uint) : void
		{
			_dofTask.maxBlurX = value;
		}

		public function get maxBlurY() : uint
		{
			return _dofTask.maxBlurY;
		}

		public function set maxBlurY(value : uint) : void
		{
			_dofTask.maxBlurY = value;
		}


		override public function update(stage : Stage3DProxy, camera : Camera3D) : void
		{
			// TODO: not used
			stage = stage;
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

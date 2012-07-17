package away3d.filters
{
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.tasks.Filter3DDoubleBufferCopyTask;
	import away3d.filters.tasks.Filter3DXFadeCompositeTask;

	public class MotionBlurFilter3D extends Filter3DBase
	{
		private var _compositeTask : Filter3DXFadeCompositeTask;
		private var _copyTask : Filter3DDoubleBufferCopyTask;

		public function MotionBlurFilter3D(strength : Number = .65)
		{
			super();
			_compositeTask = new Filter3DXFadeCompositeTask(strength);
			_copyTask = new Filter3DDoubleBufferCopyTask();

			addTask(_compositeTask);
			addTask(_copyTask);
		}

		public function get strength() : Number
		{
			return _compositeTask.amount;
		}

		public function set strength(value : Number) : void
		{
			_compositeTask.amount = value;
		}

		override public function update(stage : Stage3DProxy, camera : Camera3D) : void
		{
			_compositeTask.overlayTexture = _copyTask.getMainInputTexture(stage);
			_compositeTask.target = _copyTask.secondaryInputTexture;
		}
	}
}

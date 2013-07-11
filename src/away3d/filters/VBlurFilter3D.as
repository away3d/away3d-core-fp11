package away3d.filters
{
	import away3d.filters.tasks.Filter3DVBlurTask;
	
	public class VBlurFilter3D extends Filter3DBase
	{
		private var _blurTask:Filter3DVBlurTask;
		
		/**
		 * Creates a new VBlurFilter3D object
		 * @param amount The amount of blur in pixels
		 * @param stepSize The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
		 */
		public function VBlurFilter3D(amount:uint, stepSize:int = -1)
		{
			super();
			_blurTask = new Filter3DVBlurTask(amount, stepSize);
			addTask(_blurTask);
		}
		
		public function get amount():uint
		{
			return _blurTask.amount;
		}
		
		public function set amount(value:uint):void
		{
			_blurTask.amount = value;
		}
		
		/**
		 * The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
		 * Higher values provide better performance at the cost of reduces quality.
		 */
		public function get stepSize():int
		{
			return _blurTask.stepSize;
		}
		
		public function set stepSize(value:int):void
		{
			_blurTask.stepSize = value;
		}
	}
}

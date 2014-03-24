package away3d.filters
{
	import away3d.filters.*;
	import away3d.filters.tasks.Filter3DFishEyeTask;
	
	public class FishEyeFilter3D extends Filter3DBase
	{
		private var _fishEyeTask:Filter3DFishEyeTask;
		
		/**
		 * Creates a new FishEyeFilter3D object.
		 */
		public function FishEyeFilter3D(size:uint = 256, fov:Number = 180)
		{
			super();
			_fishEyeTask = new Filter3DFishEyeTask(size, fov)
			addTask(_fishEyeTask);
		}
		
		public function get fov():Number
		{
			return _fishEyeTask.fov;
		}
		
		public function set fov(value:Number):void
		{
			_fishEyeTask.fov = value;
		}
		
		/**
		 * The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
		 * Higher values provide better performance at the cost of reduces quality.
		 */
		public function get size():uint
		{
			return _fishEyeTask.size;
		}
		
		public function set size(value:uint):void
		{
			_fishEyeTask.size = value;
		}
	}
}

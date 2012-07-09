package away3d.filters
{
	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.tasks.Filter3DHBlurTask;
	import away3d.filters.tasks.Filter3DVBlurTask;

	import flash.display3D.textures.Texture;

	public class BlurFilter3D extends Filter3DBase
	{
		private var _hBlurTask : Filter3DHBlurTask;
		private var _vBlurTask : Filter3DVBlurTask;

		/**
		 * Creates a new BlurFilter3D object
		 * @param blurX The amount of horizontal blur to apply
		 * @param blurY The amount of vertical blur to apply
		 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
		 */
		public function BlurFilter3D(blurX : uint = 3, blurY : uint = 3, stepSize : int = -1)
		{
			super();
			addTask(_hBlurTask = new Filter3DHBlurTask(blurX, stepSize));
			addTask(_vBlurTask = new Filter3DVBlurTask(blurY, stepSize));
		}

		public function get blurX() : uint
		{
			return _hBlurTask.amount;
		}

		public function set blurX(value : uint) : void
		{
			_hBlurTask.amount = value;
		}

		public function get blurY() : uint
		{
			return _vBlurTask.amount;
		}

		public function set blurY(value : uint) : void
		{
			_vBlurTask.amount = value;
		}

		/**
		 * The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
		 * Higher values provide better performance at the cost of reduces quality.
		 */
		public function get stepSize() : int
		{
			return _hBlurTask.stepSize;
		}

		public function set stepSize(value : int) : void
		{
			_hBlurTask.stepSize = value;
			_vBlurTask.stepSize = value;
		}


		override public function setRenderTargets(mainTarget : Texture, stage3DProxy : Stage3DProxy) : void
		{
			_hBlurTask.target = _vBlurTask.getMainInputTexture(stage3DProxy);
			super.setRenderTargets(mainTarget, stage3DProxy);
		}
	}
}

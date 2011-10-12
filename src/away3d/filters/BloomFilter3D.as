package away3d.filters
{
	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.tasks.Filter3DCompositeTask;
	import away3d.filters.tasks.Filter3DBlurTask;
	import away3d.filters.tasks.Filter3DBrightPassTask;

	import flash.display.BlendMode;

	import flash.display3D.textures.Texture;

	public class BloomFilter3D extends Filter3DBase
	{
		private var _brightPassTask : Filter3DBrightPassTask;
		private var _blurTask : Filter3DBlurTask;
		private var _compositeTask : Filter3DCompositeTask;

		public function BloomFilter3D(blurX : uint = 15, blurY : uint = 15, threshold : Number = .75, exposure : Number = 3, quality : int = 3)
		{
			super();
			_brightPassTask = new Filter3DBrightPassTask(threshold);
			_blurTask = new Filter3DBlurTask(blurX, blurY);
		   	_compositeTask = new Filter3DCompositeTask(BlendMode.ADD, exposure);

			if (quality > 4) quality = 4;
			else if (quality < 0) quality = 0;

			_blurTask.textureScale = (4 - quality);

			addTask(_brightPassTask);
			addTask(_blurTask);
			addTask(_compositeTask);
		}

		override public function setRenderTargets(mainTarget : Texture, stage3DProxy : Stage3DProxy) : void
		{
			_brightPassTask.target = _blurTask.getMainInputTexture(stage3DProxy);
			_blurTask.target = _compositeTask.getMainInputTexture(stage3DProxy);
			// use bright pass's input as composite's input
			_compositeTask.overlayTexture = _brightPassTask.getMainInputTexture(stage3DProxy);

			super.setRenderTargets(mainTarget, stage3DProxy);
		}

		public function get exposure() : Number
		{
			return _compositeTask.exposure;
		}

		public function set exposure(value : Number) : void
		{
			_compositeTask.exposure = value;
		}

		public function get blurX() : uint
		{
			return _blurTask.blurX;
		}

		public function set blurX(value : uint) : void
		{
			_blurTask.blurX = value;
		}

		public function get blurY() : uint
		{
			return _blurTask.blurY;
		}

		public function set blurY(value : uint) : void
		{
			_blurTask.blurY = value;
		}

		public function get threshold() : Number
		{
			return _brightPassTask.threshold;
		}

		public function set threshold(value : Number) : void
		{
			_brightPassTask.threshold = value;
		}
	}
}

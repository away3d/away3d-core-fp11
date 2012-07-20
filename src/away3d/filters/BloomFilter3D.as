package away3d.filters
{
	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.tasks.Filter3DCompositeTask;
	import away3d.filters.tasks.Filter3DBrightPassTask;
	import away3d.filters.tasks.Filter3DHBlurTask;
	import away3d.filters.tasks.Filter3DVBlurTask;

	import flash.display.BlendMode;

	import flash.display3D.textures.Texture;

	public class BloomFilter3D extends Filter3DBase
	{
		private var _brightPassTask : Filter3DBrightPassTask;
		private var _vBlurTask : Filter3DVBlurTask;
		private var _hBlurTask : Filter3DHBlurTask;
		private var _compositeTask : Filter3DCompositeTask;

		public function BloomFilter3D(blurX : uint = 15, blurY : uint = 15, threshold : Number = .75, exposure : Number = 3, quality : int = 3)
		{
			super();
			_brightPassTask = new Filter3DBrightPassTask(threshold);
			_hBlurTask = new Filter3DHBlurTask(blurX);
			_vBlurTask = new Filter3DVBlurTask(blurY);
		   	_compositeTask = new Filter3DCompositeTask(BlendMode.ADD, exposure);

			if (quality > 4) quality = 4;
			else if (quality < 0) quality = 0;

			_hBlurTask.textureScale = (4 - quality);
			_vBlurTask.textureScale = (4 - quality);
			// composite's main input texture is from vBlur, so needs to be scaled down
			_compositeTask.textureScale = (4 - quality);

			addTask(_brightPassTask);
			addTask(_hBlurTask);
			addTask(_vBlurTask);
			addTask(_compositeTask);
		}

		override public function setRenderTargets(mainTarget : Texture, stage3DProxy : Stage3DProxy) : void
		{
			_brightPassTask.target = _hBlurTask.getMainInputTexture(stage3DProxy);
			_hBlurTask.target = _vBlurTask.getMainInputTexture(stage3DProxy);
			_vBlurTask.target = _compositeTask.getMainInputTexture(stage3DProxy);
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

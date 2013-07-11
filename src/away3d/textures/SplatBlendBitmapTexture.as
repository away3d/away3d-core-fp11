package away3d.textures
{
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class SplatBlendBitmapTexture extends BitmapTexture
	{
		[Embed(source="/../pb/NormalizeSplats.pbj", mimeType="application/octet-stream")]
		private var NormalizeKernel:Class;
		
		private var _numSplattingLayers:int;
		
		/**
		 *
		 * @param blendingData An array of BitmapData objects to be used for the blend data, as required by TerrainDiffuseMethod.
		 */
		public function SplatBlendBitmapTexture(blendingData:Array, normalize:Boolean = false)
		{
			var bitmapData:BitmapData = blendingData[0].clone();
			var channels:Array = [ BitmapDataChannel.RED, BitmapDataChannel.GREEN, BitmapDataChannel.BLUE ];
			
			super(bitmapData);
			
			_numSplattingLayers = blendingData.length;
			if (_numSplattingLayers > 3)
				throw new Error("blendingData can not have more than 3 elements!");
			
			var rect:Rectangle = bitmapData.rect;
			var origin:Point = new Point();
			
			for (var i:int = 1; i < blendingData.length; ++i)
				bitmapData.copyChannel(blendingData[i], rect, origin, BitmapDataChannel.RED, channels[i]);
			
			if (normalize)
				normalizeSplats();
		}
		
		private function normalizeSplats():void
		{
			if (_numSplattingLayers <= 1)
				return;
			var shader:Shader = new Shader(new NormalizeKernel());
			shader.data.numLayers = _numSplattingLayers;
			shader.data.src.input = bitmapData;
			new ShaderJob(shader, bitmapData).start(true);
		}
		
		override public function dispose():void
		{
			super.dispose();
			bitmapData.dispose();
		}
	}
}

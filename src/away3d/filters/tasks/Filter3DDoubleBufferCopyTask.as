package away3d.filters.tasks
{
	import away3d.*;
	import away3d.cameras.*;
	import away3d.core.managers.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	
	use namespace arcane;
	
	public class Filter3DDoubleBufferCopyTask extends Filter3DTaskBase
	{
		private var _secondaryInputTexture:TextureBase;
		
		public function Filter3DDoubleBufferCopyTask()
		{
			super();
		}
		
		public function get secondaryInputTexture():TextureBase
		{
			return _secondaryInputTexture;
		}
		
		override protected function getFragmentCode():String
		{
			return "tex oc, v0, fs0 <2d,nearest,clamp>\n";
		}
		
		override protected function updateTextures(stage:Stage3DProxy):void
		{
			super.updateTextures(stage);
			
			if (_secondaryInputTexture)
				_secondaryInputTexture.dispose();
			
			_secondaryInputTexture = stage.context3D.createTexture(_textureWidth >> _textureScale, _textureHeight >> _textureScale, Context3DTextureFormat.BGRA, true);
			
			var dummy:BitmapData = new BitmapData(_textureWidth >> _textureScale, _textureHeight >> _textureScale, false, 0);
			(_mainInputTexture as Texture).uploadFromBitmapData(dummy);
			(_secondaryInputTexture as Texture).uploadFromBitmapData(dummy);
			dummy.dispose();
		}
		
		override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D, depthTexture:Texture):void
		{
			swap();
			super.activate(stage3DProxy, camera, depthTexture);
		}
		
		private function swap():void
		{
			var tmp:TextureBase = _secondaryInputTexture;
			_secondaryInputTexture = _mainInputTexture;
			_mainInputTexture = tmp;
		}
	}
}

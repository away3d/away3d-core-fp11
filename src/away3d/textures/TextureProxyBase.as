package away3d.textures
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.errors.AbstractMethodError;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;
	
	use namespace arcane;
	
	public class TextureProxyBase extends NamedAssetBase implements IAsset
	{
		protected var _format:String = Context3DTextureFormat.BGRA;
		protected var _hasMipmaps:Boolean = true;
		
		protected var _textures:Vector.<TextureBase>;
		protected var _dirty:Vector.<Context3D>;
		
		protected var _width:int;
		protected var _height:int;
		
		public function TextureProxyBase()
		{
			_textures = new Vector.<TextureBase>(8);
			_dirty = new Vector.<Context3D>(8);
		}
		
		public function get hasMipMaps():Boolean
		{
			return _hasMipmaps;
		}
		
		public function get format():String
		{
			return _format;
		}
		
		public function get assetType():String
		{
			return AssetType.TEXTURE;
		}
		
		public function get width():int
		{
			return _width;
		}
		
		public function get height():int
		{
			return _height;
		}
		
		public function getTextureForStage3D(stage3DProxy:Stage3DProxy):TextureBase
		{
			var contextIndex:int = stage3DProxy._stage3DIndex;
			var tex:TextureBase = _textures[contextIndex];
			var context:Context3D = stage3DProxy._context3D;
			
			if (!tex || _dirty[contextIndex] != context) {
				_textures[contextIndex] = tex = createTexture(context);
				_dirty[contextIndex] = context;
				uploadContent(tex);
			}
			
			return tex;
		}
		
		protected function uploadContent(texture:TextureBase):void
		{
			throw new AbstractMethodError();
		}
		
		protected function setSize(width:int, height:int):void
		{
			if (_width != width || _height != height)
				invalidateSize();
			
			_width = width;
			_height = height;
		}
		
		public function invalidateContent():void
		{
			for (var i:int = 0; i < 8; ++i)
				_dirty[i] = null;
		}
		
		protected function invalidateSize():void
		{
			var tex:TextureBase;
			for (var i:int = 0; i < 8; ++i) {
				tex = _textures[i];
				if (tex) {
					tex.dispose();
					_textures[i] = null;
					_dirty[i] = null;
				}
			}
		}
		
		protected function createTexture(context:Context3D):TextureBase
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			for (var i:int = 0; i < 8; ++i) {
				if (_textures[i])
					_textures[i].dispose();
			}
		}
	}
}

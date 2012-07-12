package away3d.materials.utils
{
	import away3d.core.base.*;
	import away3d.materials.*;
	import away3d.textures.*;
	
	import flash.display.*;
	/**
	 * @author robbateman
	 */
	public class DefaultMaterialManager
	{
		private static var _defaultTextureBitmapData:BitmapData;
		private static var _defaultMaterial:TextureMaterial;
		//private static var _defaultMaterialRenderables:Vector.<IMaterialOwner> = new Vector.<IMaterialOwner>();
		
		public static function getDefaultMaterial(renderable:IMaterialOwner):TextureMaterial
		{
			if (!_defaultMaterial)
				createDefaultMaterial();
			
			//_defaultMaterialRenderables.push(renderable);
			
			return _defaultMaterial;
		}
		
		private static function createDefaultMaterial():void
		{
			_defaultTextureBitmapData = new BitmapData(8, 8, false, 0x0);
			
			//create chekerboard
			var i:uint, j:uint;
			for (i=0; i<8; i++) {
				for (j=0; j<8; j++) {
					if ((j & 1) ^ (i & 1))
						_defaultTextureBitmapData.setPixel(i, j, 0XFFFFFF);
				}
			}
			
			_defaultMaterial = new TextureMaterial(new BitmapTexture(_defaultTextureBitmapData));
			_defaultMaterial.mipmap = false;
			_defaultMaterial.smooth = false;
		}
	}
}

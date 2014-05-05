package away3d.materials.utils
{
	import away3d.core.base.IMaterialOwner;
	import away3d.library.assets.AssetType;
	import away3d.materials.MaterialBase;
	import away3d.materials.SegmentMaterial;
	import away3d.materials.TextureMaterial;
	import away3d.textures.BitmapTexture;

	import flash.display.BitmapData;

	public class DefaultMaterialManager
	{
		private static var _defaultTextureBitmapData:BitmapData;
		private static var _defaultTextureMaterial:TextureMaterial;
		private static var _defaultSegmentMaterial:SegmentMaterial;
		private static var _defaultTexture:BitmapTexture;

		public static function getDefaultMaterial(materialOwner:IMaterialOwner = null):MaterialBase
		{
			if (materialOwner != null && materialOwner.assetType == AssetType.LINE_SUB_MESH) {
				if (!_defaultSegmentMaterial)
					createDefaultSegmentMaterial();

				return _defaultSegmentMaterial;
			} else {
				if (!_defaultTextureMaterial)
					createDefaultTextureMaterial();

				return _defaultTextureMaterial;
			}
		}

		public static function getDefaultTexture(materialOwner:IMaterialOwner = null):BitmapTexture
		{
			if (!_defaultTexture)
				createDefaultTexture();

			return _defaultTexture;
		}

		private static function createDefaultTexture():void
		{
			_defaultTextureBitmapData = createCheckeredBitmapData();
			_defaultTexture = new BitmapTexture(_defaultTextureBitmapData, false);
			_defaultTexture.name = "defaultTexture";
		}

		public static function createCheckeredBitmapData():BitmapData
		{
			var b:BitmapData = new BitmapData(8, 8, false, 0x000000);

			//create chekerboard
			var i:Number, j:Number;
			for (i = 0; i < 8; i++) {
				for (j = 0; j < 8; j++) {
					if ((j & 1) ^ (i & 1)) {
						b.setPixel(i, j, 0XFFFFFF);
					}
				}
			}

			return b;
		}

		private static function createDefaultTextureMaterial():void
		{
			if (!_defaultTexture)
				createDefaultTexture();

			_defaultTextureMaterial = new TextureMaterial(_defaultTexture);
			_defaultTextureMaterial.mipmap = false;
			_defaultTextureMaterial.smooth = false;
			_defaultTextureMaterial.name = "defaultTextureMaterial";
		}

		private static function createDefaultSegmentMaterial():void
		{
			_defaultSegmentMaterial = new SegmentMaterial();
			_defaultSegmentMaterial.name = "defaultSegmentMaterial";
		}
	}
}
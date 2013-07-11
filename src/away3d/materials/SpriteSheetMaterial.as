package away3d.materials
{
	import away3d.arcane;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;
	
	/**
	 * SpriteSheetMaterial is a material required for a SpriteSheetAnimator if you have an animation spreaded over more maps
	 * and/or have animated normalmaps, specularmaps
	 */
	
	public class SpriteSheetMaterial extends TextureMaterial
	{
		//private var currentID:uint = 0;
		
		private var _diffuses:Vector.<Texture2DBase>;
		private var _normals:Vector.<Texture2DBase>;
		private var _speculars:Vector.<Texture2DBase>;
		
		private var _TBDiffuse:Texture2DBase;
		private var _TBNormal:Texture2DBase;
		private var _TBSpecular:Texture2DBase;
		
		private var _currentMapID:uint;
		
		/**
		 * Creates a new SpriteSheetMaterial required for a SpriteSheetAnimator
		 *
		 * (the sprite sheet maps of each textures must have power of 2 sizes)
		 * @param diffuses        Vector.&lt;Texture2DBase&gt; : One or more Texture2DBase representing the diffuse information of the spritesheets. Must hold at least 1 diffuse.
		 * @param normals        Vector.&lt;Texture2DBase&gt; : One or more Texture2DBase representing the normal information of the spritesheets. Default is null. If not null, must hold same amount of textures as diffuses.
		 * @param speculars        Vector.&lt;Texture2DBase&gt; : One or more Texture2DBase representing the specular information of the spritesheets. Default is null. If not null, must hold same amount of textures as diffuses.
		 * @param smooth        Boolean : Material smoothing. Default is true.
		 * @param repeat        Boolean : Material repeat. Default is false.
		 * @param mipmap        Boolean : Material mipmap. Set it to false if the animation graphics have thin lines or text information in them. Default is true.
		 */
		
		public function SpriteSheetMaterial(diffuses:Vector.<Texture2DBase>, normals:Vector.<Texture2DBase> = null, speculars:Vector.<Texture2DBase> = null, smooth:Boolean = true, repeat:Boolean = false, mipmap:Boolean = true)
		{
			
			_diffuses = diffuses;
			_normals = normals;
			_speculars = speculars;
			
			initTextures();
			
			super(_TBDiffuse, smooth, repeat, mipmap);
			
			if (_TBNormal)
				this.normalMap = _TBNormal;
			
			if (_TBSpecular)
				this.specularMap = _TBSpecular;
		
		}
		
		private function initTextures():void
		{
			if (!_diffuses || _diffuses.length == 0)
				throw new Error("you must pass at least one bitmapdata into diffuses param!");
			
			_TBDiffuse = _diffuses[0];
			
			if (_normals && _normals.length > 0) {
				if (_normals.length != _diffuses.length)
					throw new Error("The amount of normals bitmapDatas must be same as the amount of diffuses param!");
				
				_TBNormal = _normals[0];
			}
			
			if (_speculars && _speculars.length > 0) {
				if (_speculars.length != _diffuses.length)
					throw new Error("The amount of normals bitmapDatas must be same as the amount of diffuses param!");
				
				_TBSpecular = _speculars[0];
			}
			
			_currentMapID = 0;
		
		}
		
		arcane function swap(mapID:uint = 0):Boolean
		{
			
			if (_currentMapID != mapID) {
				
				_currentMapID = mapID;
				
				_TBDiffuse = _diffuses[mapID];
				this.texture = _TBDiffuse;
				
				if (_TBNormal)
					this.normalMap = _TBNormal = _normals[mapID];
				
				if (_TBSpecular)
					this.specularMap = _TBSpecular = _speculars[mapID];
				
				return true;
				
			}
			
			return false;
		
		}
	
	}
}

package away3d.materials
{
	import away3d.arcane;
	import away3d.textures.BitmapTexture;

	import flash.display.BitmapData;

	use namespace arcane;

	/**
	* SpriteSheetMaterial is a material required for a SpriteSheetAnimator if you have an animation spreaded over more maps
	* and/or have animated normalmaps, specularmaps
	*/

	public class SpriteSheetMaterial extends TextureMaterial
	{
		private var currentID:uint = 0;

		private var _diffuses : Vector.<BitmapData>; 
		private var _normals : Vector.<BitmapData>;
		private var _speculars : Vector.<BitmapData>;

		private var _TBDiffuse : BitmapTexture; 
		private var _TBNormal : BitmapTexture;
		private var _TBSpecular : BitmapTexture;

		private var _currentMapID : uint;

		/**
		* Creates a new SpriteSheetMaterial required for a SpriteSheetAnimator
		* 
		* @param diffuses 		Vector.<BitmapData> : One or more diffuse bitmapdata's spritesheets of exact same power of 2 sizes. Must hold at least 1 diffuse.
		* @param normals 		Vector.<BitmapData> : One or more normalmaps bitmapdata's spritesheets of exact same power of 2 sizes. Default is null.
		* @param speculars 		Vector.<BitmapData> : One or more specular bitmapdata's spritesheets of exact same power of 2 sizes. Default is null.
		* @param smooth 		Boolean : Material smoothing. Default is true.
		* @param repeat 		Boolean : Material repeat. Default is false.
		* @param mipmap 		Boolean : Material mipmap. Set it to false if the animation graphics have thin lines or text information in them. Default is true. 
		*/

		public function SpriteSheetMaterial(diffuses : Vector.<BitmapData>, 
								normals : Vector.<BitmapData> = null,
								speculars : Vector.<BitmapData> = null,
								smooth : Boolean = true, repeat : Boolean = false, mipmap : Boolean = true){

			_diffuses = diffuses;
			_normals = normals;
			_speculars = speculars;

			initTextures();	
 
			super(_TBDiffuse, smooth, repeat, mipmap);

		}

		private function initTextures(mapID:uint = 0) : void
		{
			if(!_diffuses || _diffuses.length == 0)
				throw new Error("you must pass at least one bitmapdata into diffuses param!");
			
			_TBDiffuse =  new BitmapTexture(_diffuses[0]);
				

			if(_normals && _normals.length > 0){
				if(_normals.length != _diffuses.length)
					throw new Error("The amount of normals bitmapDatas must be same as the amount of diffuses param!");

				_TBNormal = new BitmapTexture(_normals[0]);
			}

			if(_speculars && _speculars.length > 0){
				if(_speculars.length != _diffuses.length)
					throw new Error("The amount of normals bitmapDatas must be same as the amount of diffuses param!");

				_TBSpecular = new BitmapTexture(_speculars[0]);
			}

			_currentMapID = 0;
  
		}

		arcane function swap(mapID:uint = 0) : Boolean
		{

			if(_currentMapID != mapID) {

				_currentMapID = mapID;
			
				 _TBDiffuse.bitmapData = _diffuses[mapID];

				if(_TBNormal) _TBNormal.bitmapData = _normals[mapID];

				if(_TBSpecular) _TBSpecular.bitmapData = _speculars[mapID];

				return true;

			}

			return false;

		}
		 
	}
}
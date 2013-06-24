package away3d.tools.helpers
{
	import away3d.animators.data.SpriteSheetAnimationFrame;
	import away3d.animators.nodes.SpriteSheetClipNode;
	import away3d.textures.BitmapTexture;
	import away3d.textures.Texture2DBase;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
	 * SpriteSheetHelper, a class to ease sprite sheet animation data generation
	 */
	public class SpriteSheetHelper
	{
		function SpriteSheetHelper()
		{
		}
		
		/**
		 * Generates and returns one or more "sprite sheets" BitmapTexture from a given movieClip
		 *
		 * @param sourceMC                MovieClip: A movieclip with timeline animation
		 * @param cols                    uint: Howmany cells along the u axis.
		 * @param rows                    uint: Howmany cells along the v axis.
		 * @param width                uint: The result bitmapData(s) width.
		 * @param height                uint: The result bitmapData(s) height.
		 * @param transparent                Boolean: if the bitmapData(s) must be transparent.
		 * @param backgroundColor            uint: the bitmapData(s) background color if not transparent.
		 *
		 * @return Vector.&lt;Texture2DBase&gt;    The generated Texture2DBase vector for the SpriteSheetMaterial.
		 */
		public function generateFromMovieClip(sourceMC:MovieClip, cols:uint, rows:uint, width:uint, height:uint, transparent:Boolean = false, backgroundColor:uint = 0):Vector.<Texture2DBase>
		{
			var spriteSheets:Vector.<Texture2DBase> = new Vector.<Texture2DBase>();
			var framesCount:uint = sourceMC.totalFrames;
			var i:uint = framesCount;
			var w:uint = width;
			var h:uint = height;
			
			if (!TextureUtils.isPowerOfTwo(w))
				w = TextureUtils.getBestPowerOf2(w);
			if (!TextureUtils.isPowerOfTwo(h))
				h = TextureUtils.getBestPowerOf2(h);
			
			var spriteSheet:BitmapData;
			var destCellW:Number = Math.round(h/cols);
			var destCellH:Number = Math.round(w/rows);
			//var cellRect:Rectangle = new Rectangle(0, 0, destCellW, destCellH);
			
			var mcFrameW:uint = sourceMC.width;
			var mcFrameH:uint = sourceMC.height;
			
			var sclw:Number = destCellW/mcFrameW;
			var sclh:Number = destCellH/mcFrameH;
			var t:Matrix = new Matrix();
			t.scale(sclw, sclh);
			
			var tmpCache:BitmapData = new BitmapData(mcFrameW*sclw, mcFrameH*sclh, transparent, transparent? 0x00FFFFFF : backgroundColor);
			
			var u:uint, v:uint;
			var cellsPerMap:uint = cols*rows;
			var maps:uint = framesCount/cellsPerMap;
			if (maps < framesCount/cellsPerMap)
				maps++;
			
			var pastePoint:Point = new Point();
			var frameNum:uint = 0;
			var bitmapTexture:BitmapTexture;
			
			while (maps--) {
				
				u = v = 0;
				spriteSheet = new BitmapData(w, h, transparent, transparent? 0x00FFFFFF : backgroundColor);
				
				for (i = 0; i < cellsPerMap; i++) {
					frameNum++;
					if (frameNum <= framesCount) {
						pastePoint.x = Math.round(destCellW*u);
						pastePoint.y = Math.round(destCellH*v);
						sourceMC.gotoAndStop(frameNum);
						tmpCache.draw(sourceMC, t, null, "normal", tmpCache.rect, true);
						spriteSheet.copyPixels(tmpCache, tmpCache.rect, pastePoint);
						
						if (transparent)
							tmpCache.fillRect(tmpCache.rect, 0x00FFFFFF);
						
						u++;
						if (u == cols) {
							u = 0;
							v++;
						}
						
					} else
						break;
					
				}
				
				bitmapTexture = new BitmapTexture(spriteSheet);
				spriteSheets.push(bitmapTexture);
			}
			
			tmpCache.dispose();
			
			return spriteSheets;
		}
		
		/**
		 * Returns a SpriteSheetClipNode to pass to animator from animation id , cols and rows.
		 * @param animID                String:The name of the animation
		 * @param cols                    uint: Howmany cells along the u axis.
		 * @param rows                    uint: Howmany cells along the v axis.
		 * @param mapCount                uint: If the same animation is spread over more bitmapDatas. Howmany bimapDatas. Default is 1.
		 * @param from                    uint: The offset start if the animation first frame isn't in first cell top left on the map. zero based. Default is 0.
		 * @param to                    uint: The last cell if the animation last frame cell isn't located down right on the map. zero based. Default is 0.
		 *
		 * @return SpriteSheetClipNode        SpriteSheetClipNode: The SpriteSheetClipNode filled with the data
		 */
		public function generateSpriteSheetClipNode(animID:String, cols:uint, rows:uint, mapCount:uint = 1, from:uint = 0, to:uint = 0):SpriteSheetClipNode
		{
			var spriteSheetClipNode:SpriteSheetClipNode = new SpriteSheetClipNode();
			spriteSheetClipNode.name = animID;
			
			var u:uint, v:uint;
			var framesCount:uint = cols*rows;
			
			if (mapCount < 1)
				mapCount = 1;
			if (to == 0 || to < from || to > framesCount*mapCount)
				to = cols*rows*mapCount;
			
			if (from > to)
				throw new Error("Param 'from' must be lower than the 'to' param.");
			
			var scaleV:Number = 1/rows;
			var scaleU:Number = 1/cols;
			
			var frame:SpriteSheetAnimationFrame;
			
			var i:uint, j:uint;
			var animFrames:uint = 0;
			
			for (i = 0; i < mapCount; ++i) {
				u = v = 0;
				
				for (j = 0; j < framesCount; ++j) {
					
					if (animFrames >= from && animFrames < to) {
						
						frame = new SpriteSheetAnimationFrame();
						frame.offsetU = scaleU*u;
						frame.offsetV = scaleV*v;
						frame.scaleU = scaleU;
						frame.scaleV = scaleV;
						frame.mapID = i;
						
						spriteSheetClipNode.addFrame(frame, 16);
					}
					
					if (animFrames == to)
						return spriteSheetClipNode;
					
					animFrames++;
					
					u++;
					if (u == cols) {
						u = 0;
						v++;
					}
				}
			}
			
			return spriteSheetClipNode;
		}
	}
}

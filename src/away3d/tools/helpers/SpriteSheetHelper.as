package away3d.tools.helpers
{
	import away3d.animators.SpriteSheetAnimationSet;
	import away3d.animators.nodes.SpriteSheetClipNode;
	import away3d.animators.data.SpriteSheetAnimationFrame;

	/**
	 * SpriteSheetHelper, a class to ease sprite sheet animation data generation
	 */
	public class SpriteSheetHelper
	{
		function SpriteSheetHelper(){}

		/**
		 * Returns a SpriteSheetAnimationSet to pass to animator from animation id , cols and rows.
		 * @param animID 				String:The name of the animation
		 * @param cols 					uint: Howmany cells along the u axis.
		 * @param rows 					uint: Howmany cells along the v axis.
		 * @param mapCount 				uint: If the same animation is spread over more bitmapDatas. Howmany bimapDatas. Default is 1.
		 * @param from 					uint: The offset start if the animation first frame isn't in first cell top left on the map. zero based. Default is 0.
		 * @param to 					uint: The last cell if the animation last frame cell isn't located down right on the map. zero based. Default is 0.
		 * 
		 * @return SpriteSheetAnimationSet 	SpriteSheetAnimationSet: The SpriteSheetAnimationSet filled with the data
		 */
		public function generateAnimationSet(animID:String, cols:uint, rows:uint, mapCount:uint = 1, from:uint = 0, to:uint = 0) : SpriteSheetAnimationSet
		{
			var spriteSheetAnimationSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
			var node:SpriteSheetClipNode = new SpriteSheetClipNode();
			node.name = animID;
			
			spriteSheetAnimationSet.addAnimation(node);
			 
			var u:uint, v:uint;
			var framesCount:uint = cols*rows;
 
			if(to == 0 || to < from || to > framesCount ) to = framesCount;
			if(mapCount<1) mapCount = 1;
			if(from > to)
				throw new Error("Param 'from' must be lower than the 'to' param.")

			var scaleV:Number  = 1/rows;
			var scaleU:Number  = 1/cols;
			
			var frame:SpriteSheetAnimationFrame;

			var i:uint, j:uint;

			for(i = 0;i<mapCount; ++i){
				u = v = 0;

				for(j = 0;j<framesCount; ++j){

					if(j >= from){

						frame = new SpriteSheetAnimationFrame();
						frame.offsetU = scaleU*u;
						frame.offsetV = scaleV*v;
						frame.scaleU = scaleU;
						frame.scaleV = scaleV;
						frame.mapID = i;

						node.addFrame(frame, 16);
					}
					
					if(j == to) break;

					u++;
					if(u == cols){
						u = 0;
						v++;
					}
				}
			}

			return spriteSheetAnimationSet;
		}
	}

}
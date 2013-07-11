package away3d.animators.data
{
	
	/**
	 * A value object for a single frame of animation in a <code>SpriteSheetClipNode</code> object.
	 *
	 * @see away3d.animators.nodes.SpriteSheetClipNode
	 */
	public class SpriteSheetAnimationFrame
	{
		/**
		 * The u-component offset of the spritesheet frame.
		 */
		public var offsetU:Number;
		
		/**
		 * The v-component offset of the spritesheet frame.
		 */
		public var offsetV:Number;
		
		/**
		 * The u-component scale of the spritesheet frame.
		 */
		public var scaleU:Number;
		
		/**
		 * The v-component scale of the spritesheet frame.
		 */
		public var scaleV:Number;
		
		/**
		 * The mapID, zero based, if the animation is spreaded over more bitmapData's
		 */
		public var mapID:uint;
		
		/**
		 * Creates a new <code>SpriteSheetAnimationFrame</code> object.
		 *
		 * @param offsetU    The u-component offset of the spritesheet frame.
		 * @param offsetV    The v-component offset of the spritesheet frame.
		 * @param scaleU    The u-component scale of the spritesheet frame.
		 * @param scaleV    The v-component scale of the spritesheet frame.
		 * @param mapID    The v-component scale of the spritesheet frame.
		 */
		public function SpriteSheetAnimationFrame(offsetU:Number = 0, offsetV:Number = 0, scaleU:Number = 1, scaleV:Number = 1, mapID:uint = 0)
		{
			this.offsetU = offsetU;
			this.offsetV = offsetV;
			this.scaleU = scaleU;
			this.scaleV = scaleV;
			this.mapID = mapID;
		}
	}
}

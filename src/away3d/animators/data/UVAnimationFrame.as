package away3d.animators.data
{
	
	/**
	 * A value object for a single frame of animation in a <code>UVClipNode</code> object.
	 *
	 * @see away3d.animators.nodes.UVClipNode
	 */
	public class UVAnimationFrame
	{
		/**
		 * The u-component offset of the UV animation frame.
		 */
		public var offsetU:Number;
		
		/**
		 * The v-component offset of the UV animation frame.
		 */
		public var offsetV:Number;
		
		/**
		 * The u-component scale of the UV animation frame.
		 */
		public var scaleU:Number;
		
		/**
		 * The v-component scale of the UV animation frame.
		 */
		public var scaleV:Number;
		
		/**
		 * The rotation value (in degrees) of the UV animation frame.
		 */
		public var rotation:Number;
		
		/**
		 * Creates a new <code>UVAnimationFrame</code> object.
		 *
		 * @param offsetU The u-component offset of the UV animation frame.
		 * @param offsetV The v-component offset of the UV animation frame.
		 * @param scaleU The u-component scale of the UV animation frame.
		 * @param scaleV The v-component scale of the UV animation frame.
		 * @param rotation The rotation value (in degrees) of the UV animation frame.
		 */
		public function UVAnimationFrame(offsetU:Number = 0, offsetV:Number = 0, scaleU:Number = 1, scaleV:Number = 1, rotation:Number = 0)
		{
			this.offsetU = offsetU;
			this.offsetV = offsetV;
			this.scaleU = scaleU;
			this.scaleV = scaleV;
			this.rotation = rotation;
		}
	}
}

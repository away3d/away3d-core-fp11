package away3d.primitives.data
{
	import away3d.core.base.data.Vertex;
	import away3d.arcane;
	
	use namespace arcane;
	
	/**
	 * A nurbvertex that simply extends vertex with a w weight property.
	 * Properties x, y, z and w represent a 3d point in space with nurb weighting.
	 */
	public class NURBSVertex extends Vertex
	{
		
		private var _w:Number;
		
		public function get w():Number
		{
			return _w;
		}
		
		public function set w(w:Number):void
		{
			_w = w;
		}
		
		/**
		 * Creates a new <code>Vertex</code> object.
		 *
		 * @param    x    [optional]    The local x position of the vertex. Defaults to 0.
		 * @param    y    [optional]    The local y position of the vertex. Defaults to 0.
		 * @param    z    [optional]    The local z position of the vertex. Defaults to 0.
		 * @param    w    [optional]    The local w weight of the vertex. Defaults to 1.
		 */
		public function NURBSVertex(x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 1)
		{
			_w = w;
			super(x, y, z);
		}
	}
}

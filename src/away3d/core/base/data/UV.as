package away3d.core.base.data
{
	
	/**
	 * Texture coordinates value object.
	 */
	public class UV
	{
		private var _u:Number;
		private var _v:Number;
		
		/**
		 * Creates a new <code>UV</code> object.
		 *
		 * @param    u        [optional]    The horizontal coordinate of the texture value. Defaults to 0.
		 * @param    v        [optional]    The vertical coordinate of the texture value. Defaults to 0.
		 */
		public function UV(u:Number = 0, v:Number = 0)
		{
			_u = u;
			_v = v;
		}
		
		/**
		 * Defines the vertical coordinate of the texture value.
		 */
		public function get v():Number
		{
			return _v;
		}
		
		public function set v(value:Number):void
		{
			_v = value;
		}
		
		/**
		 * Defines the horizontal coordinate of the texture value.
		 */
		public function get u():Number
		{
			return _u;
		}
		
		public function set u(value:Number):void
		{
			_u = value;
		}
		
		/**
		 * returns a new UV value Object
		 */
		public function clone():UV
		{
			return new UV(_u, _v);
		}
		
		/**
		 * returns the value object as a string for trace/debug purpose
		 */
		public function toString():String
		{
			return _u + "," + _v;
		}
	
	}
}

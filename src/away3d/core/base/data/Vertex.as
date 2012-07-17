package away3d.core.base.data
{
	/**
	* Vertex value object.
	*/
    public class Vertex
    {
		private var _x:Number;
		private var _y:Number;
		private var _z:Number;
		private var _index:uint;
		
		/**
		* Creates a new <code>Vertex</code> value object.
		*
		* @param	x			[optional]	The x value. Defaults to 0.
		* @param	y			[optional]	The y value. Defaults to 0.
		* @param	z			[optional]	The z value. Defaults to 0.
		* @param	index		[optional]	The index value. Defaults is NaN.
		*/
        public function Vertex(x:Number = 0, y:Number = 0, z:Number = 0, index:uint = NaN)
        {
            _x = x;
            _y = y;
			_z = z;
			_index = index;
        }
		/**
		* To define/store the index of value object
		* @param	ind		The index
		*/
        public function set index(ind:uint):void
        {
            _index = ind;
        }
		public function get index():uint
        {
            return _index;
        }
		
		/**
		* To define/store the x value of the value object
		* @param	value		The x value
		*/
		public function get x():Number
        {
            return _x;
        }
        public function set x(value:Number):void
        {
            _x = value;
        }
		
		/**
		* To define/store the y value of the value object
		* @param	value		The y value
		*/
        public function get y():Number
		{
            return _y;
        }
        public function set y(value:Number):void
        {
            _y = value;
        }
		
		/**
		* To define/store the z value of the value object
		* @param	value		The z value
		*/
        public function get z():Number
        {
            return _z;
        }

        public function set z(value:Number):void
        {
            _z = value;
        }
		
		/**
		 * returns a new Vertex value Object
		 */
		public function clone():Vertex
  		{
			return new Vertex(_x, _y, _z);
		}
		
		/**
		 * returns the value object as a string for trace/debug purpose
		 */
		public function toString():String
  		{
			return _x+","+_y+","+ _z;
		}
		
		 
    }
}
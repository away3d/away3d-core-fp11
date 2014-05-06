/**
 * A Box object is an area defined by its position, as indicated by its
 * top-left-front corner point(<i>x</i>, <i>y</i>, <i>z</i>) and by its width,
 * height and depth.
 *
 *
 * <p>The <code>x</code>, <code>y</code>, <code>z</code>, <code>width</code>,
 * <code>height</code> <code>depth</code> properties of the Box class are
 * independent of each other; changing the value of one property has no effect
 * on the others. However, the <code>right</code>, <code>bottom</code> and
 * <code>back</code> properties are integrally related to those six
 * properties. For example, if you change the value of the <code>right</code>
 * property, the value of the <code>width</code> property changes; if you
 * change the <code>bottom</code> property, the value of the
 * <code>height</code> property changes. </p>
 *
 * <p>The following methods and properties use Box objects:</p>
 *
 * <ul>
 *   <li>The <code>bounds</code> property of the DisplayObject class</li>
 * </ul>
 *
 * <p>You can use the <code>new Box()</code> constructor to create a
 * Box object.</p>
 *
 * <p><b>Note:</b> The Box class does not define a cubic Shape
 * display object.
 */
package away3d.core.math {
	import flash.geom.Vector3D;

	public class Box {
		private var _size:Vector3D;
		private var _bottomRightBack:Vector3D;
		private var _topLeftFront:Vector3D;
		private var _height:Number;
		private var _width:Number;
		private var _depth:Number;
		private var _x:Number;
		private var _y:Number;
		private var _z:Number

		/**
		 * The sum of the <code>z</code> and <code>depth</code> properties.
		 */
		public function get back():Number
		{
			return _z + _depth;
		}

		public function set back(val:Number):void
		{
			_depth = val - _z;
		}

		/**
		 * The sum of the <code>y</code> and <code>height</code> properties.
		 */
		public function get bottom():Number
		{
			return _y + _height;
		}

		public function set bottom(val:Number):void
		{
			_height = val - _y;
		}

		/**
		 * The location of the Box object's bottom-right corner, determined by the
		 * values of the <code>right</code> and <code>bottom</code> properties.
		 */
		public function get bottomRightBack():Vector3D
		{
			if (!_bottomRightBack) _bottomRightBack = new Vector3D();

			_bottomRightBack.x = _x + _width;
			_bottomRightBack.y = _y + _height;
			_bottomRightBack.z = _z + _depth;

			return _bottomRightBack;
		}

		/**
		 * The <i>z</i> coordinate of the top-left-front corner of the box. Changing
		 * the <code>front</code> property of a Box object has no effect on the
		 * <code>x</code>, <code>y</code>, <code>width</code> and <code>height</code>
		 * properties. However it does affect the <code>depth</code> property,
		 * whereas changing the <code>z</code> value does <i>not</i> affect the
		 * <code>depth</code> property.
		 *
		 * <p>The value of the <code>left</code> property is equal to the value of
		 * the <code>x</code> property.</p>
		 */
		public function get front():Number
		{
			return _z;
		}

		public function set front(val:Number):void
		{
			_depth += _z - val;
			_z = val;
		}

		/**
		 * The <i>x</i> coordinate of the top-left corner of the box. Changing the
		 * <code>left</code> property of a Box object has no effect on the
		 * <code>y</code> and <code>height</code> properties. However it does affect
		 * the <code>width</code> property, whereas changing the <code>x</code> value
		 * does <i>not</i> affect the <code>width</code> property.
		 *
		 * <p>The value of the <code>left</code> property is equal to the value of
		 * the <code>x</code> property.</p>
		 */
		public function get left():Number
		{
			return _x;
		}

		public function set left(val:Number):void
		{
			_width += _x - val;
			_x = val;
		}

		/**
		 * The sum of the <code>x</code> and <code>width</code> properties.
		 */
		public function get right():Number
		{
			return _x + _width;
		}

		public function set right(val:Number):void
		{
			_width = val - _x;
		}

		/**
		 * The size of the Box object, expressed as a Vector3D object with the
		 * values of the <code>width</code>, <code>height</code> and
		 * <code>depth</code> properties.
		 */
		public function get size():Vector3D
		{
			if (!_size)	_size = new Vector3D();

			_size.x = _width;
			_size.y = _height;
			_size.z = _depth;

			return _size;
		}

		/**
		 * The <i>y</i> coordinate of the top-left-front corner of the box. Changing
		 * the <code>top</code> property of a Box object has no effect on the
		 * <code>x</code> and <code>width</code> properties. However it does affect
		 * the <code>height</code> property, whereas changing the <code>y</code>
		 * value does <i>not</i> affect the <code>height</code> property.
		 *
		 * <p>The value of the <code>top</code> property is equal to the value of the
		 * <code>y</code> property.</p>
		 */
		public function get top():Number
		{
			return _y;
		}

		public function set top(val:Number):void
		{
			_height += (_y - val);
			_y = val;
		}

		/**
		 * The location of the Box object's top-left-front corner, determined by the
		 * <i>x</i>, <i>y</i> and <i>z</i> coordinates of the point.
		 */
		public function get topLeftFront():Vector3D
		{
			if (!_topLeftFront)	_topLeftFront = new Vector3D();

			_topLeftFront.x = _x;
			_topLeftFront.y = _y;
			_topLeftFront.z = _z;

			return _topLeftFront;
		}

		/**
		 * Creates a new Box object with the top-left-front corner specified by the
		 * <code>x</code>, <code>y</code> and <code>z</code> parameters and with the
		 * specified <code>width</code>, <code>height</code> and <code>depth</code>
		 * parameters. If you call this public without parameters, a box with
		 * <code>x</code>, <code>y</code>, <code>z</code>, <code>width</code>,
		 * <code>height</code> and <code>depth</code> properties set to 0 is created.
		 *
		 * @param x      The <i>x</i> coordinate of the top-left-front corner of the
		 *               box.
		 * @param y      The <i>y</i> coordinate of the top-left-front corner of the
		 *               box.
		 * @param z      The <i>z</i> coordinate of the top-left-front corner of the
		 *               box.
		 * @param width  The width of the box, in pixels.
		 * @param height The height of the box, in pixels.
		 * @param depth The depth of the box, in pixels.
		 */
		function Box(x:Number = 0, y:Number = 0, z:Number = 0, width:Number = 0, height:Number = 0, depth:Number = 0)
		{
			_x = x;
			_y = y;
			_z = z;
			_width = width;
			_height = height;
			_depth = depth;
		}

		/**
		 * Returns a new Box object with the same values for the <code>x</code>,
		 * <code>y</code>, <code>z</code>, <code>width</code>, <code>height</code>
		 * and <code>depth</code> properties as the original Box object.
		 *
		 * @return A new Box object with the same values for the <code>x</code>,
		 *         <code>y</code>, <code>z</code>, <code>width</code>,
		 *         <code>height</code> and <code>depth</code> properties as the
		 *         original Box object.
		 */
		public function clone():Box
		{
			return new Box(_x, _y, _z, _width, _height, _depth);
		}

		/**
		 * Determines whether the specified position is contained within the cubic
		 * region defined by this Box object.
		 *
		 * @param x The <i>x</i> coordinate(horizontal component) of the position.
		 * @param y The <i>y</i> coordinate(vertical component) of the position.
		 * @param z The <i>z</i> coordinate(longitudinal component) of the position.
		 * @return A value of <code>true</code> if the Box object contains the
		 *         specified position; otherwise <code>false</code>.
		 */
		public function contains(x:Number, y:Number, z:Number):Boolean
		{
			return (_x <= x && _x + _width >= x && _y <= y && _y + _height >= y && _z <= z && _z + _depth >= z);
		}

		/**
		 * Determines whether the specified position is contained within the cubic
		 * region defined by this Box object. This method is similar to the
		 * <code>Box.contains()</code> method, except that it takes a Vector3D
		 * object as a parameter.
		 *
		 * @param position The position, as represented by its <i>x</i>, <i>y</i> and
		 *                 <i>z</i> coordinates.
		 * @return A value of <code>true</code> if the Box object contains the
		 *         specified position; otherwise <code>false</code>.
		 */
		public function containsPoint(position:Vector3D):Boolean
		{
			return (_x <= position.x && _x + _width >= position.x && _y <= position.y && _y + _height >= position.y && _z <= position.z && _z + _depth >= position.z);
		}

		/**
		 * Determines whether the Box object specified by the <code>box</code>
		 * parameter is contained within this Box object. A Box object is said to
		 * contain another if the second Box object falls entirely within the
		 * boundaries of the first.
		 *
		 * @param box The Box object being checked.
		 * @return A value of <code>true</code> if the Box object that you specify
		 *         is contained by this Box object; otherwise <code>false</code>.
		 */
		public function containsRect(box:Box):Boolean
		{
			return (_x <= box.x && _x + _width >= box.x + box.width && _y <= box.y && _y + _height >= box.y + box.height && _z <= box.z && _z + _depth >= box.z + box.depth)
		}

		/**
		 * Copies all of box data from the source Box object into the calling
		 * Box object.
		 *
		 * @param sourceBox The Box object from which to copy the data.
		 */
		public function copyFrom(sourceBox:Box):void
		{
			//TODO
		}

		/**
		 * Determines whether the object specified in the <code>toCompare</code>
		 * parameter is equal to this Box object. This method compares the
		 * <code>x</code>, <code>y</code>, <code>z</code>, <code>width</code>,
		 * <code>height</code> and <code>depth</code> properties of an object against
		 * the same properties of this Box object.
		 *
		 * @param toCompare The box to compare to this Box object.
		 * @return A value of <code>true</code> if the object has exactly the same
		 *         values for the <code>x</code>, <code>y</code>, <code>z</code>,
		 *         <code>width</code>, <code>height</code> and <code>depth</code>
		 *         properties as this Box object; otherwise <code>false</code>.
		 */
		public function equals(toCompare:Box):Boolean
		{
			return (_x == toCompare.x && _y == toCompare.y && _z == toCompare.z && _width == toCompare.width && _height == toCompare.height && _depth == toCompare.depth)
		}

		/**
		 * Increases the size of the Box object by the specified amounts, in
		 * pixels. The center point of the Box object stays the same, and its
		 * size increases to the left and right by the <code>dx</code> value, to
		 * the top and the bottom by the <code>dy</code> value, and to
		 * the front and the back by the <code>dz</code> value.
		 *
		 * @param dx The value to be added to the left and the right of the Box
		 *           object. The following equation is used to calculate the new
		 *           width and position of the box:
		 * @param dy The value to be added to the top and the bottom of the Box
		 *           object. The following equation is used to calculate the new
		 *           height and position of the box:
		 * @param dz The value to be added to the front and the back of the Box
		 *           object. The following equation is used to calculate the new
		 *           depth and position of the box:
		 */
		public function inflate(dx:Number, dy:Number, dz:Number):void
		{
			_x -= dx/2;
			_y -= dy/2;
			_z -= dz/2;
			_width += dx/2;
			_height += dy/2;
			_depth += dz/2;
		}

		/**
		 * Increases the size of the Box object. This method is similar to the
		 * <code>Box.inflate()</code> method except it takes a Vector3D object as
		 * a parameter.
		 *
		 * <p>The following two code examples give the same result:</p>
		 *
		 * @param delta The <code>x</code> property of this Vector3D object is used to
		 *              increase the horizontal dimension of the Box object.
		 *              The <code>y</code> property is used to increase the vertical
		 *              dimension of the Box object.
		 *              The <code>z</code> property is used to increase the
		 *              longitudinal dimension of the Box object.
		 */
		public function inflatePoint(delta:Vector3D):void
		{
			_x -= delta.x/2;
			_y -= delta.y/2;
			_z -= delta.z/2;
			_width += delta.x/2;
			_height += delta.y/2;
			_depth += delta.z/2;
		}

		/**
		 * If the Box object specified in the <code>toIntersect</code> parameter
		 * intersects with this Box object, returns the area of intersection
		 * as a Box object. If the boxes do not intersect, this method returns an
		 * empty Box object with its properties set to 0.
		 *
		 * @param toIntersect The Box object to compare against to see if it
		 *                    intersects with this Box object.
		 * @param    b        [optional] A box holder to prevent make new Box instance if already exists. Default is null.
		 * @return A Box object that equals the area of intersection. If the
		 *         boxes do not intersect, this method returns an empty Box
		 *         object; that is, a box with its <code>x</code>, <code>y</code>,
		 *         <code>z</code>, <code>width</code>,  <code>height</code>, and
		 *         <code>depth</code> properties set to 0.
		 */
		public function intersection(toIntersect:Box, b:Box = null):Box
		{
			if(!b) b = new Box();

			if (intersects(toIntersect)) {
				if (_x > toIntersect.x) {
					b.x = _x;
					b.width = toIntersect.x - _x + toIntersect.width;

					if (b.width > _width)
						b.width = _width;
				} else {
					b.x = toIntersect.x;
					b.width = _x - toIntersect.x + _width;

					if (b.width > toIntersect.width)
						b.width = toIntersect.width;
				}

				if (_y > toIntersect.y) {
					b.y = _y;
					b.height = toIntersect.y - _y + toIntersect.height;

					if (b.height > _height)
						b.height = _height;
				} else {
					b.y = toIntersect.y;
					b.height = _y - toIntersect.y + _height;

					if (b.height > toIntersect.height)
						b.height = toIntersect.height;
				}


				if (_z > toIntersect.z) {
					b.z = _z;
					b.depth = toIntersect.z - _z + toIntersect.depth;

					if (b.depth > _depth)
						b.depth = _depth;
				} else {
					b.z = toIntersect.z;
					b.depth = _z - toIntersect.z + _depth;

					if (b.depth > toIntersect.depth)
						b.depth = toIntersect.depth;
				}

				return b;
			}

			return b;
		}

		/**
		 * Determines whether the object specified in the <code>toIntersect</code>
		 * parameter intersects with this Box object. This method checks the
		 * <code>x</code>, <code>y</code>, <code>z</code>, <code>width</code>,
		 * <code>height</code>, and <code>depth</code> properties of the specified
		 * Box object to see if it intersects with this Box object.
		 *
		 * @param toIntersect The Box object to compare against this Box object.
		 * @return A value of <code>true</code> if the specified object intersects
		 *         with this Box object; otherwise <code>false</code>.
		 */
		public function intersects(toIntersect:Box):Boolean
		{
			return (_x + _width > toIntersect.x && _x < toIntersect.x + toIntersect.width && _y + _height > toIntersect.y && _y < toIntersect.y + toIntersect.height && _z + _depth > toIntersect.z && _z < toIntersect.z + toIntersect.depth);
		}

		/**
		 * Determines whether or not this Box object is empty.
		 *
		 * @return A value of <code>true</code> if the Box object's width, height or
		 *         depth is less than or equal to 0; otherwise <code>false</code>.
		 */
		public function isEmpty():Boolean
		{
			return (_x == 0 && _y == 0 && _z == 0 && _width == 0 && _height == 0 && _depth == 0);
		}

		/**
		 * Adjusts the location of the Box object, as determined by its
		 * top-left-front corner, by the specified amounts.
		 *
		 * @param dx Moves the <i>x</i> value of the Box object by this amount.
		 * @param dy Moves the <i>y</i> value of the Box object by this amount.
		 * @param dz Moves the <i>z</i> value of the Box object by this amount.
		 */
		public function offset(dx:Number, dy:Number, dz:Number):void
		{
			_x += dx;
			_y += dy;
			_z += dz;
		}

		/**
		 * Adjusts the location of the Box object using a Vector3D object as a
		 * parameter. This method is similar to the <code>Box.offset()</code>
		 * method, except that it takes a Vector3D object as a parameter.
		 *
		 * @param position A Vector3D object to use to offset this Box object.
		 */
		public function offsetPosition(position:Vector3D):void
		{
			_x += position.x;
			_y += position.y;
			_z += position.z;
		}

		/**
		 * Sets all of the Box object's properties to 0. A Box object is empty if its
		 * width, height or depth is less than or equal to 0.
		 *
		 * <p> This method sets the values of the <code>x</code>, <code>y</code>,
		 * <code>z</code>, <code>width</code>, <code>height</code>, and
		 * <code>depth</code> properties to 0.</p>
		 *
		 */
		public function setEmpty():void
		{
			_x = 0;
			_y = 0;
			_z = 0;
			_width = 0;
			_height = 0;
			_depth = 0;
		}

		/**
		 * Sets the members of Box to the specified values
		 *
		 * @param xa      The <i>x</i> coordinate of the top-left-front corner of the
		 *                box.
		 * @param ya      The <i>y</i> coordinate of the top-left-front corner of the
		 *                box.
		 * @param yz      The <i>z</i> coordinate of the top-left-front corner of the
		 *                box.
		 * @param widtha  The width of the box, in pixels.
		 * @param heighta The height of the box, in pixels.
		 * @param deptha  The depth of the box, in pixels.
		 */
		public function setTo(xa:Number, ya:Number, za:Number, widtha:Number, heighta:Number, deptha:Number):void
		{
			_x = xa;
			_y = ya;
			_z = za;
			_width = widtha;
			_height = heighta;
			_depth = deptha;
		}

		/**
		 * Builds and returns a string that lists the horizontal, vertical and
		 * longitudinal positions and the width, height and depth of the Box object.
		 *
		 * @return A string listing the value of each of the following properties of
		 *         the Box object: <code>x</code>, <code>y</code>, <code>z</code>,
		 *         <code>width</code>, <code>height</code>, and <code>depth</code>.
		 */
		public function toString():String
		{
			return "[Box] (x=" + _x + ", y=" + _y + ", z=" + _z + ", width=" + _width + ", height=" + _height + ", depth=" + _depth + ")";
		}

		/**
		 * Adds two boxes together to create a new Box object, by filling
		 * in the horizontal, vertical and longitudinal space between the two boxes.
		 *
		 * <p><b>Note:</b> The <code>union()</code> method ignores boxes with
		 * <code>0</code> as the height, width or depth value, such as: <code>var
		 * box2:Box = new Box(300,300,300,50,50,0);</code></p>
		 *
		 * @param toUnion A Box object to add to this Box object.
		 * @param    b        [optional] A box holder to prevent make new Box instance if already exists. Default is null.
		 * @return A new Box object that is the union of the two boxes.
		 */
		public function union(toUnion:Box, b:Box = null):Box
		{
			if(!b) b = new Box();

			if (_x < toUnion.x) {
				b.x = _x;
				b.width = toUnion.x - _x + toUnion.width;

				if (b.width < _width)
					b.width = _width;
			} else {
				b.x = toUnion.x;
				b.width = _x - toUnion.x + _width;

				if (b.width < toUnion.width)
					b.width = toUnion.width;
			}

			if (_y < toUnion.y) {
				b.y = _y;
				b.height = toUnion.y - _y + toUnion.height;

				if (b.height < _height)
					b.height = _height;
			} else {
				b.y = toUnion.y;
				b.height = _y - toUnion.y + _height;

				if (b.height < toUnion.height)
					b.height = toUnion.height;
			}

			if (_z < toUnion.z) {
				b.z = _z;
				b.depth = toUnion.z - _z + toUnion.depth;

				if (b.depth < _depth)
					b.depth = _depth;
			} else {
				b.z = toUnion.z;
				b.depth = _z - toUnion.z + _depth;

				if (b.depth < toUnion.depth)
					b.depth = toUnion.depth;
			}

			return b;
		}

		public function get z():Number {
			return _z;
		}

		/**
		 * The <i>y</i> coordinate of the top-left-front corner of the box.
		 * Changing the value of the <code>z</code> property of a Box object has no
		 * effect on the <code>x</code>, <code>y</code>, <code>width</code>,
		 * <code>height</code> and <code>depth</code> properties.
		 *
		 * <p>The value of the <code>z</code> property is equal to the value of the
		 * <code>front</code> property.</p>
		 */
		public function set z(value:Number):void {
			_z = value;
		}

		public function get y():Number {
			return _y;
		}

		/**
		 * The <i>y</i> coordinate of the top-left-front corner of the box.
		 * Changing the value of the <code>y</code> property of a Box object has no
		 * effect on the <code>x</code>, <code>z</code>, <code>width</code>,
		 * <code>height</code> and <code>depth</code> properties.
		 *
		 * <p>The value of the <code>y</code> property is equal to the value of the
		 * <code>top</code> property.</p>
		 */
		public function set y(value:Number):void {
			_y = value;
		}

		public function get x():Number {
			return _x;
		}

		/**
		 * The <i>x</i> coordinate of the top-left-front corner of the box.
		 * Changing the value of the <code>x</code> property of a Box object has no
		 * effect on the <code>y</code>, <code>z</code>, <code>width</code>,
		 * <code>height</code> and <code>depth</code> properties.
		 *
		 * <p>The value of the <code>x</code> property is equal to the value of the
		 * <code>left</code> property.</p>
		 */
		public function set x(value:Number):void {
			_x = value;
		}

		public function get depth():Number {
			return _depth;
		}

		/**
		 * The depth of the box, in pixels. Changing the <code>depth</code> value
		 * of a Box object has no effect on the <code>x</code>, <code>y</code>,
		 * <code>z</code>, <code>width</code> and <code>height</code> properties.
		 */
		public function set depth(value:Number):void {
			_depth = value;
		}

		public function get width():Number {
			return _width;
		}

		/**
		 * The width of the box, in pixels. Changing the <code>width</code> value
		 * of a Box object has no effect on the <code>x</code>, <code>y</code>,
		 * <code>z</code>, <code>depth</code> and <code>height</code> properties.
		 */
		public function set width(value:Number):void {
			_width = value;
		}

		public function get height():Number {
			return _height;
		}

		/**
		 * The height of the box, in pixels. Changing the <code>height</code> value
		 * of a Box object has no effect on the <code>x</code>, <code>y</code>,
		 * <code>z</code>, <code>depth</code> and <code>width</code> properties.
		 */
		public function set height(value:Number):void {
			_height = value;
		}
	}
}

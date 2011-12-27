package away3d.core.base.data
{
	
    /**
    * Face value object.
    */
    public class Face
    {
		private var _vertices:Vector.<Number>;
		private var _uvs:Vector.<Number>;
		private var _faceIndex:uint;
		private var _v0Index:uint;
		private var _v1Index:uint;
		private var _v2Index:uint;
		private var _uv0Index:uint;
		private var _uv1Index:uint;
		private var _uv2Index:uint;
		
		/**
		 * Creates a new <code>Face</code> value object.
		 *
		 * @param	vertices		[optional] 9 entries long Vector.&lt;Number&gt; representing the x, y and z of v0, v1, and v2 of a face
		 * @param	uvs			[optional] 6 entries long Vector.&lt;Number&gt; representing the u and v of uv0, uv1, and uv2 of a face
		 */
		function Face(vertices:Vector.<Number> = null, uvs:Vector.<Number> = null)
		{
			_vertices = vertices || Vector.<Number>([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]);
			_uvs = uvs || Vector.<Number>([0.0,0.0,0.0,0.0,0.0,0.0]);
		}
		
		//uvs
		/**
		 * To set uv values for either uv0, uv1 or uv2.
		 * @param	index		The id of the uv (0, 1 or 2)
		 * @param	u			The horizontal coordinate of the texture value.
		 * @param	v			The vertical coordinate of the texture value.
		 */
  		public function setUVat(index:uint, u:Number, v:Number):void
  		{
			var ind:uint = (index*2);
            _uvs[ind] = u;
			_uvs[ind+1] = v;
  		}
		/**
		 * To store a temp index of a face during a loop
		 * @param	ind		The index
		 */
		public function set faceIndex(ind:uint):void
  		{
			_faceIndex = ind;
		}
		/**
		 * @return			Returns the tmp index set for this Face object
		 */
		public function get faceIndex():uint
  		{
			return _faceIndex;
		}
		
		//uv0
		/**
		 * the index set for uv0 in this Face value object
		 * @param	ind		The index
		 */
		public function set uv0Index(ind:uint):void
  		{
			// TODO: not used
			ind = ind;			
			_uv0Index;
		}
		/**
		* @return return the index set for uv0 in this Face value object
		*/
		public function get uv0Index():uint
  		{
			return _uv0Index;
		}
		/**
		 * uv0 u and v values
		 * @param	u		The u value
		 * @param	v		The v value
		 */
		public function setUv0Value(u:Number, v:Number ):void
  		{
            _uvs[0] = u;
			_uvs[1] = v;
  		}
		/**
		* @return return the u value of the uv0 of this Face value object
		*/
		public function get uv0u():Number
  		{
            return _uvs[0];
  		}
		/**
		* @return return the v value of the uv0 of this Face value object
		*/
		public function get uv0v():Number
  		{
            return _uvs[1];
  		}
		
		//uv1
		/**
		 * the index set for uv1 in this Face value object
		 * @param	ind		The index
		 */
		public function set uv1Index(ind:uint):void
  		{
			// TODO: not used			
			ind = ind;
			_uv1Index;
		}
		/**
		* @return Returns the index set for uv1 in this Face value object
		*/
		public function get uv1Index():uint
  		{
			return _uv1Index;
		}
		/**
		 * uv1 u and v values
		 * @param	u		The u value
		 * @param	v		The v value
		 */
		public function setUv1Value(u:Number, v:Number ):void
  		{
            _uvs[2] = u;
			_uvs[3] = v;
  		}
		/**
		* @return Returns the u value of the uv1 of this Face value object
		*/
		public function get uv1u():Number
  		{
            return _uvs[2];
  		}
		/**
		* @return Returns the v value of the uv1 of this Face value object
		*/
		public function get uv1v():Number
  		{
            return _uvs[3];
  		}
		
		//uv2
		/**
		 * the index set for uv2 in this Face value object
		 * @param	ind		The index
		 */
		public function set uv2Index(ind:uint):void
  		{
			// TODO: not used
			ind = ind;
			_uv2Index;
		}
		/**
		* @return return the index set for uv2 in this Face value object
		*/
		public function get uv2Index():uint
  		{
			return _uv2Index;
		}
		/**
		 * uv2 u and v values
		 * @param	u		The u value
		 * @param	v		The v value
		 */
		public function setUv2Value(u:Number, v:Number ):void
  		{
            _uvs[4] = u;
			_uvs[5] = v;
  		}
		/**
		* @return return the u value of the uv2 of this Face value object
		*/
		public function get uv2u():Number
  		{
            return _uvs[4];
  		}
		/**
		* @return return the v value of the uv2 of this Face value object
		*/
		public function get uv2v():Number
  		{
            return _uvs[5];
  		}
		 
  		//vertices
		/**
		 * To set uv values for either v0, v1 or v2.
		 * @param	index		The id of the uv (0, 1 or 2)
		 * @param	x			The x value of the vertex.
		 * @param	y			The y value of the vertex.
		 * @param	z			The z value of the vertex.
		 */
  		public function setVertexAt(index:uint, x:Number, y:Number, z:Number):void
  		{
			var ind:uint = (index*3);
            _vertices[ind] = x;
			_vertices[ind+1] = y;
			_vertices[ind+2] = z;
  		}
		
		//v0
		/**
		 * set the index value for v0
		 * @param	ind			The index value to store
		 */
		public function set v0Index(ind:uint):void
  		{
			// TODO: not used
			ind = ind;
			_v0Index;
		}
		/**
		* @return Returns the index value of the v0 stored in the Face value object
		*/
		public function get v0Index():uint
  		{
			return _v0Index;
		}
		/**
		* @return Returns a Vector.<Number> representing the v0 stored in the Face value object
		*/
		public function get v0():Vector.<Number>
  		{
            return Vector.<Number>([_vertices[0],_vertices[1], _vertices[2]]);
  		}
		/**
		* @return Returns the x value of the v0 stored in the Face value object
		*/
		public function get v0x():Number
  		{
            return _vertices[0];
  		}
		/**
		* @return Returns the y value of the v0 stored in the Face value object
		*/
		public function get v0y():Number
  		{
            return _vertices[1];
  		}
		/**
		* @return Returns the z value of the v0 stored in the Face value object
		*/
		public function get v0z():Number
  		{
            return _vertices[2];
  		}
		
		//v1
		/**
		 * set the index value for v1
		 * @param	ind			The index value to store
		 */
		public function set v1Index(ind:uint):void
  		{
			// TODO: not used
			ind = ind;
			_v1Index;
		}
		/**
		* @return Returns the index value of the v1 stored in the Face value object
		*/
		public function get v1Index():uint
  		{
			return _v1Index;
		}
		/**
		* @return Returns a Vector.<Number> representing the v1 stored in the Face value object
		*/
		public function get v1():Vector.<Number>
  		{
            return Vector.<Number>([_vertices[3],_vertices[4], _vertices[5]]);
  		}
		/**
		* @return Returns the x value of the v1 stored in the Face value object
		*/
		public function get v1x():Number
  		{
            return _vertices[3];
  		}
		/**
		* @return Returns the y value of the v1 stored in the Face value object
		*/
		public function get v1y():Number
  		{
            return _vertices[4];
  		}
		/**
		* @return Returns the z value of the v1 stored in the Face value object
		*/
		public function get v1z():Number
  		{
            return _vertices[5];
  		}
		
		//v2
		/**
		 * set the index value for v2
		 * @param	ind			The index value to store
		 */
		public function set v2Index(ind:uint):void
  		{
			// TODO: not used
			ind = ind;
			_v2Index;
		}
		/**
		* @return return the index value of the v2 stored in the Face value object
		*/
		public function get v2Index():uint
  		{
			return _v2Index;
		}
		/**
		* @return Returns a Vector.<Number> representing the v2 stored in the Face value object
		*/
		public function get v2():Vector.<Number>
  		{
            return Vector.<Number>([_vertices[6],_vertices[7], _vertices[8]]);
  		}
		/**
		* @return Returns the x value of the v2 stored in the Face value object
		*/
		public function get v2x():Number
  		{
            return _vertices[6];
  		}
		/**
		* @return Returns the y value of the v2 stored in the Face value object
		*/
		public function get v2y():Number
  		{
            return _vertices[7];
  		}
		/**
		* @return Returns the z value of the v2 stored in the Face value object
		*/
		public function get v2z():Number
  		{
            return _vertices[8];
  		}
		/**
		 * returns a new Face value Object
		 */
		public function clone():Face
  		{
			var nVertices:Vector.<Number> = Vector.<Number>([	_vertices[0],_vertices[1],_vertices[2],
																								_vertices[3],_vertices[4],_vertices[5],
																								_vertices[6],_vertices[7],_vertices[8]]);
			
			var nUvs:Vector.<Number> = Vector.<Number>([_uvs[0],_uvs[1],
																						_uvs[2],_uvs[3],
																						_uvs[4],_uvs[5]]);

			return new Face(nVertices, nUvs);
		}
  		
    }
}

package away3d.bounds
{

	import away3d.arcane;
	import away3d.core.math.*;
	import away3d.core.pick.*;
	import away3d.primitives.*;

	import flash.geom.*;

	use namespace arcane;

	/**
	 * AxisAlignedBoundingBox represents a bounding box volume that has its planes aligned to the local coordinate axes of the bounded object.
	 * This is useful for most meshes.
	 */
	public class AxisAlignedBoundingBox extends BoundingVolumeBase
	{
		private var _centerX:Number = 0;
		private var _centerY:Number = 0;
		private var _centerZ:Number = 0;
		private var _halfExtentsX:Number = 0;
		private var _halfExtentsY:Number = 0;
		private var _halfExtentsZ:Number = 0;

		/**
		 * Creates a new <code>AxisAlignedBoundingBox</code> object.
		 */
		public function AxisAlignedBoundingBox()
		{
		}

		/**
		 * @inheritDoc
		 */
		override public function nullify():void {
			super.nullify();
			_centerX = _centerY = _centerZ = 0;
			_halfExtentsX = _halfExtentsY = _halfExtentsZ = 0;
		}

		/**
		 * @inheritDoc
		 */
		override public function isInFrustum( mvpMatrix:Matrix3D ):Boolean {
			var raw:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			mvpMatrix.copyRawDataTo( raw );
			var c11:Number = raw[uint( 0 )], c12:Number = raw[uint( 4 )], c13:Number = raw[uint( 8 )], c14:Number = raw[uint( 12 )];
			var c21:Number = raw[uint( 1 )], c22:Number = raw[uint( 5 )], c23:Number = raw[uint( 9 )], c24:Number = raw[uint( 13 )];
			var c31:Number = raw[uint( 2 )], c32:Number = raw[uint( 6 )], c33:Number = raw[uint( 10 )], c34:Number = raw[uint( 14 )];
			var c41:Number = raw[uint( 3 )], c42:Number = raw[uint( 7 )], c43:Number = raw[uint( 11 )], c44:Number = raw[uint( 15 )];
			var a:Number, b:Number, c:Number, d:Number;
			var dd:Number, rr:Number;

			// this is basically a p/n vertex test in object space against the frustum planes derived from the mvp
			// with a lot of inlining

			// left plane
			a = c41 + c11;
			b = c42 + c12;
			c = c43 + c13;
			d = c44 + c14;
			dd = a * _centerX + b * _centerY + c * _centerZ;
			if( a < 0 ) a = -a;
			if( b < 0 ) b = -b;
			if( c < 0 ) c = -c;
			rr = a * _halfExtentsX + b * _halfExtentsY + c * _halfExtentsZ;
			if( dd + rr < -d ) return false;
			// right plane
			a = c41 - c11;
			b = c42 - c12;
			c = c43 - c13;
			d = c44 - c14;
			dd = a * _centerX + b * _centerY + c * _centerZ;
			if( a < 0 ) a = -a;
			if( b < 0 ) b = -b;
			if( c < 0 ) c = -c;
			rr = a * _halfExtentsX + b * _halfExtentsY + c * _halfExtentsZ;
			if( dd + rr < -d ) return false;
			// bottom plane
			a = c41 + c21;
			b = c42 + c22;
			c = c43 + c23;
			d = c44 + c24;
			dd = a * _centerX + b * _centerY + c * _centerZ;
			if( a < 0 ) a = -a;
			if( b < 0 ) b = -b;
			if( c < 0 ) c = -c;
			rr = a * _halfExtentsX + b * _halfExtentsY + c * _halfExtentsZ;
			if( dd + rr < -d ) return false;
			// top plane
			a = c41 - c21;
			b = c42 - c22;
			c = c43 - c23;
			d = c44 - c24;
			dd = a * _centerX + b * _centerY + c * _centerZ;
			if( a < 0 ) a = -a;
			if( b < 0 ) b = -b;
			if( c < 0 ) c = -c;
			rr = a * _halfExtentsX + b * _halfExtentsY + c * _halfExtentsZ;
			if( dd + rr < -d ) return false;
			// near plane
			a = c31;
			b = c32;
			c = c33;
			d = c34;
			dd = a * _centerX + b * _centerY + c * _centerZ;
			if( a < 0 ) a = -a;
			if( b < 0 ) b = -b;
			if( c < 0 ) c = -c;
			rr = a * _halfExtentsX + b * _halfExtentsY + c * _halfExtentsZ;
			if( dd + rr < -d ) return false;
			// far plane
			a = c41 - c31;
			b = c42 - c32;
			c = c43 - c33;
			d = c44 - c34;
			dd = a * _centerX + b * _centerY + c * _centerZ;
			if( a < 0 ) a = -a;
			if( b < 0 ) b = -b;
			if( c < 0 ) c = -c;
			rr = a * _halfExtentsX + b * _halfExtentsY + c * _halfExtentsZ;
			if( dd + rr < -d ) return false;

			return true;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function intersectsRay( position:Vector3D, direction:Vector3D, pickingCollisionVO:PickingCollisionVO ):Boolean
		{
			var px:Number = position.x - _centerX, py:Number = position.y - _centerY, pz:Number = position.z - _centerZ;
			var vx:Number = direction.x, vy:Number = direction.y, vz:Number = direction.z;
			var ix:Number, iy:Number, iz:Number;
			var rayEntryDistance:Number;
			var localNormal:Vector3D;
			var rayOriginIsInsideBounds:Boolean;
			
			// possible tests
			var testPosX:Boolean = true, testNegX:Boolean = true, testPosY:Boolean = true;
			var testNegY:Boolean = true, testPosZ:Boolean = true, testNegZ:Boolean = true;

			// discard tests 1: ray is parallel to some sides?
			if( vx == 0 ) testNegX = testPosX = false;
			if( vy == 0 ) testPosY = testNegY = false;
			if( vz == 0 ) testPosZ = testNegZ = false;

			// discard tests 2: ray hits sides from the back?
			if( vx < 0 ) testNegX = false;
			else if( vx > 0 ) testPosX = false;
			if( vy < 0 ) testNegY = false;
			else if( vy > 0 ) testPosY = false;
			if( vz < 0 ) testNegZ = false;
			else if( vz > 0 ) testPosZ = false;

			// ray-plane tests
			var intersects:Boolean;

			// X
			if( testPosX ) {
				rayEntryDistance = ( _halfExtentsX - px ) / vx;
				if( rayEntryDistance > 0 ) {
					iy = py + rayEntryDistance * vy;
					iz = pz + rayEntryDistance * vz;
					if( iy > -_halfExtentsY && iy < _halfExtentsY && iz > -_halfExtentsZ && iz < _halfExtentsZ ) {
						localNormal = new Vector3D( 1, 0, 0 );
						intersects = true;
					}
				}
			}
			if( !intersects && testNegX ) {
				rayEntryDistance = ( -_halfExtentsX - px ) / vx;
				if( rayEntryDistance > 0 ) {
					iy = py + rayEntryDistance * vy;
					iz = pz + rayEntryDistance * vz;
					if( iy > -_halfExtentsY && iy < _halfExtentsY && iz > -_halfExtentsZ && iz < _halfExtentsZ ) {
						localNormal = new Vector3D( -1, 0, 0 );
						intersects = true;
					}
				}
			}

			// Y
			if( !intersects && testPosY ) {
				rayEntryDistance = ( _halfExtentsY - py ) / vy;
				if( rayEntryDistance > 0 ) {
					ix = px + rayEntryDistance * vx;
					iz = pz + rayEntryDistance * vz;
					if( ix > -_halfExtentsX && ix < _halfExtentsX && iz > -_halfExtentsZ && iz < _halfExtentsZ ) {
						localNormal = new Vector3D( 0, 1, 0 );
						intersects = true;
					}
				}
			}
			if( !intersects && testNegY ) {
				rayEntryDistance = ( -_halfExtentsY - py ) / vy;
				if( rayEntryDistance > 0 ) {
					ix = px + rayEntryDistance * vx;
					iz = pz + rayEntryDistance * vz;
					if( ix > -_halfExtentsX && ix < _halfExtentsX && iz > -_halfExtentsZ && iz < _halfExtentsZ ) {
						localNormal = new Vector3D( 0, -1, 0 );
						intersects = true;
					}
				}
			}

			// Z
			if( !intersects && testPosZ ) {
				rayEntryDistance = ( _halfExtentsZ - pz ) / vz;
				if( rayEntryDistance > 0 ) {
					ix = px + rayEntryDistance * vx;
					iy = py + rayEntryDistance * vy;
					if( iy > -_halfExtentsY && iy < _halfExtentsY && ix > -_halfExtentsX && ix < _halfExtentsX ) {
						localNormal = new Vector3D( 0, 0, 1);
						intersects = true;
					}
				}
			}
			if( !intersects && testNegZ ) {
				rayEntryDistance = ( -_halfExtentsZ - pz ) / vz;
				if( rayEntryDistance > 0 ) {
					ix = px + rayEntryDistance * vx;
					iy = py + rayEntryDistance * vy;
					if( iy > -_halfExtentsY && iy < _halfExtentsY && ix > -_halfExtentsX && ix < _halfExtentsX ) {
						localNormal = new Vector3D( 0, 0, -1 );
						intersects = true;
					}
				}
			}
			
			// accept cases on which the ray starts inside the bounds
			if( rayEntryDistance < 0 && (rayOriginIsInsideBounds = containsPoint(position)) ) {
				rayEntryDistance = 0;
				intersects = true;
			}
			
			if (intersects) {
				pickingCollisionVO.localNormal = localNormal;
				pickingCollisionVO.localPosition = new Vector3D(position.x + rayEntryDistance*direction.x, position.y + rayEntryDistance*direction.y, position.z + rayEntryDistance*direction.z);
				pickingCollisionVO.rayEntryDistance = rayEntryDistance;
				pickingCollisionVO.rayOriginIsInsideBounds = rayOriginIsInsideBounds;
				
				return true;
			}
			
			
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function containsPoint( position:Vector3D ):Boolean {
			var px:Number = position.x - _centerX, py:Number = position.y - _centerY, pz:Number = position.z - _centerZ;
			if( px > _halfExtentsX || px < -_halfExtentsX ) return false;
			if( py > _halfExtentsY || py < -_halfExtentsY ) return false;
			if( pz > _halfExtentsZ || pz < -_halfExtentsZ ) return false;
			return true;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function fromExtremes( minX:Number, minY:Number, minZ:Number, maxX:Number, maxY:Number, maxZ:Number ):void {
			_centerX = (maxX + minX) * .5;
			_centerY = (maxY + minY) * .5;
			_centerZ = (maxZ + minZ) * .5;
			_halfExtentsX = (maxX - minX) * .5;
			_halfExtentsY = (maxY - minY) * .5;
			_halfExtentsZ = (maxZ - minZ) * .5;
			super.fromExtremes( minX, minY, minZ, maxX, maxY, maxZ );
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():BoundingVolumeBase
		{
			var clone:AxisAlignedBoundingBox = new AxisAlignedBoundingBox();
			clone.fromExtremes( _min.x, _min.y, _min.z, _max.x, _max.y, _max.z );
			return clone;
		}
		
		public function get halfExtentsX():Number
		{
			return _halfExtentsX;
		}
		
		public function get halfExtentsY():Number
		{
			return _halfExtentsY;
		}
		
		public function get halfExtentsZ():Number
		{
			return _halfExtentsZ;
		}
		
		public function closestPointToPoint(point : Vector3D, target : Vector3D = null) : Vector3D
		{
			var p : Number;
			target ||= new Vector3D();

			p = point.x;
			if (p < _min.x) p = _min.x;
			if (p > _max.x) p = _max.x;
			target.x = p;

			p = point.y;
			if (p < _min.y) p = _min.y;
			if (p > _max.y) p = _max.y;
			target.y = p;

			p = point.z;
			if (p < _min.z) p = _min.z;
			if (p > _max.z) p = _max.z;
			target.z = p;

			return target;
		}
		
		override protected function updateBoundingRenderable():void {
			_boundingRenderable.scaleX = Math.max( _halfExtentsX * 2, 0.001 );
			_boundingRenderable.scaleY = Math.max( _halfExtentsY * 2, 0.001 );
			_boundingRenderable.scaleZ = Math.max( _halfExtentsZ * 2, 0.001 );
			_boundingRenderable.x = _centerX;
			_boundingRenderable.y = _centerY;
			_boundingRenderable.z = _centerZ;
		}
		
		override protected function createBoundingRenderable():WireframePrimitiveBase {
			return new WireframeCube( 1, 1, 1 );
		}
	}
}
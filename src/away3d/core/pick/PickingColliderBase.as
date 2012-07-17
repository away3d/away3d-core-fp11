package away3d.core.pick
{
	import flash.geom.*;

	/**
	 * An abstract base class for all picking collider classes. It should not be instantiated directly.
	 */
	public class PickingColliderBase
	{
		protected var rayPosition:Vector3D;
		protected var rayDirection:Vector3D;

		protected function getCollisionNormal( indexData:Vector.<uint>, vertexData:Vector.<Number>, triangleIndex:uint ):Vector3D {
			var normal:Vector3D = new Vector3D();
			var i0:uint = indexData[ triangleIndex ] * 3;
			var i1:uint = indexData[ triangleIndex + 1 ] * 3;
			var i2:uint = indexData[ triangleIndex + 2 ] * 3;
			var p0:Vector3D = new Vector3D( vertexData[ i0 ], vertexData[ i0 + 1 ], vertexData[ i0 + 2 ] );
			var p1:Vector3D = new Vector3D( vertexData[ i1 ], vertexData[ i1 + 1 ], vertexData[ i1 + 2 ] );
			var p2:Vector3D = new Vector3D( vertexData[ i2 ], vertexData[ i2 + 1 ], vertexData[ i2 + 2 ] );
			var side0:Vector3D = p1.subtract( p0 );
			var side1:Vector3D = p2.subtract( p0 );
			normal = side0.crossProduct( side1 );
			normal.normalize();
			return normal;
		}

		protected function getCollisionUV( indexData:Vector.<uint>, uvData:Vector.<Number>, triangleIndex:uint, v:Number, w:Number, u:Number ):Point {
			var uv:Point = new Point();
			var uvIndex:Number = indexData[ triangleIndex ] * 2;
			var uv0:Vector3D = new Vector3D( uvData[ uvIndex ], uvData[ uvIndex + 1 ] );
			triangleIndex++;
			uvIndex = indexData[ triangleIndex ] * 2;
			var uv1:Vector3D = new Vector3D( uvData[ uvIndex ], uvData[ uvIndex + 1 ] );
			triangleIndex++;
			uvIndex = indexData[ triangleIndex ] * 2;
			var uv2:Vector3D = new Vector3D( uvData[ uvIndex ], uvData[ uvIndex + 1 ] );
			uv.x = u * uv0.x + v * uv1.x + w * uv2.x;
			uv.y = u * uv0.y + v * uv1.y + w * uv2.y;
			return uv;
		}

		/**
		 * @inheritDoc
		 */
		public function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):void
		{
			rayPosition = localPosition;
			rayDirection = localDirection;
		}
	}
}

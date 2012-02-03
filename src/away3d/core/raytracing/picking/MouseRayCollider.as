package away3d.core.raytracing.picking
{

	import away3d.containers.View3D;
	import away3d.core.base.IRenderable;
	import away3d.core.data.RenderableListItem;
	import away3d.entities.Entity;
	import away3d.core.raytracing.colliders.*;

	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	public class MouseRayCollider extends RayCollider
	{
		private var _triangleCollider:RayTriangleCollider;
		private var _numBoundHits:uint;

		public function MouseRayCollider() {
			super();
			_triangleCollider = new RayTriangleCollider();
		}

		override public function evaluate( item:RenderableListItem ):Boolean {

			if( !item ) return _collisionExists = false;

			// init
			var i:uint, j:uint;
			var entity:Entity;
			var collisionVO:MouseCollisionVO;
			var entityToCollisionVoDictionary:Dictionary = new Dictionary();
			var collisionVOs:Vector.<MouseCollisionVO> = new Vector.<MouseCollisionVO>();
			var cameraIsInEntityBounds:Boolean;
			var t:Number;
			var rp:Vector3D, rd:Vector3D;

			// sweep renderables and collect entities whose bounds are hit by ray
			while( item ) {
				if( item.renderable.mouseEnabled ) {
					entity = item.renderable.sourceEntity;
					if( entity.visible ) {
						if( !entityToCollisionVoDictionary[ entity ] ) {
							cameraIsInEntityBounds = false;
							rp = entity.inverseSceneTransform.transformVector( _rayPosition );
							rd = entity.inverseSceneTransform.deltaTransformVector( _rayDirection );
							t = entity.bounds.intersectsRay( rp, rd );
							if( t == -1 ) {
								cameraIsInEntityBounds = entity.bounds.containsPoint( rp );
								if( cameraIsInEntityBounds ) t = 0;
							}
							if( t >= 0 ) {
								collisionVO = new MouseCollisionVO();
								collisionVO.entity = entity;
								collisionVO.renderableItems.push( item );
								collisionVO.localRayPosition = rp;
								collisionVO.localRayDirection = rd;
								collisionVO.t = t;
								collisionVO.cameraIsInEntityBounds = cameraIsInEntityBounds;
								collisionVOs.push( collisionVO );
							}
						}
						else {
							entityToCollisionVoDictionary[ entity ].renderableItems.push( item );
						}
					}
				}
				item = item.next;
			}
			_numBoundHits = collisionVOs.length;

			// no bound hits?
			if( _numBoundHits == 0 ) {
				return _collisionExists = false;
			}

			// sort collisions from closest to furthest
			collisionVOs = collisionVOs.sort( onSmallestT );

			// sweep hit entities and perform triangle tests on the entities, from closest to furthest
			var numItems:uint;
			for( i = 0; i < _numBoundHits; ++i ) {
				collisionVO = collisionVOs[ i ];
				numItems = collisionVO.renderableItems.length;
				if( numItems > 0 ) _triangleCollider.updateRay( collisionVO.localRayPosition, collisionVO.localRayDirection );
				// sweep renderables
				for( j = 0; j < numItems; ++j ) {
					item = collisionVO.renderableItems[ j ];
					// need triangle collision test?
					if( collisionVO.cameraIsInEntityBounds || item.renderable.mouseHitMethod == MouseHitMethod.MESH_CLOSEST_HIT
							|| item.renderable.mouseHitMethod == MouseHitMethod.MESH_ANY_HIT ) {
						_triangleCollider.breakOnFirstTriangleHit = item.renderable.mouseHitMethod == MouseHitMethod.MESH_ANY_HIT;
						if( _triangleCollider.evaluate( item ) ) {
							_t = collisionVO.t;
							_collidingRenderable = _triangleCollider.collidingRenderable;
							_collisionPoint = _triangleCollider.collisionPoint;
							return _collisionExists = true; // exit at first triangle hit success
						}
					}
					else {
						_t = collisionVO.t;
						_collidingRenderable = item.renderable;
						_collisionPoint = new Vector3D();
						_collisionPoint.x = collisionVO.localRayPosition.x + collisionVO.t * collisionVO.localRayDirection.x;
						_collisionPoint.y = collisionVO.localRayPosition.y + collisionVO.t * collisionVO.localRayDirection.y;
						_collisionPoint.z = collisionVO.localRayPosition.z + collisionVO.t * collisionVO.localRayDirection.z;
						return _collisionExists = true; // or exit at first end-bound collision
					}
				}
			}

			return _collisionExists = false;
		}

		private function onSmallestT( a:MouseCollisionVO, b:MouseCollisionVO ):Number {
			return a.t < b.t ? -1 : 1;
		}

		public function get collisionUV():Point {
			return _triangleCollider.collisionUV;
		}
	}
}

import away3d.core.data.RenderableListItem;
import away3d.entities.Entity;

import flash.geom.Vector3D;

class MouseCollisionVO
{
	public var entity:Entity;
	public var renderableItems:Vector.<RenderableListItem>;
	public var t:Number;
	public var localRayPosition:Vector3D;
	public var localRayDirection:Vector3D;
	public var cameraIsInEntityBounds:Boolean;

	public function MouseCollisionVO() {
		renderableItems = new Vector.<RenderableListItem>();
	}
}

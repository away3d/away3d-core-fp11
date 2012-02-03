package away3d.raytracing.picking
{

	import away3d.containers.View3D;
	import away3d.core.base.IRenderable;
	import away3d.core.data.RenderableListItem;
	import away3d.entities.Entity;
	import away3d.raytracing.colliders.*;

	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	public class MouseRayCollider extends RayCollider
	{
		private var _triangleCollider:RayTriangleCollider;
		private var _numBoundHits:int;

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

			// sweep renderables and collect entities whose bounds are hit by ray
			while( item ) {
				var renderable:IRenderable = item.renderable;
				if( renderable.mouseEnabled ) {
					entity = renderable.sourceEntity;
					if( entity.visible ) {
						if( !entityToCollisionVoDictionary[ entity ] ) {
							collisionVO = new MouseCollisionVO();
							collisionVO.entity = entity;
							collisionVO.renderableItems.push( item );
							collisionVO.localRayPosition = entity.inverseSceneTransform.transformVector( _rayPosition );
							collisionVO.localRayDirection = entity.inverseSceneTransform.deltaTransformVector( _rayDirection );
							collisionVO.t = entity.bounds.intersectsRay( collisionVO.localRayPosition, collisionVO.localRayDirection );
							if( collisionVO.t == -1 ) {
								if( collisionVO.cameraIsInEntityBounds = entity.bounds.containsPoint( collisionVO.localRayPosition ) ) {
									collisionVO.t = 0;
								}
							}
							if( collisionVO.t >= 0 ) {
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

			// no bound hits?
			_numBoundHits = collisionVOs.length;
			if( _numBoundHits == 0 ) {
				return _collisionExists = false;
			}

			// sort collisions from closest to furthest
			collisionVOs = collisionVOs.sort( onSmallestT );

			// sweep hit entities and perform triangle tests on the entities, from closest to furthest
			for( i = 0; i < _numBoundHits; ++i ) {
				collisionVO = collisionVOs[ i ];
				var numItems:uint = collisionVO.renderableItems.length;
				_triangleCollider.updateRay( collisionVO.localRayPosition, collisionVO.localRayDirection );
				// sweep renderables
				for( j = 0; j < numItems; ++j ) {
					item = collisionVO.renderableItems[ j ];
					// need triangle collision test?
					if( collisionVO.cameraIsInEntityBounds || item.renderable.mouseHitMethod == MouseHitMethod.MESH
							|| item.renderable.mouseHitMethod == MouseHitMethod.MESH_FAST ) {
						_triangleCollider.breakOnFirstTriangleHit = item.renderable.mouseHitMethod == MouseHitMethod.MESH_FAST;
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

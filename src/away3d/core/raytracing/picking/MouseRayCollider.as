package away3d.core.raytracing.picking
{

	import away3d.core.data.RenderableListItem;
	import away3d.core.raytracing.colliders.*;
	import away3d.entities.Entity;
	import away3d.entities.SegmentSet;

	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	public class MouseRayCollider extends RayCollider
	{
		private var _triangleCollider:RayTriangleCollider;
		private var _nearestCollisionVO:MouseCollisionVO;
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
			var entityHasBeenChecked:Dictionary = new Dictionary();
			var collisionVOs:Vector.<MouseCollisionVO> = new Vector.<MouseCollisionVO>();
			var cameraIsInEntityBounds:Boolean;
			var t:Number;
			var rp:Vector3D, rd:Vector3D;

			// sweep renderables and collect entities whose bounds are hit by ray
			while( item ) {
				entity = item.renderable.sourceEntity;
				if( entity.visible && entity.mouseEnabled && !( entity is SegmentSet ) ) { // TODO: remove "is" check
					if( !entityHasBeenChecked[ entity ] ) {
						// convert ray to object space
						rp = entity.inverseSceneTransform.transformVector( _rayPosition );
						rd = entity.inverseSceneTransform.deltaTransformVector( _rayDirection );
						// check for ray-bounds collision
						t = entity.bounds.intersectsRay( rp, rd );
						cameraIsInEntityBounds = false;
						if( t == -1 ) { // if there is no collision, check if the ray starts inside the bounding volume
							cameraIsInEntityBounds = entity.bounds.containsPoint( rp );
							if( cameraIsInEntityBounds ) t = 0;
						}
						if( t >= 0 ) { // collision exists for this renderable's entity bounds
							// store collision VO
							collisionVO = new MouseCollisionVO();
							collisionVO.t = t;
							collisionVO.entity = entity;
							collisionVO.localRayPosition = rp;
							collisionVO.localRayDirection = rd;
							collisionVO.renderableItems.push( item );
							collisionVO.cameraIsInEntityBounds = cameraIsInEntityBounds;
							entityToCollisionVoDictionary[ entity ] = collisionVO;
							collisionVOs.push( collisionVO );
						}
						entityHasBeenChecked[ entity ] = true; // do not check entities twice
					}
					else {
						// if entity has been checked and a collision was found for it, collect all its renderables
						collisionVO = entityToCollisionVoDictionary[ entity ];
						if( collisionVO ) collisionVO.renderableItems.push( item );
					}
				}
				item = item.next;
			}

			// no bound hits?
			_numBoundHits = collisionVOs.length;
			if( _numBoundHits == 0 ) {
				return _collisionExists = false;
			}

			_collisionExists = true;

			// sweep all hit entities and find more info about the collisions, also find nearest collision
			_nearestCollisionVO = new MouseCollisionVO();
			_nearestCollisionVO.t = Number.MAX_VALUE;
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
						if( _triangleCollider.evaluate( item ) ) { // triangle collision exists?
							collisionVO.t = _triangleCollider.collisionT;
							collisionVO.collidingRenderable = item.renderable;
							collisionVO.collisionPoint = _triangleCollider.collisionPoint.clone(); // TODO: avoid calc for all hits?
							collisionVO.collisionUV = _triangleCollider.collisionUV.clone();
							if( collisionVO.t < _nearestCollisionVO.t ) _nearestCollisionVO = collisionVO;
						}
						// if there is no triangle hit the collisionVO is not eligible for nearest hit ( its a miss )
					}
					else {
						collisionVO.collidingRenderable = item.renderable;
						// find hit position for bound collision if necessary
						// TODO: avoid calc for all hits?
						var point:Vector3D = new Vector3D();
						point.x = collisionVO.localRayPosition.x + collisionVO.t * collisionVO.localRayDirection.x;
						point.y = collisionVO.localRayPosition.y + collisionVO.t * collisionVO.localRayDirection.y;
						point.z = collisionVO.localRayPosition.z + collisionVO.t * collisionVO.localRayDirection.z;
						collisionVO.collisionPoint = point;
						if( collisionVO.t < _nearestCollisionVO.t ) _nearestCollisionVO = collisionVO;
					}
				}
			}

			// use nearest collision found
			_t = _nearestCollisionVO.t;
			_collidingRenderable = _nearestCollisionVO.collidingRenderable;
			_collisionPoint = _nearestCollisionVO.collisionPoint;

			return _collisionExists;
		}

		override public function get collisionPoint():Vector3D {
			return _nearestCollisionVO.collisionPoint;
		}

		public function get collisionUV():Point {
			return _nearestCollisionVO.collisionUV;
		}
	}
}

import away3d.core.base.IRenderable;
import away3d.core.data.RenderableListItem;
import away3d.entities.Entity;

import flash.geom.Point;

import flash.geom.Vector3D;

class MouseCollisionVO
{
	public var entity:Entity;
	public var renderableItems:Vector.<RenderableListItem>;
	public var t:Number;
	public var collidingRenderable:IRenderable;
	public var localRayPosition:Vector3D;
	public var localRayDirection:Vector3D;
	public var cameraIsInEntityBounds:Boolean;
	public var collisionPoint:Vector3D;
	public var collisionUV:Point;

	public function MouseCollisionVO() {
		renderableItems = new Vector.<RenderableListItem>();
	}
}

package away3d.core.raycast
{

	import away3d.core.data.RenderableListItem;
	import away3d.core.raycast.colliders.*;
	import away3d.entities.Entity;

	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	public class MouseRaycast extends ColliderBase
	{
		private var _triangleCollider:TriangleCollider;
		private var _nearestCollisionVO:MouseCollisionVO;

		public function MouseRaycast() {
			super();
			_triangleCollider = new TriangleCollider();
		}

		override public function evaluate( item:RenderableListItem ):Boolean {

			if( !item ) return _collisionExists = false;

			// init
			var t:Number;
			var entity:Entity;
			var i:uint, j:uint;
			var rp:Vector3D, rd:Vector3D;
			var collisionVO:MouseCollisionVO;
			var cameraIsInEntityBounds:Boolean;
			var entityHasBeenChecked:Dictionary = new Dictionary();
			var entityToCollisionVoDictionary:Dictionary = new Dictionary();
			var collisionVOs:Vector.<MouseCollisionVO> = new Vector.<MouseCollisionVO>();

			// sweep renderables and collect entities whose bounds are hit by ray
			while( item ) {
				entity = item.renderable.sourceEntity;
				if( entity.visible && entity.mouseEnabled ) {
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
							collisionVO.boundsCollisionT = t;
							collisionVO.boundsCollisionFarT = entity.bounds.rayFarT;
							collisionVO.entity = entity;
							collisionVO.localRayPosition = rp;
							collisionVO.localRayDirection = rd;
							collisionVO.renderableItems.push( item );
							collisionVO.cameraIsInEntityBounds = cameraIsInEntityBounds;
							collisionVO.collidingRenderable = item.renderable;
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
			var numBoundHits:uint = collisionVOs.length;
			if( numBoundHits == 0 ) return _collisionExists = false;

			// sort collision vos, closest to furthest
			collisionVOs = collisionVOs.sort( onSmallestT );

			// find nearest collision and perform triangle collision tests where necessary
			var numItems:uint;
			_nearestCollisionVO = new MouseCollisionVO();
			_nearestCollisionVO.finalCollisionT = Number.MAX_VALUE;
			_nearestCollisionVO.boundsCollisionT = Number.MAX_VALUE;
			_nearestCollisionVO.boundsCollisionFarT = Number.MAX_VALUE;
			for( i = 0; i < numBoundHits; ++i ) {
				collisionVO = collisionVOs[ i ];
				// this collision could only be closer if the bounds collision t is closer, otherwise, no need to test ( except if bounds intersect )
				if( collisionVO.cameraIsInEntityBounds
						|| collisionVO.boundsCollisionT < _nearestCollisionVO.finalCollisionT
						|| ( collisionVO.boundsCollisionT > _nearestCollisionVO.boundsCollisionT && collisionVO.boundsCollisionT < _nearestCollisionVO.boundsCollisionFarT ) ) { // bounds intersection test
					numItems = collisionVO.renderableItems.length;
					if( numItems > 0 ) _triangleCollider.updateRay( collisionVO.localRayPosition, collisionVO.localRayDirection );
					// sweep renderables
					var triHitFound:Boolean = false;
					for( j = 0; j < numItems; ++j ) {
						item = collisionVO.renderableItems[ j ];
						// need triangle collision test?
						if( collisionVO.cameraIsInEntityBounds
								|| item.renderable.mouseHitMethod == MouseHitMethod.MESH_CLOSEST_HIT
								|| item.renderable.mouseHitMethod == MouseHitMethod.MESH_ANY_HIT ) {
							_triangleCollider.breakOnFirstTriangleHit = item.renderable.mouseHitMethod == MouseHitMethod.MESH_ANY_HIT;
							if( _triangleCollider.evaluate( item ) ) { // triangle collision exists?
								collisionVO.finalCollisionT = _triangleCollider.collisionT;
								collisionVO.collidingRenderable = item.renderable;
								collisionVO.collisionUV = _triangleCollider.collisionUV.clone();
								collisionVO.isTriangleHit = true;
								if( collisionVO.finalCollisionT < _nearestCollisionVO.finalCollisionT ) _nearestCollisionVO = collisionVO;
								triHitFound = true;
							}
							// on required tri hit, if there is no triangle hit the collisionVO is not eligible for nearest hit ( its a miss )
						}
						else if( !triHitFound ) { // on required bounds hit, consider t for nearest hit
							collisionVO.finalCollisionT = collisionVO.boundsCollisionT;
							if( collisionVO.finalCollisionT < _nearestCollisionVO.finalCollisionT ) _nearestCollisionVO = collisionVO;
						}
					}
				}
			}

			// use nearest collision found
			_t = _nearestCollisionVO.finalCollisionT;
			_collidingRenderable = _nearestCollisionVO.collidingRenderable;
			return _collisionExists = _nearestCollisionVO.finalCollisionT != Number.MAX_VALUE;
		}

		override public function get collisionPoint():Vector3D
		{
			if( !_collisionExists )
				return null;
			
			var point:Vector3D = new Vector3D();
			point.x = _nearestCollisionVO.localRayPosition.x + _nearestCollisionVO.finalCollisionT * _nearestCollisionVO.localRayDirection.x;
			point.y = _nearestCollisionVO.localRayPosition.y + _nearestCollisionVO.finalCollisionT * _nearestCollisionVO.localRayDirection.y;
			point.z = _nearestCollisionVO.localRayPosition.z + _nearestCollisionVO.finalCollisionT * _nearestCollisionVO.localRayDirection.z;
			return point;
		}
		
		
		public function get entity():Entity
		{
			if( !_collisionExists )
				return null;
			
			return _nearestCollisionVO.entity;
		}
		
		private function onSmallestT( a:MouseCollisionVO, b:MouseCollisionVO ):Number {
			return a.boundsCollisionT < b.boundsCollisionT ? -1 : 1;
		}

		public function get collisionUV():Point {
			if( !_collisionExists || !_nearestCollisionVO.isTriangleHit ) return null;
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
	public var boundsCollisionT:Number;
	public var boundsCollisionFarT:Number;
	public var finalCollisionT:Number;
	public var entity:Entity;
	public var collisionUV:Point;
	public var isTriangleHit:Boolean;
	public var localRayPosition:Vector3D;
	public var localRayDirection:Vector3D;
	public var cameraIsInEntityBounds:Boolean;
	public var collidingRenderable:IRenderable;
	public var renderableItems:Vector.<RenderableListItem>;

	public function MouseCollisionVO() {
		renderableItems = new Vector.<RenderableListItem>();
	}
}

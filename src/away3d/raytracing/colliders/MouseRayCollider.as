package away3d.raytracing.colliders
{

	import away3d.bounds.BoundingVolumeBase;
	import away3d.containers.View3D;
	import away3d.core.base.IRenderable;
	import away3d.core.data.RenderableListItem;
	import away3d.entities.Entity;
	import away3d.raytracing.data.MousePickingPrecision;

	import flash.geom.Point;

	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	public class MouseRayCollider extends RayCollider
	{
		private var _triangleCollider:RayTriangleCollider;
		private var _view:View3D;
		private var _numBoundHits:uint;

		public function MouseRayCollider( view:View3D ) {
			super();
			_view = view;
			_triangleCollider = new RayTriangleCollider();
		}

		override public function evaluate( item:RenderableListItem ):Boolean {

			// TODO: implement without these dictionaries - introduce a vo and use array.sortOn()?
			// TODO: the complication is that bounds need to be checked and then ordered from closest
			// TODO: to furthest "t" value, before performing any triangle collision tests.

			// init
			var i:uint, j:uint;
			var entityRenderableItems:Dictionary = new Dictionary();
			var boundsCollisionPoints:Dictionary = new Dictionary();
			var boundsCollisionTs:Vector.<Number> = new Vector.<Number>();
			var entitiesWhoseBoundsAreHitByRay:Dictionary = new Dictionary();
			var alreadyCheckedEntity:Dictionary = new Dictionary();
			var objectSpaceRayPositions:Dictionary = new Dictionary();
			var objectSpaceRayDirections:Dictionary = new Dictionary();
			var cameraInBounds:Dictionary = new Dictionary();
			var entity:Entity;

			// update ray to shoot from mouse
			updateRay( _view.camera.position, _view.unproject( _view.mouseX, _view.mouseY ) );

			// filter entities whose bounds are hit by ray
			while(item) {
				var renderable:IRenderable = item.renderable;
				if( renderable.mouseEnabled ) {
					// identify the renderable's entity
					entity = renderable.sourceEntity;
					if( entity.visible && !alreadyCheckedEntity[ entity ] ) {
						// remember which renderables are associated with this entity
						if( !entityRenderableItems[ entity ] ) entityRenderableItems[ entity ] = new Vector.<RenderableListItem>;
						entityRenderableItems[ entity ].push( item );
						// transform ray to object space
						var transformedRayPosition:Vector3D = entity.inverseSceneTransform.transformVector( _rayPosition );
						var transformedRayDirection:Vector3D = entity.inverseSceneTransform.deltaTransformVector( _rayDirection );
						objectSpaceRayPositions[ entity ] = transformedRayPosition;
						objectSpaceRayDirections[ entity ] = transformedRayDirection;
						// perform collision check on bounds ( camera inside bounds counts as a hit and is a special case )
						var bounds:BoundingVolumeBase = entity.bounds;
						_t = bounds.intersectsRay( transformedRayPosition, transformedRayDirection );
						var cameraIsInsideBounds:Boolean = false;
						if( _t == -1 ) {
							cameraIsInsideBounds = bounds.containsPoint( transformedRayPosition );
						}
						if( cameraIsInsideBounds ) _t = 0;
						cameraInBounds[ entity ] = cameraIsInsideBounds;
						if( _t >= 0 ) { // if passed, store entity and some data
							boundsCollisionTs.push( _t );
							entitiesWhoseBoundsAreHitByRay[ _t ] = entity;
							var point:Vector3D = new Vector3D();
							point.x = transformedRayPosition.x + _t * transformedRayDirection.x;
							point.y = transformedRayPosition.y + _t * transformedRayDirection.y;
							point.z = transformedRayPosition.z + _t * transformedRayDirection.z;
							boundsCollisionPoints[ _t ] = point;
						}
					}
					alreadyCheckedEntity[ entity ] = true;
				}
				item = item.next;
			}

			// no bound hits?
			_numBoundHits = boundsCollisionTs.length;
			if( _numBoundHits == 0 ) {
				return _collisionExists = false;
			}

			// sort collisions from closest to furthest
			boundsCollisionTs = boundsCollisionTs.sort( Array.NUMERIC );

			// perform triangle tests on the entities, from closest to furthest
			for( i = 0; i < _numBoundHits; ++i ) {
				// retrieve entity
				_t = boundsCollisionTs[ i ];
				entity = entitiesWhoseBoundsAreHitByRay[ _t ];
				var items:Vector.<RenderableListItem> = entityRenderableItems[ entity ];
				var numItems:uint = items.length;
				// update triangle collider ray
				_triangleCollider.updateRay( objectSpaceRayPositions[ entity ], objectSpaceRayDirections[ entity ] );
				// sweep renderables
				for( j = 0; j < numItems; ++j ) {
					item = items[ j ];
					// need triangle collision test?
					if( cameraInBounds[ entity ] || item.renderable.mousePickingPrecision == MousePickingPrecision.MESH ) {
						if( _triangleCollider.evaluate( item ) ) {
							_collidingRenderable = _triangleCollider.collidingRenderable;
							_collisionPoint = _triangleCollider.collisionPoint;
							return _collisionExists = true; // exit at first triangle hit success
						}
					}
					else {
						_collidingRenderable = item.renderable;
						_collisionPoint = boundsCollisionPoints[ _t ];
						return _collisionExists = true;
					}
				}
			}

			return _collisionExists = false;
		}

		public function get collisionUV():Point {
			return _triangleCollider.collisionUV;
		}

		public function get numBoundHits():uint {
			return _numBoundHits;
		}
	}
}

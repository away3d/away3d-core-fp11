package away3d.core.raycast.colliders.mouse {

	import away3d.core.base.IRenderable;
	import away3d.core.data.LinkedListUtil;
	import away3d.core.data.ListItem;
	import away3d.core.raycast.*;

	import away3d.core.base.SubMesh;
	import away3d.core.data.RenderableListItem;
import away3d.core.raycast.colliders.*;
	import away3d.core.raycast.colliders.bounds.RenderableBoundsRayCollider;
	import away3d.core.raycast.colliders.bounds.vo.BoundsCollisionVO;
	import away3d.core.raycast.colliders.triangle.PBTriangleRayCollider;
	import away3d.entities.Entity;

import flash.geom.Point;
import flash.geom.Vector3D;
import flash.utils.Dictionary;

public class RenderableRayCollider extends RayColliderBase {

	private var _boundsCollider:RenderableBoundsRayCollider;
	private var _triangleCollider:PBTriangleRayCollider;

    public function RenderableRayCollider() {
        super();
		_boundsCollider = new RenderableBoundsRayCollider();
        _triangleCollider = new PBTriangleRayCollider();
    }

	override public function updateRay( position:Vector3D, direction:Vector3D ):void {
		super.updateRay( position, direction );
		_boundsCollider.updateRay( position, direction );
	}

	override public function updateCurrentListItem( currentListItem:ListItem ):void {
		super.updateCurrentListItem( currentListItem );
		_boundsCollider.updateCurrentListItem( currentListItem );
	}

    override public function evaluate():void {

		_collisionExists = false;
		_numberOfCollisions = 0;
		_lastCollidingListItem = null;

		// ---------------------------------------------------------------------
		// Filter out renderables whose bounds don't collide with ray.
		// ---------------------------------------------------------------------

		var boundsCollisionVO:BoundsCollisionVO;
		var renderableListItem:RenderableListItem;

		renderableListItem = RenderableListItem( _currentListItem );
		_boundsCollider.evaluate();
		if( !_boundsCollider.aCollisionExists ) {
			_collisionExists = false;
			return;
		}
		else {
			_currentListItem = _boundsCollider.collidingListItemHead;
		}

		// ---------------------------------------------------------------------
		// Evaluate triangle collisions when needed.
		// ---------------------------------------------------------------------

		var renderable:IRenderable;

		renderableListItem = RenderableListItem( _currentListItem );
		while( renderableListItem ) {

			renderable = renderableListItem.renderable;

			// TODO: Remove linked list util for function call overheads?

			if( renderable. ) {

			}

			boundsCollisionVO = _boundsCollider.collisionData[ renderableListItem ];



		}

        // find nearest collision and perform triangle collision tests where necessary
        var numItems:uint;
        var _nearestCollisionVO:BoundsCollisionVO = new BoundsCollisionVO();
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
//                        triTests++;
                        _triangleCollider.breakOnFirstTriangleHit = item.renderable.mouseHitMethod == MouseHitMethod.MESH_ANY_HIT;
						_triangleCollider.updateCurrentListItem( item.renderable as SubMesh );
						if( _triangleCollider.evaluate() ) { // triangle collision exists?
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

//        time = getTimer() - time;
//        trace( "phase 2 test time: " + time + ", with " + triTests + " triangle collision tests." );

        // use nearest collision found
        _t = _nearestCollisionVO.finalCollisionT;
        _collidingRenderables = _nearestCollisionVO.collidingRenderable;
        return _collisionExists = _nearestCollisionVO.finalCollisionT != Number.MAX_VALUE;
    }

    override public function get collisionPoint():Vector3D {
        if( !_collisionExists )
            return null;

        var point:Vector3D = new Vector3D();
        point.x = _nearestCollisionVO.localRayPosition.x + _nearestCollisionVO.finalCollisionT * _nearestCollisionVO.localRayDirection.x;
        point.y = _nearestCollisionVO.localRayPosition.y + _nearestCollisionVO.finalCollisionT * _nearestCollisionVO.localRayDirection.y;
        point.z = _nearestCollisionVO.localRayPosition.z + _nearestCollisionVO.finalCollisionT * _nearestCollisionVO.localRayDirection.z;
        return point;
    }


    public function get entity():Entity {
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

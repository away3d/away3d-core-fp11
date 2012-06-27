package away3d.core.pick
{
	import away3d.entities.*;
	
	import flash.geom.*;
	
	/**
	 * @author robbateman
	 */
	public class PickingCollisionVO
	{
		private var _entity:Entity;
		
		public var localPosition:Vector3D;
		
		public var localNormal:Vector3D;
		
		public var uv:Point;
		
		public var localRayPosition:Vector3D;
		
		public var localRayDirection:Vector3D;
		
		public var rayOriginIsInsideBounds:Boolean;
		
		public var collisionT:Number;
		
		public function get entity():Entity
		{
			return _entity;
		}
		
		function PickingCollisionVO(entity:Entity)
		{
			_entity = entity;
		}
		
	}
}

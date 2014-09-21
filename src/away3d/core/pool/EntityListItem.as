package away3d.core.pool
{
	import away3d.entities.IEntity;

	public class EntityListItem
	{
		public var entity:IEntity;
		public var next:EntityListItem;
	}
}

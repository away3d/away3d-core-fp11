package away3d.core.data
{
	
	import away3d.core.base.IRenderable;
	
	import flash.geom.Matrix3D;
	
	public final class RenderableListItem
	{
		public var next:RenderableListItem;
		public var renderable:IRenderable;
		
		// for faster access while sorting or rendering (cached values)
		public var materialId:int;
		public var renderOrderId:int;
		public var zIndex:Number;
		public var renderSceneTransform:Matrix3D;
		
		public var cascaded:Boolean;
		
		public function RenderableListItem()
		{
		
		}
	}
}

/**
 *
 */
package away3d.events
{
	import away3d.projections.ProjectionBase;
	
	import flash.events.Event;
	
	public class ProjectionEvent extends Event
	{
		public static const MATRIX_CHANGED:String = "matrixChanged";
		
		private var _lens:ProjectionBase;
		
		public function ProjectionEvent(type:String, lens:ProjectionBase, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			_lens = lens;
		}
		
		public function get lens():ProjectionBase
		{
			return _lens;
		}
		
		override public function clone():Event
		{
			return new ProjectionEvent(type, _lens, bubbles, cancelable);
		}
	}
}

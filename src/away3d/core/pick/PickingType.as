package away3d.core.pick
{
	public class PickingType
	{
		public static const SHADER:IPicker = new ShaderPicker();
		public static const RAYCAST_FIRST_ENCOUNTERED:IPicker = new RaycastPicker( false );
		public static const RAYCAST_BEST_HIT:IPicker = new RaycastPicker( true );
	}
}

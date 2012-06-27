package away3d.core.pick
{
	public class PickingMode
	{
		public static const SHADER_PICKER:IPicker = new ShaderPicker();
		public static const RAYCAST_PICKER:IPicker = new RaycastPicker( false );
		public static const RAYCAST_PICKER_1:IPicker = new RaycastPicker( true );
	}
}

package away3d.events
{
	import away3d.containers.View3D;
	import away3d.core.base.IRenderable;
	import away3d.core.base.Object3D;
	import away3d.materials.MaterialBase;

	import flash.events.Event;
	import flash.geom.Point;

	/**
	 * A MouseEvent3D is dispatched when a mouse event occurs over a mouseEnabled object in View3D.
	 * todo: we don't have screenZ data, nor global coords, tho this should be easy to implement
	 */
	public class MouseEvent3D extends Event
	{
		/**
    	 * Defines the value of the type property of a mouseOver3d event object.
    	 */
    	public static const MOUSE_OVER:String = "mouseOver3d";

    	/**
    	 * Defines the value of the type property of a mouseOut3d event object.
    	 */
    	public static const MOUSE_OUT:String = "mouseOut3d";

    	/**
    	 * Defines the value of the type property of a mouseUp3d event object.
    	 */
    	public static const MOUSE_UP:String = "mouseUp3d";

    	/**
    	 * Defines the value of the type property of a mouseDown3d event object.
    	 */
    	public static const MOUSE_DOWN:String = "mouseDown3d";

    	/**
    	 * Defines the value of the type property of a mouseMove3d event object.
    	 */
    	public static const MOUSE_MOVE:String = "mouseMove3d";

    	/**
    	 * Defines the value of the type property of a rollOver3d event object.
    	 */
    	public static const ROLL_OVER:String = "rollOver3d";

    	/**
    	 * Defines the value of the type property of a rollOut3d event object.
    	 */
    	public static const ROLL_OUT:String = "rollOut3d";

		/**
		 * Defines the value of the type property of a click3d event object.
		 */
		public static const CLICK : String = "click3d";

		/**
		 * Defines the value of the type property of a doubleClick3d event object.
		 */
		public static const DOUBLE_CLICK : String = "doubleClick3d";

		/**
		 * Defines the value of the type property of a mouseWheel3d event object.
		 */
		public static const MOUSE_WHEEL : String = "mouseWheel3d";

		/**
    	 * The horizontal coordinate at which the event occurred in view coordinates.
    	 */
        public var screenX:Number;

        /**
        * The vertical coordinate at which the event occurred in view coordinates.
        */
        public var screenY:Number;

		/**
		 * The view object inside which the event took place.
		 */
        public var view:View3D;

		/**
		 * The 3d object inside which the event took place.
		 */
        public var object:Object3D;

		/**
		 * The renderable inside which the event took place.
		 */
        public var renderable:IRenderable;

		/**
		 * The material of the 3d element inside which the event took place.
		 */
        public var material:MaterialBase;

		/**
		 * The uv coordinate inside the draw primitive where the event took place.
		 */
        public var uv : Point;

		/**
		 * The x-coordinate in object space where the event took place
		 */
		public var localX : Number;

		/**
		 * The y-coordinate in object space where the event took place
		 */
		public var localY : Number;

		/**
		 * The z-coordinate in object space where the event took place
		 */
		public var localZ : Number;

		/**
		 * Indicates whether the Control key is active (true) or inactive (false).
		 */
        public var ctrlKey:Boolean;

		/**
		 * Indicates whether the Alt key is active (true) or inactive (false).
		 */
        public var altKey:Boolean;

        /**
        * Indicates whether the Shift key is active (true) or inactive (false).
        */
        public var shiftKey:Boolean;

		/**
		 * Indicates how many lines should be scrolled for each unit the user rotates the mouse wheel.
		 */
		public var delta : int;

		/**
		 * Create a new MouseEvent3D object.
		 * @param type The type of the MouseEvent3D.
		 */
		public function MouseEvent3D(type : String)
		{
			super(type, false, true);
		}

		/**
		 * Creates a copy of the MouseEvent3D object and sets the value of each property to match that of the original.
		 */
        public override function clone():Event
        {
            var result:MouseEvent3D = new MouseEvent3D(type);

			if(isDefaultPrevented())
            	result.preventDefault();

            result.screenX = screenX;
            result.screenY = screenY;

            result.view = view;
            result.object = object;
			result.renderable = renderable;
            result.material = material;
            result.uv = uv;
            result.localX = localX;
            result.localY = localY;
            result.localZ = localZ;

            result.ctrlKey = ctrlKey;
            result.shiftKey = shiftKey;

            return result;
        }
	}
}
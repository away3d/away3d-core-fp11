package away3d.events
{
	
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.core.base.IRenderable;
	import away3d.materials.MaterialBase;
	
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	public class TouchEvent3D extends Event
	{
		// Private.
		arcane var _allowedToPropagate:Boolean = true;
		arcane var _parentEvent:TouchEvent3D;
		
		public static const TOUCH_END:String = "touchEnd3d";
		public static const TOUCH_BEGIN:String = "touchBegin3d";
		public static const TOUCH_MOVE:String = "touchMove3d";
		public static const TOUCH_OUT:String = "touchOut3d";
		public static const TOUCH_OVER:String = "touchOver3d";
		
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
		public var object:ObjectContainer3D;
		
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
		public var uv:Point;
		
		/**
		 * The index of the face where the event took place.
		 */
		public var index:uint;
		
		/**
		 * The index of the subGeometry where the event took place.
		 */
		public var subGeometryIndex:uint;
		
		/**
		 * The position in object space where the event took place
		 */
		public var localPosition:Vector3D;
		
		/**
		 * The normal in object space where the event took place
		 */
		public var localNormal:Vector3D;
		
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
		
		public var touchPointID:int;
		
		/**
		 * Create a new TouchEvent3D object.
		 * @param type The type of the TouchEvent3D.
		 */
		public function TouchEvent3D(type:String)
		{
			super(type, true, true);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function get bubbles():Boolean
		{
			// Don't bubble if propagation has been stopped.
			return super.bubbles && _allowedToPropagate;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function stopPropagation():void
		{
			super.stopPropagation();
			_allowedToPropagate = false;
			if (_parentEvent)
				_parentEvent._allowedToPropagate = false;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function stopImmediatePropagation():void
		{
			super.stopImmediatePropagation();
			_allowedToPropagate = false;
			if (_parentEvent)
				_parentEvent._allowedToPropagate = false;
		}
		
		/**
		 * Creates a copy of the TouchEvent3D object and sets the value of each property to match that of the original.
		 */
		public override function clone():Event
		{
			var result:TouchEvent3D = new TouchEvent3D(type);
			
			if (isDefaultPrevented())
				result.preventDefault();
			
			result.screenX = screenX;
			result.screenY = screenY;
			
			result.view = view;
			result.object = object;
			result.renderable = renderable;
			result.material = material;
			result.uv = uv;
			result.localPosition = localPosition;
			result.localNormal = localNormal;
			result.index = index;
			result.subGeometryIndex = subGeometryIndex;
			
			result.ctrlKey = ctrlKey;
			result.shiftKey = shiftKey;
			
			result._parentEvent = this;
			
			return result;
		}
		
		/**
		 * The position in scene space where the event took place
		 */
		public function get scenePosition():Vector3D
		{
			if (object is ObjectContainer3D)
				return ObjectContainer3D(object).sceneTransform.transformVector(localPosition);
			else
				return localPosition;
		}
		
		/**
		 * The normal in scene space where the event took place
		 */
		public function get sceneNormal():Vector3D
		{
			if (object is ObjectContainer3D) {
				var sceneNormal:Vector3D = ObjectContainer3D(object).sceneTransform.deltaTransformVector(localNormal);
				sceneNormal.normalize();
				return sceneNormal;
			} else
				return localNormal;
		}
	}
}

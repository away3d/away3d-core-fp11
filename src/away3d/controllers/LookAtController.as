package away3d.controllers
{
	import away3d.containers.*;
	import away3d.entities.*;
	import away3d.events.*;
	
	import flash.geom.*;
	
	
    /**
    * Extended camera used to automatically look at a specified target object.
    * 
    * @see away3d.containers.View3D
    */
    public class LookAtController extends ControllerBase
    {
        private var _lookAtObject:ObjectContainer3D;
		
		private function onLookAtObjectChanged(event:Object3DEvent):void
		{
			notifyUpdate();
		}
		
        /**
        * The 3d object that the target looks at.
        */
		public function get lookAtObject():ObjectContainer3D
		{
			return _lookAtObject;
		}
		
		public function set lookAtObject(val:ObjectContainer3D):void
		{
			if (_lookAtObject == val)
				return;
			
			if (_lookAtObject)
				_lookAtObject.removeEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
			
			_lookAtObject = val;
			
			if (_lookAtObject)
				_lookAtObject.addEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
			
			notifyUpdate();
		}
		
	    /**
	    * Creates a new <code>LookAtController</code> object.
		 */
        public function LookAtController(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null)
        {
            super(targetObject);
			
			this.lookAtObject = lookAtObject || new ObjectContainer3D();
        }
        
		/**
		 * @inheritDoc
		 */
		public override function update():void
		{
			if (targetObject != null || lookAtObject != null)
				targetObject.lookAt(lookAtObject.scene ? lookAtObject.scenePosition : lookAtObject.position);
		}
    }
}   

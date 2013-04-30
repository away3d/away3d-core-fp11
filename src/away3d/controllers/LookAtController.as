package away3d.controllers
{
	import away3d.containers.*;
	import away3d.entities.*;
	import away3d.events.*;

	import flash.geom.Vector3D;
	
    /**
    * Extended camera used to automatically look at a specified target object.
    * 
    * @see away3d.containers.View3D
    */
    public class LookAtController extends ControllerBase
    {
        protected var _lookAtPosition:Vector3D;
        protected var _lookAtObject:ObjectContainer3D;
		protected var _origin:Vector3D = new Vector3D(0.0,0.0,0.0);

		/**
		 * Creates a new <code>LookAtController</code> object.
		 */
		public function LookAtController(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null)
		{
			super(targetObject);

			if (lookAtObject)
				this.lookAtObject = lookAtObject;
			else
				this.lookAtPosition = new Vector3D();
		}

		/**
        * The Vector3D object that the target looks at.
        */
		public function get lookAtPosition():Vector3D
		{
			return _lookAtPosition;
		}
		
		public function set lookAtPosition(val:Vector3D):void
		{
			if (_lookAtObject){
				_lookAtObject.removeEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
				_lookAtObject = null;
			}
				
			_lookAtPosition = val;
			
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
			if(_lookAtPosition)
				_lookAtPosition = null;
			
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
		 * @inheritDoc
		 */
		public override function update(interpolate:Boolean = true):void
		{
			interpolate = interpolate;// prevents unused warning

			if (_targetObject) {
				
				if(_lookAtPosition) {
					_targetObject.lookAt(_lookAtPosition);
				} else if (_lookAtObject) {
					_targetObject.lookAt(_lookAtObject.scene ? _lookAtObject.scenePosition : _lookAtObject.position);
				}
			}
		}

		private function onLookAtObjectChanged(event:Object3DEvent):void
		{
			notifyUpdate();
		}
    }
}   

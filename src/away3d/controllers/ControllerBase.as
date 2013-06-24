package away3d.controllers
{
	import away3d.arcane;
	import away3d.entities.*;
	import away3d.errors.AbstractMethodError;
	
	use namespace arcane;
	
	public class ControllerBase
	{
		protected var _autoUpdate:Boolean = true;
		protected var _targetObject:Entity;
		
		protected function notifyUpdate():void
		{
			if (_targetObject && _targetObject.implicitPartition && _autoUpdate)
				_targetObject.implicitPartition.markForUpdate(_targetObject);
		}
		
		/**
		 * Target object on which the controller acts. Defaults to null.
		 */
		public function get targetObject():Entity
		{
			return _targetObject;
		}
		
		public function set targetObject(val:Entity):void
		{
			if (_targetObject == val)
				return;
			
			if (_targetObject && _autoUpdate)
				_targetObject._controller = null;
			
			_targetObject = val;
			
			if (_targetObject && _autoUpdate)
				_targetObject._controller = this;
			
			notifyUpdate();
		}
		
		/**
		 * Determines whether the controller applies updates automatically. Defaults to true
		 */
		public function get autoUpdate():Boolean
		{
			return _autoUpdate;
		}
		
		public function set autoUpdate(val:Boolean):void
		{
			if (_autoUpdate == val)
				return;
			
			_autoUpdate = val;
			
			if (_targetObject) {
				if (_autoUpdate)
					_targetObject._controller = this;
				else
					_targetObject._controller = null;
			}
		}
		
		/**
		 * Base controller class for dynamically adjusting the propeties of a 3D object.
		 *
		 * @param    targetObject    The 3D object on which to act.
		 */
		public function ControllerBase(targetObject:Entity = null):void
		{
			this.targetObject = targetObject;
		}
		
		/**
		 * Manually applies updates to the target 3D object.
		 */
		public function update(interpolate:Boolean = true):void
		{
			throw new AbstractMethodError();
		}
	}
}

package away3d.loaders.misc
{
	import away3d.events.LoaderEvent;
	import away3d.loaders.AssetLoader;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	/**
	 * Instances of this class are returned as tokens by loading operations
	 * to provide an object on which events can be listened for in cases where
	 * the actual asset loader is not directly available (e.g. when using the
	 * AssetLibrary to perform the load.)
	 * 
	 * By listening for events on this class instead of directly on the
	 * AssetLibrary, one can distinguish different loads from each other.
	 * 
	 * The token will dispatch all events that the original AssetLoader dispatches,
	 * while not providing an interface to obstruct the load and is as such a
	 * safer return value for loader wrappers than the loader itself.
	*/
	public class AssetLoaderToken extends EventDispatcher
	{
		private var _loader : AssetLoader;
		
		private var _eventBuffer : Object;
		
		public function AssetLoaderToken(loader : AssetLoader)
		{
			super();
			
			_eventBuffer = {};
			
			_loader = loader;
			_loader.addEventListener(LoaderEvent.LOAD_ERROR, onLoaderEvent);
			_loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onLoaderEvent);
			_loader.addEventListener(LoaderEvent.DEPENDENCY_COMPLETE, onLoaderEvent);
			_loader.addEventListener(LoaderEvent.DEPENDENCY_ERROR, onLoaderEvent);
		}
		
		
		public override function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			
			flushBuffer(type);
		}
		
		
		private function flushBuffer(type : String) : void
		{
			if (_eventBuffer.hasOwnProperty(type)) {
				var ev : Event;
				var events : Array = _eventBuffer[type];
				for each (ev in events) {
					dispatchEvent(ev.clone());
				}
			}
		}
		
		
		private function onLoaderEvent(ev : Event) : void
		{
			if (hasEventListener(ev.type)) {
				dispatchEvent(ev.clone());
			}
			else {
				// If no buffer exists for this type, create it.
				if (!_eventBuffer.hasOwnProperty(ev.type))
					_eventBuffer[ev.type] = [];
				
				// Add event to buffer.
				_eventBuffer[ev.type].push(ev);
			}
		}
	}
}
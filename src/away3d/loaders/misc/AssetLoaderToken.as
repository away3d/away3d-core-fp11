package away3d.loaders.misc
{
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.loaders.AssetLoader;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;

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
		
		public function AssetLoaderToken(loader : AssetLoader)
		{
			super();
			
			_loader = loader;
		}
		
		
		public override function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			_loader.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		
		public override function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			_loader.removeEventListener(type, listener, useCapture);
		}
		
		
		public override function hasEventListener(type:String):Boolean
		{
			return _loader.hasEventListener(type);
		}
		
		
		public override function willTrigger(type:String):Boolean
		{
			return _loader.willTrigger(type);
		}
	}
}
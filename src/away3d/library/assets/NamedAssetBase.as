package away3d.library.assets
{
	import away3d.arcane;
	import away3d.events.AssetEvent;
	
	import flash.events.EventDispatcher;

	use namespace arcane;
	
	public class NamedAssetBase extends EventDispatcher
	{
		private var _originalName : String;
		private var _namespace : String;
		private var _name : String;
		private var _full_path : Array;
		
		
		public function NamedAssetBase(name : String='')
		{
			_name = name;
			_originalName = name;
			
			update();
		}
		
		
		/**
		 * The original name used for this asset in the resource (e.g. file) in which
		 * it was found. This may not be the same as <code>name</code>, which may
		 * have changed due to of a name conflict.
		*/
		public function get originalName() : String
		{
			return _originalName;
		}
		
		
		public function get name() : String
		{
			return _name;
		}
		public function set name(val : String) : void
		{
			_name = val;
			update();
			
			if (hasEventListener(AssetEvent.ASSET_RENAME))
				dispatchEvent(new AssetEvent(AssetEvent.ASSET_RENAME));
		}
		
		
		public function get assetNamespace() : String
		{
			return _namespace;
		}
		
		
		public function get assetFullPath() : Array
		{
			return _full_path;
		}
		
		
		public function assetPathEquals(name : String, namespace : String) : Boolean
		{
			return (_name == name && (!namespace || _namespace==namespace));
		}
		
		
		public function resetAssetPath(name : String, namespace : String = null, overrideOriginal : Boolean = true) : void
		{
			_name = name? name : 'untitled';
			_namespace = namespace? namespace : 'default';
			if (overrideOriginal)
				_originalName = _name;
		
			update();
		}
		
		
		private function update() : void
		{
			_full_path = [ _namespace, _name ];
		}
	}
}
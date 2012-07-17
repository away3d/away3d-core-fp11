package away3d.loaders.parsers
{
	import away3d.arcane;
	import away3d.errors.AbstractMethodError;
	import away3d.events.AssetEvent;
	import away3d.events.ParserEvent;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.loaders.parsers.data.DefaultBitmapData;
	import away3d.loaders.parsers.utils.ParserUtil;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	use namespace arcane;
	
	/**
	 * <code>ParserBase</code> provides an abstract base class for objects that convert blocks of data to data structures
	 * supported by Away3D.
	 *
	 * If used by <code>AssetLoader</code> to automatically determine the parser type, two static public methods should
	 * be implemented, with the following signatures:
	 *
	 * <code>public static function supportsType(extension : String) : Boolean</code>
	 * Indicates whether or not a given file extension is supported by the parser.
	 *
	 * <code>public static function supportsData(data : *) : Boolean</code>
	 * Tests whether a data block can be parsed by the parser.
	 *
	 * Furthermore, for any concrete subtype, the method <code>initHandle</code> should be overridden to immediately
	 * create the object that will contain the parsed data. This allows <code>ResourceManager</code> to return an object
	 * handle regardless of whether the object was loaded or not.
	 *
	 * @see away3d.loading.parsers.AssetLoader
	 * @see away3d.loading.ResourceManager
	 */
	public class ParserBase extends EventDispatcher
	{
		arcane var _fileName:String;
		protected var _dataFormat : String;
		protected var _data : *;
		protected var _frameLimit : Number;
		protected var _lastFrameTime : Number;
		
		protected function getTextData():String
		{
			return ParserUtil.toString(_data);
		}
		
		protected function getByteData():ByteArray
		{
			return ParserUtil.toByteArray(_data);
		}
		
		private var _dependencies : Vector.<ResourceDependency>;
		private var _parsingPaused : Boolean;
		private var _parsingComplete : Boolean;
		private var _parsingFailure:Boolean;
		private var _timer : Timer;
		
		/**
		 * Returned by <code>proceedParsing</code> to indicate no more parsing is needed.
		 */
		protected static const PARSING_DONE : Boolean = true;
		
		/**
		 * Returned by <code>proceedParsing</code> to indicate more parsing is needed, allowing asynchronous parsing.
		 */
		protected static const MORE_TO_PARSE : Boolean = false;
		
		
		/**
		 * Creates a new ParserBase object
		 * @param format The data format of the file data to be parsed. Can be either <code>ParserDataFormat.BINARY</code> or <code>ParserDataFormat.PLAIN_TEXT</code>, and should be provided by the concrete subtype.
		 *
		 * @see away3d.loading.parsers.ParserDataFormat
		 */
		public function ParserBase(format : String)
		{
			_dataFormat = format;
			_dependencies = new Vector.<ResourceDependency>();
		}
		
		/**
		 * The url or id of the data or file to be parsed.
		 */
		public function get defaultBitmapData() : BitmapData
		{
			return DefaultBitmapData.bitmapData;
		}
		
		/**
		 * Validates a bitmapData loaded before assigning to a default BitmapMaterial 
		 */
		public function isBitmapDataValid(bitmapData: BitmapData) : Boolean
		{
			var isValid:Boolean = TextureUtils.isBitmapDataValid(bitmapData);
			if(!isValid) trace(">> Bitmap loaded is not having power of 2 dimensions or is higher than 2048");
			
			return isValid;
		}
		
		public function set parsingFailure(b:Boolean) : void
		{
			_parsingFailure = b;
		}
		public function get parsingFailure() : Boolean
		{
			return _parsingFailure;
		}
		
		
		public function get parsingPaused() : Boolean
		{
			return _parsingPaused;
		}
		
		
		public function get parsingComplete() : Boolean
		{
			return _parsingComplete;
		}
		
		
		/**
		 * The data format of the file data to be parsed. Can be either <code>ParserDataFormat.BINARY</code> or <code>ParserDataFormat.PLAIN_TEXT</code>.
		 */
		public function get dataFormat() : String
		{
			return _dataFormat;
		}
		
		/**
		 * Parse data (possibly containing bytearry, plain text or BitmapAsset) asynchronously, meaning that
		 * the parser will periodically stop parsing so that the AVM may proceed to the
		 * next frame.
		 *
		 * @param data The untyped data object in which the loaded data resides.
		 * @param frameLimit number of milliseconds of parsing allowed per frame. The
		 * actual time spent on a frame can exceed this number since time-checks can
		 * only be performed between logical sections of the parsing procedure.
		 */
		public function parseAsync(data : *, frameLimit : Number = 30) : void
		{
			_data = data;
			
			startParsing(frameLimit);
		}
		
		/**
		 * A list of dependencies that need to be loaded and resolved for the object being parsed.
		 */
		public function get dependencies() : Vector.<ResourceDependency>
		{
			return _dependencies;
		}
		
		/**
		 * Resolve a dependency when it's loaded. For example, a dependency containing an ImageResource would be assigned
		 * to a Mesh instance as a BitmapMaterial, a scene graph object would be added to its intended parent. The
		 * dependency should be a member of the dependencies property.
		 *
		 * @param resourceDependency The dependency to be resolved.
		 */
		arcane function resolveDependency(resourceDependency : ResourceDependency) : void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Resolve a dependency loading failure. Used by parser to eventually provide a default map
		 *
		 * @param resourceDependency The dependency to be resolved.
		 */
		arcane function resolveDependencyFailure(resourceDependency : ResourceDependency) : void
		{
			throw new AbstractMethodError();
		}
		
		arcane function resumeParsingAfterDependencies() : void
		{
			_dependencies.length = 0;
			_parsingPaused = false;
			_timer.start();
		}
		
		
		
		protected function finalizeAsset(asset : IAsset, name : String=null) : void
		{
			var type_event : String;
			var type_name : String;
			
			if (name)
				asset.name = name;
			
			switch (asset.assetType) {
				case AssetType.ANIMATION:
					type_name = 'animation';
					type_event = AssetEvent.ANIMATION_COMPLETE;
					break;
				case AssetType.ANIMATOR:
					type_name = 'animator';
					type_event = AssetEvent.ANIMATOR_COMPLETE;
					break;
				case AssetType.TEXTURE:
					type_name = 'texture';
					type_event = AssetEvent.BITMAP_COMPLETE;
					break;
				case AssetType.CONTAINER:
					type_name = 'container';
					type_event = AssetEvent.CONTAINER_COMPLETE;
					break;
				case AssetType.GEOMETRY:
					type_name = 'geometry';
					type_event = AssetEvent.GEOMETRY_COMPLETE;
					break;
				case AssetType.MATERIAL:
					type_name = 'material';
					type_event = AssetEvent.MATERIAL_COMPLETE;
					break;
				case AssetType.MESH:
					type_name = 'mesh';
					type_event = AssetEvent.MESH_COMPLETE;
					break;
				case AssetType.SKELETON:
					type_name = 'skeleton';
					type_event = AssetEvent.SKELETON_COMPLETE;
					break;
				case AssetType.SKELETON_POSE:
					type_name = 'skelpose';
					type_event = AssetEvent.SKELETON_POSE_COMPLETE;
					break;
				case AssetType.ENTITY:
					type_name = 'entity';
					type_event = AssetEvent.ENTITY_COMPLETE;
					break;
				default:
					throw new Error('Unhandled asset type '+asset.assetType+'. Report as bug!');
					break;
			}
				
			// If the asset has no name, give it
			// a per-type default name.
			if (!asset.name)
				asset.name = type_name;
			
			dispatchEvent(new AssetEvent(AssetEvent.ASSET_COMPLETE, asset));
			dispatchEvent(new AssetEvent(type_event, asset));
		}
		
		/**
		 * Parse the next block of data.
		 * @return Whether or not more data needs to be parsed. Can be <code>ParserBase.PARSING_DONE</code> or
		 * <code>ParserBase.MORE_TO_PARSE</code>.
		 */
		protected function proceedParsing() : Boolean
		{
			throw new AbstractMethodError();
			return true;
		}
		
		protected function dieWithError(message : String = 'Unknown parsing error') : void
		{
			_timer.removeEventListener(TimerEvent.TIMER, onInterval);
			_timer.stop();
			_timer = null;
			dispatchEvent(new ParserEvent(ParserEvent.PARSE_ERROR, message));
		}
		
		
		protected function addDependency(id : String, req : URLRequest, retrieveAsRawData : Boolean = false, data : * = null) : void
		{
			_dependencies.push(new ResourceDependency(id, req, data, this, retrieveAsRawData));
		}
		
		
		protected function pauseAndRetrieveDependencies() : void
		{
			_timer.stop();
			_parsingPaused = true;
			dispatchEvent(new ParserEvent(ParserEvent.READY_FOR_DEPENDENCIES));
		}
		
		
		/**
		 * Tests whether or not there is still time left for parsing within the maximum allowed time frame per session.
		 * @return True if there is still time left, false if the maximum allotted time was exceeded and parsing should be interrupted.
		 */
		protected function hasTime() : Boolean
		{
			return ((getTimer() - _lastFrameTime) < _frameLimit);
		}
		
		/**
		 * Called when the parsing pause interval has passed and parsing can proceed.
		 */
		protected function onInterval(event : TimerEvent = null) : void
		{
			_lastFrameTime = getTimer();
			
			if (proceedParsing() && !_parsingFailure)
				finishParsing();
		}
		
		/**
		 * Initializes the parsing of data.
		 * @param frameLimit The maximum duration of a parsing session.
		 */
		private function startParsing(frameLimit : Number) : void
		{
			_frameLimit = frameLimit;
			_timer = new Timer(_frameLimit, 0);
			_timer.addEventListener(TimerEvent.TIMER, onInterval);
			_timer.start();
		}
		
		
		/**
		 * Finish parsing the data.
		 */
		protected function finishParsing() : void
		{
			_timer.removeEventListener(TimerEvent.TIMER, onInterval);
			_timer.stop();
			_timer = null;
			_parsingComplete = true;
			dispatchEvent(new ParserEvent(ParserEvent.PARSE_COMPLETE));
		}
	}
}


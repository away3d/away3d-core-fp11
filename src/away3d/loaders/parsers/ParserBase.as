package away3d.loaders.parsers
{
	import away3d.arcane;
	import away3d.core.base.SkinnedSubGeometry;
	import away3d.core.base.SubGeometry;
	import away3d.errors.AbstractMethodError;
	import away3d.events.AssetEvent;
	import away3d.events.ParserEvent;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.loaders.misc.ResourceDependency;
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
	 * Dispatched when the parsing finishes.
	 * 
	 * @eventType away3d.events.ParserEvent
	 */
	[Event(name="parseComplete", type="away3d.events.ParserEvent")]
	
	/**
	 * Dispatched when parser pauses to wait for dependencies, used internally to trigger
	 * loading of dependencies which are then returned to the parser through it's interface
	 * in the arcane namespace.
	 * 
	 * @eventType away3d.events.ParserEvent
	 */
	[Event(name="readyForDependencies", type="away3d.events.ParserEvent")]
	
	/**
	 * Dispatched if an error was caught during parsing.
	 * 
	 * @eventType away3d.events.ParserEvent
	 */
	[Event(name="parseError", type="away3d.events.ParserEvent")]
	
	/**
	 * Dispatched when any asset finishes parsing. Also see specific events for each
	 * individual asset type (meshes, materials et c.)
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="assetComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a geometry asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="geometryComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a skeleton asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="skeletonComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a skeleton pose asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="skeletonPoseComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a container asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="containerComplete", type="away3d.events.AssetEvent")]
		
	/**
	 * Dispatched when an animation set has been constructed from a group of animation state resources.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="animationSetComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when an animation state has been constructed from a group of animation node resources.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="animationStateComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when an animation node has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="animationNodeComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when an animation state transition has been constructed from a group of animation node resources.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="stateTransitionComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a texture asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="textureComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a material asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="materialComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a animator asset has been constructed from a resource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	[Event(name="animatorComplete", type="away3d.events.AssetEvent")]
	
	
	
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
			_parsingPaused = false;
			_timer.start();
		}
		
		
		
		protected function finalizeAsset(asset : IAsset, name : String=null) : void
		{
			var type_event : String;
			var type_name : String;
			
			if (name != null)
				asset.name = name;
			
			switch (asset.assetType) {
				case AssetType.ANIMATION_SET:
					type_name = 'animationSet';
					type_event = AssetEvent.ANIMATION_SET_COMPLETE;
					break;
				case AssetType.ANIMATION_STATE:
					type_name = 'animationState';
					type_event = AssetEvent.ANIMATION_STATE_COMPLETE;
					break;
				case AssetType.ANIMATION_NODE:
					type_name = 'animationNode';
					type_event = AssetEvent.ANIMATION_NODE_COMPLETE;
					break;
				case AssetType.STATE_TRANSITION:
					type_name = 'stateTransition';
					type_event = AssetEvent.STATE_TRANSITION_COMPLETE;
					break;
				case AssetType.TEXTURE:
					type_name = 'texture';
					type_event = AssetEvent.TEXTURE_COMPLETE;
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
		
		
		protected function addDependency(id : String, req : URLRequest, retrieveAsRawData : Boolean = false, data : * = null, suppressErrorEvents : Boolean = false) : void
		{
			_dependencies.push(new ResourceDependency(id, req, data, this, retrieveAsRawData, suppressErrorEvents));
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
		
		
		/**
		 * Build a sub-geometry from data vectors.
		*/
		protected function constructSubGeometry(verts : Vector.<Number>, indices : Vector.<uint>, uvs : Vector.<Number>, 
										  normals : Vector.<Number>, tangents : Vector.<Number>, 
										  weights : Vector.<Number>, jointIndices : Vector.<Number>) : SubGeometry
		{
			var sub : SubGeometry;
			
			if (weights && jointIndices) {
				// If there were weights and joint indices defined, this
				// is a skinned mesh and needs to be built from skinned
				// sub-geometries.
				sub = new SkinnedSubGeometry(weights.length / (verts.length/3));
				SkinnedSubGeometry(sub).updateJointWeightsData(weights);
				SkinnedSubGeometry(sub).updateJointIndexData(jointIndices);
			}
			else {
				sub = new SubGeometry();
			}
			
			sub.updateVertexData(verts);
			sub.updateIndexData(indices);
			
			// Use explciti UVs or configure auto-generation
			if (uvs && uvs.length) {
				sub.updateUVData(uvs);
				sub.autoGenerateDummyUVs = false;
			}
			else {
				sub.autoGenerateDummyUVs = true;
			}
			
			// Use explicit normals or configure auto-generation
			if (normals && normals.length){
				sub.updateVertexNormalData(normals);
				sub.autoDeriveVertexNormals = false;
			}
			else {
				sub.autoDeriveVertexNormals = true;
			}
			
			// Use explicit tangents or configure auto-generation
			if (tangents && tangents.length) {
				sub.updateVertexTangentData(tangents);
				sub.autoDeriveVertexTangents = false;
			}
			else {
				sub.autoDeriveVertexTangents = true;
			}
			
			return sub;
		}
		
		
		/**
		 * Build a list of sub-geometries from raw data vectors, splitting them up in 
		 * such a way that they won't exceed buffer length limits.
		*/
		protected function constructSubGeometries(verts : Vector.<Number>, indices : Vector.<uint>, uvs : Vector.<Number>, 
											normals : Vector.<Number>, tangents : Vector.<Number>, 
											weights : Vector.<Number>, jointIndices : Vector.<Number>) : Vector.<SubGeometry>
		{
			const LIMIT : uint = 3*0xffff;
			var subs : Vector.<SubGeometry> = new Vector.<SubGeometry>();
			
			if (verts.length >= LIMIT || indices.length >= LIMIT) {
				var i : uint, len : uint, outIndex : uint;
				var splitVerts : Vector.<Number> = new Vector.<Number>();
				var splitIndices : Vector.<uint> = new Vector.<uint>();
				var splitUvs : Vector.<Number> = (uvs != null)? new Vector.<Number>() : null;
				var splitNormals : Vector.<Number> = (normals != null)? new Vector.<Number>() : null;
				var splitTangents : Vector.<Number> = (tangents != null)? new Vector.<Number>() : null;
				var splitWeights : Vector.<Number> = (weights != null)? new Vector.<Number>() : null;
				var splitJointIndices: Vector.<Number> = (jointIndices != null)? new Vector.<Number>() : null;
				
				var mappings : Vector.<int> = new Vector.<int>(verts.length/3, true);
				i = mappings.length;
				while (i-- > 0) 
					mappings[i] = -1;
				
				// Loop over all triangles
				outIndex = 0;
				len = indices.length;
				for (i=0; i<len; i+=3) {
					var j : uint;
					
					if (outIndex*3 >= LIMIT) {
						subs.push(constructSubGeometry(splitVerts, splitIndices, splitUvs, splitNormals, splitTangents, splitWeights, splitJointIndices));
						splitVerts = new Vector.<Number>();
						splitIndices = new Vector.<uint>();
						splitUvs = (uvs != null)? new Vector.<Number>() : null;
						splitNormals = (normals != null)? new Vector.<Number>() : null;
						splitTangents = (tangents != null)? new Vector.<Number>() : null;
						splitWeights = (weights != null)? new Vector.<Number>() : null;
						splitJointIndices = (jointIndices != null)? new Vector.<Number>() : null;
						
						j = mappings.length;
						while (j-- > 0)
							mappings[j] = -1;
						
						outIndex = 0;
					}
					
					// Loop over all vertices in triangle
					for (j=0; j<3; j++) {
						var originalIndex : uint;
						var splitIndex : uint;
						
						originalIndex = indices[i+j];
						
						if (mappings[originalIndex] >= 0) {
							splitIndex = mappings[originalIndex];
						}
						else {
							var o0 : uint, o1 : uint, o2 : uint,
							s0 : uint, s1 : uint, s2 : uint;
							
							o0 = originalIndex*3 + 0;
							o1 = originalIndex*3 + 1;
							o2 = originalIndex*3 + 2;
							
							// This vertex does not yet exist in the split list and
							// needs to be copied from the long list.
							splitIndex = splitVerts.length / 3;
							s0 = splitIndex*3+0;
							s1 = splitIndex*3+1;
							s2 = splitIndex*3+2;
							
							splitVerts[s0] = verts[o0];
							splitVerts[s1] = verts[o1];
							splitVerts[s2] = verts[o2];
							
							if (uvs) {
								var su : uint, ou : uint, sv : uint, ov : uint;
								su = splitIndex*2+0;
								sv = splitIndex*2+1;
								ou = originalIndex*2+0;
								ov = originalIndex*2+1;
								
								splitUvs[su] = uvs[ou];
								splitUvs[sv] = uvs[ov];
							}
							
							if (normals) {
								splitNormals[s0] = normals[o0];
								splitNormals[s1] = normals[o1];
								splitNormals[s2] = normals[o2];
							}
							
							if (tangents) {
								splitTangents[s0] = tangents[o0];
								splitTangents[s1] = tangents[o1];
								splitTangents[s2] = tangents[o2];
							}
							
							if (weights) {
								splitWeights[s0] = weights[o0];
								splitWeights[s1] = weights[o1];
								splitWeights[s2] = weights[o2];
							}
							
							if (jointIndices) {
								splitJointIndices[s0] = jointIndices[o0];
								splitJointIndices[s1] = jointIndices[o1];
								splitJointIndices[s2] = jointIndices[o2];
							}
							
							mappings[originalIndex] = splitIndex;
						}
						
						// Store new index, which may have come from the mapping look-up,
						// or from copying a new set of vertex data from the original vector
						splitIndices[outIndex+j] = splitIndex;
					}
					
					outIndex += 3;
				}
				
				if (splitVerts.length > 0) {
					// More was added in the last iteration of the loop.
					subs.push(constructSubGeometry(splitVerts, splitIndices, splitUvs, splitNormals, splitTangents, splitWeights, splitJointIndices));
				}
			}
			else {
				subs.push(constructSubGeometry(verts, indices, uvs, normals, tangents, weights, jointIndices));
			}
			
			return subs;
		}
	}
}


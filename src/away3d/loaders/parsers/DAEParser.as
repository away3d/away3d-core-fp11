package away3d.loaders.parsers
{
	import away3d.animators.AnimatorBase;
	import away3d.animators.SmoothSkeletonAnimator;
	import away3d.animators.data.AnimationSequenceBase;
	import away3d.animators.data.SkeletonAnimation;
	import away3d.animators.data.SkeletonAnimationSequence;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.JointPose;
	import away3d.animators.skeleton.Skeleton;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.animators.skeleton.SkeletonPose;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.LensBase;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.SkinnedSubGeometry;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;
	import away3d.library.assets.BitmapDataAsset;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.PointLight;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.materials.BitmapMaterial;
	import away3d.materials.ColorMaterial;
	import away3d.materials.MaterialBase;
	import away3d.materials.methods.BasicAmbientMethod;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.primitives.Sphere;
	
	import flash.display.BitmapData;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	
	use namespace arcane;
	
	/**
	 * Provides a parser for the Collada (DAE) data type.
	 */
	public class DAEParser extends ParserBase
	{	
		public static const CONFIG_USE_GPU 		: uint = 1;
		
		public static const PARSE_GEOMETRIES 	: uint = 1;
		public static const PARSE_IMAGES		: uint = 2;
		public static const PARSE_CAMERAS 		: uint = 4;
		public static const PARSE_LIGHTS 		: uint = 8;
		public static const PARSE_MATERIALS 	: uint = 16;
		public static const PARSE_VISUAL_SCENES : uint = 32;
		public static const PARSE_DEFAULT		: uint = PARSE_GEOMETRIES | PARSE_IMAGES |
														 PARSE_CAMERAS | PARSE_LIGHTS |
														 PARSE_MATERIALS | PARSE_VISUAL_SCENES;
		private var _doc : XML;
		private var _ns : Namespace;
		private var _parseState : uint = 0;
		private var _imageList : XMLList;
		private var _imageCount : uint;
		private var _currentImage : uint;
		private var _dependencyCount : uint = 0;
		
		private var _configFlags : uint;
		private var _parseFlags : uint;
		
		private var _libImages : Object;
		private var _libMaterials : Object;
		private var _libEffects : Object;
		private var _libGeometries : Object;
		private var _libControllers : Object;
		private var _libAnimations : Object;
		private var _libCameras : Object;
		private var _libLights : Object;
		
		private var _scene : DAEScene;
		private var _root : DAEVisualScene;
		private var _rootContainer : ObjectContainer3D;
		
		private var _geometries : Vector.<Geometry>;
		
		private var _animationInfo : DAEAnimationInfo;
		private var _animators : Vector.<AnimatorBase>;
		private var _sequences : Vector.<AnimationSequenceBase>;
		
		private var _defaultBitmapMaterial:BitmapMaterial = new BitmapMaterial(defaultBitmapData, true, true);
		private var _defaultColorMaterial:ColorMaterial = new ColorMaterial(0xff0000);
		
		private static var _numInstances:uint = 0;
		
		/**
		 * Constructor
		 * 
		 * @param	useGPU	Whether to use GPU for skinning
		 */ 
		public function DAEParser(configFlags : uint = 0, parseFlags : uint = 0)
		{
			_configFlags = configFlags > 0 ? configFlags : CONFIG_USE_GPU;
			_parseFlags = parseFlags > 0 ? parseFlags : PARSE_DEFAULT;
			
 			super(ParserDataFormat.PLAIN_TEXT);
		}
		
		/**
		 * Gets a Geometry by name.
		 * 
		 * @param	name
		 * @param	clone
		 * 
		 * @return the found Geometry or null on failure.
		 */ 
		public function getGeometryByName(name : String, clone : Boolean = false) : Geometry
		{
			if (!_geometries)
				return null;
			
			for each (var geometry : Geometry in _geometries) {
				if (geometry.name == name)
					return (clone ? geometry.clone() : geometry);
			}
			
			return null;
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension : String) : Boolean 
		{
			extension = extension.toLowerCase();
			return extension == "dae";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data : *) : Boolean 
		{
			// TODO
			return true;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependency(resourceDependency:ResourceDependency):void 
		{
			if (resourceDependency.assets.length != 1)
				return;
			
			var resource:BitmapDataAsset = resourceDependency.assets[0] as BitmapDataAsset;
			
			_dependencyCount--;
			
			if (resource && resource.bitmapData) {
				var image:DAEImage = _libImages[ resourceDependency.id ] as DAEImage;
				
				if (image) {
					image.resource = resource;
					if (!isBitmapDataValid(resource.bitmapData)) {
						// TODO: handle odd-sized bitmaps
					}
				}
			}
			
			if (_dependencyCount == 0)
				_parseState = DAEParserState.PARSE_MATERIALS;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{			
			if (resourceDependency.assets.length != 1)
				return;
			
			var resource:BitmapDataAsset = resourceDependency.assets[0] as BitmapDataAsset;
			
			_dependencyCount--;
			
			if (_dependencyCount == 0)
				_parseState = DAEParserState.PARSE_MATERIALS;
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function proceedParsing() : Boolean
		{
			switch (_parseState)
			{
				case DAEParserState.LOAD_XML:
					_doc = new XML(getTextData());
					_ns = _doc.namespace();
					
					_imageList = _doc._ns::library_images._ns::image;
					_imageCount = _dependencyCount = _imageList.length();
					_currentImage = 0;
					
					_parseState = _imageCount > 0 ? DAEParserState.PARSE_IMAGES : DAEParserState.PARSE_MATERIALS;
					break;
				
				case DAEParserState.PARSE_IMAGES:
					_libImages = parseLibrary(_doc._ns::library_images._ns::image, DAEImage);
					for (var imageId:String in _libImages) {
						var image:DAEImage = _libImages[imageId] as DAEImage;
						
						addDependency(image.id, new URLRequest(image.init_from));
					}
					pauseAndRetrieveDependencies();
					break;
				
				case DAEParserState.PARSE_MATERIALS:
					_libMaterials = parseLibrary(_doc._ns::library_materials._ns::material, DAEMaterial);
					_libEffects = parseLibrary(_doc._ns::library_effects._ns::effect, DAEEffect);
					
					setupMaterials();
					
					_parseState = DAEParserState.PARSE_GEOMETRIES;
					break;
				
				case DAEParserState.PARSE_GEOMETRIES:
					_libGeometries = parseLibrary(_doc._ns::library_geometries._ns::geometry, DAEGeometry);
					_geometries = translateGeometries();
					_parseState = DAEParserState.PARSE_CONTROLLERS;
					break;
				
				case DAEParserState.PARSE_CONTROLLERS:
					_libControllers = parseLibrary(_doc._ns::library_controllers._ns::controller, DAEController);
					_parseState = DAEParserState.PARSE_CAMERAS;
					break;
				
				case DAEParserState.PARSE_CAMERAS:
					_libCameras = parseLibrary(_doc._ns::library_cameras._ns::camera, DAECamera);
					_parseState = DAEParserState.PARSE_LIGHTS;
					break;
				
				case DAEParserState.PARSE_LIGHTS:
					_libLights = parseLibrary(_doc._ns::library_lights._ns::light, DAELight);
					_parseState = DAEParserState.PARSE_VISUAL_SCENE;
					break;
				
				case DAEParserState.PARSE_VISUAL_SCENE:
					_scene = null;
					_root = null;
					
					_libAnimations = parseLibrary(_doc._ns::library_animations._ns::animation, DAEAnimation);
					_animators = new Vector.<AnimatorBase>();
					_sequences = new Vector.<AnimationSequenceBase>();
					
					if (_doc.._ns::scene && _doc.._ns::scene.length()) {
						_scene = new DAEScene(_doc.._ns::scene[0]);
						
						var list : XMLList = _doc.._ns::visual_scene.(@id == _scene.instance_visual_scene.url);
						
						if (list.length()) {
							_rootContainer = new ObjectContainer3D();
							_root = new DAEVisualScene(this, list[0]);
							_root.updateTransforms(_root);
							
							_animationInfo = parseAnimationInfo();
							
							parseSceneGraph(_root, _rootContainer);
						}
					}
					_parseState = isAnimated ? DAEParserState.PARSE_ANIMATIONS : DAEParserState.PARSE_COMPLETE;
					break;
				
				case DAEParserState.PARSE_ANIMATIONS:
					_parseState = DAEParserState.PARSE_COMPLETE;
					break;
				
				case DAEParserState.PARSE_COMPLETE:
					for each (var sequence:AnimationSequenceBase in _sequences) {
						for each (var animator:AnimatorBase in _animators) {
							if (animator is SmoothSkeletonAnimator) {
								if (SmoothSkeletonAnimator(animator).hasSequence(sequence.name)) {
									SmoothSkeletonAnimator(animator).play(sequence.name);
									break;
								}
							}
						}
					}
					finalizeAsset(_rootContainer, "COLLADA_ROOT_" + (_numInstances++));
					return PARSING_DONE;
					break;
				
				default:
					break;
			}
			return MORE_TO_PARSE;
		}
		
		private function applySkinBindShape(geometry : Geometry, skin : DAESkin) : void
		{
			var vec : Vector3D = new Vector3D();
			var i : int;
			for each (var sub : SubGeometry in geometry.subGeometries) {
				var vertexData : Vector.<Number> = sub.vertexData;
				for (i = 0; i < vertexData.length; i += 3) {
					vec.x = vertexData[i+0];
					vec.y = vertexData[i+1];
					vec.z = vertexData[i+2];
					vec = skin.bind_shape_matrix.transformVector(vec);
					vertexData[i+0] = vec.x;
					vertexData[i+1] = vec.y;
					vertexData[i+2] = vec.z;
				}
				sub.updateVertexData(vertexData);
			}
		}
		
		private function applySkinController(geometry : Geometry, mesh : DAEMesh, skin : DAESkin, skeleton : Skeleton) : void
		{
			var sub : SubGeometry;
			var skinned_sub_geom : SkinnedSubGeometry;
			var primitive : DAEPrimitive;
			var jointIndices:Vector.<Number>;
			var jointWeights:Vector.<Number>
			var i : int, j : int, k : int, l : int;
			
			for (i = 0; i < geometry.subGeometries.length; i++) {
				sub = geometry.subGeometries[i];
				primitive = mesh.primitives[i];
				
				jointIndices = new Vector.<Number>(skin.maxBones * primitive.vertices.length, true);
				jointWeights = new Vector.<Number>(skin.maxBones * primitive.vertices.length, true);
				l = 0;
				
				for (j = 0; j < primitive.vertices.length; j++) {
					var weights:Vector.<DAEVertexWeight> = skin.weights[primitive.vertices[j].daeIndex];
					
					for (k = 0; k < weights.length; k++) {
						var influence:DAEVertexWeight = weights[k];
						
						// indices need to be multiplied by 3 (amount of matrix registers)
						jointIndices[l] = influence.joint * 3;
						jointWeights[l++] = influence.weight;
					}
					
					for (k = weights.length; k < skin.maxBones; k++) {
						jointIndices[l] = 0;
						jointWeights[l++] = 0;
					}
				}
				
				skinned_sub_geom = new SkinnedSubGeometry(skin.maxBones);
				skinned_sub_geom.updateVertexData(sub.vertexData);
				skinned_sub_geom.updateIndexData(sub.indexData);
				skinned_sub_geom.updateUVData(sub.UVData);
				skinned_sub_geom.updateJointIndexData(jointIndices);
				skinned_sub_geom.updateJointWeightsData(jointWeights);
				geometry.subGeometries[i] = skinned_sub_geom;
				geometry.subGeometries[i].parentGeometry = geometry;
			}
		}
		
		private function findControllerGeometry(node : DAENode) : DAEInstanceGeometry
		{
			var instance_geometry : DAEInstanceGeometry = new DAEInstanceGeometry();
			
			for (var i:int = 0; i < node.instance_controllers.length; i++) {
				var instance_controller : DAEInstanceController = node.instance_controllers[i];
				var controller : DAEController = _libControllers[instance_controller.url];
				
				instance_geometry.bind_material = instance_controller.bind_material;
				
				while (controller) {
					var source:String = controller.skin ? 
						controller.skin.source : 
						(controller.morph ? controller.morph.source : "");
					
					if (_libGeometries[source]) {
						instance_geometry.url = source;
						return instance_geometry;
					}
					controller = _libControllers[source];
				}
			}
			return null;
		}
		
		private function hasGeometry(node : DAENode) : Boolean
		{
			if (node.instance_geometries.length > 0)
				return true;
			
			if (findControllerGeometry(node) != null)
				return true;
			
			return false;
		}
		
		private function parseAnimationInfo() : DAEAnimationInfo
		{
			var info : DAEAnimationInfo = new DAEAnimationInfo();
			
			info.minTime = Number.MAX_VALUE;
			info.maxTime = -info.minTime;
			info.numFrames = 0;
			
			for each (var animation:DAEAnimation in _libAnimations) {
				for each (var channel:DAEChannel in animation.channels) {
					var node : DAENode = _root.findNodeById(channel.targetId);
					if (node) {
						node.channels.push(channel);
						info.minTime = Math.min(info.minTime, channel.sampler.minTime);
						info.maxTime = Math.max(info.maxTime, channel.sampler.maxTime);
						info.numFrames = Math.max(info.numFrames, channel.sampler.input.length);
					}
				}
			}
			
			return info;
		}
		
		/**
		 * 
		 */
		private function parseCamera(node : DAENode, instance_camera : DAEInstanceCamera) : Camera3D {
			var cam : DAECamera;
			var perspective : DAEPerspective;
			var orthographic : DAEOrthographic;
			var camera : Camera3D;
			var lens : LensBase;
			
			if (!_libCameras.hasOwnProperty(instance_camera.url))
				return null;
			
			cam = _libCameras[instance_camera.url] as DAECamera;
			if (cam.optics.orthographic) {
				trace ("orthographic cameras not supported yet");
				return null;
			} else if (cam.optics.perspective) {
				perspective = cam.optics.perspective;
				if (!isNaN(perspective.yfov)) {
					lens = new PerspectiveLens(cam.optics.perspective.yfov);
				} else {
					trace ("unhandled camera instance");
					return null;
				}
			} else {
				return null;
			}
			
			camera = new Camera3D(lens);
			camera.name = "daeCamera_" + node.id;
			return camera;
		}
		
		private function parseCameras(container : ObjectContainer3D, node : DAENode) : void
		{
			if (!node.instance_cameras || node.instance_cameras.length == 0)
				return;
			
			for (var i:int = 0; i < node.instance_cameras.length; i++) {
				var camera : Camera3D = parseCamera(node, node.instance_cameras[i]);
				if (camera) {
					container.addChild(camera);
					finalizeAsset(camera);
				}
			}
		}
		
		/**
		 * Parses a COLLADA library element.
		 * 
		 * @param	list
		 * @param 	clas
		 */ 
		private function parseLibrary(list : XMLList, clas : Class) : Object
		{
			var library:Object = new Object();
			
			for (var i:int = 0; i < list.length(); i++) {
				var obj : * = new clas(list[i]);
				library[ obj.id ] = obj;
			}
			
			return library;
		}
		
		/**
		 * 
		 */ 
		private function parseLight(node : DAENode, instance : DAEInstanceLight) : LightBase
		{
			if (!_libLights.hasOwnProperty(instance.url))
				return null;
			
			var daeLight : DAELight = _libLights[instance.url] as DAELight;
			var light : LightBase;
			var directional : DirectionalLight;
			var point : PointLight;
			
			if (daeLight.light is DAEAmbient) {
				trace ("[WARNING] DAEParser: ambient lights not supported");
			} else if (daeLight.light is DAEDirectional) {
				 light = directional = new DirectionalLight();

			} else if (daeLight.light is DAEPoint) {
				 light = point = new PointLight();
				
				
			} else if (daeLight.light is DAESpot) {
				trace ("[WARNING] DAEParser: spot lights not supported");
			}
			
			if (light is LightBase) {
				light.name = "daeLight_" + node.id;
				light.transform.rawData = node.matrix.rawData;
			}
			
			return light;
		}
		
		/**
		 * 
		 */ 
		private function parseLights(container : ObjectContainer3D, node : DAENode) : void
		{
			if (!node.instance_lights || node.instance_lights.length == 0)
				return;
			
			for (var i:int = 0; i < node.instance_lights.length; i++) {
				var light : LightBase = parseLight(node, node.instance_lights[i]);
				if (light) {
					container.addChild(light);
					finalizeAsset(light);
				}
			}
		}
		
		/**
		 * 
		 */ 
		private function parseSceneGraph(node : DAENode, parent : ObjectContainer3D = null):void
		{
			var container : ObjectContainer3D;
			var i : int;
			
			if (node.type != "JOINT") {
				
				container = new ObjectContainer3D();
				container.name = node.id;
				container.transform.rawData = node.matrix.rawData;	
				
				processGeometries(node, container);
				processControllers(node, container);
				
				if (parent) {
					parent.addChild(container);
				}
			}
			
			for (i = 0; i < node.nodes.length; i++) {
				parseSceneGraph(node.nodes[i], container);
			}
		}
		
		/**
		 * 
		 */ 
		private function processController(controller : DAEController) : Geometry
		{
			if (controller.morph) {
				return processMorphController(controller);
			}
			else if (controller.skin) {
				
			}
			return null;
		}
		
		/**
		 * 
		 */ 
		private function processMorphController(controller : DAEController) : Geometry
		{
			var morph : DAEMorph = controller.morph;
			var targets : Vector.<Geometry> = new Vector.<Geometry>();
			var base : Geometry = getGeometryByName(morph.source);
			var vertexData : Vector.<Number>;
			var sub : SubGeometry;
			var startWeight : Number = 1.0;
			var i : int, j : int, k : int;
			
			if (!base) {
				if (_libControllers[morph.source]) {
					base = processController(_libControllers[morph.source]);
				} 	
			}
			
			if  (!base) {
				return null;
			}
		
			for (i = 0; i < morph.targets.length; i++) {
				var geometry : Geometry = getGeometryByName(morph.targets[i]);
				if (!geometry) {
					return null;
				}
				targets.push(geometry);
				startWeight -= morph.weights[i];
			}
			
			for (i = 0; i < base.subGeometries.length; i++) {
				sub = base.subGeometries[i];
				vertexData = new Vector.<Number>(sub.vertexData.length);
				for (j = 0; j < vertexData.length; j++) {
					vertexData[j] = morph.method == "NORMALIZED" ? startWeight * sub.vertexData[j] : sub.vertexData[j];
					for (k = 0; k < morph.targets.length; k++) {
						vertexData[j] += morph.weights[k] * targets[k].subGeometries[i].vertexData[j];
					}
				}
				sub.updateVertexData(vertexData);
			}
			
			return base;
		}
		
		/**
		 * 
		 */ 
		private function processControllers(node : DAENode, container : ObjectContainer3D) : void
		{
			var instance : DAEInstanceController;
			var instance_geometry : DAEInstanceGeometry;
			var daeGeometry : DAEGeometry;
			var controller : DAEController;
			var effects : Vector.<DAEEffect>;
			var geometry : Geometry;
			var mesh : Mesh;
			var skeleton : Skeleton;
			var sequence : AnimationSequenceBase;
			var animator : AnimatorBase;
			var i : int, j : int;
			
			if (!node.instance_controllers || node.instance_controllers.length == 0) {
				return;
			}
			
			instance_geometry = findControllerGeometry(node);
			daeGeometry = _libGeometries[instance_geometry.url] as DAEGeometry;

			for (i = 0; i < node.instance_controllers.length; i++) {
				instance = node.instance_controllers[i];
				controller = _libControllers[instance.url] as DAEController;
				
				if (controller.skin) {
					geometry = getGeometryByName(controller.skin.source);
					if (!geometry) {
						if (_libControllers[controller.skin.source] is DAEController) {
							geometry = processController(_libControllers[controller.skin.source]);
						}
					}
				}
				if (!geometry) {
					return;
				}
				if (controller.skin && daeGeometry && daeGeometry.mesh) {
					skeleton = parseSkeleton(instance);
					geometry = geometry.clone();
					applySkinBindShape(geometry, controller.skin);
					applySkinController(geometry, daeGeometry.mesh, controller.skin, skeleton);
					effects = getMeshEffects(instance.bind_material, daeGeometry.mesh);
					mesh = new Mesh(null, geometry);
					for (j = 0; j < mesh.subMeshes.length; j++) {
						mesh.subMeshes[j].material = effects[j].material;
					}
					container.addChild(mesh);
					finalizeAsset(mesh);
					
					sequence = processSkinAnimation(controller.skin, mesh, skeleton);
					animator = new SmoothSkeletonAnimator(SkeletonAnimationState(mesh.animationState));
					sequence.looping = true;
					
					SmoothSkeletonAnimator(animator).addSequence(SkeletonAnimationSequence(sequence));
					
					_animators.push(animator);
					_sequences.push(sequence);
					
					finalizeAsset(animator);
					finalizeAsset(sequence);
				}
				
				break;
			}
		}
		
		private function processSkinAnimation(skin : DAESkin, mesh : Mesh, skeleton : Skeleton) : SkeletonAnimationSequence
		{
			var useGPU : Boolean = _configFlags & CONFIG_USE_GPU ? true : false;
			var animation : SkeletonAnimation = new SkeletonAnimation(skeleton, skin.maxBones, useGPU);
			var animated : Boolean = isAnimatedSkeleton(skeleton);
			var duration : Number = _animationInfo.numFrames == 0 ?
				1.0 : 
				_animationInfo.maxTime - _animationInfo.minTime;
			var numFrames : int = Math.max(_animationInfo.numFrames, (animated ? 50 : 2));
			var frameDuration : Number = duration / numFrames;
			var sequence : SkeletonAnimationSequence;
			var t : Number = 0;
			var i : int, j : int;
			
			sequence = new SkeletonAnimationSequence("sequence_" + _sequences.length);
			mesh.geometry.animation = animation;
			
			for (i = 0; i < numFrames; i++) {
				var skeletonPose : SkeletonPose = new SkeletonPose();
				
				for (j = 0; j < skin.joints.length; j++) {
					var node : DAENode = _root.findNodeById(skin.joints[j]) || _root.findNodeBySid(skin.joints[j]);
					var pose : JointPose = new JointPose();
					var matrix : Matrix3D;
					
					matrix = node.getAnimatedMatrix(t) || node.matrix;
					
					pose.name = skin.joints[j];
					pose.orientation.fromMatrix(matrix);
					pose.translation.copyFrom(matrix.position);
					
					if (isNaN(pose.orientation.x)) {
						pose.orientation.fromMatrix(new Matrix3D());
					}
					
					skeletonPose.jointPoses.push(pose);
				}
				t += frameDuration;
				sequence.addFrame(skeletonPose, frameDuration * 1000);
			}
			return sequence;
		}
		
		private function isAnimatedSkeleton(skeleton : Skeleton) : Boolean
		{
			var animation : DAEAnimation;
			var node : DAENode;
			var i : int;
			
			for (i = 0; i < skeleton.joints.length; i++) {
				node = _root.findNodeById(skeleton.joints[i].name) || _root.findNodeBySid(skeleton.joints[i].name);
				if (node && node.channels.length) {
					return true;
				}
			}
			
			return false;
		}
		
		/**
		 * 
		 */ 
		private function processGeometries(node : DAENode, container : ObjectContainer3D) : void
		{
			var instance : DAEInstanceGeometry;
			var daeGeometry : DAEGeometry;
			var effects : Vector.<DAEEffect>;
			var mesh : Mesh;
			var geometry : Geometry;
			var i : int, j : int;
			
			for (i = 0; i < node.instance_geometries.length; i++) {
				instance = node.instance_geometries[i];
				daeGeometry = _libGeometries[instance.url] as DAEGeometry;
				
				if (daeGeometry && daeGeometry.mesh) {
					geometry = getGeometryByName(instance.url);
					effects = getMeshEffects(instance.bind_material, daeGeometry.mesh);
					
					if (geometry && effects.length == geometry.subGeometries.length) {
						mesh = new Mesh(null, geometry);
						for (j = 0; j < mesh.subMeshes.length; j++) {
							mesh.subMeshes[j].material = effects[j].material;
						}
						container.addChild(mesh);
						finalizeAsset(mesh);
					}
				}
			}
		}
		
		private function getMeshEffects(bindMaterial : DAEBindMaterial, mesh : DAEMesh) : Vector.<DAEEffect>
		{
			var effects:Vector.<DAEEffect> = new Vector.<DAEEffect>();
			var material : DAEMaterial;
			var effect : DAEEffect;
			var instance : DAEInstanceMaterial;
			var i : int, j : int;
			
			for (i = 0; i < mesh.primitives.length; i++) {
				for (j = 0; j < bindMaterial.instance_material.length; j++) {
					instance = bindMaterial.instance_material[j];
					if (mesh.primitives[i].material == instance.symbol) {
						material = _libMaterials[instance.target] as DAEMaterial;
						effect = _libEffects[material.instance_effect.url];
						effects.push(effect);
						break;
					}
				}
			}
			
			return effects;
		}

		private function parseSkeleton(instance_controller : DAEInstanceController) : Skeleton
		{
			if (!instance_controller.skeleton.length)
				return null;
			
			var controller:DAEController = _libControllers[instance_controller.url] as DAEController;
			var skeletonId:String = instance_controller.skeleton[0];
			var skeletonRoot:DAENode = _root.findNodeById(skeletonId) || _root.findNodeBySid(skeletonId);
			
			if (!skeletonRoot)
				return null;
			
			var skeleton:Skeleton = new Skeleton();
			
			skeleton.joints = new Vector.<SkeletonJoint>(controller.skin.joints.length, true);
			
			parseSkeletonHierarchy(skeletonRoot, controller.skin, skeleton);

			return skeleton;
		}
		
		private function parseSkeletonHierarchy(node : DAENode, skin : DAESkin, skeleton : Skeleton, 
									   parent : int = -1) : void
		{
			var joint : SkeletonJoint = new SkeletonJoint();
			var ibm:Matrix3D;
			
			var jointIndex :int = skin.jointSourceType == "IDREF_array" ? 
				skin.getJointIndex(node.id) :
				skin.getJointIndex(node.sid);
			if (jointIndex < 0)
				throw new Error("could not find joint");
			
			joint.parentIndex = parent;
			joint.name = skin.joints[jointIndex];
			
			ibm = skin.inv_bind_matrix[jointIndex];
			
			joint.inverseBindPose = ibm.rawData;
			
			skeleton.joints[jointIndex] = joint;

			for (var i:int = 0; i < node.nodes.length; i++) {
				parseSkeletonHierarchy(node.nodes[i], skin, skeleton, jointIndex);
			}
		}
		
		/**
		 * 
		 */ 
		private function setupMaterial(material : DAEMaterial, effect : DAEEffect) : MaterialBase {
			if (!effect || !material)
				return null;
			var mat:MaterialBase = _defaultColorMaterial;
			var bitmapMaterial : BitmapMaterial;
			var ambient:DAEColorOrTexture = effect.shader.props["ambient"];
			var diffuse:DAEColorOrTexture = effect.shader.props["diffuse"];
			var specular:DAEColorOrTexture = effect.shader.props["specular"];
			var shininess:Number = effect.shader.props.hasOwnProperty("shininess") ? 
				effect.shader.props["shininess"] as Number :
				10;
			var transparency:Number = effect.shader.props.hasOwnProperty("transparency") ? 
				effect.shader.props["transparency"] as Number :
				1;
			
			if(diffuse && diffuse.texture && effect.surface) {
				var image:DAEImage = _libImages[effect.surface.init_from];
				if (isBitmapDataValid(image.resource.bitmapData)) {
					mat = bitmapMaterial = new BitmapMaterial(image.resource.bitmapData, true, true);
				}
			} 
			else if (diffuse && diffuse.color) {
				mat = bitmapMaterial = new BitmapMaterial();
				bitmapMaterial.bitmapData = new BitmapData(256, 256, true, 0xff << 24 | diffuse.color.rgb);
			}
			
			if (bitmapMaterial) {
				bitmapMaterial.ambientMethod = new BasicAmbientMethod();
				bitmapMaterial.diffuseMethod = new BasicDiffuseMethod();
				bitmapMaterial.specularMethod = new BasicSpecularMethod();
				
				bitmapMaterial.ambientColor = (ambient && ambient.color) ? ambient.color.rgb :  0x303030;
				bitmapMaterial.specularColor = (specular && specular.color) ? specular.color.rgb : 0x202020;
				if (transparency < 1)
					bitmapMaterial.alpha = transparency;
				bitmapMaterial.gloss = shininess;
				bitmapMaterial.ambient = 1;
				bitmapMaterial.specular = 1;
			}
			
			mat.name = material.id;
			
			finalizeAsset(mat);
			
			return mat;
		}
		
		/**
		 * 
		 */ 
		private function setupMaterials() : void
		{
			for each (var material:DAEMaterial in _libMaterials) {
				if (_libEffects.hasOwnProperty(material.instance_effect.url)) {
					var effect:DAEEffect = _libEffects[material.instance_effect.url] as DAEEffect;
					
					effect.material = setupMaterial(material, effect);
				}
			}
		}
		
		private function translateGeometries() : Vector.<Geometry>
		{
			var geometries : Vector.<Geometry> = new Vector.<Geometry>();
			var daeGeometry : DAEGeometry;
			var geometry : Geometry;
			
			for (var id:String in _libGeometries) {
				daeGeometry = _libGeometries[id] as DAEGeometry;
				if (daeGeometry.mesh) {
					geometry = translateGeometry(daeGeometry.mesh);	
					if (geometry.subGeometries.length) {
						geometry.name = id;
						geometries.push(geometry);
						
						finalizeAsset(geometry);
					}
				}	
			}
			
			return geometries;
		}
		
		private function translateGeometry(mesh : DAEMesh) : Geometry
		{
			var geometry : Geometry = new Geometry();
			for (var i:int = 0; i < mesh.primitives.length; i++) {
				var sub : SubGeometry = translatePrimitive(mesh, mesh.primitives[i]);
				if (sub) {
					geometry.addSubGeometry(sub);
				}
			}
			return geometry;
		}
		
		/**
		 * Translates a DAEPrimitive to a SubGeometry.
		 * 
		 * @param	mesh
		 * @param	primitive
		 * @param	reverseTriangles
		 * @param	autoDeriveVertexNormals
		 * @param	autoDeriveVertexTangents
		 * 
		 * @return The created SubGeometry
		 */ 
		private function translatePrimitive(mesh : DAEMesh, primitive : DAEPrimitive, 
											reverseTriangles:Boolean = true,
											autoDeriveVertexNormals : Boolean = true,
											autoDeriveVertexTangents : Boolean = true) : SubGeometry
		{
			var sub : SubGeometry = new SubGeometry();
			var indexData:Vector.<uint> = new Vector.<uint>();
			var vertexData:Vector.<Number> = new Vector.<Number>();
			var normalData:Vector.<Number> = new Vector.<Number>();
			var uvData:Vector.<Number> = new Vector.<Number>();
			var uvData2:Vector.<Number> = new Vector.<Number>();
			var faces:Vector.<DAEFace> = primitive.create(mesh);
			var v : DAEVertex, f : DAEFace;
			var i : int, j : int;
			
			// vertices, normals and uvs
			for (i = 0; i < primitive.vertices.length; i++) {
				v = primitive.vertices[i];
				vertexData.push(v.x, v.y, v.z);
				normalData.push(v.nx, v.ny, v.nz);
				if (v.numTexcoordSets > 0) {
					uvData.push(v.uvx, 1.0 - v.uvy);
					if (v.numTexcoordSets > 1)
						uvData2.push(v.uvx2, 1.0 - v.uvy2);
				} else {
					uvData.push(0, 0);
				}
			}
			
			// triangles
			for (i = 0; i < faces.length; i++) {
				f = faces[i];	
				for (j = 0; j < f.vertices.length; j++) {
					v = f.vertices[j];
					indexData.push(v.index);
				}
			}
			
			if (reverseTriangles)
				indexData.reverse();
			
			sub.autoDeriveVertexNormals = autoDeriveVertexNormals;
			sub.autoDeriveVertexTangents = autoDeriveVertexTangents;
			
			sub.updateVertexData(vertexData);
			if (autoDeriveVertexNormals == false)
				sub.updateVertexNormalData(normalData);
			
			if (vertexData.length == uvData.length*(3/2)) {
				sub.updateUVData(uvData);
				if (uvData.length == uvData2.length)
					sub.updateSecondaryUVData(uvData2);
			} else {
				uvData.length = 0;
				for (j = 0; j < vertexData.length; j += 2) {
					uvData.push(0, 0);
				}
				sub.updateUVData(uvData);
			}
			sub.updateIndexData(indexData);
			
			return sub;
		}
		
		public function get geometries() : Vector.<Geometry>
		{
			return _geometries;
		}
		
		public function get effects() : Object
		{
			return _libEffects;
		}
		
		public function get images() : Object
		{
			return _libImages;
		}
		
		public function get materials() : Object
		{
			return _libMaterials;
		}
		
		public function get isAnimated() : Boolean
		{
			return (_doc._ns::library_animations._ns::animation.length() > 0);
		}
	}
}

import away3d.loaders.parsers.DAEParser;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class DAEAnimationInfo
{
	public var minTime : Number;
	public var maxTime : Number;
	public var numFrames : uint;
}

class DAEElement
{
	public static var USE_LEFT_HANDED : Boolean = true;
	
	public var id : String;
	public var name : String;
	public var sid : String;
	
	protected var ns : Namespace;
	
	public function DAEElement(element : XML = null)
	{
		if (element)
			deserialize(element);
	}
	
	public function deserialize(element : XML) : void
	{
		ns = element.namespace();
		id = element.@id.toString();
		name = element.@name.toString();
		sid = element.@sid.toString();
	}
	
	public function dispose() : void
	{
		
	}
	
	protected function traverseChildHandler(child : XML, nodeName : String) : void 
	{
		
	}
	
	protected function traverseChildren(element : XML, name : String = null) : void
	{
		var children : XMLList = name ? element.ns::[name] : element.children();
		var count : int = children.length();
		var i : int;
		
		for (i = 0; i < count; i++) {
			traverseChildHandler(children[i], children[i].name().localName);
		}
	}
	
	protected function convertMatrix(matrix : Matrix3D) : void
	{
		var indices : Vector.<int> = Vector.<int>([2, 6, 8, 9, 11, 14]);
		var raw : Vector.<Number> = matrix.rawData;
		var i : int;
		for (i = 0; i < indices.length; i++) {
			raw[indices[i]] *= -1.0;
		}
		matrix.rawData = raw;
	}
	
	protected function getRootElement(element : XML) : XML
	{
		var tmp : XML = element;
		
		while (tmp.name().localName != "COLLADA") {
			tmp = tmp.parent();		
		}
		
		return (tmp.name().localName == "COLLADA" ? tmp : null);
	}
	
	protected function readFloatArray(element : XML) : Vector.<Number>
	{
		var raw : String = readText(element);
		var parts : Array = raw.split(/\s+/);
		var floats : Vector.<Number> = new Vector.<Number>();
		var i : int;
		
		for (i = 0; i < parts.length; i++) {
			floats.push(parseFloat(parts[i]));
		}
		
		return floats;
	}
	
	protected function readIntArray(element : XML) : Vector.<int>
	{
		var raw : String = readText(element);
		var parts : Array = raw.split(/\s+/);
		var ints : Vector.<int> = new Vector.<int>();
		var i : int;
		
		for (i = 0; i < parts.length; i++) {
			ints.push(parseInt(parts[i], 10));
		}
		
		return ints;
	}
	
	protected function readStringArray(element : XML) : Vector.<String>
	{
		var raw : String = readText(element);
		var parts : Array = raw.split(/\s+/);
		var strings : Vector.<String> = new Vector.<String>();
		var i : int;
		
		for (i = 0; i < parts.length; i++) {
			strings.push(parts[i]);
		}
		
		return strings;
	}
	
	protected function readIntAttr(element : XML, name : String, defaultValue : int = 0) : int
	{
		var v : int = parseInt(element.@[name], 10);
		v = v == 0 ? defaultValue : v;
		return v;
	}
	
	protected function readText(element : XML) : String
	{
		return trimString(element.text().toString());	
	}
	
	protected function trimString(s : String) : String
	{
		return s.replace(/^\s+/, "").replace(/\s+$/, "");
	}
}

class DAEImage extends DAEElement
{
	public var init_from : String;
	public var resource : *;
	
	public function DAEImage(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		init_from = readText(element.ns::init_from[0]);
		resource = null;
	}
}

class DAEParam extends DAEElement
{
	public var type : String;
	
	public function DAEParam(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		this.type = element.@type.toString();
	}
}

class DAEAccessor extends DAEElement
{
	public var params : Vector.<DAEParam>;
	public var source : String;
	public var stride : int;
	public var count : int;
	
	public function DAEAccessor(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.params = new Vector.<DAEParam>();
		this.source = element.@source.toString().replace(/^#/, "");
		this.stride = readIntAttr(element, "stride", 1);
		this.count = readIntAttr(element, "count", 0);
		
		traverseChildren(element, "param");
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		if (nodeName == "param") {
			this.params.push(new DAEParam(child));
		}
	}
}

class DAESource extends DAEElement
{
	public var accessor : DAEAccessor;
	public var type : String;
	public var floats : Vector.<Number>;
	public var ints : Vector.<int>;
	public var bools : Vector.<Boolean>;
	public var strings : Vector.<String>;
	
	public function DAESource(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "float_array":
				this.type = nodeName;
				this.floats = readFloatArray(child);
				break;
			case "int_array":
				this.type = nodeName;
				this.ints = readIntArray(child);
				break;
			case "bool_array":
				throw new Error("Cannot handle bool_array");
				break;
			case "Name_array":
			case "IDREF_array":
				this.type = nodeName;
				this.strings = readStringArray(child);
				break;
			case "technique_common":
				this.accessor = new DAEAccessor(child.ns::accessor[0]);
				break;
			default:
				break;
		}
	}
}

class DAEInput extends DAEElement
{
	public var semantic : String;
	public var source : String;
	public var offset : int;
	public var set : int;
	
	public function DAEInput(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.semantic = element.@semantic.toString();
		this.source = element.@source.toString().replace(/^#/, "");
		this.offset = readIntAttr(element, "offset");
		this.set = readIntAttr(element, "set");
	}
}

class DAEVertex
{
	public var x:Number;
	public var y:Number;
	public var z:Number;
	public var nx:Number;
	public var ny:Number;
	public var nz:Number;
	public var uvx:Number;
	public var uvy:Number;
	public var uvx2:Number;
	public var uvy2:Number;
	public var numTexcoordSets:uint = 0;
	public var index:uint = NaN;
	public var daeIndex:uint = NaN;
	
	public function DAEVertex(numTexcoordSets:uint)
	{
		this.numTexcoordSets = numTexcoordSets;
		x = y = z = nx = ny = nz = uvx = uvy = uvx2 = uvy2 = 0;	
	}
	
	public function get hash() : String
	{
		var s : String = format(x);
		s += "_" + format(y);
		s += "_" + format(z);
		s += "_" + format(nx);
		s += "_" + format(ny);
		s += "_" + format(nz);
		s += "_" + format(uvx);
		s += "_" + format(uvy);
		s += "_" + format(uvx2);
		s += "_" + format(uvy2);
		return s;
	}
	
	private function format(v : Number, numDecimals : int = 2) : String
	{
		return v.toFixed(numDecimals);
	}
}

class DAEFace
{
	public var vertices:Vector.<DAEVertex>;
	
	public function DAEFace()
	{
		this.vertices = new Vector.<DAEVertex>();	
	}
}

class DAEPrimitive extends DAEElement
{
	public var type : String;
	public var material : String;
	public var count : int;
	public var vertices : Vector.<DAEVertex>;
	
	private var _inputs : Vector.<DAEInput>;
	private var _p : Vector.<int>;
	private var _vcount : Vector.<int>;
	private var _texcoordSets : Vector.<int>;
	
	public function DAEPrimitive(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.type = element.name().localName;
		this.material = element.@material.toString();
		this.count = readIntAttr(element, "count", 0);
		
		_inputs = new Vector.<DAEInput>();
		_p = null;
		_vcount = null;
		
		var list:XMLList = element.ns::input;
		var i:int;
		
		for (i = 0; i < list.length(); i++) {
			_inputs.push(new DAEInput(list[i]));
		}
		
		if (element.ns::p && element.ns::p.length())
			_p = readIntArray(element.ns::p[0]);
		
		if (element.ns::vcount && element.ns::vcount.length())
			_vcount = readIntArray(element.ns::vcount[0]);
	}
	
	/**
	 * Creates the primitive. Typically called after deserialization.
	 * 
	 * @param	mesh
	 * 
	 * @return Array of DAEFace or null on failure.
	 */ 
	public function create(mesh : DAEMesh) : Vector.<DAEFace>
	{
		if (!prepareInputs(mesh))
			return null;
		
		var faces:Vector.<DAEFace> = new Vector.<DAEFace>();
		var input:DAEInput;
		var source:DAESource;
		var numInputs:uint = _inputs.length;
		var idx:int = 0, index:int;
		var i:int, j:int;
		var x:Number, y:Number, z:Number;
		var vertexIndex:uint = 0;
		var vertexDict:Object = new Object();
		var idx32:int;
		
		this.vertices = new Vector.<DAEVertex>();
		
		while (idx < _p.length) {
			var vcount:int = _vcount != null ? _vcount.shift() : 3;
			var face:DAEFace = new DAEFace();

			for (i = 0; i < vcount; i++) {
				var t:int = i * numInputs;
				var vertex:DAEVertex = new DAEVertex(_texcoordSets.length);
				
				for (j = 0; j < _inputs.length; j++) {
					input = _inputs[j];
					index = _p[idx + t + input.offset];
					source = mesh.sources[input.source] as DAESource;
					idx32 = index * source.accessor.params.length;
					
					switch (input.semantic) {
						case "VERTEX":
							vertex.x = source.floats[idx32+0];
							vertex.y = source.floats[idx32+1];
							if (DAEElement.USE_LEFT_HANDED) {
								vertex.z = -source.floats[idx32+2];
							} else {
								vertex.z = source.floats[idx32+2];
							}
							vertex.daeIndex = index;
							break;
						case "NORMAL":
							vertex.nx = source.floats[idx32+0];
							vertex.ny = source.floats[idx32+1];
							if (DAEElement.USE_LEFT_HANDED) {
								vertex.nz = -source.floats[idx32+2];
							} else {
								vertex.nz = source.floats[idx32+2];
							}
							break;
						case "TEXCOORD":
							if (input.set == _texcoordSets[0]) {
								vertex.uvx = source.floats[idx32+0];
								vertex.uvy = source.floats[idx32+1];
							}
							else {
								vertex.uvx2 = source.floats[idx32+0];
								vertex.uvy2 = source.floats[idx32+1];
							}
							break;
						default:
							break;
					}
				}
				var hash:String = vertex.hash;

				if (vertexDict[hash]) {
					face.vertices.push(vertexDict[hash]);
				}
				else {
					vertex.index = this.vertices.length;
					vertexDict[hash] = vertex;
					face.vertices.push(vertex);
					this.vertices.push(vertex);
				}
			}

			if (face.vertices.length > 3) {
				// triangulate
				var v0:DAEVertex = face.vertices[0];

				for (var k:int = 1; k < face.vertices.length - 1; k++) {
					var f:DAEFace = new DAEFace();
					f.vertices.push(v0);
					f.vertices.push(face.vertices[k]);
					f.vertices.push(face.vertices[k+1]);
					faces.push(f);
				}
			}
			else if (face.vertices.length == 3) {
				faces.push(face);
			}
			idx += (vcount * numInputs);
		}
		return faces;
	}
	
	private function prepareInputs(mesh : DAEMesh) : Boolean
	{
		var input:DAEInput;
		var i:int, j:int;
		var result : Boolean = true;
		
		_texcoordSets = new Vector.<int>();
		
		for (i = 0; i < _inputs.length; i++) {
			input = _inputs[i];
			
			if (input.semantic == "TEXCOORD") {
				_texcoordSets.push(input.set);
			}
			
			if (!mesh.sources[input.source]) {
				result = false;
				if (input.source == mesh.vertices.id) {
					for (j = 0; j < mesh.vertices.inputs.length; j++) {
						if (mesh.vertices.inputs[j].semantic == "POSITION") {
							input.source = mesh.vertices.inputs[j].source;
							result = true;
							break;
						}
					}
				}
			}
		}
		
		return result;
	}
}

class DAEVertices extends DAEElement
{
	public var mesh : DAEMesh;
	public var inputs : Vector.<DAEInput>;
	
	public function DAEVertices(mesh : DAEMesh, element : XML = null)
	{
		this.mesh = mesh;
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.inputs = new Vector.<DAEInput>();
		
		traverseChildren(element, "input");
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		this.inputs.push(new DAEInput(child));
	}
}

class DAEGeometry extends DAEElement
{	
	public var mesh : DAEMesh;
	
	public function DAEGeometry(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.mesh = null;
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "mesh":
				this.mesh = new DAEMesh(this, child);
				break;
			case "convex_mesh":
				break;
			case "spline":
				break;
			default:
				break;
		}
	}
}

class DAEMesh extends DAEElement
{	
	public var geometry : DAEGeometry;
	public var sources : Object;
	public var vertices : DAEVertices;
	public var primitives : Vector.<DAEPrimitive>;
	
	public function DAEMesh(geometry : DAEGeometry, element : XML = null)
	{
		this.geometry = geometry;
		
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.sources = new Object();
		this.vertices = null;
		this.primitives = new Vector.<DAEPrimitive>();
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "source":
				var source:DAESource = new DAESource(child);
				this.sources[source.id] = source;
				break;
			case "vertices":
				this.vertices = new DAEVertices(this, child);
				break;
			case "triangles":
			case "polylist":
			case "polygon":
				this.primitives.push(new DAEPrimitive(child));
				break;
			default:
				break;
		}
	}
}

class DAEBindMaterial extends DAEElement
{	
	public var instance_material : Vector.<DAEInstanceMaterial>;
	
	public function DAEBindMaterial(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.instance_material = new Vector.<DAEInstanceMaterial>();
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "technique_common":
				for (var j:int = 0; j < child.children().length(); j++) {
					this.instance_material.push(new DAEInstanceMaterial(child.children()[j]));
				}
				break;
			default:
				break;
		}
	}
}

class DAEBindVertexInput extends DAEElement
{
	public var semantic : String;
	public var input_semantic : String;
	public var input_set : int;
	
	public function DAEBindVertexInput(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.semantic = element.@semantic.toString();
		this.input_semantic = element.@input_semantic.toString();
		this.input_set = readIntAttr(element, "input_set");
	}
}

class DAEInstance extends DAEElement
{	
	public var url : String;
	
	public function DAEInstance(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.url = element.@url.toString().replace(/^#/, "");
	}
}

class DAEInstanceCamera extends DAEInstance
{	
	public function DAEInstanceCamera(element : XML = null)
	{
		super(element);
	}
}

class DAEInstanceController extends DAEInstance
{	
	public var bind_material : DAEBindMaterial;
	public var skeleton : Vector.<String>;
	
	public function DAEInstanceController(element : XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.bind_material = null;
		this.skeleton = new Vector.<String>();
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "skeleton":
				this.skeleton.push(readText(child).replace(/^#/, ""));
				break;
			case "bind_material":
				this.bind_material = new DAEBindMaterial(child);
				break;
			default:
				break;
		}
	}
}

class DAEInstanceEffect extends DAEInstance
{	
	public function DAEInstanceEffect(element : XML = null)
	{
		super(element);
	}
}

class DAEInstanceGeometry extends DAEInstance
{	
	public var bind_material : DAEBindMaterial;
	
	public function DAEInstanceGeometry(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.bind_material = null;
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "bind_material":
				this.bind_material = new DAEBindMaterial(child);
				break;
			default:
				break;
		}
	}
}

class DAEInstanceMaterial extends DAEInstance
{	
	public var target : String;
	public var symbol : String;
	public var bind_vertex_input : Vector.<DAEBindVertexInput>;
	
	public function DAEInstanceMaterial(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.target = element.@target.toString().replace(/^#/, "");
		this.symbol = element.@symbol.toString();
		this.bind_vertex_input = new Vector.<DAEBindVertexInput>();
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "bind_vertex_input":
				this.bind_vertex_input.push(new DAEBindVertexInput(child));
				break;
			default:
				break;
		}
	}
}

class DAEInstanceLight extends DAEInstance
{	
	public function DAEInstanceLight(element : XML = null)
	{
		super(element);
	}
}

class DAEInstanceNode extends DAEInstance
{	
	public function DAEInstanceNode(element : XML = null)
	{
		super(element);
	}
}

class DAEInstancePhysicsScene extends DAEInstance
{	
	public function DAEInstancePhysicsScene(element : XML = null)
	{
		super(element);
	}
}

class DAEInstanceVisualScene extends DAEInstance
{	
	public function DAEInstanceVisualScene(element : XML = null)
	{
		super(element);
	}
}

class DAEColor
{
	public var r : Number;
	public var g : Number;
	public var b : Number;
	public var a : Number;
	
	public function get rgb() : uint
	{
		var c:uint = 0;
		
		c |= int(r * 255.0) << 16;
		c |= int(g * 255.0) << 8;
		c |= int(b * 255.0);
		
		return c;
	}
	
	public function get rgba() : uint
	{
		return (int(a * 255.0) << 24 | this.rgb);
	}
}

class DAETexture
{
	public var texture : String;
	public var texcoord : String;
}

class DAEColorOrTexture extends DAEElement
{	
	public var color : DAEColor;
	public var texture : DAETexture;
	
	public function DAEColorOrTexture(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.color = null;
		this.texture = null;
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "color":
				var values:Vector.<Number> = readFloatArray(child);
				this.color = new DAEColor();
				this.color.r = values[0];
				this.color.g = values[1];
				this.color.b = values[2];
				this.color.a = values.length > 3 ? values[3] : 1.0;
				break;
			case "texture":
				this.texture = new DAETexture();
				this.texture.texcoord = child.@texcoord.toString();
				this.texture.texture = child.@texture.toString();
				break;
			default:
				break;
		}
	}
}

class DAESurface extends DAEElement
{	
	public var type : String;
	public var init_from : String;
	
	public function DAESurface(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.type = element.@type.toString();
		this.init_from = readText(element.ns::init_from[0]);
	}
}

class DAESampler2D extends DAEElement
{	
	public var source : String;

	public function DAESampler2D(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.source = readText(element.ns::source[0]);
	}
}

class DAEShader extends DAEElement
{	
	public var type : String;
	public var props : Object;
	
	public function DAEShader(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.type = element.name().localName;
		this.props = new Object();
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "ambient":
			case "diffuse":
			case "specular":
			case "emission":
			case "transparent":
			case "reflective":
				this.props[nodeName] = new DAEColorOrTexture(child);
				break;
			case "shininess":
			case "reflectivity":
			case "transparency":
			case "index_of_refraction":
				this.props[nodeName] = parseFloat(readText(child.ns::float[0]));
				break;
			default:
				trace("[WARNING] unhandled DAEShader property: " + nodeName);
				break;
		}
	}
}

class DAEEffect extends DAEElement
{	
	public var shader : DAEShader;
	public var surface : DAESurface;
	public var sampler : DAESampler2D;
	public var material : *;

	public function DAEEffect(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.shader = null;
		this.surface = null;
		this.sampler = null;
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "profile_COMMON":
				deserializeProfile(child);
				break;
			case "extra":
				break;
			default:
				break;
		}
	}
	
	private function deserializeProfile(element : XML) : void
	{
		var children:XMLList = element.children();
		var i:int;
		
		for (i = 0; i < children.length(); i++) {
			var child:XML = children[i];
			var name:String = child.name().localName;
			
			switch (name) {
				case "technique":
					deserializeShader(child);
					break;
				case "newparam":
					deserializeNewParam(child);
					break;
				case "extra":
					break;
				default:
					break;
			}
		}
	}
	
	private function deserializeNewParam(element : XML) : void
	{
		var children:XMLList = element.children();
		var i:int;
		
		for (i = 0; i < children.length(); i++) {
			var child:XML = children[i];
			var name:String = child.name().localName;
			
			switch (name) {
				case "surface":
					this.surface = new DAESurface(child);
					this.surface.sid = element.@sid.toString();
					break;
				case "sampler2D":
					this.sampler = new DAESampler2D(child);
					this.sampler.sid = element.@sid.toString();
					break;
				default:
					trace("[WARNING] unhandled newparam: " + name);
					break;
			}
		}
	}
	
	private function deserializeShader(technique : XML) : void
	{
		var children:XMLList = technique.children();
		var i:int;
		
		this.shader = null;
		
		for (i = 0; i < children.length(); i++) {
			var child:XML = children[i];
			var name:String = child.name().localName;
			
			switch (name) {
				case "constant":
				case "lambert":
				case "blinn":
				case "phong":
					this.shader = new DAEShader(child);
					break;
				default:
					break;
			}
		}
	}
}

class DAEMaterial extends DAEElement
{	
	public var instance_effect : DAEInstanceEffect;
	
	public function DAEMaterial(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.instance_effect = null;
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "instance_effect":
				this.instance_effect = new DAEInstanceEffect(child);
				break;
			default:
				break;
		}
	}
}

class DAETransform extends DAEElement
{
	public var type : String;
	public var data : Vector.<Number>;
	
	public function DAETransform(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.type = element.name().localName;
		this.data = readFloatArray(element);
	}
	
	public function get matrix() : Matrix3D
	{
		var matrix : Matrix3D = new Matrix3D();
		//trace(this.type);
		
		switch (this.type) {
			case "matrix":
				matrix = new Matrix3D(this.data);
				matrix.transpose();
				break;
			case "scale":
				matrix.appendScale(this.data[0], this.data[1], this.data[2]);
				break;
			case "translate":
				matrix.appendTranslation(this.data[0], this.data[1], this.data[2]);
				break;
			case "rotate":
				var axis:Vector3D = new Vector3D(this.data[0], this.data[1], this.data[2]);
				matrix.appendRotation(this.data[3], axis);
				break;
			default:
				break;
		}
		
		return matrix;
	}
}

class DAENode extends DAEElement
{
	public var type : String;
	public var parent : DAENode;
	public var parser : DAEParser;
	public var nodes : Vector.<DAENode>;
	public var transforms : Vector.<DAETransform>;
	public var instance_cameras : Vector.<DAEInstanceCamera>;
	public var instance_controllers : Vector.<DAEInstanceController>;
	public var instance_geometries : Vector.<DAEInstanceGeometry>;
	public var instance_lights : Vector.<DAEInstanceLight>;
	public var world : Matrix3D;
	public var channels : Vector.<DAEChannel>;
	
	private var _root : XML;
	
	public function DAENode(parser : DAEParser, element : XML = null, parent : DAENode = null)
	{
		this.parser = parser;
		this.parent = parent;
		this.channels = new Vector.<DAEChannel>();
		
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		_root = getRootElement(element);
		
		this.type = element.@type.toString().length ? element.@type.toString() : "NODE";
		this.nodes = new Vector.<DAENode>();
		this.transforms = new Vector.<DAETransform>();
		this.instance_cameras = new Vector.<DAEInstanceCamera>();
		this.instance_controllers = new Vector.<DAEInstanceController>();
		this.instance_geometries = new Vector.<DAEInstanceGeometry>();
		this.instance_lights = new Vector.<DAEInstanceLight>();
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		var instances : XMLList;
		var instance : DAEInstance;
		
		switch (nodeName) {
			case "node":
				this.nodes.push(new DAENode(this.parser, child, this));
				break;
			case "instance_camera":
				this.instance_cameras.push(new DAEInstanceCamera(child));
				break;
			case "instance_controller":
				instance = new DAEInstanceController(child);
				this.instance_controllers.push(instance);
				break;
			case "instance_geometry":
				this.instance_geometries.push(new DAEInstanceGeometry(child));
				break;
			case "instance_light":
				this.instance_lights.push(new DAEInstanceLight(child));
				break;
			case "instance_node":
				instance = new DAEInstanceNode(child);
				instances = _root.ns::library_nodes.ns::node.(@id == instance.url);
				if (instances.length())
					this.nodes.push(new DAENode(this.parser, instances[0], this));
				break;
			case "matrix":
			case "translate":
			case "scale":
			case "rotate":
				this.transforms.push(new DAETransform(child));
				break;
			case "lookat":
			case "skew":
				break;
			case "extra":
				break;
			default:
				trace(nodeName);
				break;
		}
	}
	
	public function getMatrixBySID(sid : String) : Matrix3D
	{
		var transform : DAETransform = getTransformBySID(sid);
		
		if (transform)
			return transform.matrix;
		
		return null;
	}
	
	public function getTransformBySID(sid : String) : DAETransform
	{
		for each (var transform : DAETransform in this.transforms) {
			if (transform.sid == sid)
				return transform;
		}
		return null;	
	}
	
	public function getAnimatedMatrix(time : Number) : Matrix3D
	{
		var matrix : Matrix3D = new Matrix3D();
		var tdata : Vector.<Number>;
		var odata : Vector.<Number>;
		var channelsBySID : Object = new Object();
		var transform : DAETransform;
		var channel : DAEChannel;
		var minTime : Number = Number.MAX_VALUE;
		var maxTime : Number = -minTime;
		var i : int, j : int, frame : int;
	
		for (i = 0; i < this.channels.length; i++) {
			channel = this.channels[i];
			minTime = Math.min(minTime, channel.sampler.minTime);
			minTime = Math.max(maxTime, channel.sampler.maxTime);
			channelsBySID[channel.targetSid] = channel;
		}
		
		for (i = 0; i < this.transforms.length; i++) {
			transform = this.transforms[i];
			tdata = transform.data;
			if (channelsBySID.hasOwnProperty(transform.sid)) {
				var m : Matrix3D = new Matrix3D();
				var found : Boolean = false;
				var frameData : DAEFrameData = null;
				
				channel = channelsBySID[transform.sid] as DAEChannel;
				frameData = channel.sampler.getFrameData(time);

				if (frameData) {
					odata = frameData.data;
	
					switch (transform.type) {
						case "matrix":
							if (channel.arrayAccess) {
								//m.rawData = tdata;
								//m.transpose();
								if (channel.arrayIndices.length > 1) {
								//	m.rawData[channel.arrayIndices[0] * 4 + channel.arrayIndices[1]] = odata[0];
								//	trace(channel.arrayIndices[0] * 4 + channel.arrayIndices[1])
								}
								
							} 
							else if (channel.dotAccess) {
								trace ("unhandled matrix array access");
							}
							else if (odata.length == 16) {
								m.rawData = odata;
								m.transpose();
							} else {
								trace("unhandled matrix " + transform.sid + " " + odata);
							}
							break;
						case "rotate":
							if (channel.arrayAccess) {
								trace ("unhandled rotate array access");
							} 
							else if (channel.dotAccess) {
								switch (channel.dotAccessor) {
									case "ANGLE":
										m.appendRotation(odata[0], new Vector3D(tdata[0], tdata[1], tdata[2]));
										break;
									default:
										trace ("unhandled rotate dot access " + channel.dotAccessor);
										break;
								}
							} else {
								trace ("unhandled rotate");
							}
							break;
						case "scale":
							if (channel.arrayAccess) {
								trace ("unhandled scale array access");
							} 
							else if (channel.dotAccess) {
								switch (channel.dotAccessor) {
									case "X":
										m.appendScale(odata[0], tdata[1], tdata[2]);
										break;
									case "Y":
										m.appendScale(tdata[0], odata[0], tdata[2]);
										break;
									case "Z":
										m.appendScale(tdata[0], tdata[1], odata[0]);
										break;
									default:
										trace ("unhandled scale dot access " + channel.dotAccessor);
										break;
								}
							} else {
								trace("unhandled scale: " + odata.length);
							}
							break;
						case "translate":
							if (channel.arrayAccess) {
								trace ("unhandled translate array access");
							} 
							else if (channel.dotAccess) {
								switch (channel.dotAccessor) {
									case "X":
										m.appendTranslation(odata[0], tdata[1], tdata[2]);
										break;
									case "Y":
										m.appendTranslation(tdata[0], odata[0], tdata[2]);
										break;
									case "Z":
										m.appendTranslation(tdata[0], tdata[1], odata[0]);
										break;
									default:
										trace ("unhandled translate dot access " + channel.dotAccessor);
										break;
								}	
							} else {
								m.appendTranslation(odata[0], odata[1], odata[2]);
							}
							break;
						default:
							trace ("unhandled transform type " + transform.type);
							continue;
					}
					matrix.prepend(m);
				} else {
					matrix.prepend(transform.matrix);
				}
			} else {
				matrix.prepend(transform.matrix);
			}
		}
		
		if (DAEElement.USE_LEFT_HANDED) {
			convertMatrix(matrix);
		}
		
		return matrix;
	}
	
	public function get matrix() : Matrix3D
	{
		var matrix : Matrix3D = new Matrix3D();
		
		for (var i:int = 0; i < this.transforms.length; i++) {
			matrix.prepend(this.transforms[i].matrix);
		}
		
		if (DAEElement.USE_LEFT_HANDED) {
			convertMatrix(matrix);
		}
		
		return matrix;
	}
}

class DAEVisualScene extends DAENode
{
	public function DAEVisualScene(parser : DAEParser, element : XML = null)
	{
		super(parser, element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{	
		super.deserialize(element);
	}
	
	/**
	 * Finds a node by its ID.
	 * 
	 * @param id
	 * @param node
	 * 
	 * @return The found node or null on failure.
	 */ 
	public function findNodeById(id : String, node : DAENode = null) : DAENode
	{
		node = node || this;
		
		if (node.id == id)
			return node;
		
		for (var i:int = 0; i < node.nodes.length; i++) {
			var result:DAENode = findNodeById(id, node.nodes[i]);
			if (result)
				return result;
		}
		
		return null;
	}
	
	/**
	 * Finds a node by its ID.
	 * 
	 * @param sid
	 * @param node
	 * 
	 * @return The found node or null on failure.
	 */ 
	public function findNodeBySid(sid : String, node : DAENode = null) : DAENode
	{
		node = node || this;
		
		if (node.sid == sid)
			return node;
		
		for (var i:int = 0; i < node.nodes.length; i++) {
			var result:DAENode = findNodeBySid(sid, node.nodes[i]);
			if (result)
				return result;
		}
		
		return null;
	}
	
	public function updateTransforms(node : DAENode, parent : DAENode = null) : void
	{
		node.world = node.matrix.clone();
		if (parent && parent.world)
			node.world.append(parent.world);
		for (var i:int = 0; i < node.nodes.length; i++) {
			updateTransforms(node.nodes[i], node);
		}
	}
}

class DAEScene extends DAEElement
{
	public var instance_visual_scene : DAEInstanceVisualScene;
	public var instance_physics_scene : DAEInstancePhysicsScene;
	
	public function DAEScene(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element : XML) : void
	{
		super.deserialize(element);
		
		this.instance_visual_scene = null;
		this.instance_physics_scene = null;
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "instance_visual_scene":
				this.instance_visual_scene = new DAEInstanceVisualScene(child);
				break;
			case "instance_physics_scene":
				this.instance_physics_scene = new DAEInstancePhysicsScene(child);
				break;
			default:
				break;
		}
	}
}

class DAEMorph extends DAEEffect
{
	public var source : String;
	public var method : String;
	public var targets : Vector.<String>;
	public var weights : Vector.<Number>;
	
	public function DAEMorph(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		
		this.source = element.@source.toString().replace(/^#/, "");
		this.method = element.@method.toString();
		this.method = this.method.length ? this.method : "NORMALIZED";
		this.targets = new Vector.<String>();
		this.weights = new Vector.<Number>();
		
		var sources : Object = new Object();
		var source : DAESource;
		var input : DAEInput;
		var list : XMLList = element.ns::source;
		var i : int;
		
		if (element.ns::targets && element.ns::targets.length() > 0) {
			for (i = 0; i < list.length(); i++) {
				source = new DAESource(list[i]);
				sources[source.id] = source;
			}
			list = element.ns::targets[0].ns::input;
			for (i = 0; i < list.length(); i++) {
				input = new DAEInput(list[i]);
				source = sources[input.source];
				switch (input.semantic) {
					case "MORPH_TARGET":
						this.targets = source.strings;
						break;
					case "MORPH_WEIGHT":
						this.weights = source.floats;
						break;
					default:
						break;
				}
			}
		}
	}	
}

class DAEVertexWeight
{
	public var vertex:uint;
	public var joint:uint;
	public var weight:Number;
}

class DAESkin extends DAEEffect
{
	public var source : String;
	public var bind_shape_matrix : Matrix3D;
	public var joints : Vector.<String>;
	public var inv_bind_matrix : Vector.<Matrix3D>;
	public var weights:Vector.<Vector.<DAEVertexWeight>>;
	public var jointSourceType:String;
	public var maxBones:uint;
	
	public function DAESkin(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		
		this.source = element.@source.toString().replace(/^#/, "");
		this.bind_shape_matrix = new Matrix3D();
		this.inv_bind_matrix = new Vector.<Matrix3D>();
		this.joints = new Vector.<String>();
		this.weights = new Vector.<Vector.<DAEVertexWeight>>();
		
		var children:XMLList = element.children();
		var i:int;
		var sources : Object = new Object();
		
		for (i = 0; i < element.ns::source.length(); i++) {
			var source : DAESource = new DAESource(element.ns::source[i]);
			sources[source.id] = source;
		}
		
		for (i = 0; i < children.length(); i++) {
			var child:XML = children[i];
			var name:String = child.name().localName;
			
			switch (name)
			{
				case "bind_shape_matrix":
					parseBindShapeMatrix(child);
					break;
				case "source":
					break;
				case "joints":
					parseJoints(child, sources);
					break;
				case "vertex_weights":
					parseVertexWeights(child, sources);
					break;
				default:
					break;
			}
		}
	}	
	
	public function getJointIndex(joint : String) : int
	{
		for (var i:int = 0; i < this.joints.length; i++) {
			if (this.joints[i] == joint)
				return i;
		}
		return -1;	
	}
	
	private function parseBindShapeMatrix(element : XML) : void
	{
		var values : Vector.<Number> = readFloatArray(element);
		
		this.bind_shape_matrix = new Matrix3D(values);
		this.bind_shape_matrix.transpose();
		if (DAEElement.USE_LEFT_HANDED) {
			convertMatrix(this.bind_shape_matrix);
		}
	}
	
	private function parseJoints(element : XML, sources : Object) : void
	{
		var list:XMLList = element.ns::input;
		var input:DAEInput;
		var source:DAESource;
		var i:int, j:int;
		
		for (i = 0; i < list.length(); i++) {
			input = new DAEInput(list[i]);	
			source = sources[input.source];
			
			switch (input.semantic) {
				case "JOINT":
					this.joints = source.strings;
					this.jointSourceType = source.type;
					break;
				case "INV_BIND_MATRIX":
					for (j = 0; j < source.floats.length; j += source.accessor.stride) {
						var matrix:Matrix3D = new Matrix3D(source.floats.slice(j, j+source.accessor.stride));
						matrix.transpose();
						if (DAEElement.USE_LEFT_HANDED) {
							convertMatrix(matrix);
						}
						inv_bind_matrix.push(matrix);
					}
					break;
				default:
					break;
			}
		}
	}
	
	private function parseVertexWeights(element : XML, sources : Object) : void
	{
		var list:XMLList = element.ns::input;
		var input:DAEInput;
		var inputs:Vector.<DAEInput> = new Vector.<DAEInput>();
		var source:DAESource;
		var i:int, j:int, k:int;
		
		if (!element.ns::vcount.length() || !element.ns::v.length())
			throw new Error("Can't parse vertex weights");
		
		var vcount:Vector.<int> = readIntArray(element.ns::vcount[0]);
		var v:Vector.<int> = readIntArray(element.ns::v[0]);
		var numWeights:int = parseInt(element.@count.toString(), 10);
		var index:uint = 0;
		
		this.maxBones = 0;
		
		for (i = 0; i < list.length(); i++) {
			inputs.push(new DAEInput(list[i]));
		}
		
		for (i = 0; i < vcount.length; i++) {
			var numBones:uint = vcount[i];
			var vertex_weights:Vector.<DAEVertexWeight> = new Vector.<DAEVertexWeight>();
			
			this.maxBones = Math.max(this.maxBones, numBones);
			
			for (j = 0; j < numBones; j++) {
				var influence:DAEVertexWeight = new DAEVertexWeight();
				
				for (k = 0; k < inputs.length; k++) {
					input = inputs[k];
					source = sources[input.source];
					
					switch (input.semantic) {
						case "JOINT":
							influence.joint = v[index + input.offset];
							break;
						case "WEIGHT":
							influence.weight = source.floats[v[index + input.offset]];
							break;
						default:
							break;
					}
				}
				influence.vertex = i;
				vertex_weights.push(influence);
				index += inputs.length;
			}
			this.weights.push(vertex_weights);
		}
	}
}

class DAEController extends DAEElement
{
	public var skin : DAESkin;
	public var morph : DAEMorph;
	
	public function DAEController(element : XML = null)
	{
		super(element);
	}
	
	/**
	 * @inheritDoc
	 */
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		
		this.skin = null;
		this.morph = null;
		
		if (element.ns::skin && element.ns::skin.length()) {
			this.skin = new DAESkin(element.ns::skin[0]);
		}
		else if (element.ns::morph && element.ns::morph.length()) {
			this.morph = new DAEMorph(element.ns::morph[0]);
		}
		else {
			throw new Error("DAEController: could not find a <skin> or <morph> element");
		}
	}
}

class DAESampler extends DAEElement
{
	public var input:Vector.<Number>;
	public var output:Vector.<Vector.<Number>>;
	public var dataType:String;
	public var interpolation:Vector.<String>;
	public var minTime:Number;
	public var maxTime:Number;
	
	private var _inputs:Vector.<DAEInput>;
	
	public function DAESampler(element : XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		
		var list:XMLList = element.ns::input;
		var i:int;
		
		_inputs = new Vector.<DAEInput>();
		
		for (i = 0; i < list.length(); i++) {
			_inputs.push(new DAEInput(list[i]));
		}
	}
	
	
	public function create(sources:Object):void
	{
		var input:DAEInput;
		var source:DAESource;
		var i:int, j:int;
		
		this.input = new Vector.<Number>();
		this.output = new Vector.<Vector.<Number>>();
		this.interpolation = new Vector.<String>();
		this.minTime = 0;
		this.maxTime = 0;
		
		for (i = 0; i < _inputs.length; i++) {
			input = _inputs[i];
			source = sources[input.source];
			
			switch (input.semantic) {
				case "INPUT":
					this.input = source.floats;
					this.minTime = this.input[0];
					this.maxTime = this.input[this.input.length-1];
					break;
				case "OUTPUT":
					for (j = 0; j < source.floats.length; j += source.accessor.stride) {
						this.output.push(source.floats.slice(j, j+source.accessor.stride));
					}
					this.dataType = source.accessor.params[0].type;
					break;
				case "INTEROLATION":
					this.interpolation = source.strings;
					break;
				default:
					break;
			}
		}
	}
	
	/**
	 * Gets frameData by time.
	 * 
	 * @param	time
	 * 
	 * @return frame
	 */ 
	public function getFrameData(time : Number) : DAEFrameData
	{
		var frameData : DAEFrameData = new DAEFrameData(0, time);
		var a:Number, b:Number;
		var i:int;
		
		if (!this.input || this.input.length == 0) {
			return null;
		}
		
		frameData.valid = true;
		frameData.time = time;
			
		if (time <= this.input[0]) {
			frameData.frame = 0;
			frameData.dt = 0;
			frameData.data = this.output[0];
		}
		else if (time >= this.input[this.input.length - 1]) {
			frameData.frame = this.input.length - 1;
			frameData.dt = 0;
			frameData.data = this.output[frameData.frame];
		}
		else {
			for (i = 0; i < this.input.length - 1; i++) {
				if (time >= this.input[i] && time < this.input[i + 1] ) {
					frameData.frame = i;
					frameData.dt = (time - this.input[i]) / (this.input[i+1] - this.input[i]);
					frameData.data = this.output[i];
					break;
				}
			}
			
			for (i = 0; i < frameData.data.length; i++) {
				a = this.output[frameData.frame][i];
				b = this.output[frameData.frame + 1][i];
				frameData.data[i] += frameData.dt * (b - a);
			}
		}

		return frameData;
	}
}

class DAEFrameData
{
	public var frame : uint;
	public var time : Number;
	public var data : Vector.<Number>;
	public var dt : Number;
	public var valid : Boolean;
	
	public function DAEFrameData(frame : uint = 0, time : Number = 0.0, dt : Number = 0.0, valid : Boolean = false) {
		this.frame = frame;
		this.time = time;
		this.dt = dt;
		this.valid = valid;
	}
}

class DAEChannel extends DAEElement
{
	public var source:String;
	public var target:String;
	public var sampler:DAESampler;
	public var targetId:String;
	public var targetSid:String;
	public var arrayAccess:Boolean;
	public var dotAccess:Boolean;
	public var dotAccessor:String;
	public var arrayIndices:Array;
	
	public function DAEChannel(element : XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
	
		this.source = element.@source.toString().replace(/^#/, "");
		this.target = element.@target.toString();
		this.sampler = null;
		
		var parts:Array = this.target.split("/");
		
		this.targetId = parts.shift();
		this.arrayAccess = this.dotAccess = false;
		
		var tmp:String = parts.shift();
		
		if (tmp.indexOf("(") >= 0) {
			parts = tmp.split("(");
			this.arrayAccess = true;
			this.arrayIndices = new Array();
			this.targetSid = parts.shift();
			for (var i:int = 0; i < parts.length; i++)
			{
				this.arrayIndices.push(parseInt(parts[i].replace(")", ""), 10));
			}
		}
		else if (tmp.indexOf(".") >= 0) {
			parts = tmp.split(".");
			this.dotAccess = true;
			this.targetSid = parts[0];
			this.dotAccessor = parts[1];
		}
		else {
			this.targetSid = tmp;
		}
	}
}

class DAEAnimation extends DAEElement
{
	public var samplers:Vector.<DAESampler>;
	public var channels:Vector.<DAEChannel>;
	public var sources : Object;
	
	public function DAEAnimation(element : XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		
		this.samplers = new Vector.<DAESampler>();
		this.channels = new Vector.<DAEChannel>();
		this.sources = new Object();
		
		traverseChildren(element);

		setupChannels(this.sources);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "source":
				var source:DAESource = new DAESource(child);
				this.sources[source.id] = source;
				break;
			case "sampler":
				this.samplers.push(new DAESampler(child));
				break;
			case "channel":
				this.channels.push(new DAEChannel(child));
				break;
			default:
				break;
		}
	}
	
	private function setupChannels(sources:Object) : void
	{
		for each (var channel:DAEChannel in this.channels) {
			for each (var sampler:DAESampler in this.samplers) {
				if (channel.source == sampler.id) {
					sampler.create(sources);
					channel.sampler = sampler;
					break;
				}
			}
		}
	}
}

class DAELightType extends DAEElement
{
	public var color : DAEColor;
	
	public function DAELightType(element : XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		if (nodeName == "color") {
			var f:Vector.<Number> = readFloatArray(child);
			
			this.color = new DAEColor();
		
			color.r = f[0];
			color.g = f[1];
			color.b = f[2];
			color.a = f.length > 3 ? f[3] : 1.0;
		}
	}
}

class DAEAmbient extends DAELightType
{
	public function DAEAmbient(element : XML = null)
	{
		super(element);
	}
}

class DAEDirectional extends DAELightType
{
	public function DAEDirectional(element : XML = null)
	{
		super(element);
	}
}

class DAEPoint extends DAELightType
{
	public function DAEPoint(element : XML = null)
	{
		super(element);
	}
}

class DAESpot extends DAELightType
{
	public function DAESpot(element : XML = null)
	{
		super(element);
	}
}

class DAELight extends DAEElement
{
	public var light : DAELightType;
	
	public function DAELight(element : XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.light = null;
		traverseChildren(element.ns::technique_common[0]);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "ambient":
				this.light = new DAEAmbient(child);
				break;
			case "directional":
				this.light = new DAEDirectional(child);
				break;
			case "point":
				this.light = new DAEPoint(child);
				break;
			case "spot":
				this.light = new DAESpot(child);
				break;
			default:
				break;
		}
	}
}

class DAEOrthographic extends DAEElement
{
	public var xmag : Number;
	public var ymag : Number;
	public var aspect_ratio : Number;
	public var znear : Number;
	public var zfar : Number;
	public var sids : Object;
	
	public function DAEOrthographic(element : XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.xmag = this.ymag = NaN;
		this.sids = new Object();
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		var sid : String = child.@sid.toString();
		
		if (sid.length) {
			this.sids[nodeName] = sid;
		}
		
		switch (nodeName) {
			case "xmag":
				this.xmag = parseFloat(readText(child));
				break;
			case "ymag":
				this.ymag = parseFloat(readText(child));
				break;
			case "aspect_ratio":
				this.aspect_ratio = parseFloat(readText(child));
				break;
			case "zfar":
				this.zfar = parseFloat(readText(child));
				break;
			case "znear":
				this.znear = parseFloat(readText(child));
				break;
			default:
				break;
		}
	}
}

class DAEPerspective extends DAEElement
{
	public var xfov : Number;
	public var yfov : Number;
	public var aspect_ratio : Number;
	public var znear : Number;
	public var zfar : Number;
	public var sids : Object;
	
	public function DAEPerspective(element : XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.xfov = this.yfov = NaN;
		this.sids = new Object();
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		var sid : String = child.@sid.toString();
		
		if (sid.length) {
			this.sids[nodeName] = sid;
		}
		
		switch (nodeName) {
			case "xfov":
				this.xfov = parseFloat(readText(child));
				break;
			case "yfov":
				this.yfov = parseFloat(readText(child));
				trace("FOV: " + this.yfov);
				break;
			case "aspect_ratio":
				this.aspect_ratio = parseFloat(readText(child));
				break;
			case "zfar":
				this.zfar = parseFloat(readText(child));
				break;
			case "znear":
				this.znear = parseFloat(readText(child));
				break;
			default:
				break;
		}
	}
}

class DAEOptics extends DAEElement
{
	public var orthographic : DAEOrthographic;
	public var perspective : DAEPerspective;
	
	public function DAEOptics(element : XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		
		traverseChildren(element.ns::technique_common[0]);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "orthographic":
				this.orthographic = new DAEOrthographic(child);
				break;
			case "perspective":
				this.perspective = new DAEPerspective(child);
				break;
			default:
				break;
		}
	}
}

class DAECamera extends DAEElement
{
	public var optics : DAEOptics;
	
	public function DAECamera(element : XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		switch (nodeName) {
			case "optics":
				this.optics = new DAEOptics(child);
				break;
			default:
				break;
		}
	}
}

class DAEParserState
{
	public static const LOAD_XML 			: uint = 0;
	public static const PARSE_IMAGES		: uint = 1;
	public static const PARSE_MATERIALS 	: uint = 2;
	public static const PARSE_GEOMETRIES 	: uint = 3;
	public static const PARSE_CONTROLLERS 	: uint = 4;
	public static const PARSE_CAMERAS 		: uint = 5;
	public static const PARSE_LIGHTS 		: uint = 6;
	public static const PARSE_VISUAL_SCENE 	: uint = 7;
	public static const PARSE_ANIMATIONS 	: uint = 8;
	public static const PARSE_COMPLETE 		: uint = 9;
}


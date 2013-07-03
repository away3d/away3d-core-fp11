package away3d.loaders.parsers
{
	import flash.display.BitmapData;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	
	import away3d.arcane;
	import away3d.animators.SkeletonAnimationSet;
	import away3d.animators.data.JointPose;
	import away3d.animators.data.Skeleton;
	import away3d.animators.data.SkeletonJoint;
	import away3d.animators.data.SkeletonPose;
	import away3d.animators.nodes.AnimationNodeBase;
	import away3d.animators.nodes.SkeletonClipNode;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.Geometry;
	import away3d.core.base.SkinnedSubGeometry;
	import away3d.debug.Debug;
	import away3d.entities.Mesh;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.materials.ColorMaterial;
	import away3d.materials.ColorMultiPassMaterial;
	import away3d.materials.MaterialBase;
	import away3d.materials.MultiPassMaterialBase;
	import away3d.materials.SinglePassMaterialBase;
	import away3d.materials.TextureMaterial;
	import away3d.materials.TextureMultiPassMaterial;
	import away3d.materials.methods.BasicAmbientMethod;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.utils.DefaultMaterialManager;
	import away3d.textures.BitmapTexture;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;
	
	/**
	 * DAEParser provides a parser for the DAE data type.
	 */
	public class DAEParser extends ParserBase
	{
		public static const CONFIG_USE_GPU:uint = 1;
		public static const CONFIG_DEFAULT:uint = CONFIG_USE_GPU;
		public static const PARSE_GEOMETRIES:uint = 1;
		public static const PARSE_IMAGES:uint = 2;
		public static const PARSE_MATERIALS:uint = 4;
		public static const PARSE_VISUAL_SCENES:uint = 8;
		public static const PARSE_DEFAULT:uint = PARSE_GEOMETRIES | PARSE_IMAGES | PARSE_MATERIALS | PARSE_VISUAL_SCENES;
		
		private var _doc:XML;
		private var _ns:Namespace;
		private var _parseState:uint = 0;
		private var _imageList:XMLList;
		private var _imageCount:uint;
		private var _currentImage:uint;
		private var _dependencyCount:uint = 0;
		private var _configFlags:uint;
		private var _parseFlags:uint;
		private var _libImages:Object;
		private var _libMaterials:Object;
		private var _libEffects:Object;
		private var _libGeometries:Object;
		private var _libControllers:Object;
		private var _libAnimations:Object;
		private var _scene:DAEScene;
		private var _root:DAEVisualScene;
		//private var _rootContainer : ObjectContainer3D;
		private var _geometries:Vector.<Geometry>;
		private var _animationInfo:DAEAnimationInfo;
		//private var _animators : Vector.<IAnimator>;
		private var _rootNodes:Vector.<AnimationNodeBase>;
		private var _defaultBitmapMaterial:MaterialBase = DefaultMaterialManager.getDefaultMaterial();
		private var _defaultColorMaterial:ColorMaterial = new ColorMaterial(0xff0000);
		private var _defaultColorMaterialMulti:ColorMultiPassMaterial = new ColorMultiPassMaterial(0xff0000);
		private static var _numInstances:uint = 0;
		
		/**
		 * @param    configFlags    Bitfield to configure the parser. 
		 * @see DAEParser.CONFIG_USE_GPU etc.
		 */
		public function DAEParser(configFlags:uint = 0)
		{
			_configFlags = configFlags > 0? configFlags : CONFIG_DEFAULT;
			_parseFlags = PARSE_DEFAULT;
			
			super(ParserDataFormat.PLAIN_TEXT);
		}
		
		public function getGeometryByName(name:String, clone:Boolean = false):Geometry
		{
			if (!_geometries)
				return null;
			
			for each (var geometry:Geometry in _geometries) {
				if (geometry.name == name)
					return (clone? geometry.clone() : geometry);
			}
			
			return null;
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension:String):Boolean
		{
			extension = extension.toLowerCase();
			return extension == "dae";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data:*):Boolean
		{
			if (String(data).indexOf("COLLADA") != -1 || String(data).indexOf("collada") != -1)
				return true;
			
			return false;
		}
		
		
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependency(resourceDependency:ResourceDependency):void
		{
			if (resourceDependency.assets.length != 1)
				return;
			var resource:Texture2DBase = resourceDependency.assets[0] as Texture2DBase;
			_dependencyCount--;
			
			if (resource && BitmapTexture(resource).bitmapData) {
				var image:DAEImage = _libImages[ resourceDependency.id ] as DAEImage;
				
				if (image)
					image.resource = BitmapTexture(resource);
			}
			
			if (_dependencyCount == 0)
				_parseState = DAEParserState.PARSE_MATERIALS;
		}
		
		
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{
			_dependencyCount--;
			
			if (_dependencyCount == 0)
				_parseState = DAEParserState.PARSE_MATERIALS;
		}
		
		
		/**
		 * @inheritDoc
		 */
		protected override function proceedParsing():Boolean
		{
			if (!_defaultBitmapMaterial)
				_defaultBitmapMaterial = buildDefaultMaterial();
			
			switch (_parseState) {
				case DAEParserState.LOAD_XML:
					try {
						_doc = new XML(getTextData());
						_ns = _doc.namespace();
						_imageList = _doc._ns::library_images._ns::image;
						_imageCount = _dependencyCount = _imageList.length();
						_currentImage = 0;
						_parseState = _imageCount > 0? DAEParserState.PARSE_IMAGES : DAEParserState.PARSE_MATERIALS;
						
					} catch (e:Error) {
						return PARSING_DONE;
					}
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
					_parseState = DAEParserState.PARSE_VISUAL_SCENE;
					break;
				
				case DAEParserState.PARSE_VISUAL_SCENE:
					_scene = null;
					_root = null;
					_libAnimations = parseLibrary(_doc._ns::library_animations._ns::animation, DAEAnimation);
					//_animators = new Vector.<IAnimator>();
					_rootNodes = new Vector.<AnimationNodeBase>();
					
					if (_doc.._ns::scene && _doc.._ns::scene.length()) {
						_scene = new DAEScene(_doc.._ns::scene[0]);
						
						var list:XMLList = _doc.._ns::visual_scene.(@id == _scene.instance_visual_scene.url);
						
						if (list.length()) {
							//_rootContainer = new ObjectContainer3D();
							_root = new DAEVisualScene(this, list[0]);
							_root.updateTransforms(_root);
							_animationInfo = parseAnimationInfo();
							parseSceneGraph(_root);
						}
					}
					_parseState = isAnimated? DAEParserState.PARSE_ANIMATIONS : DAEParserState.PARSE_COMPLETE;
					break;
				
				case DAEParserState.PARSE_ANIMATIONS:
					_parseState = DAEParserState.PARSE_COMPLETE;
					break;
				
				case DAEParserState.PARSE_COMPLETE:
					//finalizeAsset(_rootContainer, "COLLADA_ROOT_" + (_numInstances++));
					return PARSING_DONE;
			}
			
			return MORE_TO_PARSE;
		}
		
		private function buildDefaultMaterial(map:BitmapData = null):MaterialBase
		{
			//TODO:fix this duplication mess
			if (map) {
				if (materialMode < 2)
					_defaultBitmapMaterial = new TextureMaterial(new BitmapTexture(map));
				else
					_defaultBitmapMaterial = new TextureMultiPassMaterial(new BitmapTexture(map));
			} else if (materialMode < 2)
				_defaultBitmapMaterial = DefaultMaterialManager.getDefaultMaterial();
			else
				_defaultBitmapMaterial = new TextureMultiPassMaterial(DefaultMaterialManager.getDefaultTexture());
			
			return _defaultBitmapMaterial;
		}
		
		private function applySkinBindShape(geometry:Geometry, skin:DAESkin):void
		{
			var vec:Vector3D = new Vector3D();
			var i:uint;
			for each (var sub:CompactSubGeometry in geometry.subGeometries) {
				var vertexData:Vector.<Number> = sub.vertexData;
				
				for (i = sub.vertexOffset; i < vertexData.length; i += sub.vertexStride) {
					vec.x = vertexData[i + 0];
					vec.y = vertexData[i + 1];
					vec.z = vertexData[i + 2];
					vec = skin.bind_shape_matrix.transformVector(vec);
					vertexData[i + 0] = vec.x;
					vertexData[i + 1] = vec.y;
					vertexData[i + 2] = vec.z;
				}
				sub.updateData(vertexData);
			}
		}
		
		private function applySkinController(geometry:Geometry, mesh:DAEMesh, skin:DAESkin, skeleton:Skeleton):void
		{
			var sub:CompactSubGeometry;
			var skinned_sub_geom:SkinnedSubGeometry;
			var primitive:DAEPrimitive;
			var jointIndices:Vector.<Number>;
			var jointWeights:Vector.<Number>;
			var i:uint, j:uint, k:uint, l:int;
			
			for (i = 0; i < geometry.subGeometries.length; i++) {
				sub = CompactSubGeometry(geometry.subGeometries[i]);
				primitive = mesh.primitives[i];
				jointIndices = new Vector.<Number>(skin.maxBones*primitive.vertices.length, true);
				jointWeights = new Vector.<Number>(skin.maxBones*primitive.vertices.length, true);
				l = 0;
				
				for (j = 0; j < primitive.vertices.length; j++) {
					var weights:Vector.<DAEVertexWeight> = skin.weights[primitive.vertices[j].daeIndex];
					
					for (k = 0; k < weights.length; k++) {
						var influence:DAEVertexWeight = weights[k];
						// indices need to be multiplied by 3 (amount of matrix registers)
						jointIndices[l] = influence.joint*3;
						jointWeights[l++] = influence.weight;
					}
					
					for (k = weights.length; k < skin.maxBones; k++) {
						jointIndices[l] = 0;
						jointWeights[l++] = 0;
					}
				}
				
				skinned_sub_geom = new SkinnedSubGeometry(skin.maxBones);
				skinned_sub_geom.updateData(sub.vertexData.concat());
				skinned_sub_geom.updateIndexData(sub.indexData);
				skinned_sub_geom.updateJointIndexData(jointIndices);
				skinned_sub_geom.updateJointWeightsData(jointWeights);
				geometry.subGeometries[i] = skinned_sub_geom;
				geometry.subGeometries[i].parentGeometry = geometry;
			}
		}
		
		private function parseAnimationInfo():DAEAnimationInfo
		{
			var info:DAEAnimationInfo = new DAEAnimationInfo();
			info.minTime = Number.MAX_VALUE;
			info.maxTime = -info.minTime;
			info.numFrames = 0;
			
			for each (var animation:DAEAnimation in _libAnimations) {
				for each (var channel:DAEChannel in animation.channels) {
					var node:DAENode = _root.findNodeById(channel.targetId);
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
		
		private function parseLibrary(list:XMLList, clas:Class):Object
		{
			var library:Object = {};
			for (var i:uint = 0; i < list.length(); i++) {
				var obj:* = new clas(list[i]);
				library[ obj.id ] = obj;
			}
			
			return library;
		}
		
		private function parseSceneGraph(node:DAENode, parent:ObjectContainer3D = null, tab:String = ""):void
		{
			var _tab:String = tab + "-";
			
			Debug.trace(_tab + node.name);
			
			if (node.type != "JOINT") {
				Debug.trace(_tab + "ObjectContainer3D : " + node.name);
				
				var container:ObjectContainer3D;
				
				if (node.instance_geometries.length > 0)
					container = processGeometries(node, parent);
				else if (node.instance_controllers.length > 0)
					container = processControllers(node, parent);
				else {
					// trace("Should be a container " + node.id)
					container = new ObjectContainer3D();
					container.name = node.id;
					container.transform.rawData = node.matrix.rawData;
					finalizeAsset(container, node.id);
					
					if (parent)
						parent.addChild(container);
				}
				
				parent = container;
			}
			for (var i:uint = 0; i < node.nodes.length; i++)
				parseSceneGraph(node.nodes[i], parent, _tab);
		}
		
		private function processController(controller:DAEController, instance:DAEInstanceController):Geometry
		{
			var geometry:Geometry;
			if (!controller)
				return null;
			
			if (controller.morph)
				geometry = processControllerMorph(controller, instance);
			else if (controller.skin)
				geometry = processControllerSkin(controller, instance);
			
			return geometry;
		}
		
		private function processControllerMorph(controller:DAEController, instance:DAEInstanceController):Geometry
		{
			Debug.trace(" * processControllerMorph : " + controller);
			
			var morph:DAEMorph = controller.morph;
			
			var base:Geometry = processController(_libControllers[morph.source], instance);
			if (!base)
				return null;
			
			var targets:Vector.<Geometry> = new Vector.<Geometry>();
			base = getGeometryByName(morph.source);
			var vertexData:Vector.<Number>;
			var sub:CompactSubGeometry;
			var startWeight:Number = 1.0;
			var i:uint, j:uint, k:uint;
			var geometry:Geometry;
			
			for (i = 0; i < morph.targets.length; i++) {
				geometry = getGeometryByName(morph.targets[i]);
				if (!geometry)
					return null;
				
				targets.push(geometry);
				startWeight -= morph.weights[i];
			}
			
			for (i = 0; i < base.subGeometries.length; i++) {
				sub = CompactSubGeometry(base.subGeometries[i]);
				vertexData = sub.vertexData.concat();
				for (var v:int = 0; v < vertexData.length/13; v++) {
					j = sub.vertexOffset + v*sub.vertexStride;
					vertexData[j] = morph.method == "NORMALIZED"? startWeight*sub.vertexData[j] : sub.vertexData[j];
					for (k = 0; k < morph.targets.length; k++)
						vertexData[j] += morph.weights[k]*targets[k].subGeometries[i].vertexData[j];
				}
				sub.updateData(vertexData);
			}
			
			return base;
		}
		
		private function processControllerSkin(controller:DAEController, instance:DAEInstanceController):Geometry
		{
			Debug.trace(" * processControllerSkin : " + controller);
			
			var geometry:Geometry = getGeometryByName(controller.skin.source);
			
			if (!geometry)
				geometry = processController(_libControllers[controller.skin.source], instance);
			
			if (!geometry)
				return null;
			
			var skeleton:Skeleton = parseSkeleton(instance);
			var daeGeometry:DAEGeometry = _libGeometries[geometry.name];
			applySkinBindShape(geometry, controller.skin);
			applySkinController(geometry, daeGeometry.mesh, controller.skin, skeleton);
			controller.skin.userData = skeleton;
			
			finalizeAsset(skeleton);
			
			return geometry;
		}
		
		private function processControllers(node:DAENode, container:ObjectContainer3D):Mesh
		{
			Debug.trace(" * processControllers : " + node.name);
			
			var instance:DAEInstanceController;
			var daeGeometry:DAEGeometry;
			var controller:DAEController;
			var effects:Vector.<DAEEffect>;
			var geometry:Geometry;
			var mesh:Mesh;
			var skeleton:Skeleton;
			var clip:SkeletonClipNode;
			//var anim:SkeletonAnimation;
			var animationSet:SkeletonAnimationSet;
			var i:uint, j:uint;
			var hasMaterial:Boolean;
			var weights:uint;
			var jpv:uint;
			
			for (i = 0; i < node.instance_controllers.length; i++) {
				instance = node.instance_controllers[i];
				controller = _libControllers[instance.url] as DAEController;
				
				geometry = processController(controller, instance);
				if (!geometry)
					continue;
				
				daeGeometry = _libGeometries[geometry.name] as DAEGeometry;
				effects = getMeshEffects(instance.bind_material, daeGeometry.mesh);
				
				mesh = new Mesh(geometry, null);
				hasMaterial = false;
				
				if (node.name != "")
					mesh.name = node.name;
				
				if (effects.length > 0) {
					for (j = 0; j < mesh.subMeshes.length; j++) {
						if (effects[j].material) {
							mesh.subMeshes[j].material = effects[j].material;
							hasMaterial = true;
						}
					}
				}
				
				if (!hasMaterial)
					mesh.material = _defaultBitmapMaterial;
				
				if (container)
					container.addChild(mesh);
				
				if (controller.skin && controller.skin.userData is Skeleton) {
					
					if (!animationSet)
						animationSet = new SkeletonAnimationSet(controller.skin.maxBones);
					
					skeleton = controller.skin.userData as Skeleton;
					
					clip = processSkinAnimation(controller.skin, mesh, skeleton);
					clip.looping = true;
					
					weights = SkinnedSubGeometry(mesh.geometry.subGeometries[0]).jointIndexData.length;
					jpv = weights/(mesh.geometry.subGeometries[0].vertexData.length/3);
					//anim = new SkeletonAnimation(skeleton, jpv);
					
					//var state:SkeletonAnimationState = SkeletonAnimationState(mesh.animationState);
					//animator = new SmoothSkeletonAnimator(state);
					//SmoothSkeletonAnimator(animator).addSequence(SkeletonAnimationSequence(sequence));
					clip.name = "node_" + _rootNodes.length;
					animationSet.addAnimation(clip);
					
					//_animators.push(animator);
					_rootNodes.push(clip);
				}
				
				finalizeAsset(mesh);
			}
			
			if (animationSet)
				finalizeAsset(animationSet);
			
			return mesh;
		}
		
		private function processSkinAnimation(skin:DAESkin, mesh:Mesh, skeleton:Skeleton):SkeletonClipNode
		{
			Debug.trace(" * processSkinAnimation : " + mesh.name);
			
			//var useGPU : Boolean = _configFlags & CONFIG_USE_GPU ? true : false;
			//var animation : SkeletonAnimation = new SkeletonAnimation(skeleton, skin.maxBones, useGPU);
			var animated:Boolean = isAnimatedSkeleton(skeleton);
			var duration:Number = _animationInfo.numFrames == 0? 1.0 : _animationInfo.maxTime - _animationInfo.minTime;
			var numFrames:int = Math.max(_animationInfo.numFrames, (animated? 50 : 2));
			var frameDuration:Number = duration/numFrames;
			
			var t:Number = 0;
			var i:uint, j:uint;
			var clip:SkeletonClipNode = new SkeletonClipNode();
			//mesh.geometry.animation = animation;
			var skeletonPose:SkeletonPose;
			var identity:Matrix3D;
			var matrix:Matrix3D;
			var node:DAENode;
			var pose:JointPose;
			
			for (i = 0; i < numFrames; i++) {
				skeletonPose = new SkeletonPose();
				
				for (j = 0; j < skin.joints.length; j++) {
					node = _root.findNodeById(skin.joints[j]) || _root.findNodeBySid(skin.joints[j]);
					pose = new JointPose();
					matrix = node.getAnimatedMatrix(t) || node.matrix;
					pose.name = skin.joints[j];
					pose.orientation.fromMatrix(matrix);
					pose.translation.copyFrom(matrix.position);
					
					if (isNaN(pose.orientation.x)) {
						if (!identity)
							identity = new Matrix3D();
						pose.orientation.fromMatrix(identity);
					}
					
					skeletonPose.jointPoses.push(pose);
				}
				
				t += frameDuration;
				clip.addFrame(skeletonPose, frameDuration*1000);
			}
			
			finalizeAsset(clip);
			
			return clip;
		}
		
		private function isAnimatedSkeleton(skeleton:Skeleton):Boolean
		{
			var node:DAENode;
			
			for (var i:uint = 0; i < skeleton.joints.length; i++) {
				try {
					node = _root.findNodeById(skeleton.joints[i].name) || _root.findNodeBySid(skeleton.joints[i].name);
				} catch (e:Error) {
					trace("Errors found in skeleton joints data");
					return false;
				}
				if (node && node.channels.length)
					return true;
			}
			
			return false;
		}
		
		private function processGeometries(node:DAENode, container:ObjectContainer3D):Mesh
		{
			Debug.trace(" * processGeometries : " + node.name);
			var instance:DAEInstanceGeometry;
			var daeGeometry:DAEGeometry;
			var effects:Vector.<DAEEffect>;
			var mesh:Mesh;
			var geometry:Geometry;
			var i:uint, j:uint;
			
			for (i = 0; i < node.instance_geometries.length; i++) {
				instance = node.instance_geometries[i];
				daeGeometry = _libGeometries[instance.url] as DAEGeometry;
				
				if (daeGeometry && daeGeometry.mesh) {
					geometry = getGeometryByName(instance.url);
					effects = getMeshEffects(instance.bind_material, daeGeometry.mesh);
					
					if (geometry) {
						mesh = new Mesh(geometry);
						
						if (node.name != "")
							mesh.name = node.name;
						
						if (effects.length == geometry.subGeometries.length) {
							for (j = 0; j < mesh.subMeshes.length; j++)
								mesh.subMeshes[j].material = effects[j].material;
						}
						mesh.transform = node.matrix;
						
						if (container)
							container.addChild(mesh);
						
						finalizeAsset(mesh);
					}
				}
			}
			
			return mesh;
		}
		
		private function getMeshEffects(bindMaterial:DAEBindMaterial, mesh:DAEMesh):Vector.<DAEEffect>
		{
			var effects:Vector.<DAEEffect> = new Vector.<DAEEffect>();
			if (!bindMaterial)
				return effects;
			
			var material:DAEMaterial;
			var effect:DAEEffect;
			var instance:DAEInstanceMaterial;
			var i:uint, j:uint;
			
			for (i = 0; i < mesh.primitives.length; i++) {
				if (!bindMaterial.instance_material)
					continue;
				for (j = 0; j < bindMaterial.instance_material.length; j++) {
					instance = bindMaterial.instance_material[j];
					if (mesh.primitives[i].material == instance.symbol) {
						material = _libMaterials[instance.target] as DAEMaterial;
						effect = _libEffects[material.instance_effect.url];
						if (effect)
							effects.push(effect);
						break;
					}
				}
			}
			
			return effects;
		}
		
		private function parseSkeleton(instance_controller:DAEInstanceController):Skeleton
		{
			if (!instance_controller.skeleton.length)
				return null;
			
			Debug.trace(" * parseSkeleton : " + instance_controller);
			
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
		
		private function parseSkeletonHierarchy(node:DAENode, skin:DAESkin, skeleton:Skeleton, parent:int = -1, tab:String = ""):void
		{
			var _tab:String = tab + "-";
			
			Debug.trace(_tab + "[" + node.id + "," + node.sid + "]");
			
			var jointIndex:int = skin.jointSourceType == "IDREF_array"? skin.getJointIndex(node.id) : skin.getJointIndex(node.sid);
			
			if (jointIndex >= 0) {
				var joint:SkeletonJoint = new SkeletonJoint();
				joint.parentIndex = parent;
				
				if (!isNaN(jointIndex) && jointIndex < skin.joints.length) {
					if (skin.joints[jointIndex])
						joint.name = skin.joints[jointIndex];
				} else {
					Debug.trace("Error: skin.joints index out of range");
					return;
				}
				
				var ibm:Matrix3D = skin.inv_bind_matrix[jointIndex];
				
				joint.inverseBindPose = ibm.rawData;
				
				skeleton.joints[jointIndex] = joint;
			} else
				Debug.trace(_tab + "no jointIndex!");
			
			for (var i:uint = 0; i < node.nodes.length; i++) {
				try {
					parseSkeletonHierarchy(node.nodes[i], skin, skeleton, jointIndex);
				} catch (e:Error) {
					trace(e.message);
				}
			}
		}
		
		private function setupMaterial(material:DAEMaterial, effect:DAEEffect):MaterialBase
		{
			if (!effect || !material)
				return null;
			
			var mat:MaterialBase
			if (materialMode < 2)
				mat = _defaultColorMaterial;
			else
				mat = new ColorMultiPassMaterial(_defaultColorMaterial.color);
			
			var textureMaterial:TextureMaterial;
			var ambient:DAEColorOrTexture = effect.shader.props["ambient"];
			var diffuse:DAEColorOrTexture = effect.shader.props["diffuse"];
			var specular:DAEColorOrTexture = effect.shader.props["specular"];
			var shininess:Number = effect.shader.props.hasOwnProperty("shininess")? Number(effect.shader.props["shininess"]) : 10;
			var transparency:Number = effect.shader.props.hasOwnProperty("transparency")? Number(effect.shader.props["transparency"]) : 1;
			
			if (diffuse && diffuse.texture && effect.surface) {
				var image:DAEImage = _libImages[effect.surface.init_from];
				
				if (image.resource !== null && isBitmapDataValid(image.resource.bitmapData)) {
					mat = buildDefaultMaterial(image.resource.bitmapData);
					if (materialMode < 2)
						TextureMaterial(mat).alpha = transparency;
				} else
					mat = buildDefaultMaterial();
				
			}
			
			else if (diffuse && diffuse.color) {
				if (materialMode < 2)
					mat = new ColorMaterial(diffuse.color.rgb, transparency);
				else
					mat = new ColorMultiPassMaterial(diffuse.color.rgb);
			}
			if (mat) {
				if (materialMode < 2) {
					SinglePassMaterialBase(mat).ambientMethod = new BasicAmbientMethod();
					SinglePassMaterialBase(mat).diffuseMethod = new BasicDiffuseMethod();
					SinglePassMaterialBase(mat).specularMethod = new BasicSpecularMethod();
					SinglePassMaterialBase(mat).ambientColor = (ambient && ambient.color)? ambient.color.rgb : 0x303030;
					SinglePassMaterialBase(mat).specularColor = (specular && specular.color)? specular.color.rgb : 0x202020;
					SinglePassMaterialBase(mat).gloss = shininess;
					SinglePassMaterialBase(mat).ambient = 1;
					SinglePassMaterialBase(mat).specular = 1;
				} else {
					MultiPassMaterialBase(mat).ambientMethod = new BasicAmbientMethod();
					MultiPassMaterialBase(mat).diffuseMethod = new BasicDiffuseMethod();
					MultiPassMaterialBase(mat).specularMethod = new BasicSpecularMethod();
					MultiPassMaterialBase(mat).ambientColor = (ambient && ambient.color)? ambient.color.rgb : 0x303030;
					MultiPassMaterialBase(mat).specularColor = (specular && specular.color)? specular.color.rgb : 0x202020;
					MultiPassMaterialBase(mat).gloss = shininess;
					MultiPassMaterialBase(mat).ambient = 1;
					MultiPassMaterialBase(mat).specular = 1;
					
				}
			}
			
			mat.name = material.id;
			finalizeAsset(mat);
			
			return mat;
		}
		
		private function setupMaterials():void
		{
			for each (var material:DAEMaterial in _libMaterials) {
				if (_libEffects.hasOwnProperty(material.instance_effect.url)) {
					var effect:DAEEffect = _libEffects[material.instance_effect.url] as DAEEffect;
					effect.material = setupMaterial(material, effect);
				}
			}
		}
		
		private function translateGeometries():Vector.<Geometry>
		{
			var geometries:Vector.<Geometry> = new Vector.<Geometry>();
			var daeGeometry:DAEGeometry;
			var geometry:Geometry;
			
			for (var id:String in _libGeometries) {
				daeGeometry = _libGeometries[id] as DAEGeometry;
				if (daeGeometry.mesh) {
					geometry = translateGeometry(daeGeometry.mesh);
					if (geometry.subGeometries.length) {
						if (id && isNaN(Number(id)))
							geometry.name = id;
						geometries.push(geometry);
						
						finalizeAsset(geometry);
					}
				}
			}
			
			return geometries;
		}
		
		private function translateGeometry(mesh:DAEMesh):Geometry
		{
			var geometry:Geometry = new Geometry();
			for (var i:uint = 0; i < mesh.primitives.length; i++) {
				var sub:CompactSubGeometry = translatePrimitive(mesh, mesh.primitives[i]);
				if (sub)
					geometry.addSubGeometry(sub);
			}
			
			return geometry;
		}
		
		private function translatePrimitive(mesh:DAEMesh, primitive:DAEPrimitive, reverseTriangles:Boolean = true, autoDeriveVertexNormals:Boolean = true, autoDeriveVertexTangents:Boolean = true):CompactSubGeometry
		{
			var sub:CompactSubGeometry = new CompactSubGeometry();
			var indexData:Vector.<uint> = new Vector.<uint>();
			var data:Vector.<Number> = new Vector.<Number>();
			var faces:Vector.<DAEFace> = primitive.create(mesh);
			var v:DAEVertex, f:DAEFace;
			var i:uint, j:uint;
			
			// vertices, normals and uvs
			for (i = 0; i < primitive.vertices.length; i++) {
				v = primitive.vertices[i];
				data.push(v.x, v.y, v.z);
				data.push(v.nx, v.ny, v.nz);
				data.push(0, 0, 0);
				
				if (v.numTexcoordSets > 0) {
					data.push(v.uvx, 1.0 - v.uvy);
					if (v.numTexcoordSets > 1)
						data.push(v.uvx2, 1.0 - v.uvy2);
					else
						data.push(v.uvx, 1.0 - v.uvy);
				} else
					data.push(0, 0, 0, 0);
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
			sub.updateData(data);
			sub.updateIndexData(indexData);
			
			return sub;
		}
		
		public function get geometries():Vector.<Geometry>
		{
			return _geometries;
		}
		
		public function get effects():Object
		{
			return _libEffects;
		}
		
		public function get images():Object
		{
			return _libImages;
		}
		
		public function get materials():Object
		{
			return _libMaterials;
		}
		
		public function get isAnimated():Boolean
		{
			return (_doc._ns::library_animations._ns::animation.length() > 0);
		}
	
	}
}

import away3d.loaders.parsers.*;

import flash.geom.*;

class DAEAnimationInfo
{
	public var minTime:Number;
	public var maxTime:Number;
	public var numFrames:uint;
	
	public function DAEAnimationInfo()
	{
	}
}

class DAEElement
{
	public static var USE_LEFT_HANDED:Boolean = true;
	public var id:String;
	public var name:String;
	public var sid:String;
	public var userData:*;
	protected var ns:Namespace;
	
	public function DAEElement(element:XML = null)
	{
		if (element)
			deserialize(element);
	}
	
	public function deserialize(element:XML):void
	{
		ns = element.namespace();
		id = element.@id.toString();
		name = element.@name.toString();
		sid = element.@sid.toString();
	}
	
	public function dispose():void
	{
	}
	
	protected function traverseChildHandler(child:XML, nodeName:String):void
	{
	}
	
	protected function traverseChildren(element:XML, name:String = null):void
	{
		var children:XMLList = name? element.ns::[name] : element.children();
		var count:int = children.length();
		
		for (var i:uint = 0; i < count; i++)
			traverseChildHandler(children[i], children[i].name().localName);
	}
	
	protected function convertMatrix(matrix:Matrix3D):void
	{
		var indices:Vector.<int> = Vector.<int>([2, 6, 8, 9, 11, 14]);
		var raw:Vector.<Number> = matrix.rawData;
		for (var i:uint = 0; i < indices.length; i++)
			raw[indices[i]] *= -1.0;
		
		matrix.rawData = raw;
	}
	
	protected function getRootElement(element:XML):XML
	{
		var tmp:XML = element;
		while (tmp.name().localName != "COLLADA")
			tmp = tmp.parent();
		
		return (tmp.name().localName == "COLLADA"? tmp : null);
	}
	
	protected function readFloatArray(element:XML):Vector.<Number>
	{
		var raw:String = readText(element);
		var parts:Array = raw.split(/\s+/);
		var floats:Vector.<Number> = new Vector.<Number>();
		
		for (var i:uint = 0; i < parts.length; i++)
			floats.push(parseFloat(parts[i]));
		
		return floats;
	}
	
	protected function readIntArray(element:XML):Vector.<int>
	{
		var raw:String = readText(element);
		var parts:Array = raw.split(/\s+/);
		var ints:Vector.<int> = new Vector.<int>();
		
		for (var i:uint = 0; i < parts.length; i++)
			ints.push(parseInt(parts[i], 10));
		
		return ints;
	}
	
	protected function readStringArray(element:XML):Vector.<String>
	{
		var raw:String = readText(element);
		var parts:Array = raw.split(/\s+/);
		var strings:Vector.<String> = new Vector.<String>();
		
		for (var i:uint = 0; i < parts.length; i++)
			strings.push(parts[i]);
		
		return strings;
	}
	
	protected function readIntAttr(element:XML, name:String, defaultValue:int = 0):int
	{
		var v:int = parseInt(element.@[name], 10);
		v = v == 0? defaultValue : v;
		return v;
	}
	
	protected function readText(element:XML):String
	{
		return trimString(element.text().toString());
	}
	
	protected function trimString(s:String):String
	{
		return s.replace(/^\s+/, "").replace(/\s+$/, "");
	}
}

class DAEImage extends DAEElement
{
	public var init_from:String;
	public var resource:*;
	
	public function DAEImage(element:XML = null):void
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		init_from = readText(element.ns::init_from[0]);
		resource = null;
	}
}

class DAEParam extends DAEElement
{
	public var type:String;
	
	public function DAEParam(element:XML = null):void
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.type = element.@type.toString();
	}
}

class DAEAccessor extends DAEElement
{
	public var params:Vector.<DAEParam>;
	public var source:String;
	public var stride:int;
	public var count:int;
	
	public function DAEAccessor(element:XML = null):void
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
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
		if (nodeName == "param")
			this.params.push(new DAEParam(child));
	}
}

class DAESource extends DAEElement
{
	public var accessor:DAEAccessor;
	public var type:String;
	public var floats:Vector.<Number>;
	public var ints:Vector.<int>;
	public var bools:Vector.<Boolean>;
	public var strings:Vector.<String>;
	
	public function DAESource(element:XML = null):void
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
		}
	}
}

class DAEInput extends DAEElement
{
	public var semantic:String;
	public var source:String;
	public var offset:int;
	public var set:int;
	
	public function DAEInput(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
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
	public var index:uint = 0;
	public var daeIndex:uint = 0;
	
	public function DAEVertex(numTexcoordSets:uint)
	{
		this.numTexcoordSets = numTexcoordSets;
		x = y = z = nx = ny = nz = uvx = uvy = uvx2 = uvy2 = 0;
	}
	
	public function get hash():String
	{
		var s:String = format(x);
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
	
	private function format(v:Number, numDecimals:int = 2):String
	{
		return v.toFixed(numDecimals);
	}
}

class DAEFace
{
	public var vertices:Vector.<DAEVertex>;
	
	public function DAEFace():void
	{
		this.vertices = new Vector.<DAEVertex>();
	}
}

class DAEPrimitive extends DAEElement
{
	public var type:String;
	public var material:String;
	public var count:int;
	public var vertices:Vector.<DAEVertex>;
	private var _inputs:Vector.<DAEInput>;
	private var _p:Vector.<int>;
	private var _vcount:Vector.<int>;
	private var _texcoordSets:Vector.<int>;
	
	public function DAEPrimitive(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.type = element.name().localName;
		this.material = element.@material.toString();
		this.count = readIntAttr(element, "count", 0);
		
		_inputs = new Vector.<DAEInput>();
		_p = null;
		_vcount = null;
		
		var list:XMLList = element.ns::input;
		
		for (var i:uint = 0; i < list.length(); i++)
			_inputs.push(new DAEInput(list[i]));
		
		if (element.ns::p && element.ns::p.length())
			_p = readIntArray(element.ns::p[0]);
		
		if (element.ns::vcount && element.ns::vcount.length())
			_vcount = readIntArray(element.ns::vcount[0]);
	}
	
	public function create(mesh:DAEMesh):Vector.<DAEFace>
	{
		if (!prepareInputs(mesh))
			return null;
		
		var faces:Vector.<DAEFace> = new Vector.<DAEFace>();
		var input:DAEInput;
		var source:DAESource;
		//var numInputs : uint = _inputs.length;  //shared inputs offsets VERTEX and TEXCOORD
		var numInputs:uint;
		if (_inputs.length > 1) {
			var offsets:Array = [];
			for each (var daei:DAEInput in _inputs) {
				if (!offsets[daei.offset]) {
					offsets[daei.offset] = true;
					numInputs++;
				}
			}
		} else
			numInputs = _inputs.length;
		
		var idx:uint = 0, index:uint;
		var i:uint, j:uint;
		var vertexDict:Object = {};
		var idx32:uint;
		this.vertices = new Vector.<DAEVertex>();
		
		while (idx < _p.length) {
			var vcount:uint = _vcount != null? _vcount.shift() : 3;
			var face:DAEFace = new DAEFace();
			
			for (i = 0; i < vcount; i++) {
				var t:uint = i*numInputs;
				var vertex:DAEVertex = new DAEVertex(_texcoordSets.length);
				
				for (j = 0; j < _inputs.length; j++) {
					input = _inputs[j];
					index = _p[idx + t + input.offset];
					source = mesh.sources[input.source] as DAESource;
					idx32 = index*source.accessor.params.length;
					
					switch (input.semantic) {
						case "VERTEX":
							vertex.x = source.floats[idx32 + 0];
							vertex.y = source.floats[idx32 + 1];
							if (DAEElement.USE_LEFT_HANDED)
								vertex.z = -source.floats[idx32 + 2];
							else
								vertex.z = source.floats[idx32 + 2];
							vertex.daeIndex = index;
							break;
						case "NORMAL":
							vertex.nx = source.floats[idx32 + 0];
							vertex.ny = source.floats[idx32 + 1];
							if (DAEElement.USE_LEFT_HANDED)
								vertex.nz = -source.floats[idx32 + 2];
							else
								vertex.nz = source.floats[idx32 + 2];
							break;
						case "TEXCOORD":
							if (input.set == _texcoordSets[0]) {
								vertex.uvx = source.floats[idx32 + 0];
								vertex.uvy = source.floats[idx32 + 1];
							} else {
								vertex.uvx2 = source.floats[idx32 + 0];
								vertex.uvy2 = source.floats[idx32 + 1];
							}
							break;
						default:
							break;
					}
				}
				var hash:String = vertex.hash;
				
				if (vertexDict[hash])
					face.vertices.push(vertexDict[hash]);
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
				for (var k:uint = 1; k < face.vertices.length - 1; k++) {
					var f:DAEFace = new DAEFace();
					f.vertices.push(v0);
					f.vertices.push(face.vertices[k]);
					f.vertices.push(face.vertices[k + 1]);
					faces.push(f);
				}
				
			} else if (face.vertices.length == 3)
				faces.push(face);
			idx += (vcount*numInputs);
		}
		return faces;
	}
	
	private function prepareInputs(mesh:DAEMesh):Boolean
	{
		var input:DAEInput;
		var i:uint, j:uint;
		var result:Boolean = true;
		_texcoordSets = new Vector.<int>();
		
		for (i = 0; i < _inputs.length; i++) {
			input = _inputs[i];
			
			if (input.semantic == "TEXCOORD")
				_texcoordSets.push(input.set);
			
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
	public var mesh:DAEMesh;
	public var inputs:Vector.<DAEInput>;
	
	public function DAEVertices(mesh:DAEMesh, element:XML = null)
	{
		this.mesh = mesh;
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.inputs = new Vector.<DAEInput>();
		traverseChildren(element, "input");
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		nodeName = nodeName;
		this.inputs.push(new DAEInput(child));
	}
}

class DAEGeometry extends DAEElement
{
	public var mesh:DAEMesh;
	public var meshName:String = "";
	
	public function DAEGeometry(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		traverseChildren(element);
		meshName = element.attribute("name");
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		if (nodeName == "mesh")
			this.mesh = new DAEMesh(this, child); //case "spline"//case "convex_mesh":
	}
}

class DAEMesh extends DAEElement
{
	public var geometry:DAEGeometry;
	public var sources:Object;
	public var vertices:DAEVertices;
	public var primitives:Vector.<DAEPrimitive>;
	
	public function DAEMesh(geometry:DAEGeometry, element:XML = null)
	{
		this.geometry = geometry;
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.sources = {};
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
		}
	}
}

class DAEBindMaterial extends DAEElement
{
	public var instance_material:Vector.<DAEInstanceMaterial>;
	
	public function DAEBindMaterial(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.instance_material = new Vector.<DAEInstanceMaterial>();
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		if (nodeName == "technique_common") {
			for (var i:uint = 0; i < child.children().length(); i++)
				this.instance_material.push(new DAEInstanceMaterial(child.children()[i]));
		}
	}
}

class DAEBindVertexInput extends DAEElement
{
	public var semantic:String;
	public var input_semantic:String;
	public var input_set:int;
	
	public function DAEBindVertexInput(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.semantic = element.@semantic.toString();
		this.input_semantic = element.@input_semantic.toString();
		this.input_set = readIntAttr(element, "input_set");
	}
}

class DAEInstance extends DAEElement
{
	public var url:String;
	
	public function DAEInstance(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.url = element.@url.toString().replace(/^#/, "");
	}
}

class DAEInstanceController extends DAEInstance
{
	public var bind_material:DAEBindMaterial;
	public var skeleton:Vector.<String>;
	
	public function DAEInstanceController(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
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
		}
	}
}

class DAEInstanceEffect extends DAEInstance
{
	public function DAEInstanceEffect(element:XML = null)
	{
		super(element);
	}
}

class DAEInstanceGeometry extends DAEInstance
{
	public var bind_material:DAEBindMaterial;
	
	public function DAEInstanceGeometry(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.bind_material = null;
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		if (nodeName == "bind_material")
			this.bind_material = new DAEBindMaterial(child);
	}
}

class DAEInstanceMaterial extends DAEInstance
{
	public var target:String;
	public var symbol:String;
	public var bind_vertex_input:Vector.<DAEBindVertexInput>;
	
	public function DAEInstanceMaterial(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.target = element.@target.toString().replace(/^#/, "");
		this.symbol = element.@symbol.toString();
		this.bind_vertex_input = new Vector.<DAEBindVertexInput>();
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		if (nodeName == "bind_vertex_input")
			this.bind_vertex_input.push(new DAEBindVertexInput(child));
	}
}

class DAEInstanceNode extends DAEInstance
{
	public function DAEInstanceNode(element:XML = null)
	{
		super(element);
	}
}

class DAEInstanceVisualScene extends DAEInstance
{
	public function DAEInstanceVisualScene(element:XML = null)
	{
		super(element);
	}
}

class DAEColor
{
	public var r:Number;
	public var g:Number;
	public var b:Number;
	public var a:Number;
	
	public function DAEColor()
	{
	}
	
	public function get rgb():uint
	{
		var c:uint = 0;
		c |= int(r*255.0) << 16;
		c |= int(g*255.0) << 8;
		c |= int(b*255.0);
		
		return c;
	}
	
	public function get rgba():uint
	{
		return (int(a*255.0) << 24 | this.rgb);
	}
}

class DAETexture
{
	public var texture:String;
	public var texcoord:String;
	
	public function DAETexture()
	{
	}
}

class DAEColorOrTexture extends DAEElement
{
	public var color:DAEColor;
	public var texture:DAETexture;
	
	public function DAEColorOrTexture(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
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
				this.color.a = values.length > 3? values[3] : 1.0;
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
	public var type:String;
	public var init_from:String;
	
	public function DAESurface(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.type = element.@type.toString();
		this.init_from = readText(element.ns::init_from[0]);
	}
}

class DAESampler2D extends DAEElement
{
	public var source:String;
	
	public function DAESampler2D(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.source = readText(element.ns::source[0]);
	}
}

class DAEShader extends DAEElement
{
	public var type:String;
	public var props:Object;
	
	public function DAEShader(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.type = element.name().localName;
		this.props = {};
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
		}
	}
}

class DAEEffect extends DAEElement
{
	public var shader:DAEShader;
	public var surface:DAESurface;
	public var sampler:DAESampler2D;
	public var material:*;
	
	public function DAEEffect(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.shader = null;
		this.surface = null;
		this.sampler = null;
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		if (nodeName == "profile_COMMON")
			deserializeProfile(child);
	}
	
	private function deserializeProfile(element:XML):void
	{
		var children:XMLList = element.children();
		
		for (var i:uint = 0; i < children.length(); i++) {
			var child:XML = children[i];
			var name:String = child.name().localName;
			
			switch (name) {
				case "technique":
					deserializeShader(child);
					break;
				case "newparam":
					deserializeNewParam(child);
			}
		}
	}
	
	private function deserializeNewParam(element:XML):void
	{
		var children:XMLList = element.children();
		
		for (var i:uint = 0; i < children.length(); i++) {
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
			}
		}
	}
	
	private function deserializeShader(technique:XML):void
	{
		var children:XMLList = technique.children();
		this.shader = null;
		
		for (var i:uint = 0; i < children.length(); i++) {
			var child:XML = children[i];
			var name:String = child.name().localName;
			
			switch (name) {
				case "constant":
				case "lambert":
				case "blinn":
				case "phong":
					this.shader = new DAEShader(child);
			}
		}
	}
}

class DAEMaterial extends DAEElement
{
	public var instance_effect:DAEInstanceEffect;
	
	public function DAEMaterial(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.instance_effect = null;
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		if (nodeName == "instance_effect")
			this.instance_effect = new DAEInstanceEffect(child);
	}
}

class DAETransform extends DAEElement
{
	public var type:String;
	public var data:Vector.<Number>;
	
	public function DAETransform(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.type = element.name().localName;
		this.data = readFloatArray(element);
	}
	
	public function get matrix():Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();
		
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
		}
		
		return matrix;
	}
}

class DAENode extends DAEElement
{
	public var type:String;
	public var parent:DAENode;
	public var parser:DAEParser;
	public var nodes:Vector.<DAENode>;
	public var transforms:Vector.<DAETransform>;
	public var instance_controllers:Vector.<DAEInstanceController>;
	public var instance_geometries:Vector.<DAEInstanceGeometry>;
	public var world:Matrix3D;
	public var channels:Vector.<DAEChannel>;
	private var _root:XML;
	
	public function DAENode(parser:DAEParser, element:XML = null, parent:DAENode = null)
	{
		this.parser = parser;
		this.parent = parent;
		this.channels = new Vector.<DAEChannel>();
		
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		
		_root = getRootElement(element);
		
		this.type = element.@type.toString().length? element.@type.toString() : "NODE";
		this.nodes = new Vector.<DAENode>();
		this.transforms = new Vector.<DAETransform>();
		this.instance_controllers = new Vector.<DAEInstanceController>();
		this.instance_geometries = new Vector.<DAEInstanceGeometry>();
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		var instances:XMLList;
		var instance:DAEInstance;
		
		switch (nodeName) {
			case "node":
				this.nodes.push(new DAENode(this.parser, child, this));
				break;
			
			case "instance_controller":
				instance = new DAEInstanceController(child);
				this.instance_controllers.push(instance);
				break;
			
			case "instance_geometry":
				this.instance_geometries.push(new DAEInstanceGeometry(child));
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
		}
	}
	
	public function getMatrixBySID(sid:String):Matrix3D
	{
		var transform:DAETransform = getTransformBySID(sid);
		if (transform)
			return transform.matrix;
		
		return null;
	}
	
	public function getTransformBySID(sid:String):DAETransform
	{
		for each (var transform:DAETransform in this.transforms) {
			if (transform.sid == sid)
				return transform;
		}
		
		return null;
	}
	
	public function getAnimatedMatrix(time:Number):Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();
		var tdata:Vector.<Number>;
		var odata:Vector.<Number>;
		var channelsBySID:Object = {};
		var transform:DAETransform;
		var channel:DAEChannel;
		var minTime:Number = Number.MAX_VALUE;
		var maxTime:Number = -minTime;
		var i:uint;
		//var j : uint;
		//var frame : int;
		
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
				var m:Matrix3D = new Matrix3D();
				//var found : Boolean = false;
				var frameData:DAEFrameData = null;
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
								
							} else if (channel.dotAccess)
								trace("unhandled matrix array access");
							
							else if (odata.length == 16) {
								m.rawData = odata;
								m.transpose();
								
							} else
								trace("unhandled matrix " + transform.sid + " " + odata);
							break;
						
						case "rotate":
							if (channel.arrayAccess)
								trace("unhandled rotate array access");
							
							else if (channel.dotAccess) {
								
								switch (channel.dotAccessor) {
									case "ANGLE":
										m.appendRotation(odata[0], new Vector3D(tdata[0], tdata[1], tdata[2]));
										break;
									default:
										trace("unhandled rotate dot access " + channel.dotAccessor);
								}
								
							} else
								trace("unhandled rotate");
							break;
						
						case "scale":
							if (channel.arrayAccess)
								trace("unhandled scale array access");
							
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
										trace("unhandled scale dot access " + channel.dotAccessor);
								}
								
							} else
								trace("unhandled scale: " + odata.length);
							break;
						
						case "translate":
							if (channel.arrayAccess)
								trace("unhandled translate array access");
							
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
										trace("unhandled translate dot access " + channel.dotAccessor);
								}
								
							} else
								m.appendTranslation(odata[0], odata[1], odata[2]);
							break;
						
						default:
							trace("unhandled transform type " + transform.type);
							continue;
					}
					matrix.prepend(m);
					
				} else
					matrix.prepend(transform.matrix);
				
			} else
				matrix.prepend(transform.matrix);
		}
		
		if (DAEElement.USE_LEFT_HANDED)
			convertMatrix(matrix);
		
		return matrix;
	}
	
	public function get matrix():Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();
		for (var i:uint = 0; i < this.transforms.length; i++)
			matrix.prepend(this.transforms[i].matrix);
		
		if (DAEElement.USE_LEFT_HANDED)
			convertMatrix(matrix);
		
		return matrix;
	}
}

class DAEVisualScene extends DAENode
{
	public function DAEVisualScene(parser:DAEParser, element:XML = null)
	{
		super(parser, element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
	}
	
	public function findNodeById(id:String, node:DAENode = null):DAENode
	{
		node = node || this;
		if (node.id == id)
			return node;
		
		for (var i:uint = 0; i < node.nodes.length; i++) {
			var result:DAENode = findNodeById(id, node.nodes[i]);
			if (result)
				return result;
		}
		
		return null;
	}
	
	public function findNodeBySid(sid:String, node:DAENode = null):DAENode
	{
		node = node || this;
		if (node.sid == sid)
			return node;
		
		for (var i:uint = 0; i < node.nodes.length; i++) {
			var result:DAENode = findNodeBySid(sid, node.nodes[i]);
			if (result)
				return result;
		}
		
		return null;
	}
	
	public function updateTransforms(node:DAENode, parent:DAENode = null):void
	{
		node.world = node.matrix.clone();
		if (parent && parent.world)
			node.world.append(parent.world);
		
		for (var i:uint = 0; i < node.nodes.length; i++)
			updateTransforms(node.nodes[i], node);
	}
}

class DAEScene extends DAEElement
{
	public var instance_visual_scene:DAEInstanceVisualScene;
	
	public function DAEScene(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.instance_visual_scene = null;
		traverseChildren(element);
	}
	
	protected override function traverseChildHandler(child:XML, nodeName:String):void
	{
		if (nodeName == "instance_visual_scene")
			this.instance_visual_scene = new DAEInstanceVisualScene(child);
	}
}

class DAEMorph extends DAEEffect
{
	public var source:String;
	public var method:String;
	public var targets:Vector.<String>;
	public var weights:Vector.<Number>;
	
	public function DAEMorph(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.source = element.@source.toString().replace(/^#/, "");
		this.method = element.@method.toString();
		this.method = this.method.length? this.method : "NORMALIZED";
		this.targets = new Vector.<String>();
		this.weights = new Vector.<Number>();
		
		var sources:Object = {};
		var source:DAESource;
		var input:DAEInput;
		var list:XMLList = element.ns::source;
		
		if (element.ns::targets && element.ns::targets.length() > 0) {
			for (var i:uint = 0; i < list.length(); i++) {
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
	
	public function DAEVertexWeight()
	{
	}
}

class DAESkin extends DAEElement
{
	public var source:String;
	public var bind_shape_matrix:Matrix3D;
	public var joints:Vector.<String>;
	public var inv_bind_matrix:Vector.<Matrix3D>;
	public var weights:Vector.<Vector.<DAEVertexWeight>>;
	public var jointSourceType:String;
	public var maxBones:uint;
	
	public function DAESkin(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		
		this.source = element.@source.toString().replace(/^#/, "");
		this.bind_shape_matrix = new Matrix3D();
		this.inv_bind_matrix = new Vector.<Matrix3D>();
		this.joints = new Vector.<String>();
		this.weights = new Vector.<Vector.<DAEVertexWeight>>();
		
		var children:XMLList = element.children();
		var i:uint;
		var sources:Object = {};
		
		for (i = 0; i < element.ns::source.length(); i++) {
			var source:DAESource = new DAESource(element.ns::source[i]);
			sources[source.id] = source;
		}
		
		for (i = 0; i < children.length(); i++) {
			var child:XML = children[i];
			var name:String = child.name().localName;
			
			switch (name) {
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
	
	public function getJointIndex(joint:String):int
	{
		for (var i:uint = 0; i < this.joints.length; i++) {
			if (this.joints[i] == joint)
				return i;
		}
		return -1;
	}
	
	private function parseBindShapeMatrix(element:XML):void
	{
		var values:Vector.<Number> = readFloatArray(element);
		this.bind_shape_matrix = new Matrix3D(values);
		this.bind_shape_matrix.transpose();
		if (DAEElement.USE_LEFT_HANDED)
			convertMatrix(this.bind_shape_matrix);
	}
	
	private function parseJoints(element:XML, sources:Object):void
	{
		var list:XMLList = element.ns::input;
		var input:DAEInput;
		var source:DAESource;
		var i:uint, j:uint;
		
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
						var matrix:Matrix3D = new Matrix3D(source.floats.slice(j, j + source.accessor.stride));
						matrix.transpose();
						if (DAEElement.USE_LEFT_HANDED)
							convertMatrix(matrix);
						inv_bind_matrix.push(matrix);
					}
			}
		}
	}
	
	private function parseVertexWeights(element:XML, sources:Object):void
	{
		var list:XMLList = element.ns::input;
		var input:DAEInput;
		var inputs:Vector.<DAEInput> = new Vector.<DAEInput>();
		var source:DAESource;
		var i:uint, j:uint, k:uint;
		
		if (!element.ns::vcount.length() || !element.ns::v.length())
			throw new Error("Can't parse vertex weights");
		
		var vcount:Vector.<int> = readIntArray(element.ns::vcount[0]);
		var v:Vector.<int> = readIntArray(element.ns::v[0]);
		var numWeights:uint = parseInt(element.@count.toString(), 10);
		numWeights = numWeights;
		var index:uint = 0;
		this.maxBones = 0;
		
		for (i = 0; i < list.length(); i++)
			inputs.push(new DAEInput(list[i]));
		
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
	public var skin:DAESkin;
	public var morph:DAEMorph;
	
	public function DAEController(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.skin = null;
		this.morph = null;
		
		if (element.ns::skin && element.ns::skin.length())
			this.skin = new DAESkin(element.ns::skin[0]);
		else if (element.ns::morph && element.ns::morph.length())
			this.morph = new DAEMorph(element.ns::morph[0]);
		else
			throw new Error("DAEController: could not find a <skin> or <morph> element");
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
	
	public function DAESampler(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		var list:XMLList = element.ns::input;
		var i:uint;
		_inputs = new Vector.<DAEInput>();
		
		for (i = 0; i < list.length(); i++)
			_inputs.push(new DAEInput(list[i]));
	}
	
	public function create(sources:Object):void
	{
		var input:DAEInput;
		var source:DAESource;
		var i:uint, j:uint;
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
					this.maxTime = this.input[this.input.length - 1];
					break;
				case "OUTPUT":
					for (j = 0; j < source.floats.length; j += source.accessor.stride)
						this.output.push(source.floats.slice(j, j + source.accessor.stride));
					this.dataType = source.accessor.params[0].type;
					break;
				case "INTEROLATION":
					this.interpolation = source.strings;
			}
		}
	}
	
	public function getFrameData(time:Number):DAEFrameData
	{
		var frameData:DAEFrameData = new DAEFrameData(0, time);
		
		if (!this.input || this.input.length == 0)
			return null;
		
		var a:Number, b:Number;
		var i:uint;
		frameData.valid = true;
		frameData.time = time;
		
		if (time <= this.input[0]) {
			frameData.frame = 0;
			frameData.dt = 0;
			frameData.data = this.output[0];
			
		} else if (time >= this.input[this.input.length - 1]) {
			frameData.frame = this.input.length - 1;
			frameData.dt = 0;
			frameData.data = this.output[frameData.frame];
			
		} else {
			
			for (i = 0; i < this.input.length - 1; i++) {
				if (time >= this.input[i] && time < this.input[i + 1]) {
					frameData.frame = i;
					frameData.dt = (time - this.input[i])/(this.input[i + 1] - this.input[i]);
					frameData.data = this.output[i];
					break;
				}
			}
			
			for (i = 0; i < frameData.data.length; i++) {
				a = this.output[frameData.frame][i];
				b = this.output[frameData.frame + 1][i];
				frameData.data[i] += frameData.dt*(b - a);
			}
		}
		
		return frameData;
	}
}

class DAEFrameData
{
	public var frame:uint;
	public var time:Number;
	public var data:Vector.<Number>;
	public var dt:Number;
	public var valid:Boolean;
	
	public function DAEFrameData(frame:uint = 0, time:Number = 0.0, dt:Number = 0.0, valid:Boolean = false)
	{
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
	
	public function DAEChannel(element:XML = null)
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
			for (var i:uint = 0; i < parts.length; i++)
				this.arrayIndices.push(parseInt(parts[i].replace(")", ""), 10));
			
		} else if (tmp.indexOf(".") >= 0) {
			parts = tmp.split(".");
			this.dotAccess = true;
			this.targetSid = parts[0];
			this.dotAccessor = parts[1];
			
		} else
			this.targetSid = tmp;
	}
}

class DAEAnimation extends DAEElement
{
	public var samplers:Vector.<DAESampler>;
	public var channels:Vector.<DAEChannel>;
	public var sources:Object;
	
	public function DAEAnimation(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):void
	{
		super.deserialize(element);
		this.samplers = new Vector.<DAESampler>();
		this.channels = new Vector.<DAEChannel>();
		this.sources = {};
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
		}
	}
	
	private function setupChannels(sources:Object):void
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
	public var color:DAEColor;
	
	public function DAELightType(element:XML = null)
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
			color.a = f.length > 3? f[3] : 1.0;
		}
	}
}

class DAEParserState
{
	public static const LOAD_XML:uint = 0;
	public static const PARSE_IMAGES:uint = 1;
	public static const PARSE_MATERIALS:uint = 2;
	public static const PARSE_GEOMETRIES:uint = 3;
	public static const PARSE_CONTROLLERS:uint = 4;
	public static const PARSE_VISUAL_SCENE:uint = 5;
	public static const PARSE_ANIMATIONS:uint = 6;
	public static const PARSE_COMPLETE:uint = 7;
}

package away3d.animators
{
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.data.ParticleAnimationData;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.nodes.AnimationNodeBase;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleTimeNode;
	import away3d.arcane;
	import away3d.core.base.ISubMesh;
	import away3d.core.base.ParticleGeometry;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.data.ParticleData;
	import away3d.managers.Stage3DProxy;
	import away3d.entities.Mesh;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.passes.MaterialPassBase;

	import flash.display3D.Context3D;

	import flash.utils.Dictionary;

	use namespace arcane;
	
	/**
	 * The animation data set used by particle-based animators, containing particle animation data.
	 *
	 * @see away3d.animators.ParticleAnimator
	 */
	public class ParticleAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		/** @private */
		arcane var _animationRegisterCache:AnimationRegisterCache;
		
		//all other nodes dependent on it
		private var _timeNode:ParticleTimeNode;
		
		/**
		 * Property used by particle nodes that require compilation at the end of the shader
		 */
		public static const POST_PRIORITY:int = 9;
		
		/**
		 * Property used by particle nodes that require color compilation
		 */
		public static const COLOR_PRIORITY:int = 18;
		
		private var _animationSubGeometries:Dictionary = new Dictionary(true);
		private var _particleNodes:Vector.<ParticleNodeBase> = new Vector.<ParticleNodeBase>();
		private var _localDynamicNodes:Vector.<ParticleNodeBase> = new Vector.<ParticleNodeBase>();
		private var _localStaticNodes:Vector.<ParticleNodeBase> = new Vector.<ParticleNodeBase>();
		private var _totalLenOfOneVertex:int = 0;
		
		//set true if has an node which will change UV
		public var hasUVNode:Boolean;
		//set if the other nodes need to access the velocity
		public var needVelocity:Boolean;
		//set if has a billboard node.
		public var hasBillboard:Boolean;
		//set if has an node which will apply color multiple operation
		public var hasColorMulNode:Boolean;
		//set if has an node which will apply color add operation
		public var hasColorAddNode:Boolean;
		
		/**
		 * Initialiser function for static particle properties. Needs to reference a function with teh following format
		 *
		 * <code>
		 * function initParticleFunc(prop:ParticleProperties):void
		 * {
		 * 		//code for settings local properties
		 * }
		 * </code>
		 *
		 * Aside from setting any properties required in particle animation nodes using local static properties, the initParticleFunc function
		 * is required to time node requirements as they may be needed. These properties on the ParticleProperties object can include
		 * <code>startTime</code>, <code>duration</code> and <code>delay</code>. The use of these properties is determined by the setting
		 * arguments passed in the constructor of the particle animation set. By default, only the <code>startTime</code> property is required.
		 */
		public var initParticleFunc:Function;
		
		/**
		 * Creates a new <code>ParticleAnimationSet</code>
		 *
		 * @param    [optional] usesDuration    Defines whether the animation set uses the <code>duration</code> data in its static properties function to determine how long a particle is visible for. Defaults to false.
		 * @param    [optional] usesLooping     Defines whether the animation set uses a looping timeframe for each particle determined by the <code>startTime</code>, <code>duration</code> and <code>delay</code> data in its static properties function. Defaults to false. Requires <code>usesDuration</code> to be true.
		 * @param    [optional] usesDelay       Defines whether the animation set uses the <code>delay</code> data in its static properties function to determine how long a particle is hidden for. Defaults to false. Requires <code>usesLooping</code> to be true.
		 */
		public function ParticleAnimationSet(usesDuration:Boolean = false, usesLooping:Boolean = false, usesDelay:Boolean = false)
		{
			//automatically add a particle time node to the set
			addAnimation(_timeNode = new ParticleTimeNode(usesDuration, usesLooping, usesDelay));
		}
		
		/**
		 * Returns a vector of the particle animation nodes contained within the set.
		 */
		public function get particleNodes():Vector.<ParticleNodeBase>
		{
			return _particleNodes;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function addAnimation(node:AnimationNodeBase):void
		{
			var i:int;
			var n:ParticleNodeBase = node as ParticleNodeBase;
			n.processAnimationSetting(this);
			if (n.mode == ParticlePropertiesMode.LOCAL_STATIC) {
				n.dataOffset = _totalLenOfOneVertex;
				_totalLenOfOneVertex += n.dataLength;
				_localStaticNodes.push(n);
			} else if (n.mode == ParticlePropertiesMode.LOCAL_DYNAMIC)
				_localDynamicNodes.push(n);
			
			for (i = _particleNodes.length - 1; i >= 0; i--) {
				if (_particleNodes[i].priority <= n.priority)
					break;
			}
			
			_particleNodes.splice(i + 1, 0, n);
			
			super.addAnimation(node);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function activate(shaderObject:ShaderObjectBase, stage3DProxy:Stage3DProxy):void
		{
//			_animationRegisterCache = pass.animationRegisterCache;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function deactivate(shaderObject:ShaderObjectBase, stage3DProxy:Stage3DProxy):void
		{
//			if (_animationRegisterCache)
//			{
//				var context:Context3D = stage3DProxy.context3D;
//				var offset:int = _animationRegisterCache.vertexAttributesOffset;
//				var used:int = _animationRegisterCache.numUsedStreams;
//				for (var i:int = offset; i < used; i++)
//					context.setVertexBufferAt(i, null);
//			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(shaderObject:ShaderObjectBase):String
		{
			//grab animationRegisterCache from the materialpassbase or create a new one if the first time
			_animationRegisterCache = shaderObject.animationRegisterCache;
			
			//reset animationRegisterCache
			_animationRegisterCache.vertexConstantOffset = shaderObject.numUsedVertexConstants;
			_animationRegisterCache.vertexAttributesOffset = shaderObject.numUsedStreams;
			_animationRegisterCache.varyingsOffset = shaderObject.numUsedVaryings;
			_animationRegisterCache.fragmentConstantOffset = shaderObject.numUsedFragmentConstants;
			_animationRegisterCache.hasUVNode = hasUVNode;
			_animationRegisterCache.needVelocity = needVelocity;
			_animationRegisterCache.hasBillboard = hasBillboard;
			_animationRegisterCache.sourceRegisters = shaderObject.animatableAttributes;
			_animationRegisterCache.targetRegisters = shaderObject.animationTargetRegisters;
			_animationRegisterCache.needFragmentAnimation = shaderObject.usesFragmentAnimation;
			_animationRegisterCache.needUVAnimation = !shaderObject.usesUVTransform;
			_animationRegisterCache.hasColorAddNode = hasColorAddNode;
			_animationRegisterCache.hasColorMulNode = hasColorMulNode;
			_animationRegisterCache.reset();
			
			var code:String = "";
			
			code += _animationRegisterCache.getInitCode();
			
			var node:ParticleNodeBase;
			for each (node in _particleNodes) {
				if (node.priority < POST_PRIORITY)
					code += node.getAGALVertexCode(shaderObject, _animationRegisterCache);
			}
			
			code += _animationRegisterCache.getCombinationCode();
			
			for each (node in _particleNodes) {
				if (node.priority >= POST_PRIORITY && node.priority < COLOR_PRIORITY)
					code += node.getAGALVertexCode(shaderObject, _animationRegisterCache);
			}
			
			code += _animationRegisterCache.initColorRegisters();
			for each (node in _particleNodes) {
				if (node.priority >= COLOR_PRIORITY)
					code += node.getAGALVertexCode(shaderObject, _animationRegisterCache);
			}
			code += _animationRegisterCache.getColorPassCode();
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALUVCode(shaderObject:ShaderObjectBase):String
		{
			var code:String = "";
			if (hasUVNode) {
				_animationRegisterCache.setUVSourceAndTarget(shaderObject.uvSource, shaderObject.uvTarget);
				code += "mov " + _animationRegisterCache.uvTarget + ".xy," + _animationRegisterCache.uvAttribute.toString() + "\n";
				var node:ParticleNodeBase;
				for each (node in _particleNodes)
					code += node.getAGALUVCode(shaderObject, _animationRegisterCache);
				code += "mov " + _animationRegisterCache.uvVar.toString() + "," + _animationRegisterCache.uvTarget + ".xy\n";
			} else
				code += "mov " + shaderObject.uvTarget + "," + shaderObject.uvSource + "\n";
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALFragmentCode(shaderObject:ShaderObjectBase, shadedTarget:String):String
		{
			return _animationRegisterCache.getColorCombinationCode(shadedTarget);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function doneAGALCode(shaderObject:ShaderObjectBase):void
		{
			_animationRegisterCache.setDataLength();
			
			//set vertexZeroConst,vertexOneConst,vertexTwoConst
			_animationRegisterCache.setVertexConst(_animationRegisterCache.vertexZeroConst.index, 0, 1, 2, 0);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get usesCPU():Boolean
		{
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function cancelGPUCompatibility():void
		{
		
		}
		
		override public function dispose():void
		{
			var subGeometry:AnimationSubGeometry;
			
			for each (subGeometry in _animationSubGeometries)
				subGeometry.dispose();
			
			super.dispose();
		}

		public function getAnimationSubGeometry(subMesh:ISubMesh):AnimationSubGeometry
		{
			var mesh:Mesh = subMesh.parentMesh;
			var animationSubGeometry:AnimationSubGeometry = (mesh.shareAnimationGeometry)? _animationSubGeometries[subMesh.subGeometry.id] : _animationSubGeometries[subMesh.id];

			if (animationSubGeometry)
				return animationSubGeometry;

			generateAnimationSubGeometries(mesh);

			return (mesh.shareAnimationGeometry)? _animationSubGeometries[subMesh.subGeometry.id] : _animationSubGeometries[subMesh.id];
		}
		
		/** @private */
		arcane function generateAnimationSubGeometries(mesh:Mesh):void
		{
			if (initParticleFunc == null)
				throw(new Error("no initParticleFunc set"));
			
			var geometry:ParticleGeometry = mesh.geometry as ParticleGeometry;
			
			if (!geometry)
				throw(new Error("Particle animation can only be performed on a ParticleGeometry object"));
			
			var i:int, j:int;
			var animationSubGeometry:AnimationSubGeometry;
			var newAnimationSubGeometry:Boolean;
			var subGeometry:SubGeometryBase;
			var subMesh:ISubMesh;
			var localNode:ParticleNodeBase;
			
			for (i = 0; i < mesh.subMeshes.length; i++) {
				subMesh = mesh.subMeshes[i];
				subGeometry = subMesh.subGeometry;
				if (mesh.shareAnimationGeometry) {
					animationSubGeometry = _animationSubGeometries[subGeometry.id];
					
					if (animationSubGeometry) {
						continue;
					}
				}
				
				animationSubGeometry = new AnimationSubGeometry();
				if (mesh.shareAnimationGeometry) {
					_animationSubGeometries[subGeometry.id] = animationSubGeometry;
				}else{
					_animationSubGeometries[subMesh.id] = animationSubGeometry;
				}

				
				newAnimationSubGeometry = true;
				
				//create the vertexData vector that will be used for local node data
				animationSubGeometry.createVertexData(subGeometry.numVertices, _totalLenOfOneVertex);
			}
			
			if (!newAnimationSubGeometry)
				return;
			
			var particles:Vector.<ParticleData> = geometry.particles;
			var particlesLength:uint = particles.length;
			var numParticles:uint = geometry.numParticles;
			var particleProperties:ParticleProperties = new ParticleProperties();
			var particle:ParticleData;
			
			var oneDataLen:int;
			var oneDataOffset:int;
			var counterForVertex:int;
			var counterForOneData:int;
			var oneData:Vector.<Number>;
			var numVertices:uint;
			var vertexData:Vector.<Number>;
			var vertexLength:uint;
			var startingOffset:uint;
			var vertexOffset:uint;
			
			//default values for particle param
			particleProperties.total = numParticles;
			particleProperties.startTime = 0;
			particleProperties.duration = 1000;
			particleProperties.delay = 0.1;
			
			i = 0;
			j = 0;
			while (i < numParticles) {
				particleProperties.index = i;
				
				//call the init function on the particle parameters
				initParticleFunc(particleProperties);
				
				//create the next set of node properties for the particle
				for each (localNode in _localStaticNodes)
					localNode.generatePropertyOfOneParticle(particleProperties);
				
				//loop through all particle data for the curent particle
				while (j < particlesLength && (particle = particles[j]).particleIndex == i) {
					//find the target animationSubGeometry
					for each (subMesh in mesh.subMeshes) {
						if (subMesh.subGeometry == particle.subGeometry) {
							animationSubGeometry = (mesh.shareAnimationGeometry)? _animationSubGeometries[subMesh.subGeometry.id] : _animationSubGeometries[subMesh.id];
							break;
						}
					}
					numVertices = particle.numVertices;
					vertexData = animationSubGeometry.vertexData;
					vertexLength = numVertices*_totalLenOfOneVertex;
					startingOffset = animationSubGeometry.numProcessedVertices*_totalLenOfOneVertex;
					
					//loop through each static local node in the animation set
					for each (localNode in _localStaticNodes) {
						oneData = localNode.oneData;
						oneDataLen = localNode.dataLength;
						oneDataOffset = startingOffset + localNode.dataOffset;
						
						//loop through each vertex set in the vertex data
						for (counterForVertex = 0; counterForVertex < vertexLength; counterForVertex += _totalLenOfOneVertex) {
							vertexOffset = oneDataOffset + counterForVertex;
							
							//add the data for the local node to the vertex data
							for (counterForOneData = 0; counterForOneData < oneDataLen; counterForOneData++)
								vertexData[vertexOffset + counterForOneData] = oneData[counterForOneData];
						}
						
					}
					
					//store particle properties if they need to be retreived for dynamic local nodes
					if (_localDynamicNodes.length)
						animationSubGeometry.animationParticles.push(new ParticleAnimationData(i, particleProperties.startTime, particleProperties.duration, particleProperties.delay, particle));
					
					animationSubGeometry.numProcessedVertices += numVertices;
					
					//next index
					j++;
				}
				
				//next particle
				i++;
			}
		}
	}
}

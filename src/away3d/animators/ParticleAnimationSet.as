package away3d.animators
{
	import away3d.core.base.SubMesh;
	import away3d.core.base.ParticleGeometry;
	import away3d.animators.nodes.AnimationNodeBase;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleTimeNode;
	import away3d.arcane;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.data.ParticleData;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.Mesh;
	import away3d.materials.passes.MaterialPassBase;
	import flash.display3D.Context3D;
	import flash.utils.Dictionary;
	
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		public static const POST_PRIORITY:int = 9;
		
		private var _animationRegisterCache:AnimationRegisterCache;
		
		private var _animationSubGeometries:Dictionary = new Dictionary(true);
		
		private var _particleNodes:Vector.<ParticleNodeBase> = new Vector.<ParticleNodeBase>();
		
		private var _localNodes:Vector.<ParticleNodeBase> = new Vector.<ParticleNodeBase>();
		
		private var _totalLenOfOneVertex:int = 0;
		
		//set true if has an node which will change UV
		public var hasUVNode:Boolean;
		//set true if has an node which will change color
		public var hasColorNode:Boolean;
		//set if the other nodes need to access the velocity
		public var needVelocity:Boolean;
		
		//all other nodes dependent on it
		private var timeNode:ParticleTimeNode;
		private var _initParticleFunc:Function;
		
		
		public function ParticleAnimationSet()
		{
			super();
			timeNode = new ParticleTimeNode(ParticleTimeNode.LOCAL);
			addAnimation(timeNode);
		}
		
		public function get particleNodes():Vector.<ParticleNodeBase>
		{
			return _particleNodes;
		}
		
		public function get animationRegisterCache():AnimationRegisterCache
		{
			return _animationRegisterCache;
		}
		
		public function set hasDuration(value:Boolean):void
		{
			timeNode.hasDuration = value;
		}
		
		public function set hasDelay(value:Boolean):void
		{
			timeNode.hasDelay = value;
		}
		
		
		public function set loop(value:Boolean):void
		{
			timeNode.loop = value;
		}
		
		override public function addAnimation(node:AnimationNodeBase):void
		{
			var i:int;
			var n:ParticleNodeBase = node as ParticleNodeBase;
			n.processAnimationSetting(this);
			if (n.mode == ParticleNodeBase.LOCAL) {
				n.dataOffset = _totalLenOfOneVertex;
				_totalLenOfOneVertex += n.dataLength;
				_localNodes.push(n);
			}
			
			for (i = _particleNodes.length - 1; i >= 0; i--)
				if (_particleNodes[i].priority <= n.priority)
					break;
			
			_particleNodes.splice(i + 1, 0, n);
			
			super.addAnimation(node);
		}
		
		
		public function activate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			_animationRegisterCache = pass.animationRegisterCache;
		}
		public function deactivate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			var context : Context3D = stage3DProxy.context3D;
			var offset:int = _animationRegisterCache.vertexAttributesOffset;
			var used:int = _animationRegisterCache.numUsedStreams;
			for (var i:int = offset; i < used; i++)
				context.setVertexBufferAt(i, null);
		}
		
		public function getAGALVertexCode(pass : MaterialPassBase, sourceRegisters : Vector.<String>, targetRegisters : Vector.<String>) : String
		{
			//grab animationRegisterCache from the materialpassbase or create a new one if the first time
			_animationRegisterCache = pass.animationRegisterCache ||= new AnimationRegisterCache();
			
			//reset animationRegisterCache
			_animationRegisterCache.vertexConstantOffset = pass.numUsedVertexConstants;
			_animationRegisterCache.vertexAttributesOffset = pass.numUsedStreams;
			_animationRegisterCache.varyingsOffset = pass.numUsedVaryings;
			_animationRegisterCache.fragmentConstantOffset = pass.numUsedFragmentConstants;
			_animationRegisterCache.hasUVNode = hasUVNode;
			_animationRegisterCache.hasColorNode = hasColorNode;
			_animationRegisterCache.needVelocity = needVelocity;
			_animationRegisterCache.sourceRegisters = sourceRegisters;
			_animationRegisterCache.targetRegisters = targetRegisters;
			_animationRegisterCache.needFragmentAnimation = pass.needFragmentAnimation;
			_animationRegisterCache.needUVAnimation = pass.needUVAnimation;
			_animationRegisterCache.reset();
			
			var code:String = "";
			
			code += _animationRegisterCache.getInitCode();
			
			
			var node:ParticleNodeBase;
			for each(node in _particleNodes)
				if (node.priority < POST_PRIORITY)
					code += node.getAGALVertexCode(pass, _animationRegisterCache);
			
			code += _animationRegisterCache.getCombinationCode();
			
			for each(node in _particleNodes)
				if (node.priority >= POST_PRIORITY)
					code += node.getAGALVertexCode(pass, _animationRegisterCache);
			
			return code;
		}
		
		override public function getAGALUVCode(pass : MaterialPassBase, UVSource : String, UVTarget:String) : String
		{
			var code:String = "";
			if (hasUVNode)
			{
				_animationRegisterCache.setUVSourceAndTarget(UVSource, UVTarget);
				code += "mov " + _animationRegisterCache.uvTarget.toString() + "," + _animationRegisterCache.uvAttribute.toString() + "\n";
				var node:ParticleNodeBase;
				for each(node in _particleNodes)
				{
					code += node.getAGALUVCode(pass, _animationRegisterCache);
				}
				code += "mov " + _animationRegisterCache.uvVar.toString() + "," + _animationRegisterCache.uvTarget.toString() + "\n";
			}
			else
			{
				code += "mov " + UVTarget + "," + UVSource + "\n";
			}
			return code;
		}
		
		override public function getAGALFragmentCode(pass : MaterialPassBase, shadedTarget : String) : String
		{
			_animationRegisterCache.setShadedTarget(shadedTarget);
			var code:String = "";
			var node:ParticleNodeBase;
			for each(node in _particleNodes)
			{
				code += node.getAGALFragmentCode(pass, _animationRegisterCache);
			}
			return code;
		}
		
		override public function doneAGALCode(pass : MaterialPassBase):void
		{
			_animationRegisterCache.setDataLength();
			
			//set vertexZeroConst,vertexOneConst,vertexTwoConst
			_animationRegisterCache.setVertexConst(_animationRegisterCache.vertexZeroConst.index, 0, 1, 2, 0);
			if (_animationRegisterCache.numFragmentConstant > 0)
			{
				//set fragmentZeroConst,fragmentOneConst
				_animationRegisterCache.setFragmentConst(_animationRegisterCache.fragmentZeroConst.index, 0, 1, 1 / 255, 0);
			}
		}
		
		
		override public function get usesCPU() : Boolean
		{
			return false;
		}
		
		public function get initParticleFunc():Function
		{
			return _initParticleFunc;
		}
		
		public function set initParticleFunc(value:Function):void
		{
			_initParticleFunc = value;
		}
		
		override public function cancelGPUCompatibility() : void
        {
			
        }
		
		
		
		public function generateAnimationSubGeometries(mesh:Mesh):void
		{
			if (_initParticleFunc == null)
				throw(new Error("no initParticleFunc"));			
			
			var geometry:ParticleGeometry =  mesh.geometry as ParticleGeometry;
			
			if (!geometry)
				throw(new Error("It must be ParticleGeometry"));
			
			var i:int, j:int;
			var animationSubGeometry:AnimationSubGeometry;
			var newAnimationSubGeometry:Boolean;
			var subGeometry:ISubGeometry;
			var subMesh:SubMesh;
			var localNode:ParticleNodeBase;
			
			for (i = 0; i < mesh.subMeshes.length; i++)
			{
				subMesh = mesh.subMeshes[i];
				subGeometry = subMesh.subGeometry;
				if ((animationSubGeometry = _animationSubGeometries[subGeometry])) {
					subMesh.animationSubGeometry = animationSubGeometry;
					continue;
				}
				
				animationSubGeometry = subMesh.animationSubGeometry = _animationSubGeometries[subGeometry] = new AnimationSubGeometry();
				
				newAnimationSubGeometry = true;
				
				//create the vertexData vector that will be used for local node data
				animationSubGeometry.createVertexData(subGeometry.numVertices, _totalLenOfOneVertex);
			}
			
			if (!newAnimationSubGeometry)
				return;
			
			var particles:Vector.<ParticleData> = geometry.particles;
			var particlesLength:uint = particles.length;
			var numParticles:uint = geometry.numParticles;
			var param:ParticleParameter = new ParticleParameter();
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
			param.total = numParticles;
			param.startTime = 0;
			param.particleDuration = 1000;
			param.delay = 0.1;
			
			i = 0;
			j = 0;
			while (i < numParticles)
			{
				param.index = i;
				
				//call the init function on the particle parameters
				_initParticleFunc(param);
				
				//create the next set of node properties for the particle
				for each (localNode in _localNodes)
					localNode.generatePropertyOfOneParticle(param);
				
				//loop through all particle data for the curent particle
				while (j < particlesLength && (particle = particles[j]).particleIndex == i) {
					animationSubGeometry = _animationSubGeometries[particle.subGeometry];
					numVertices = particle.numVertices;
					vertexData = animationSubGeometry.vertexData;
					vertexLength = numVertices * _totalLenOfOneVertex;
					startingOffset = animationSubGeometry.numProcessedVertices * _totalLenOfOneVertex;
					
					//loop through each local node in the animation set
					for each (localNode in _localNodes) {
						oneData = localNode.oneData;
						oneDataLen = localNode.dataLength;
						oneDataOffset = startingOffset + localNode.dataOffset;
						
						//loop through each vertex set in the vertex data
						for (counterForVertex = 0; counterForVertex < vertexLength; counterForVertex+=_totalLenOfOneVertex) {
							vertexOffset = oneDataOffset + counterForVertex;
							
							//add the data for the local node to the vertex data
							for (counterForOneData = 0; counterForOneData < oneDataLen; counterForOneData++)
								vertexData[vertexOffset + counterForOneData] = oneData[counterForOneData];
						}
						
						localNode.processExtraData(param, animationSubGeometry, numVertices);
					}
					
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
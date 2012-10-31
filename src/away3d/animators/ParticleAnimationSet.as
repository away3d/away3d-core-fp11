package away3d.animators
{
	import away3d.animators.nodes.AnimationNodeBase;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.nodes.LocalParticleNodeBase;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleTimeNode;
	import away3d.arcane;
	import away3d.core.base.IParticleSubGeometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.data.ParticleData;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.Mesh;
	import away3d.materials.compilation.ShaderRegisterCache;
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
		
		
		private var compilers:Dictionary = new Dictionary(true);
		
		private var _animationRegisterCache:AnimationRegisterCache;
		
		private var _particleNodes:Vector.<ParticleNodeBase> = new Vector.<ParticleNodeBase>();
		
		private var _localNodes:Vector.<LocalParticleNodeBase> = new Vector.<LocalParticleNodeBase>();
		
		private var _streamDatas:Dictionary = new Dictionary(true);
		
		//set true if has an node which will change UV
		public var hasUVNode:Boolean;
		//set true if has an node which will change color
		public var hasColorNode:Boolean;
		//set if the other nodes need to access the velocity
		public var needVelocity:Boolean;
		
		//all other nodes dependent on it
		private var timeNode:ParticleTimeNode;
		public var _initParticleFun:Function;
		
		
		public function ParticleAnimationSet()
		{
			super();
			timeNode = new ParticleTimeNode();
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
		
		public function get streamDatas():Dictionary
		{
			return _streamDatas;
		}
		
		public function set hasDuringTime(value:Boolean):void
		{
			timeNode.hasDuringTime = value;
		}
		
		public function set hasSleepTime(value:Boolean):void
		{
			timeNode.hasSleepTime = value;
		}
		
		
		public function set loop(value:Boolean):void
		{
			timeNode.loop = value;
		}
		
		public function set initParticleFun(value:Function):void
		{
			_initParticleFun = value;
		}
		
		override public function addAnimation(node:AnimationNodeBase):void
		{
			var i:int;
			var n:ParticleNodeBase = node as ParticleNodeBase;
			n.processAnimationSetting(this);
			if (n.nodeType==ParticleNodeBase.LOCAL)
				_localNodes.push(n);
			
			for (i = _particleNodes.length - 1; i >= 0; i--)
			{
				if (_particleNodes[i].priority <= n.priority)
				{
					break;
				}
			}
			_particleNodes.splice(i + 1, 0, n);
			
			super.addAnimation(node);
		}
		
		
		public function activate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			_animationRegisterCache = compilers[pass];
		}
		public function deactivate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			var context : Context3D = stage3DProxy.context3D;
			var offset:int = _animationRegisterCache.vertexAttributesOffset;
			var used:int = _animationRegisterCache.numUsedStreams;
			for (var i:int = offset; i < used; i++)
				context.setVertexBufferAt(i, null);
		}
		
		
		private function reset(pass:MaterialPassBase, sourceRegisters : Array, targetRegisters : Array):void
		{
			_animationRegisterCache = compilers[pass] ||= new AnimationRegisterCache();
			
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
		}

		
		public function getAGALVertexCode(pass : MaterialPassBase, sourceRegisters : Array, targetRegisters : Array) : String
		{
			reset(pass, sourceRegisters, targetRegisters);
			
			var code:String = "";
			
			code += _animationRegisterCache.getInitCode();
			
			
			var node:ParticleNodeBase;
			for each(node in _particleNodes)
			{
				if (node.priority < POST_PRIORITY)
				{
					code += node.getAGALVertexCode(pass, _animationRegisterCache);
				}
			}
			code += _animationRegisterCache.getCombinationCode();
			
			for each(node in _particleNodes)
			{
				if (node.priority >= POST_PRIORITY)
				{
					code += node.getAGALVertexCode(pass, _animationRegisterCache);
				}
			}
			
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
		
		override public function cancelGPUCompatibility() : void
        {
			
        }
		
		
		
		public function generateStreamData(mesh:Mesh):void
		{
			if (_initParticleFun == null)
				throw(new Error("no initParticleFun"));
				
			var sharedData:Dictionary;
			if (_streamDatas[mesh.geometry])
			{
				return;
			}
			else
			{
				sharedData = _streamDatas[mesh.geometry] = new Dictionary(true);
			}
			
			
			var subGeometries:Vector.<ISubGeometry> = mesh.geometry.subGeometries;
			var firstSubGeometry:IParticleSubGeometry = subGeometries[0] as IParticleSubGeometry;
			if (!firstSubGeometry)
				throw(new Error("It must be IParticleSubGeometry"));
			
			var i:int;
			var animationSubGeometry:AnimationSubGeometry;
			for (i = 0; i < mesh.subMeshes.length; i++)
			{
				animationSubGeometry = sharedData[subGeometries[i]] = new AnimationSubGeometry();
				for each(var node:LocalParticleNodeBase in _localNodes)
				{
					animationSubGeometry.applyData(node.dataLength, node);
				}
				animationSubGeometry.setVertexNum(subGeometries[i].numVertices);
			}
				
			var numParticles:uint = firstSubGeometry.particles.length;
			var numCursors:uint = subGeometries.length;
			var cursors:Vector.<int> = new Vector.<int>(numCursors, true);
			var finished:int;
			var param:ParticleParameter = new ParticleParameter();
			param.total = numParticles;
			//default value
			param.startTime = 0;
			param.duringTime = 1000;
			param.sleepTime = 0.1;
			
			i = 0;
			
			while (finished < numCursors)
			{
				param.index = i;
				
				_initParticleFun(param);
				
				var len:int = _localNodes.length;
				var j:int;
				
				for (j = 0; j < len; j++)
				{
					_localNodes[j].generatePropertyOfOneParticle(param);
				}
				
				for (var k:int = 0; k < numCursors; k++)
				{
					if (cursors[k] == -1)
						continue;
					var otherSubGeometry:IParticleSubGeometry = IParticleSubGeometry(subGeometries[k]);
					var particle:ParticleData = otherSubGeometry.particles[cursors[k]];
					animationSubGeometry = sharedData[otherSubGeometry];
					var numVertex:uint = particle.numVertices;
					var targetData:Vector.<Number> = animationSubGeometry.vertexData;
					var totalLenOfOneVertex:int = animationSubGeometry.totalLenOfOneVertex;
					var initedOffset:int = animationSubGeometry.numInitedVertices * totalLenOfOneVertex;;
					var oneDataLen:int;
					var oneDataOffset:int;
					var counterForVertex:int;
					var counterForOneData:int;
					var oneData:Vector.<Number>;
					
					if (i == particle.particleIndex)
					{
						for (j = 0; j < len; j++)
						{
							oneData = _localNodes[j].oneData;
							oneDataLen = _localNodes[j].dataLength;
							oneDataOffset = animationSubGeometry.getNodeDataOffset(_localNodes[j]);
							for (counterForVertex = 0; counterForVertex < numVertex; counterForVertex++)
							{
								for (counterForOneData = 0; counterForOneData < oneDataLen; counterForOneData++)
								{
									targetData[initedOffset + oneDataOffset + totalLenOfOneVertex * counterForVertex + counterForOneData] = oneData[counterForOneData];
								}
							}
							_localNodes[j].procressExtraData(param, animationSubGeometry, numVertex);
						}
						animationSubGeometry.numInitedVertices += numVertex;
						
						cursors[k]++;
						if (cursors[k] == otherSubGeometry.particles.length)
						{
							cursors[k] = -1;
							finished++;
						}
					}
				}
				i++;
			}
			
		}
		
	}

}
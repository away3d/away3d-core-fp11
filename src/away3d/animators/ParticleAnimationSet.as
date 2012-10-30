package away3d.animators
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleConstantManager;
	import away3d.animators.data.ParticleParamter;
	import away3d.animators.data.ParticleStreamManager;
	import away3d.animators.IAnimationSet;
	import away3d.animators.nodes.LocalParticleNodeBase;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleTimeNode;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.cameras.Camera3D;
	import away3d.core.base.data.ParticleData;
	import away3d.core.base.IParticleSubGeometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.Mesh;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.passes.MaterialPassBase;
	import flash.display3D.Context3D;
	import flash.utils.Dictionary;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		public static const POST_PRIORITY:int = 9;
		
		
		private var compilers:Dictionary = new Dictionary(true);
		
		private var _activatedCompiler:ParticleAnimationCompiler;
		
		private var _particleNodes:Vector.<ParticleNodeBase> = new Vector.<ParticleNodeBase>();
		
		private var _localNodes:Vector.<LocalParticleNodeBase> = new Vector.<LocalParticleNodeBase>();
		
		
		private var _sharedSetting:ParticleAnimationSetting = new ParticleAnimationSetting;
		
		private var _constantDatas:Dictionary = new Dictionary(true);
		private var _activatedConstantData:ParticleConstantManager;
		
		private var _streamDatas:Dictionary = new Dictionary(true);
		
		
		//all other nodes dependent on it
		private var timeNode:ParticleTimeNode;
		public var _initParticleFun:Function;
		
		
		public function ParticleAnimationSet()
		{
			super();
			timeNode = new ParticleTimeNode();
			addParticleNode(timeNode);
		}
		
		public function get particleNodes():Vector.<ParticleNodeBase>
		{
			return _particleNodes;
		}
		
		public function get sharedSetting():ParticleAnimationSetting
		{
			return _sharedSetting;
		}
		
		public function get activatedCompiler():ParticleAnimationCompiler
		{
			return _activatedCompiler;
		}
		
		public function get activatedConstantData():ParticleConstantManager
		{
			return _activatedConstantData;
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
		
		public function addParticleNode(node:ParticleNodeBase):void
		{
			var i:int;
			node.processAnimationSetting(_sharedSetting);
			if (node.nodeType==ParticleNodeBase.LOCAL)
				_localNodes.push(node);
			
			for (i = _particleNodes.length - 1; i >= 0; i--)
			{
				if (_particleNodes[i].priority <= node.priority)
				{
					break;
				}
			}
			_particleNodes.splice(i + 1, 0, node);
			addAnimation(node.nodeName, node);
		}
		
		
		public function activate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			_activatedCompiler = compilers[pass];
			_activatedConstantData = _constantDatas[pass];
		}
		public function deactivate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			var context : Context3D = stage3DProxy.context3D;
			var offset:int = _activatedCompiler.shaderRegisterCache.vertexAttributesOffset;
			var used:int = _activatedCompiler.shaderRegisterCache.numUsedStreams;
			for (var i:int = offset; i < used; i++)
				context.setVertexBufferAt(i, null);
		}
		
		
		private function reset(pass:MaterialPassBase, sourceRegisters : Array, targetRegisters : Array):void
		{
			_activatedCompiler = compilers[pass] ||= new ParticleAnimationCompiler();
			_activatedConstantData = _constantDatas[pass] ||= new ParticleConstantManager();
			
			var shaderRegisterCache:ShaderRegisterCache = _activatedCompiler.shaderRegisterCache;
			shaderRegisterCache.vertexConstantOffset = pass.numUsedVertexConstants;
			shaderRegisterCache.vertexAttributesOffset = pass.numUsedStreams;
			shaderRegisterCache.varyingsOffset = pass.numUsedVaryings;
			shaderRegisterCache.fragmentConstantOffset = pass.numUsedFragmentConstants;
			shaderRegisterCache.reset();
			_activatedCompiler.sourceRegisters = sourceRegisters;
			_activatedCompiler.targetRegisters = targetRegisters;
			_activatedCompiler.needFragmentAnimation = pass.needFragmentAnimation;
			_activatedCompiler.needUVAnimation = pass.needUVAnimation;
			_activatedCompiler.reset(_sharedSetting);
		}

		
		public function getAGALVertexCode(pass : MaterialPassBase, sourceRegisters : Array, targetRegisters : Array) : String
		{
			reset(pass, sourceRegisters, targetRegisters);
			
			var code:String = "";
			
			code += _activatedCompiler.getInitCode();
			
			
			var node:ParticleNodeBase;
			for each(node in _particleNodes)
			{
				if (node.priority < POST_PRIORITY)
				{
					code += node.getAGALVertexCode(pass, _sharedSetting, _activatedCompiler);
				}
			}
			code += _activatedCompiler.getCombinationCode();
			
			for each(node in _particleNodes)
			{
				if (node.priority >= POST_PRIORITY)
				{
					code += node.getAGALVertexCode(pass, _sharedSetting, _activatedCompiler);
				}
			}
			
			return code;
		}
		
		override public function getAGALUVCode(pass : MaterialPassBase, UVSource : String, UVTarget:String) : String
		{
			var code:String = "";
			if (sharedSetting.hasUVNode)
			{
				_activatedCompiler.setUVSourceAndTarget(UVSource, UVTarget);
				code += "mov " + _activatedCompiler.uvTarget.toString() + "," + _activatedCompiler.uvAttribute.toString() + "\n";
				var node:ParticleNodeBase;
				for each(node in _particleNodes)
				{
					code += node.getAGALUVCode(pass, _sharedSetting, _activatedCompiler);
				}
				code += "mov " + _activatedCompiler.uvVar.toString() + "," + _activatedCompiler.uvTarget.toString() + "\n";
			}
			else
			{
				code += "mov " + UVTarget + "," + UVSource + "\n";
			}
			return code;
		}
		
		override public function getAGALFragmentCode(pass : MaterialPassBase, shadedTarget : String) : String
		{
			_activatedCompiler.setShadedTarget(shadedTarget);
			var code:String = "";
			var node:ParticleNodeBase;
			for each(node in _particleNodes)
			{
				code += node.getAGALFragmentCode(pass, _sharedSetting, _activatedCompiler);
			}
			return code;
		}
		
		override public function doneAGALCode(pass : MaterialPassBase):void
		{
			var shaderRegisterCache:ShaderRegisterCache = _activatedCompiler.shaderRegisterCache;
			_activatedConstantData.setDataLength(shaderRegisterCache.numUsedVertexConstants, shaderRegisterCache.vertexConstantOffset, shaderRegisterCache.numUsedFragmentConstants, shaderRegisterCache.fragmentConstantOffset);
			
			//set vertexZeroConst,vertexOneConst,vertexTwoConst
			_activatedConstantData.setVertexConst(_activatedCompiler.vertexZeroConst.index, 0, 1, 2, 0);
			if (_activatedConstantData.usedFragmentConstant > 0)
			{
				//set fragmentZeroConst,fragmentOneConst
				_activatedConstantData.setFragmentConst(_activatedCompiler.fragmentZeroConst.index, 0, 1, 1 / 255, 0);
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
			var streamManager:ParticleStreamManager;
			for (i = 0; i < mesh.subMeshes.length; i++)
			{
				streamManager = sharedData[subGeometries[i]] = new ParticleStreamManager();
				for each(var node:LocalParticleNodeBase in _localNodes)
				{
					streamManager.applyData(node.dataLenght, node);
				}
				streamManager.setVertexNum(subGeometries[i].numVertices);
			}
				
			var numParticles:uint = firstSubGeometry.particles.length;
			var numCursors:uint = subGeometries.length;
			var cursors:Vector.<int> = new Vector.<int>(numCursors, true);
			var finished:int;
			var param:ParticleParamter = new ParticleParamter();
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
					_localNodes[j].generatePorpertyOfOneParticle(param);
				}
				
				for (var k:int = 0; k < numCursors; k++)
				{
					if (cursors[k] == -1)
						continue;
					var otherSubGeometry:IParticleSubGeometry = IParticleSubGeometry(subGeometries[k]);
					var particle:ParticleData = otherSubGeometry.particles[cursors[k]];
					streamManager = sharedData[otherSubGeometry];
					var numVertex:uint = particle.numVertices;
					var targetData:Vector.<Number> = streamManager.vertexData;
					var totalLenOfOneVertex:int = streamManager.totalLenOfOneVertex;
					var initedOffset:int = streamManager.numInitedVertices * totalLenOfOneVertex;;
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
							oneDataLen = _localNodes[j].dataLenght;
							oneDataOffset = streamManager.getNodeDataOffset(_localNodes[j]);
							for (counterForVertex = 0; counterForVertex < numVertex; counterForVertex++)
							{
								for (counterForOneData = 0; counterForOneData < oneDataLen; counterForOneData++)
								{
									targetData[initedOffset + oneDataOffset + totalLenOfOneVertex * counterForVertex + counterForOneData] = oneData[counterForOneData];
								}
							}
							_localNodes[j].procressExtraData(param, streamManager, numVertex);
						}
						streamManager.numInitedVertices += numVertex;
						
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
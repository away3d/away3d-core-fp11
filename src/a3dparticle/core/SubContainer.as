package a3dparticle.core
{
	import a3dparticle.particle.ParticleMaterialBase;
	import a3dparticle.ParticlesContainer;
	import away3d.animators.IAnimator;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.Entity;
	import away3d.materials.MaterialBase;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class SubContainer implements IRenderable
	{
		private var _particleMaterial:ParticleMaterialBase;
		private var _material:SimpleParticleMaterial;
		private var _shareAtt:cloneShareAtt;
		
		private var _numTriangles:uint;
		private var _parent:ParticlesContainer;
		
		public function SubContainer(parent:ParticlesContainer, particleMaterial:ParticleMaterialBase, clone:Boolean = false )
		{
			this._parent = parent;
			this._particleMaterial = particleMaterial;
			if (!clone)
			{
				this._shareAtt = new cloneShareAtt;
				this._material = new SimpleParticleMaterial(particleMaterial);
				this._material.animation = parent.animation;
			}
		}
		
		public function get shareAtt():cloneShareAtt
		{
			return _shareAtt;
		}
		
		public function clone(parent:ParticlesContainer):SubContainer
		{
			
			var clone:SubContainer = new SubContainer(parent, _particleMaterial, true);
			clone._shareAtt = _shareAtt;
			clone._material = _material;
			clone.numTriangles = numTriangles;
			return clone;
		}
		
		public function get particleMaterial():ParticleMaterialBase
		{
			return _particleMaterial;
		}
		
		public function get material() : MaterialBase
		{
			return _material;
		}
		
		public function set material(value:MaterialBase) : void
		{
			throw(new Error("can't set the material of SubContainer"));
		}
		
		
		/*public function get animation() : AnimationBase
		{
			return ParticlesContainer(_parent).animation;
		}*/
		
		public function get animator() : IAnimator
		{
			return ParticlesContainer(_parent).animator;
		}
		
		public function get shaderPickingDetails() : Boolean
		{
			return false;
		}

		public function get numTriangles() : uint
		{
			return _numTriangles;
		}
		
		public function set numTriangles(value:uint) : void
		{
			_numTriangles = value;
		}
		
		public function get sourceEntity() : Entity
		{
			return _parent as Entity;
		}
		
		public function get castsShadows() : Boolean
		{
			return false;
		}
		
		public function getVertexNormalBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return null;
		}

		public function getVertexTangentBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return null;
		}
		public function getSecondaryUVBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return null;
		}
		public function get uvTransform() : Matrix
		{
			return null;
		}
		
		public function getVertexBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			if (!_shareAtt._vertexBuffer || _shareAtt._vertexContex3D != stage3DProxy.context3D)
			{
				_shareAtt._vertexBuffer = stage3DProxy._context3D.createVertexBuffer(_shareAtt._vertices.length/3, 3);
				_shareAtt._vertexBuffer.uploadFromVector(_shareAtt._vertices, 0, _shareAtt._vertices.length / 3);
				_shareAtt._vertexContex3D = stage3DProxy.context3D;
			}
			return _shareAtt._vertexBuffer;
		}
		
		public function getIndexBuffer(stage3DProxy : Stage3DProxy) : IndexBuffer3D
		{
			if (!_shareAtt._indexBuffer || _shareAtt._indexContex3D != stage3DProxy.context3D)
			{
				_shareAtt._indexBuffer = stage3DProxy._context3D.createIndexBuffer(_shareAtt._indices.length);
				_shareAtt._indexBuffer.uploadFromVector(_shareAtt._indices, 0, _shareAtt._indices.length);
				_shareAtt._indexContex3D = stage3DProxy.context3D;
			}
			return _shareAtt._indexBuffer;
		}
		
		public function getUVBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			if (!_shareAtt._uvBuffer || _shareAtt._uvContex3D != stage3DProxy.context3D)
			{
				_shareAtt._uvBuffer = stage3DProxy._context3D.createVertexBuffer(_shareAtt._uvData.length/2, 2);
				_shareAtt._uvBuffer.uploadFromVector(_shareAtt._uvData, 0, _shareAtt._uvData.length / 2);
				_shareAtt._uvContex3D = stage3DProxy.context3D;
			}
			return _shareAtt._uvBuffer;
		}
		
		public function get extraBuffers() : Object
		{
			return _shareAtt._extraBuffers;
		}
		
		public function get extraDatas():Object
		{
			return _shareAtt._extraDatas;
		}
		
		public function get indexData():Vector.<uint>
		{
			return _shareAtt._indices;
		}
		public function get UVData():Vector.<Number>
		{
			return _shareAtt._uvData;
		}
		public function get vertexData():Vector.<Number>
		{
			return _shareAtt._vertices;
		}
		
		
		public function get zIndex() : Number
		{
			return _parent.zIndex;
		}

		public function get sceneTransform() : Matrix3D
		{
			return _parent.sceneTransform;
		}

		public function get inverseSceneTransform() : Matrix3D
		{
			return _parent.inverseSceneTransform;
		}
		public function get modelViewProjection() : Matrix3D
		{
			return _parent.modelViewProjection;
		}
		public function getModelViewProjectionUnsafe() : Matrix3D
		{
			return _parent.getModelViewProjectionUnsafe();
		}
		public function get mouseEnabled() : Boolean
		{
			return _parent.mouseEnabled;
		}
		
		
		public function getCustomBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return null;
		}
		
		public function get vertexBufferOffset() : int
		{
			return 0;
		}
		public function get normalBufferOffset() : int
		{
			return 0;
		}
		public function get tangentBufferOffset() : int
		{
			return 0;
		}
		public function get UVBufferOffset() : int
		{
			return 0;
		}
		public function get secondaryUVBufferOffset() : int
		{
			return 0;
		}
		public function get geometryId():int
		{
			return _shareAtt.geometryId;
		}
		
	}
}

import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;

class cloneShareAtt
{
	public var _vertexBuffer : VertexBuffer3D;
	public var _indexBuffer : IndexBuffer3D;
	public var _uvBuffer : VertexBuffer3D;
	public var _vertices : Vector.<Number>=new Vector.<Number>();
	public var _indices : Vector.<uint> = new Vector.<uint>;
	public var _uvData:Vector.<Number> = new Vector.<Number>();
	public var _vertexContex3D:Context3D;
	public var _indexContex3D:Context3D;
	public var _uvContex3D:Context3D;
	public var _extraDatas:Object = { };
	public var _extraBuffers:Object = { };
	
	private static var currentId:int;
	private var _geometryId : int;
	public function cloneShareAtt()
	{
		_geometryId = currentId++;
	}
	public function get geometryId():int
	{
		return _geometryId;
	}
}
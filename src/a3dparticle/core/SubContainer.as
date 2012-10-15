package a3dparticle.core
{
	import a3dparticle.particle.ParticleMaterialBase;
	import a3dparticle.ParticlesContainer;
	import away3d.animators.IAnimator;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.Entity;
	import away3d.materials.MaterialBase;
	import flash.display3D.Context3DVertexBufferFormat;
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
		private var _particleMaterial:MaterialBase;
		private var _material:MaterialBase;
		private var _shareAtt:cloneShareAtt;
		
		private var _numTriangles:uint;
		private var _parent:ParticlesContainer;
		
		public function SubContainer(parent:ParticlesContainer, particleMaterial:MaterialBase, clone:Boolean = false )
		{
			this._parent = parent;
			this._particleMaterial = particleMaterial;
			if (!clone)
			{
				this._shareAtt = new cloneShareAtt;
				this._material = particleMaterial;
				_material.addOwner(this);
				//this._material = parent.animation;
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
		
		/*public function get particleMaterial():ParticleMaterialBase
		{
			return _particleMaterial;
		}*/
		
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
			return true;
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
			return _shareAtt.getVertexBuffer(stage3DProxy);
		}
		
		public function getIndexBuffer(stage3DProxy : Stage3DProxy) : IndexBuffer3D
		{
			return _shareAtt.getIndexBuffer(stage3DProxy);
		}
		
		public function getUVBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _shareAtt.getUVBuffer(stage3DProxy);
		}
		
		public function getExtraBuffer(stage3DProxy:Stage3DProxy, bufferName:String, dataLenght:uint) : VertexBuffer3D
		{
			return _shareAtt.getExtraBuffer(stage3DProxy, bufferName, dataLenght);
		}
		
		public function getExtraData(bufferName:String):Vector.<Number>
		{
			return _shareAtt.getExtraData(bufferName);
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
		
		
		
		public function activateVertexBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy.context3D.setVertexBufferAt(index, getVertexBuffer(stage3DProxy), 0, Context3DVertexBufferFormat.FLOAT_3);
		}
		public function activateUVBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy.context3D.setVertexBufferAt(index, getUVBuffer(stage3DProxy), 0, Context3DVertexBufferFormat.FLOAT_2);
		}
		
		public function activateSecondaryUVBuffer(index : int, stage3DProxy : Stage3DProxy) : void{};
		public function activateVertexNormalBuffer(index : int, stage3DProxy : Stage3DProxy) : void{};
		public function activateVertexTangentBuffer(index : int, stage3DProxy : Stage3DProxy) : void{};
		public function get numVertices() : uint { return 0 };
		public function get vertexStride() : uint { return 0 };
		public function get vertexNormalData() : Vector.<Number>{return null};
		public function get vertexTangentData() : Vector.<Number> { return null};
	}
}

import away3d.core.managers.Stage3DProxy;
import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;

class cloneShareAtt
{
	private var _vertexBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8, true);
	private var _indexBuffer : Vector.<IndexBuffer3D> = new Vector.<IndexBuffer3D>(8, true);
	private var _uvBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8, true);
	public var _vertices : Vector.<Number>=new Vector.<Number>();
	public var _indices : Vector.<uint> = new Vector.<uint>;
	public var _uvData:Vector.<Number> = new Vector.<Number>();
	private var _vertexContex3D:Vector.<Context3D> = new Vector.<Context3D>(8, true);
	private var _indexContex3D:Vector.<Context3D> = new Vector.<Context3D>(8, true);
	private var _uvContex3D:Vector.<Context3D> = new Vector.<Context3D>(8, true);
	public var _extraDatas:Object = { };
	private var _extraBuffers:Object = { };
	private var _extraContex3Ds:Object = { };
	
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
	
	public function getVertexBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
	{
		var contextIndex : int = stage3DProxy.stage3DIndex;
		var context : Context3D = stage3DProxy.context3D;
		var t : VertexBuffer3D = _vertexBuffer[contextIndex];
		if (!t || _vertexContex3D[contextIndex] != context)
		{
			t = _vertexBuffer[contextIndex] = context.createVertexBuffer(_vertices.length / 3, 3);
			t.uploadFromVector(_vertices, 0, _vertices.length / 3);
			_vertexContex3D[contextIndex] = context;
		}
		return t;
	}
	
	public function getIndexBuffer(stage3DProxy : Stage3DProxy) : IndexBuffer3D
	{
		var contextIndex : int = stage3DProxy.stage3DIndex;
		var context : Context3D = stage3DProxy.context3D;
		var t : IndexBuffer3D = _indexBuffer[contextIndex];
		if (!t || _indexContex3D[contextIndex] != context)
		{
			t = _indexBuffer[contextIndex] = context.createIndexBuffer(_indices.length);
			t.uploadFromVector(_indices, 0, _indices.length);
			_indexContex3D[contextIndex] = context;
		}
		return t;
	}
	
	public function getUVBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
	{
		var contextIndex : int = stage3DProxy.stage3DIndex;
		var context : Context3D = stage3DProxy.context3D;
		var t : VertexBuffer3D = _uvBuffer[contextIndex];
		if (!t || _uvContex3D[contextIndex] != context)
		{
			t = _uvBuffer[contextIndex] = context.createVertexBuffer(_uvData.length / 2, 2);
			t.uploadFromVector(_uvData, 0, _uvData.length / 2);
			_uvContex3D[contextIndex] = context;
		}
		return t;
	}
	
	public function getExtraBuffer(stage3DProxy:Stage3DProxy, bufferName:String, dataLenght:uint) : VertexBuffer3D
	{
		var buffer:Vector.<VertexBuffer3D> = _extraBuffers[bufferName];
		var context3D:Vector.<Context3D> = _extraContex3Ds[bufferName];
		if (!buffer)
		{
			buffer = _extraBuffers[bufferName] = new Vector.<VertexBuffer3D>(8, true);
			context3D = _extraContex3Ds[bufferName] = new Vector.<Context3D>(8, true);
		}
		var contextIndex : int = stage3DProxy.stage3DIndex;
		var context : Context3D = stage3DProxy.context3D;
		var t : VertexBuffer3D = buffer[contextIndex];
		if (!t || context3D[contextIndex] != context)
		{
			var data:Vector.<Number> = getExtraData(bufferName);
			t = buffer[contextIndex] = context.createVertexBuffer(data.length / dataLenght, dataLenght);
			t.uploadFromVector(data, 0, data.length / dataLenght);
			context3D[contextIndex] = context;
		}
		return t;
	}
	
	public function getExtraData(bufferName:String):Vector.<Number>
	{
		var t : Vector.<Number> = _extraDatas[bufferName];
		if (!t)
		{
			t = _extraDatas[bufferName] = new Vector.<Number>();
		}
		return t;
	}

}
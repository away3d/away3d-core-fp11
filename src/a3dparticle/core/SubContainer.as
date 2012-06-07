package a3dparticle.core 
{
	import a3dparticle.particle.ParticleMaterialBase;
	import a3dparticle.ParticlesContainer;
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
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
				this._material.animation = animation;
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
		
		
		public function get animation() : AnimationBase
		{
			return ParticlesContainer(_parent).animation;
		}
		
		public function get animationState() : AnimationStateBase
		{
			return ParticlesContainer(_parent).animationState;
		}
		
		public function get mouseDetails() : Boolean
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
		public function get mouseHitMethod():uint
		{
			return _parent.mouseHitMethod;
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

import away3d.core.managers.Stage3DProxy;
import away3d.events.Stage3DEvent;
import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.utils.Dictionary;

import away3d.arcane;
use namespace arcane;

class cloneShareAtt
{
	protected var _vertexBuffer : Dictionary = new Dictionary(true);
	protected var _indexBuffer : Dictionary = new Dictionary(true);
	protected var _uvBuffer : Dictionary = new Dictionary(true);
	public var _vertices : Vector.<Number> = new Vector.<Number>();
	public var _indices : Vector.<uint> = new Vector.<uint>;
	public var _uvData:Vector.<Number> = new Vector.<Number>();
	public var _extraDatas:Object = { };
	protected var _extraBuffers:Object = { };
	
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
		var t : VertexBuffer3D = _vertexBuffer[stage3DProxy];
		if (!t) 
		{
			t = _vertexBuffer[stage3DProxy] = stage3DProxy._context3D.createVertexBuffer(_vertices.length / 3, 3);
			t.uploadFromVector(_vertices, 0, _vertices.length / 3);
			stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onRecreated, false, 0, true);
		}

		return t;
	}
	
	public function getIndexBuffer(stage3DProxy : Stage3DProxy) : IndexBuffer3D
	{
		var t : IndexBuffer3D = _indexBuffer[stage3DProxy];
		if (!t) 
		{
			t = _indexBuffer[stage3DProxy] = stage3DProxy._context3D.createIndexBuffer(_indices.length);
			t.uploadFromVector(_indices, 0, _indices.length);
			stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onRecreated, false, 0, true);
		}

		return t;
	}
	
	public function getUVBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
	{
		var t : VertexBuffer3D = _uvBuffer[stage3DProxy];
		if (!t) 
		{
			t = _uvBuffer[stage3DProxy] = stage3DProxy._context3D.createVertexBuffer(_uvData.length / 2, 2);
			t.uploadFromVector(_uvData, 0, _uvData.length / 2);
			stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onRecreated, false, 0, true);
		}
		return t;
	}
	
	public function getExtraBuffer(stage3DProxy:Stage3DProxy, bufferName:String, dataLenght:uint) : VertexBuffer3D
	{
		var buffer:Dictionary = _extraBuffers[bufferName];
		if (!buffer)
		{
			buffer = _extraBuffers[bufferName] = new Dictionary(true);
		}
		var t : VertexBuffer3D = buffer[stage3DProxy];
		if (!t) 
		{
			var data:Vector.<Number> = getExtraData(bufferName);
			t = buffer[stage3DProxy] = stage3DProxy._context3D.createVertexBuffer(data.length / dataLenght, dataLenght);
			t.uploadFromVector(data, 0, data.length / dataLenght);
			stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onRecreated, false, 0, true);
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

	private function onRecreated(e:Stage3DEvent):void
	{
		var stage3Dproxy:Stage3DProxy = e.target as Stage3DProxy;
		delete _vertexBuffer[stage3Dproxy];
		delete _uvBuffer[stage3Dproxy];
		delete _indexBuffer[stage3Dproxy];
		for each(var i:Dictionary in _extraBuffers)
		{
			delete i[stage3Dproxy];
		}
	}
}
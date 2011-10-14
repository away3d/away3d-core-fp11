package a3dparticle 
{
	import a3dparticle.animators.actions.ActionBase;
	import a3dparticle.animators.actions.AllParticleAction;
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.animators.ParticleAnimation;
	import a3dparticle.animators.ParticleAnimationState;
	import a3dparticle.animators.ParticleAnimationtor;
	import a3dparticle.materials.SimpleParticleMaterial;
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.IRenderable;
	import away3d.core.base.Object3D;
	import away3d.core.base.SubGeometry;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.RenderableNode;
	import away3d.entities.Entity;
	import away3d.materials.MaterialBase;
	import flash.display.BitmapData;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;

	import away3d.arcane;
	use namespace arcane;
	/**
	 * A container of particles
	 * 
	 */
	public class ParticlesContainer extends Entity implements IRenderable
	{
		private var _numTriangles:uint;
		private var _count:uint;
		private var __controller:ParticleAnimationtor;
		private var _animationState:ParticleAnimationState;
		private var _material : SimpleParticleMaterial;
		private var _particleAnimation : ParticleAnimation;
		private var _shareAtt:cloneShareAtt;
		private var _hasGen:Boolean;
		
		
		/**
		* @param count uint.The total count of the particles.
		* @param particleMaterial SimpleParticleMaterial.The material of all the particles.
		* @param isClone Boolean.
		*/
		public function ParticlesContainer(count:uint=1,particleMaterial:SimpleParticleMaterial=null,isClone:Boolean=false) 
		{
			super();
			if (!isClone)
			{
				_count = count;
				_shareAtt = new cloneShareAtt();
				_particleAnimation = new ParticleAnimation();
				material = particleMaterial;
				_animationState = new ParticleAnimationState(_particleAnimation);
				__controller = new ParticleAnimationtor(_animationState);
			}
		}
		
		public function set timeScale(value:Number):void
		{
			__controller.timeScale = value;
		}
		public function get timeScale():Number
		{
			return __controller.timeScale;
		}
		public function set time(value:Number):void
		{
			__controller.time = value;
		}
		public function get time():Number
		{
			return __controller.time;
		}
		
		public function addAction(action:ActionBase):void
		{
			if (_hasGen) throw(new Error("can't add action after gen!"));
			_particleAnimation.addAction(action);
		}
		
		public function set startTimeFun(fun:Function):void
		{
			_particleAnimation.startTimeFun = fun;
		}
		
		public function set endTimeFun(fun:Function):void
		{
			_particleAnimation.endTimeFun = fun;
		}
		
		public function set loop(value:Boolean):void
		{
			_particleAnimation.loop = value;
		}
		
		public function generate(subGem : SubGeometry):void
		{
			if (_hasGen) throw(new Error("has generated!"));
			var vertexData:Vector.<Number> = subGem.vertexData;
			var uvData:Vector.<Number> = subGem.UVData;
			var indexData:Vector.<uint> = subGem.indexData;
			
			_numTriangles = _count * subGem.numTriangles;
			
			_particleAnimation.startGen();
			
			for (var i:int=0; i < _count; i++)
			{
				var j:uint = 0;
				var length:uint = vertexData.length;
				var _num:uint = length / 3;
				indexData.forEach(function(index:Number, ...rest):void { _shareAtt._indices.push(index + i * _num); } );
				uvData.forEach(function(uv:Number, ...rest):void { _shareAtt._uvData.push(uv); } );
				
				_particleAnimation.genOne(i);
				
				for (j = 0; j < length; j += 3)
				{
					_shareAtt._vertices.push(vertexData[j]);
					_shareAtt._vertices.push(vertexData[j + 1]);
					_shareAtt._vertices.push(vertexData[j + 2]);
					_particleAnimation.distributeOne(i, j);
				}
			}
			_particleAnimation.finishGen();
			_hasGen = true;
			
		}
		
		public function start():void
		{
			__controller.play();
		}
		
		public function stop():void
		{
			__controller.stop();
		}
		
		public function get material() : MaterialBase
		{
			return _material;
		}
		
		public function set material(value : MaterialBase) : void
		{
			var _value:SimpleParticleMaterial = value as SimpleParticleMaterial;
			if (_value == _material) return;
			if (_material) _material.removeOwner(this);
			_material = _value;
			if (_material) _material.addOwner(this);
		}
		
		public function get animation() : AnimationBase
		{
			return _particleAnimation;
		}
		
		public function get animationState() : AnimationStateBase
		{
			return _animationState;
		}
		override protected function createEntityPartitionNode() : EntityNode
		{
			return new RenderableNode(this);
		}
		
		public function get mouseDetails() : Boolean
		{
			return false;
		}

		public function get numTriangles() : uint
		{
			return _numTriangles;
		}

		public function get sourceEntity() : Entity
		{
			return this;
		}

		public function get castsShadows() : Boolean
		{
			return false;
		}
		override protected function updateBounds() : void
		{

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
			if (!_shareAtt._vertexBuffer) {
				_shareAtt._vertexBuffer = stage3DProxy._context3D.createVertexBuffer(_shareAtt._vertices.length/3, 3);
				_shareAtt._vertexBuffer.uploadFromVector(_shareAtt._vertices, 0, _shareAtt._vertices.length/3);
			}
			return _shareAtt._vertexBuffer;
		}
		
		public function getIndexBuffer(stage3DProxy : Stage3DProxy) : IndexBuffer3D
		{
			if (!_shareAtt._indexBuffer) {
				_shareAtt._indexBuffer = stage3DProxy._context3D.createIndexBuffer(_shareAtt._indices.length);
				_shareAtt._indexBuffer.uploadFromVector(_shareAtt._indices, 0, _shareAtt._indices.length);
			}
			return _shareAtt._indexBuffer;
		}
		
		public function getUVBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			if (!_shareAtt._uvBuffer) {
				_shareAtt._uvBuffer = stage3DProxy._context3D.createVertexBuffer(_shareAtt._uvData.length/2, 2);
				_shareAtt._uvBuffer.uploadFromVector(_shareAtt._uvData, 0, _shareAtt._uvData.length/2);
			}
			return _shareAtt._uvBuffer;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone() : Object3D
		{
			if (!_hasGen) throw(new Error("can't not clone a object that has not gen!"));
			var clone : ParticlesContainer = new ParticlesContainer(_count, null, true);
			clone._count = _count;
			clone._numTriangles = _numTriangles;
			clone._shareAtt = _shareAtt;
			clone._hasGen = _hasGen;
			clone._particleAnimation = _particleAnimation;
			clone._material = _material;
			clone._animationState = new ParticleAnimationState(_particleAnimation);
			clone.__controller = new ParticleAnimationtor(clone._animationState);
			
			clone.pivotPoint = pivotPoint;
			clone.partition = partition;
			clone.bounds = _bounds.clone();
			clone.name = name;

			for (var i:int = 0; i < numChildren; ++i) {
				clone.addChild(ObjectContainer3D(getChildAt(i).clone()));
			}
			return clone;
		}
		
	}

}

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
}
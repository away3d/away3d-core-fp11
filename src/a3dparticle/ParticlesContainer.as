package a3dparticle 
{
	import a3dparticle.animators.actions.ActionBase;
	import a3dparticle.animators.ParticleAnimation;
	import a3dparticle.animators.ParticleAnimationState;
	import a3dparticle.animators.ParticleAnimationtor;
	import a3dparticle.core.ParticlesNode;
	import a3dparticle.core.SubContainer;
	import a3dparticle.generater.GeneraterBase;
	import a3dparticle.particle.ParticleSample;
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Object3D;
	import away3d.core.partition.EntityNode;
	import away3d.entities.Entity;

	import away3d.arcane;
	use namespace arcane;
	/**
	 * A container of particles
	 * 
	 */
	public class ParticlesContainer extends Entity
	{
		private var __controller:ParticleAnimationtor;
		private var _animationState:ParticleAnimationState;
		private var _particleAnimation : ParticleAnimation;
		private var _hasGen:Boolean;
		
		public var _subContainers : Vector.<SubContainer>;
		
		public function ParticlesContainer(isClone:Boolean=false) 
		{
			super();
			if (!isClone)
			{
				_particleAnimation = new ParticleAnimation();
				_animationState = new ParticleAnimationState(_particleAnimation);
				__controller = new ParticleAnimationtor(_animationState);
				_subContainers = new Vector.<SubContainer>();
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
		
		public function set sleepTimeFun(fun:Function):void
		{
			_particleAnimation.sleepTimeFun = fun;
		}
		
		public function set loop(value:Boolean):void
		{
			_particleAnimation.loop = value;
		}
		
		public function generate(generater:GeneraterBase):void
		{
			if (_hasGen) throw(new Error("has generated!"));
			
			_particleAnimation.startGen();

			var _vec:Vector.<ParticleSample> = generater.particlesSamples;
			
			var vertexData:Vector.<Number>;
			var uvData:Vector.<Number>;
			var indexData:Vector.<uint>;
			var j:uint;
			var length:uint;
			
			for (var i:uint = 0; i < _vec.length; i++)
			{
				for (j = 0; j < _subContainers.length; j++)
				{
					if (_subContainers[j].particleMaterial == _vec[i].material) break;
				}
				if (j == _subContainers.length)
				{
					_subContainers[j] = new SubContainer(this, _vec[i].material);
				}
				length = _vec[i].subGem.vertexData.length;
				indexData = _vec[i].subGem.indexData;
				vertexData = _vec[i].subGem.vertexData;
				uvData = _vec[i].subGem.UVData;
				
				_subContainers[j].numTriangles+= _vec[i].subGem.numTriangles;
				indexData.forEach(function(index:uint, ...rest):void { _subContainers[j].indices.push(index + _subContainers[j].vertexData.length / 3); } );
				uvData.forEach(function(uv:Number, ...rest):void { _subContainers[j].uvData.push(uv); } );
				_particleAnimation.genOne(i);
				for (var k:uint = 0; k < length; k += 3)
				{
					_subContainers[j].vertexData.push(vertexData[k]);
					_subContainers[j].vertexData.push(vertexData[k + 1]);
					_subContainers[j].vertexData.push(vertexData[k + 2]);
					_particleAnimation.distributeOne(i, k, _subContainers[j]);
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
				
		override protected function createEntityPartitionNode() : EntityNode
		{
			return new ParticlesNode(this);
		}
		
		public function get animation() : AnimationBase
		{
			return _particleAnimation;
		}
		
		public function get animationState() : AnimationStateBase
		{
			return _animationState;
		}
		
		
		override protected function updateBounds() : void
		{

		}
		
		override public function get showBounds() : Boolean
		{
			return false;
		}

		override public function set showBounds(value : Boolean) : void
		{
			throw(new Error("the particlesContainer can't show bounds!"));
		}
		

		override public function get mouseEnabled() : Boolean
		{
			return false;
		}
		
		override public function set mouseEnabled(value : Boolean) : void
		{
			throw(new Error("the particlesContainer is not interactive!"));
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone() : Object3D
		{
			if (!_hasGen) throw(new Error("can't not clone a object that has not gen!"));
			var clone : ParticlesContainer = new ParticlesContainer();
			clone._hasGen = _hasGen;
			clone._particleAnimation = _particleAnimation;
			clone._subContainers = _subContainers;
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

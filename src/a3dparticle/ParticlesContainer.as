package a3dparticle
{
	import a3dparticle.animators.actions.ActionBase;
	import a3dparticle.animators.ParticleAnimation;
	import a3dparticle.animators.ParticleAnimationtor;
	import a3dparticle.core.ParticlesNode;
	import a3dparticle.core.SubContainer;
	import a3dparticle.generater.GeneraterBase;
	import a3dparticle.particle.ParticleParam;
	import a3dparticle.particle.ParticleSample;
	import away3d.animators.IAnimationSet;
	import away3d.bounds.AxisAlignedBoundingBox;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Object3D;
	import away3d.core.partition.EntityNode;
	import away3d.entities.Entity;
	

	/**
	 * A container of particles
	 * @author liaocheng.Email:liaocheng210@126.com.
	 */
	public class ParticlesContainer extends Entity
	{
		public var initParticleFun:Function;
		
		protected var _animator:ParticleAnimationtor;
		protected var _particleAnimation : ParticleAnimation;
		
		protected var _isStart:Boolean;
		protected var _hasGen:Boolean;
		protected var _alwaysInFrustum:Boolean;
		
		private var _mouseHitMethod:uint;
		
		public var _subContainers : Vector.<SubContainer>;
		
		public function ParticlesContainer(isClone:Boolean=false)
		{
			super();
			if (!isClone)
			{
				_particleAnimation = new ParticleAnimation();
				
				_animator = new ParticleAnimationtor(_particleAnimation);
				_subContainers = new Vector.<SubContainer>();
			}
		}
		
		public function set alwaysInFrustum(value:Boolean):void
		{
			_alwaysInFrustum = value;
		}
		
		public function get alwaysInFrustum():Boolean
		{
			return _alwaysInFrustum;
		}
		
		
		public function set playbackSpeed(value:Number):void
		{
			_animator.playbackSpeed = value;
		}
		public function get playbackSpeed():Number
		{
			return _animator.playbackSpeed;
		}
		public function set time(value:Number):void
		{
			_animator.absoluteTime = value * 1000;
		}
		public function get time():Number
		{
			return _animator.absoluteTime /1000;
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
		
		public function set hasDuringTime(value:Boolean):void
		{
			_particleAnimation.hasDuringTime = value;
		}
		
		public function set hasSleepTime(value:Boolean):void
		{
			_particleAnimation.hasSleepTime = value;
		}
		
		public function set duringTimeFun(fun:Function):void
		{
			_particleAnimation.duringTimeFun = fun;
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
			var param:ParticleParam;
			
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
				indexData.forEach(function(index:uint, ...rest):void { _subContainers[j].indexData.push(index + _subContainers[j].vertexData.length / 3); } );
				uvData.forEach(function(uv:Number, ...rest):void { _subContainers[j].UVData.push(uv); } );
				
				param = initParticleParam();
				param.total = _vec.length;
				param.index = i;
				param.sample = _vec[i];
				
				if (initParticleFun != null) initParticleFun(param);
				
				_particleAnimation.genOne(param);
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
		
		protected function initParticleParam():ParticleParam
		{
			return new ParticleParam;
		}
		
		public function start():void
		{
			_isStart = true;
			_animator.start();
		}
		
		public function stop():void
		{
			_isStart = false;
			_animator.stop();
		}
				
		override protected function createEntityPartitionNode() : EntityNode
		{
			return new ParticlesNode(this);
		}
		
		override protected function getDefaultBoundingVolume():BoundingVolumeBase
		{
			return new AxisAlignedBoundingBox();
		}

		override protected function updateBounds():void
		{
			_bounds.fromExtremes( -100, -100, -100, 100, 100, 100 );
			_boundsInvalid = false;
		}
		
		public function get animation() : IAnimationSet
		{
			return _particleAnimation;
		}
		
		public function get animator() : ParticleAnimationtor
		{
			return _animator;
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
		 * Indicates what picking method to use on this mesh. See MouseHitMethod for available options.
		 */
		public function get mouseHitMethod():uint
		{
			return _mouseHitMethod;
		}

		public function set mouseHitMethod( value:uint ):void
		{
			_mouseHitMethod = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone() : Object3D
		{
			if (!_hasGen) throw(new Error("can't not clone a object that has not gen!"));
			var clone : ParticlesContainer = new ParticlesContainer(true);
			clone._hasGen = _hasGen;
			clone._particleAnimation = _particleAnimation;
			clone._animator = new ParticleAnimationtor(_particleAnimation);
			clone._subContainers = new Vector.<SubContainer>();
			clone._isStart = _isStart;
			clone.alwaysInFrustum = alwaysInFrustum;
			
			if (_isStart) clone.start();
			for (var j:uint = 0; j < _subContainers.length; j++)
			{
				clone._subContainers[j] = _subContainers[j].clone(clone);
			}
			
			clone.transform = transform;
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

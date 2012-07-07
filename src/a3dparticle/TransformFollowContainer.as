package a3dparticle 
{
	import a3dparticle.animators.ParticleAnimation;
	import a3dparticle.animators.ParticleAnimationState;
	import a3dparticle.animators.ParticleAnimationtor;
	import a3dparticle.animators.TransformFollowState;
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Object3D;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class TransformFollowContainer extends ParticlesContainer
	{
		private var defaultSleepTime:Number;
		/**
		 * 
		 * @param	offset Boolean.If following target offset
		 * @param	rotation Boolean.If following target rotation.This is conflict with BillboardGlobal.
		 * @param	sleepTime Number.The particles must has a sleepTime,otherwise it will looks strange.
		 * @param	isClone Boolean.
		 */
		public function TransformFollowContainer(offset:Boolean = true, rotation:Boolean = false, sleepTime:Number = 0.1, isClone:Boolean = false) 
		{
			super(true);
			if (!isClone)
			{
				_particleAnimation = new ParticleAnimation();
				
				_animationState = new TransformFollowState(offset, rotation, _particleAnimation);
				
				__controller = new ParticleAnimationtor(_animationState);
				_subContainers = new Vector.<SubContainer>();
				this.hasSleepTime = true;
				defaultSleepTime = sleepTime;
			}
			
		}

		public function set followTarget(value:Object3D):void
		{
			TransformFollowState(this.animationState).followTarget = value;
		}
		
		override protected function initParticleParam():ParticleParam
		{
			var param:ParticleParam = new ParticleParam();
			param.sleepTime = defaultSleepTime;
			return param; 
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone() : Object3D
		{
			if (!_hasGen) throw(new Error("can't not clone a object that has not gen!"));
			var clone : TransformFollowContainer = new TransformFollowContainer(true, true, defaultSleepTime, true);
			clone._hasGen = _hasGen;
			clone._particleAnimation = _particleAnimation;
			clone._animationState = _animationState.clone() as ParticleAnimationState;
			clone.__controller = new ParticleAnimationtor(clone._animationState);
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
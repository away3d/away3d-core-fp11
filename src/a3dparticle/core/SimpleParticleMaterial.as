package a3dparticle.core
{
	import a3dparticle.animators.ParticleAnimation;
	import a3dparticle.animators.ParticleAnimationtor;
	import a3dparticle.particle.ParticleMaterialBase;
	import away3d.animators.AnimationSetBase;
	import away3d.animators.IAnimationSet;
	import away3d.arcane;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.traverse.EntityCollector;
	import away3d.materials.MaterialBase;
	import flash.display.BlendMode;
	import flash.display3D.Context3D;
	
	
	use namespace arcane;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class SimpleParticleMaterial extends MaterialBase
	{
		public var _screenPass : SimpleParticlePass;
		private var _particleMaterial:ParticleMaterialBase;
		
		private var renderTimes:int;
		
		public function SimpleParticleMaterial(particleMaterial:ParticleMaterialBase)
		{
			super();
			this._particleMaterial = particleMaterial;
			addPass(_screenPass = new SimpleParticlePass(particleMaterial));
			_screenPass.material = this;
			cpoyParam();
		}
		
		private function cpoyParam():void
		{
			bothSides = _particleMaterial.bothSides;
			blendMode = _particleMaterial.blendMode;
		}
		

		override  public function get bothSides() : Boolean
		{
			return _particleMaterial.bothSides;
		}

		
		/**
		 * @inheritDoc
		 */
		override public function get requiresBlending() : Boolean
		{
			return _particleMaterial.requiresBlending;
		}
		
		override arcane function addOwner(owner : IMaterialOwner) : void
		{
			throw(new Error("this is along with only one owner"));
		}
		
		public function set animation(value:IAnimationSet):void
		{
			for (var i : int = 0; i < _numPasses; ++i)
				_passes[i].animationSet = value;
		}
		
		override arcane function removeOwner(owner : IMaterialOwner) : void
		{
			return;
		}
		
		override arcane function updateMaterial(context : Context3D) : void
		{
			cpoyParam();
			if (renderTimes != _particleMaterial.renderTimes)
			{
				invalidatePasses(null);
				renderTimes = _particleMaterial.renderTimes;
			}
			super.updateMaterial(context);
		}
		
		
		override arcane function renderPass(index : uint, renderable : IRenderable, stage3DProxy : Stage3DProxy, entityCollector : EntityCollector) : void
		{
			var subContainer:SubContainer;
			if ((subContainer = renderable as SubContainer))
			{
				//sometimes action need to read the camera, set it temporary
				(subContainer.animator.animationSet as ParticleAnimation).camera = entityCollector.camera;
				for (var i:int = 0; i < renderTimes; i++)
				{
					ParticleAnimationtor(subContainer.animator).passCount = i;
					ParticleAnimationtor(subContainer.animator).offestTime = -i * _particleMaterial.timeInterval;
					super.renderPass(index, renderable, stage3DProxy, entityCollector);
				}
			}
			
		}
		
	}

}
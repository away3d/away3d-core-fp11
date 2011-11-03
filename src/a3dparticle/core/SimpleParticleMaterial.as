package a3dparticle.core 
{
	import a3dparticle.animators.ParticleAnimation;
	import a3dparticle.particle.ParticleMaterialBase;
	import away3d.animators.data.AnimationBase;
	import away3d.arcane;
	import away3d.core.base.IMaterialOwner;
	import away3d.materials.MaterialBase;
	import flash.display.BitmapData;
	
	
	use namespace arcane;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class SimpleParticleMaterial extends MaterialBase
	{
		public var _screenPass : SimpleParticlePass;
		private var _particleMaterial:ParticleMaterialBase;
		
		public function SimpleParticleMaterial(particleMaterial:ParticleMaterialBase) 
		{
			super();
			this._particleMaterial = particleMaterial;
			addPass(_screenPass = new SimpleParticlePass(particleMaterial));
			_screenPass.material = this;
			//bothSides = true;
		}
		

		override  public function get bothSides() : Boolean
		{
			return _particleMaterial.bothSides;
		}

		override public function set bothSides(value : Boolean) : void
		{
			throw(new Error("don't set it directly"));
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get requiresBlending() : Boolean
		{
			return true;
		}
		
		override arcane function addOwner(owner : IMaterialOwner) : void
		{
			throw(new Error("this is along with only one owner"));
		}
		
		public function set animation(value:AnimationBase):void
		{
			for (var i : int = 0; i < _numPasses; ++i)
				_passes[i].animation = value;
		}
		
		override arcane function removeOwner(owner : IMaterialOwner) : void
		{
			return;
		}
		
	}

}
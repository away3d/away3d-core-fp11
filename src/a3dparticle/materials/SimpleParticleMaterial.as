package a3dparticle.materials 
{
	import a3dparticle.animators.ParticleAnimation;
	import away3d.arcane;
	import away3d.core.base.IMaterialOwner;
	import away3d.materials.MaterialBase;
	import flash.display.BitmapData;
	
	
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class SimpleParticleMaterial extends MaterialBase
	{
		public var _screenPass : SimpleParticlePass;
		
		private var __animation : ParticleAnimation;
		
		public function SimpleParticleMaterial(bitmapData:BitmapData=null) 
		{
			super();
			bothSides = true;
			addPass(_screenPass = new SimpleParticlePass(bitmapData));
			_screenPass.material = this;
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
			if (__animation) {
				if (!owner.animation.equals(__animation))
					throw new Error("A Material instance cannot be shared across renderables with different animation instances");
			}
			else {
				__animation = owner.animation as ParticleAnimation;
				if (!__animation) throw(new Error("owner.animation is not ParticleAnimation"));
				for (var i : int = 0; i < _numPasses; ++i)
					_passes[i].animation = __animation;
				//TODO I don't konw if it is right
				//_depthPass.animation = __animation;
			}
		}

		/**
		 * Removes an IMaterialOwner as owner.
		 * @param owner
		 * @private
		 */
		override arcane function removeOwner(owner : IMaterialOwner) : void
		{
			return;
		}
		
	}

}
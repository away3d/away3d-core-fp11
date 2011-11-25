package a3dparticle.core 
{
	import a3dparticle.ParticlesContainer;
	import away3d.cameras.Camera3D;
	import away3d.core.partition.EntityNode;
	import away3d.core.traverse.PartitionTraverser;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class ParticlesNode extends EntityNode
	{
		private var _particlesContainer : ParticlesContainer;
		
		public function ParticlesNode(particlesContainer:ParticlesContainer) 
		{
			super(particlesContainer);
			this._particlesContainer = particlesContainer;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser : PartitionTraverser) : void
		{
			if (traverser.enterNode(this)) {
				super.acceptTraverser(traverser);
				var subs : Vector.<SubContainer> = _particlesContainer._subContainers;
				var i : uint;
				var len : uint = subs.length;
				while (i < len)
					traverser.applyRenderable(subs[i++]);
			}
			traverser.leaveNode(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function isInFrustum(camera : Camera3D) : Boolean
		{
			if (_particlesContainer.isVisible == false) return false;
			_particlesContainer.pushModelViewProjection(camera);
			if (_particlesContainer.alwaysInFrustum) 
			{
				return true;
			}
			else
			{
				if (_particlesContainer.bounds.isInFrustum(_particlesContainer.getModelViewProjectionUnsafe()))
				{
					return true;
				}
				else 
				{
					_particlesContainer.popModelViewProjection();
					return false;
				}
			}
			
		}
		
	}

}
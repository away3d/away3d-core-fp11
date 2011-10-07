package a3dparticle.animators 
{
	import a3dparticle.animators.actions.ActionBase;
	import a3dparticle.materials.SimpleParticlePass;
	import a3dparticle.ParticlesContainer;
	import away3d.animators.data.AnimationStateBase;
	import away3d.arcane;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.Mesh;
	import away3d.materials.passes.MaterialPassBase;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	
	

	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleAnimationState extends AnimationStateBase
	{
		public var time:Number = 0;
		private var _particleAnimation:ParticleAnimation;
		
		
		
		public function ParticleAnimationState(animation : ParticleAnimation) 
		{
			super(animation);
			_particleAnimation = animation;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			
			var particlesContainer:ParticlesContainer = ParticlesContainer(renderable);
			if (_particleAnimation.hasGen)
			{
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _particleAnimation.timeConst.index, Vector.<Number>([ time, time, time, 0 ]));
				if (SimpleParticlePass(pass)._texture)
				{
					context.setVertexBufferAt(_particleAnimation.uvAttribute.index, particlesContainer.getUVBuffer(stage3DProxy), 0, Context3DVertexBufferFormat.FLOAT_2);
				}
				var action:ActionBase;
				_particleAnimation.setRenderState(stage3DProxy, pass , renderable);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone() : AnimationStateBase
		{
			var clone : ParticleAnimationState = new ParticleAnimationState(ParticleAnimation(_animation));
			clone.time = 0;
			return clone;
		}
		
		override arcane function addOwner(mesh : Mesh) : void
		{
			return;
		}

		override arcane function removeOwner(mesh : Mesh) : void
		{
			return;
		}
		
	}

}
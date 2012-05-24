package a3dparticle.animators 
{
	import a3dparticle.animators.actions.ActionBase;
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
	
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleAnimationState extends AnimationStateBase
	{
		protected var _time:Number = 0;
		protected var _particleAnimation:ParticleAnimation;
		
		
		public function ParticleAnimationState(animation : ParticleAnimation) 
		{
			super(animation);
			_particleAnimation = animation;
		}
		
		public function get time():Number
		{
			return _time;
		}
		
		public function set time(value:Number):void
		{
			_time = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			if (_particleAnimation.hasGen)
			{
				var context : Context3D = stage3DProxy._context3D;
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _particleAnimation.timeConst.index, Vector.<Number>([ time, time, time, 0 ]));
				_particleAnimation.setRenderState(stage3DProxy, renderable);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone() : AnimationStateBase
		{
			var clone : ParticleAnimationState = new ParticleAnimationState(ParticleAnimation(_animation));
			clone.time = time;
			return clone;
		}
		
	}

}
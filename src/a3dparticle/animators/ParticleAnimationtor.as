package a3dparticle.animators
{
	import away3d.animators.AnimatorBase;
	import away3d.animators.IAnimator;
	import away3d.animators.transitions.StateTransitionBase;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import flash.display3D.Context3DProgramType;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleAnimationtor extends AnimatorBase implements IAnimator
	{
		private var _particleAnimation:ParticleAnimation;
		
		//for multiple-pass-rendering
		public var offestTime:Number = 0;
		public var passCount:int = 0;
		
		
		public function ParticleAnimationtor(animationSet : ParticleAnimation)
		{
			super(animationSet);
			_particleAnimation = animationSet;
		}
		
		public function set absoluteTime(value:Number):void
		{
			_absoluteTime = value;
		}
		
		public function get absoluteTime():Number
		{
			return _absoluteTime;
		}

		public function play(stateName : String, stateTransition:StateTransitionBase = null) :void
		{
			throw(new Error("use start instead"));
		}
		
		public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			if (_particleAnimation.hasGen)
			{
				var actionTime:Number = _absoluteTime / 1000;
				if (passCount != 0)
					actionTime += offestTime;
				stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _particleAnimation.timeConst.index, Vector.<Number>([ actionTime, actionTime, actionTime, 0 ]));
				if (passCount == 0)
				{
					_particleAnimation.setRenderState(stage3DProxy, renderable);
				}
			}
		}
		
		override protected function updateDeltaTime(dt : Number) : void
		{
			absoluteTime += dt;
		}
		
		public function testGPUCompatibility(pass : MaterialPassBase) : void
		{
			
		}
		
	}

}
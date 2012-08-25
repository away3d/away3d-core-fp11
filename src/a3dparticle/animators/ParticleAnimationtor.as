package a3dparticle.animators
{
	import away3d.animators.AnimatorBase;
	import away3d.animators.IAnimator;
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
		private var _programConstantData:Vector.<Number>;
		
		//for multiple-pass-rendering
		public var offestTime:Number = 0;
		public var passCount:int = 0;
		
		
		public function ParticleAnimationtor(animationSet : ParticleAnimation)
		{
			super(animationSet);
			_particleAnimation = animationSet;
			_programConstantData = new Vector.<Number>(4, true);
			_programConstantData[3] = 0;
		}
		
		public function set absoluteTime(value:Number):void
		{
			_absoluteTime = value;
		}
		
		
		public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			if (_particleAnimation.hasGen)
			{
				var actionTime:Number = _absoluteTime / 1000;
				if (passCount != 0)
				{
					actionTime += offestTime;
				}
				
				_programConstantData[0] = actionTime;
				_programConstantData[1] = actionTime;
				_programConstantData[2] = actionTime;
				
				stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _particleAnimation.timeConst.index, _programConstantData);
				
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
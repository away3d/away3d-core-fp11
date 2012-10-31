package away3d.animators
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.data.ParticleStreamManager;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.states.ParticleStateBase;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.base.SubMesh;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import flash.display3D.Context3DProgramType;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleAnimator extends AnimatorBase implements IAnimator
	{
		
		private var _particleAnimationSet:ParticleAnimationSet;
		private var _renderParameter:ParticleRenderParameter = new ParticleRenderParameter;
		
		protected var _allParticleStates:Vector.<ParticleStateBase> = new Vector.<ParticleStateBase>;
		protected var _needTimeStates:Vector.<ParticleStateBase> = new Vector.<ParticleStateBase>;
		
		public function ParticleAnimator(animationSet:ParticleAnimationSet)
		{
			super(animationSet);
			_particleAnimationSet = animationSet;
			
			var state:ParticleStateBase;
			for each (var node:ParticleNodeBase in _particleAnimationSet.particleNodes)
			{
				state = getAnimationState(node) as ParticleStateBase;
				_allParticleStates.push(state);
				if (state.needUpdateTime)
					_needTimeStates.push(state);
			}
			
		}
		
		public function getAnimationStateByName(name:String):ParticleStateBase
		{
			return getAnimationState(_particleAnimationSet.getAnimation(name)) as ParticleStateBase;
		}
		
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:int, vertexStreamOffset:int, camera:Camera3D):void
		{
			var sharedSetting:ParticleAnimationSetting = _particleAnimationSet.sharedSetting;
			var activatedCompiler:ParticleAnimationCompiler = _particleAnimationSet.activatedCompiler;
			
			var subMesh:SubMesh = renderable as SubMesh;
			if (!subMesh)
				throw(new Error("Must be subMesh"));
			
			if (!_particleAnimationSet.streamDatas[subMesh.parentMesh.geometry])
			{
				_particleAnimationSet.generateStreamData(subMesh.parentMesh);
			}
			
			var streamManager:ParticleStreamManager = _particleAnimationSet.streamDatas[subMesh.parentMesh.geometry][subMesh.subGeometry];
			
			_renderParameter.activatedCompiler = activatedCompiler;
			_renderParameter.camera = camera;
			_renderParameter.sharedSetting = sharedSetting;
			_renderParameter.stage3DProxy = stage3DProxy;
			_renderParameter.streamManager = streamManager;
			_renderParameter.renderable = renderable;
			for each (var state:ParticleStateBase in _allParticleStates)
			{
				state.setRenderState(_renderParameter);
			}
			
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, activatedCompiler.vertexConstantOffset, activatedCompiler.vertexConstantData, activatedCompiler.usedVertexConstant);
			if (activatedCompiler.usedFragmentConstant > 0)
			{
				stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, activatedCompiler.fragmentConstantOffset, activatedCompiler.fragmentConstantData, activatedCompiler.usedFragmentConstant);
			}
		}
		
		public function testGPUCompatibility(pass:MaterialPassBase):void
		{
		
		}
		
		override public function start():void
		{
			super.start();
			for each (var state:ParticleStateBase in _needTimeStates)
			{
				state.offset(_absoluteTime);
			}
		}
		
		override protected function updateDeltaTime(dt:Number):void
		{
			_absoluteTime += dt;
			
			for each (var state:ParticleStateBase in _needTimeStates)
			{
				state.update(_absoluteTime);
			}
		}
		
	}

}

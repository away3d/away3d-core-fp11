package away3d.animators
{
	import away3d.animators.AnimatorBase;
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleConstantManager;
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.data.ParticleStreamManager;
	import away3d.animators.IAnimator;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.nodes.ParticleTimeNode;
	import away3d.animators.states.ParticleStateBase;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.base.SubMesh;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import flash.display3D.Context3DProgramType;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 */
	public class ParticleAnimator extends AnimatorBase implements IAnimator
	{
		
		private var _particleAnimationSet:ParticleAnimationSet;
		private var _renderParameter:ParticleRenderParameter=new ParticleRenderParameter;
		
		protected var _allParticleStates:Vector.<ParticleStateBase> = new Vector.<ParticleStateBase>;
		
		public function ParticleAnimator(animationSet : ParticleAnimationSet)
		{
			super(animationSet);
			_particleAnimationSet = animationSet;
			
			for each(var node:ParticleNodeBase in _particleAnimationSet.particleNodes)
			{
				_allParticleStates.push(getAnimationState(node));
			}
			
			_activeNode = _animationSet.getAnimation(ParticleTimeNode.NAME);
			_activeState = getAnimationState(_activeNode);
		}
		
		
		
		public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int, camera:Camera3D) : void
		{
			var sharedSetting:ParticleAnimationSetting = _particleAnimationSet.sharedSetting;
			var activatedCompiler:ParticleAnimationCompiler = _particleAnimationSet.activatedCompiler;
			var activatedConstantData:ParticleConstantManager = _particleAnimationSet.activatedConstantData;
			
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
			_renderParameter.constantData = activatedConstantData;
			for each(var state:ParticleStateBase in _allParticleStates)
			{
				state.setRenderState(_renderParameter);
			}
			
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, activatedConstantData.vertexConstantOffset, activatedConstantData.vertexConstantData, activatedConstantData.usedVertexConstant);
			if (activatedConstantData.usedFragmentConstant>0)
			{
				stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, activatedConstantData.fragmentConstantOffset, activatedConstantData.fragmentConstantData, activatedConstantData.usedFragmentConstant);
			}
		}
		
		
		public function testGPUCompatibility(pass : MaterialPassBase) : void
		{
			
		}
		
		override public function start() : void
		{
			super.start();
			_activeState.offset(this._absoluteTime);
		}
		
	}

}
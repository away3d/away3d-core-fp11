package away3d.animators
{
	import flash.utils.Dictionary;
	import away3d.entities.Mesh;
	import away3d.core.base.ParticleGeometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.data.ParticleData;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.states.ParticleStateBase;
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
		private var _animationParticleStates:Vector.<ParticleStateBase> = new Vector.<ParticleStateBase>;
		private var _animatorParticleStates:Vector.<ParticleStateBase> = new Vector.<ParticleStateBase>;
		private var _timeParticleStates:Vector.<ParticleStateBase> = new Vector.<ParticleStateBase>;
		private var _totalLenOfOneVertex:uint = 0;
		private var _animatorSubGeometries:Dictionary = new Dictionary(true);
		
		public function ParticleAnimator(animationSet:ParticleAnimationSet)
		{
			super(animationSet);
			_particleAnimationSet = animationSet;
			
			var state:ParticleStateBase;
			var node:ParticleNodeBase;
			for each (node in _particleAnimationSet.particleNodes)
			{
				state = getAnimationState(node) as ParticleStateBase;
				if (node.mode == ParticlePropertiesMode.LOCAL_DYNAMIC) {
					_animatorParticleStates.push(state);
					node.dataOffset = _totalLenOfOneVertex;
					_totalLenOfOneVertex += node.dataLength;
				} else {
					_animationParticleStates.push(state);
				}
				if (state.needUpdateTime)
					_timeParticleStates.push(state);
			}
			
		}
		
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:int, vertexStreamOffset:int, camera:Camera3D):void
		{
			var animationRegisterCache:AnimationRegisterCache = _particleAnimationSet.animationRegisterCache;
			
			var subMesh:SubMesh = renderable as SubMesh;
			var state:ParticleStateBase;
			
			if (!subMesh)
				throw(new Error("Must be subMesh"));
			
			//process animation sub geometries
			if (!subMesh.animationSubGeometry)
				_particleAnimationSet.generateAnimationSubGeometries(subMesh.parentMesh);
			
			var animationSubGeometry:AnimationSubGeometry = subMesh.animationSubGeometry;
			
			for each (state in _animationParticleStates)
				state.setRenderState(stage3DProxy, renderable, animationSubGeometry, animationRegisterCache, camera);
			
			//process animator subgeometries
			if (!subMesh.animatorSubGeometry && _animatorParticleStates.length)
				generateAnimatorSubGeometry(subMesh);
			
			var animatorSubGeometry:AnimationSubGeometry = subMesh.animatorSubGeometry;
			
			for each (state in _animatorParticleStates)
				state.setRenderState(stage3DProxy, renderable, animatorSubGeometry, animationRegisterCache, camera);
			
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, animationRegisterCache.vertexConstantOffset, animationRegisterCache.vertexConstantData, animationRegisterCache.numVertexConstant);
			
			if (animationRegisterCache.numFragmentConstant > 0)
				stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, animationRegisterCache.fragmentConstantOffset, animationRegisterCache.fragmentConstantData, animationRegisterCache.numFragmentConstant);
		}
		
		public function testGPUCompatibility(pass:MaterialPassBase):void
		{
		
		}
		
		override public function start():void
		{
			super.start();
			for each (var state:ParticleStateBase in _timeParticleStates)
			{
				state.offset(_absoluteTime);
			}
		}
		
		override protected function updateDeltaTime(dt:Number):void
		{
			_absoluteTime += dt;
			
			for each (var state:ParticleStateBase in _timeParticleStates)
			{
				state.update(_absoluteTime);
			}
		}
		
		public function resetTime(offset : int = 0) : void
		{
			for each (var state:ParticleStateBase in _timeParticleStates)
			{
				state.offset(_absoluteTime + offset);
			}
		}
		
		private function generateAnimatorSubGeometry(subMesh:SubMesh):void
		{
			var subGeometry:ISubGeometry = subMesh.subGeometry;
			var animatorSubGeometry:AnimationSubGeometry = subMesh.animatorSubGeometry = _animatorSubGeometries[subGeometry] = new AnimationSubGeometry();
			
			//create the vertexData vector that will be used for local state data
			animatorSubGeometry.createVertexData(subGeometry.numVertices, _totalLenOfOneVertex);
			
			//pass the particles data to the animator subGeometry
			animatorSubGeometry.animationParticles = subMesh.animationSubGeometry.animationParticles;
		}
	}

}

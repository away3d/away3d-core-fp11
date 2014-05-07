package away3d.animators
{
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.states.ParticleStateBase;
	import away3d.arcane;
	import away3d.core.base.ISubMesh;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.pool.IRenderable;
	import away3d.core.pool.RenderableBase;
	import away3d.entities.Camera3D;
	import away3d.materials.passes.MaterialPassBase;

	import flash.display3D.Context3DProgramType;

	import flash.utils.Dictionary;

	use namespace arcane;
	
	/**
	 * Provides an interface for assigning paricle-based animation data sets to mesh-based entity objects
	 * and controlling the various available states of animation through an interative playhead that can be
	 * automatically updated or manually triggered.
	 *
	 * Requires that the containing geometry of the parent mesh is particle geometry
	 *
	 * @see away3d.core.base.ParticleGeometry
	 */
	public class ParticleAnimator extends AnimatorBase implements IAnimator
	{
		
		private var _particleAnimationSet:ParticleAnimationSet;
		private var _animationParticleStates:Vector.<ParticleStateBase> = new Vector.<ParticleStateBase>;
		private var _animatorParticleStates:Vector.<ParticleStateBase> = new Vector.<ParticleStateBase>;
		private var _timeParticleStates:Vector.<ParticleStateBase> = new Vector.<ParticleStateBase>;
		private var _totalLenOfOneVertex:uint = 0;
		private var _animatorSubGeometries:Dictionary = new Dictionary(true);
		
		/**
		 * Creates a new <code>ParticleAnimator</code> object.
		 *
		 * @param particleAnimationSet The animation data set containing the particle animations used by the animator.
		 */
		public function ParticleAnimator(particleAnimationSet:ParticleAnimationSet)
		{
			super(particleAnimationSet);
			_particleAnimationSet = particleAnimationSet;
			
			var state:ParticleStateBase;
			var node:ParticleNodeBase;
			for each (node in _particleAnimationSet.particleNodes) {
				state = getAnimationState(node) as ParticleStateBase;
				if (node.mode == ParticlePropertiesMode.LOCAL_DYNAMIC) {
					_animatorParticleStates.push(state);
					node.dataOffset = _totalLenOfOneVertex;
					_totalLenOfOneVertex += node.dataLength;
				} else
					_animationParticleStates.push(state);
				if (state.needUpdateTime)
					_timeParticleStates.push(state);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():IAnimator
		{
			return new ParticleAnimator(_particleAnimationSet);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:RenderableBase, vertexConstantOffset:int, vertexStreamOffset:int, camera:Camera3D):void
		{
			var animationRegisterCache:AnimationRegisterCache = _particleAnimationSet._animationRegisterCache;
			
			var subMesh:ISubMesh = renderable as ISubMesh;
			var state:ParticleStateBase;
			
			if (!subMesh)
				throw(new Error("Must be subMesh"));
			
			//process animation sub geometries
			var animationSubGeometry:AnimationSubGeometry = _particleAnimationSet.getAnimationSubGeometry(subMesh);
			
			for each (state in _animationParticleStates)
				state.setRenderState(stage3DProxy, renderable, animationSubGeometry, animationRegisterCache, camera);
			
			//process animator subgeometries
			var animatorSubGeometry:AnimationSubGeometry = getAnimatorSubGeometry(subMesh);
			
			for each (state in _animatorParticleStates)
				state.setRenderState(stage3DProxy, renderable, animatorSubGeometry, animationRegisterCache, camera);
			
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, animationRegisterCache.vertexConstantOffset, animationRegisterCache.vertexConstantData, animationRegisterCache.numVertexConstant);
			
			if (animationRegisterCache.numFragmentConstant > 0)
				stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, animationRegisterCache.fragmentConstantOffset, animationRegisterCache.fragmentConstantData, animationRegisterCache.numFragmentConstant);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function testGPUCompatibility(pass:MaterialPassBase):void
		{
		
		}
		
		/**
		 * @inheritDoc
		 */
		override public function start():void
		{
			super.start();
			for each (var state:ParticleStateBase in _timeParticleStates)
				state.offset(_absoluteTime);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateDeltaTime(dt:Number):void
		{
			_absoluteTime += dt;
			
			for each (var state:ParticleStateBase in _timeParticleStates)
				state.update(_absoluteTime);
		}
		
		/**
		 * @inheritDoc
		 */
		public function resetTime(offset:int = 0):void
		{
			for each (var state:ParticleStateBase in _timeParticleStates)
				state.offset(_absoluteTime + offset);
			update(time);
		}
		
		override public function dispose():void
		{
			var subGeometry:AnimationSubGeometry;
			for each (subGeometry in _animatorSubGeometries)
				subGeometry.dispose();
		}
		
		private function getAnimatorSubGeometry(subMesh:ISubMesh):AnimationSubGeometry
		{
			if (!_animatorParticleStates.length) return null;

			var subGeometry:SubGeometryBase = subMesh.subGeometry;
			var animatorSubGeometry:AnimationSubGeometry = _animatorSubGeometries[subGeometry] = new AnimationSubGeometry();
			
			//create the vertexData vector that will be used for local state data
			animatorSubGeometry.createVertexData(subGeometry.numVertices, _totalLenOfOneVertex);
			
			//pass the particles data to the animator subGeometry
			animatorSubGeometry.animationParticles = _particleAnimationSet.getAnimationSubGeometry(subMesh).animationParticles;
			return animatorSubGeometry;
		}
	}

}

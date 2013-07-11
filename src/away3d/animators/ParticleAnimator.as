package away3d.animators
{
	import flash.display3D.*;
	import flash.utils.*;
	
	import away3d.*;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	import away3d.animators.states.*;
	import away3d.cameras.*;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.materials.passes.*;
	
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
		public function clone():IAnimator
		{
			return new ParticleAnimator(_particleAnimationSet);
		}
		
		/**
		 * @inheritDoc
		 */
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:int, vertexStreamOffset:int, camera:Camera3D):void
		{
			var animationRegisterCache:AnimationRegisterCache = _particleAnimationSet._animationRegisterCache;
			
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
		
		/**
		 * @inheritDoc
		 */
		public function testGPUCompatibility(pass:MaterialPassBase):void
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

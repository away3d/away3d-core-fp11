package away3d.animators
{
	import away3d.animators.states.*;
	import away3d.animators.transitions.*;
	import away3d.animators.data.*;
	import away3d.cameras.Camera3D;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.materials.*;
	import away3d.materials.passes.*;
	
	/**
	 * Provides an interface for assigning uv-based animation data sets to mesh-based entity objects
	 * and controlling the various available states of animation through an interative playhead that can be
	 * automatically updated or manually triggered.
	 */
	public class UVAnimator extends AnimatorBase implements IAnimator
	{
		private var _uvAnimationSet:UVAnimationSet;
		private var _deltaFrame : UVAnimationFrame = new UVAnimationFrame();
		private var _activeUVState:IUVAnimationState;
		
		/**
		 * Creates a new <code>UVAnimator</code> object.
		 *
		 * @param uvAnimationSet The animation data set containing the uv animations used by the animator.
		 */
		public function UVAnimator(uvAnimationSet:UVAnimationSet)
		{
			super(uvAnimationSet);
			
			_uvAnimationSet = uvAnimationSet;
		}
		
		/**
		 * @inheritDoc
		 */
		public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int, camera:Camera3D) : void
		{
			var material:TextureMaterial = renderable.material as TextureMaterial;
			var subMesh:SubMesh = renderable as SubMesh;
			
			if (!material || !subMesh)
				return;
			
			if (!material.animateUVs)
				material.animateUVs = true;
			
			subMesh.offsetU = _deltaFrame.offsetU;
			subMesh.offsetV = _deltaFrame.offsetV;
			subMesh.scaleU = _deltaFrame.scaleU;
			subMesh.scaleV = _deltaFrame.scaleV;
			subMesh.uvRotation = _deltaFrame.rotation;
		}
		
		/**
		 * @inheritDoc
		 */
		public function play(name : String, transition : IAnimationTransition = null, offset : Number = NaN) : void
		{
			if (_name == name)
				return;
			
			_name = name;
			
			if (!_animationSet.hasAnimation(name))
				throw new Error("Animation root node " + name + " not found!");
			
			_activeNode = _animationSet.getAnimation(name);
			
			_activeState = getAnimationState(_activeNode);
			
			_activeUVState = _activeState as IUVAnimationState;
			
			start();
		}
		
		/**
		 * Applies the calculated time delta to the active animation state node.
		 */
		override protected function updateDeltaTime(dt : Number) : void
		{
			_absoluteTime += dt;
			
			_activeUVState.update(_absoluteTime);
			
			var currentUVFrame : UVAnimationFrame = _activeUVState.currentUVFrame;
			var nextUVFrame : UVAnimationFrame = _activeUVState.currentUVFrame;
			var blendWeight : Number = _activeUVState.blendWeight;
			
			_deltaFrame.offsetU = currentUVFrame.offsetU + blendWeight * (nextUVFrame.offsetU - currentUVFrame.offsetU);
			_deltaFrame.offsetV = currentUVFrame.offsetV + blendWeight * (nextUVFrame.offsetV - currentUVFrame.offsetV);
			_deltaFrame.scaleU = currentUVFrame.scaleU + blendWeight * (nextUVFrame.scaleU - currentUVFrame.scaleU);
			_deltaFrame.scaleV = currentUVFrame.scaleV + blendWeight * (nextUVFrame.scaleV - currentUVFrame.scaleV);
			_deltaFrame.rotation = currentUVFrame.rotation + blendWeight * (nextUVFrame.rotation - currentUVFrame.rotation);
		}
						
        /**
         * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
		 * Needs to be called if gpu code is potentially required.
         */
        public function testGPUCompatibility(pass : MaterialPassBase) : void
        {
        }
	}
}
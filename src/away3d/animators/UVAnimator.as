package away3d.animators
{
	import away3d.materials.passes.MaterialPassBase;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.data.UVAnimationFrame;
	import away3d.animators.data.UVAnimationSequence;
	import away3d.animators.utils.TimelineUtil;
	import away3d.arcane;
	import away3d.core.base.SubMesh;
	import away3d.materials.TextureMaterial;

	use namespace arcane;
	
	public class UVAnimator extends AnimatorBase implements IAnimator
	{
		private var _target : SubMesh;
		private var _sequences : Object;
		private var _activeSequence : UVAnimationSequence;
		
		private var _tlUtil : TimelineUtil;
		private var _absoluteTime : Number;
		private var _deltaFrame : UVAnimationFrame;
		
		public function UVAnimator(target : SubMesh)
		{
			super(null);
			
			_target = target;
            // disable transform warning
            _target.uvRotation = 1;
            _target.uvRotation = 0;
			_sequences = {};
			_deltaFrame = new UVAnimationFrame();
			_tlUtil = new TimelineUtil();
		}
		
		public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			
		}
		
		
		public function addSequence(sequence : UVAnimationSequence) : void
		{
			_sequences[sequence.name] = sequence;
		}
		
		
		public function play(sequenceName : String) : void
		{
			var material : TextureMaterial = _target.material as TextureMaterial;

			_activeSequence = _sequences[sequenceName];

			if (material)
				material.animateUVs = true;

			reset();
			start();
		}
		
		override protected function updateAnimation(realDT:Number, scaledDT:Number):void
		{
			// TODO: not used
			realDT = realDT;
			
			var w : Number;
			var frame0 : UVAnimationFrame, frame1 : UVAnimationFrame;
			
			_absoluteTime += scaledDT;
			if (_absoluteTime >= _activeSequence._totalDuration)
				_absoluteTime %= _activeSequence._totalDuration;
			
			// TODO: not used
			//var frame : UVAnimationFrame;
			//var idx : uint;
			
			_tlUtil.updateFrames(_absoluteTime, _activeSequence);
			frame0 = _activeSequence._frames[_tlUtil.frame0];
			frame1 = _activeSequence._frames[_tlUtil.frame1];
			w = _tlUtil.blendWeight;
			
			_deltaFrame.offsetU = frame1.offsetU - frame0.offsetU;
			_deltaFrame.offsetV = frame1.offsetV - frame0.offsetV;
			_deltaFrame.scaleU = frame1.scaleU - frame0.scaleU;
			_deltaFrame.scaleV = frame1.scaleV - frame0.scaleV;
			_deltaFrame.rotation = frame1.rotation - frame0.rotation;
			
			// TODO: Find closest direction for rotation
			// TODO: Fix snap-back issue when looping
			
			_target.offsetU = frame0.offsetU + (w * _deltaFrame.offsetU);
			_target.offsetV = frame0.offsetV + (w * _deltaFrame.offsetV);
			_target.scaleU = frame0.scaleU + (w * _deltaFrame.scaleU);
			_target.scaleV = frame0.scaleV + (w * _deltaFrame.scaleV);
			_target.uvRotation = frame0.rotation + (w * _deltaFrame.rotation);
		}
						
        /**
         * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
		 * Needs to be called if gpu code is potentially required.
         */
        public function testGPUCompatibility(pass : MaterialPassBase) : void
        {
        }
		
		private function reset() : void
		{
			_absoluteTime = 0;
		}
	}
}
package away3d.animators
{
	import away3d.animators.data.UVAnimationFrame;
	import away3d.animators.data.UVAnimationSequence;
	import away3d.animators.utils.TimelineUtil;
	import away3d.arcane;
	import away3d.materials.BitmapMaterial;
	
	use namespace arcane;
	
	public class UVAnimator extends AnimatorBase
	{
		private var _target : BitmapMaterial;
		private var _sequences : Object;
		private var _activeSequence : UVAnimationSequence;
		
		private var _tlUtil : TimelineUtil;
		private var _absoluteTime : Number;
		private var _deltaFrame : UVAnimationFrame;
		
		
		public function UVAnimator(target : BitmapMaterial)
		{
			super();
			
			_target = target;
			_sequences = {};
			_deltaFrame = new UVAnimationFrame();
			_tlUtil = new TimelineUtil();
		}
		
		
		public function addSequence(sequence : UVAnimationSequence) : void
		{
			_sequences[sequence.name] = sequence;
		}
		
		
		public function play(sequenceName : String) : void
		{
			_activeSequence = _sequences[sequenceName];
			
			reset();
			start();
		}
		
		override protected function updateAnimation(realDT:Number, scaledDT:Number):void
		{
			var w : Number;
			var frame0 : UVAnimationFrame, frame1 : UVAnimationFrame;
			
			_absoluteTime += scaledDT;
			if (_absoluteTime >= _activeSequence._totalDuration)
				_absoluteTime %= _activeSequence._totalDuration;
			
			var frame : UVAnimationFrame;
			var idx : uint;
			
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
		
		
		private function reset() : void
		{
			_absoluteTime = 0;
		}
	}
}
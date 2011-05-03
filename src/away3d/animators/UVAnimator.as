package away3d.animators
{
	import away3d.animators.data.UVAnimationFrame;
	import away3d.animators.data.UVAnimationSequence;
	import away3d.arcane;
	import away3d.materials.BitmapMaterial;
	
	use namespace arcane;
	
	public class UVAnimator extends AnimatorBase
	{
		private var _target : BitmapMaterial;
		private var _sequences : Object;
		private var _activeSequence : UVAnimationSequence;
		
		private var _absoluteTime : Number;
		
		public function UVAnimator(target : BitmapMaterial)
		{
			super();
			
			_target = target;
			_sequences = {};
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
			// TODO: Interpolate
			_absoluteTime += scaledDT;
			if (_absoluteTime > _activeSequence._totalDuration)
				_absoluteTime %= _activeSequence._totalDuration;
			
			var frame : UVAnimationFrame;
			var idx : uint;
			
			idx = (_absoluteTime / _activeSequence._totalDuration) * _activeSequence._frames.length;
			frame = _activeSequence._frames[idx];
			
			_target.offsetU = frame.offsetU;
			_target.offsetV = frame.offsetV;
			_target.scaleU = frame.scaleU;
			_target.scaleV = frame.scaleV;
			_target.uvRotation = frame.rotation;
		}
		
		
		private function reset() : void
		{
			_absoluteTime = 0;
		}
	}
}
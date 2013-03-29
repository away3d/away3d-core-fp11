package away3d.animators.states
{
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	
	public class SpriteSheetAnimationState extends AnimationClipState implements ISpriteSheetAnimationState
	{
		private var _frames:Vector.<SpriteSheetAnimationFrame>;
		private var _clipNode : SpriteSheetClipNode;
		private var _currentFrameID : uint = 0;
		private var _reverse : Boolean;
		private var _back : Boolean;
		private var _backAndForth : Boolean;
		
		function SpriteSheetAnimationState(animator:IAnimator, clipNode:SpriteSheetClipNode)
		{
			super(animator, clipNode);
			
			_clipNode = clipNode;
			_frames = _clipNode.frames;
		}

		public function set reverse(b:Boolean):void
		{	
			_back = false;
			_reverse = b;
		}

		public function set backAndForth(b:Boolean):void
		{
			if(b) _reverse = false;
			_back = false;
			_backAndForth = b;
		}
		
		/**
		* @inheritDoc
		*/
		public function get currentFrameData() : SpriteSheetAnimationFrame
		{
			if (_framesDirty)
				updateFrames();
			
			return _frames[_currentFrameID];
		}
		
		public function get currentFrameNumber() : uint
		{
			return _currentFrameID;
		}
		
		
		/**
		* @inheritDoc
		*/
		override protected function updateFrames() : void
		{
			super.updateFrames();
			
			if(_reverse){

				if(_currentFrameID-1>-1){
					_currentFrameID--;
				} else if (_clipNode.looping){

					if(_backAndForth){
						_reverse = false;
					} else {
						_currentFrameID = _frames.length-1;	
					}
					
				}

			} else {

				if(_currentFrameID<_frames.length-1){
					_currentFrameID++;

				} else if (_clipNode.looping){

					if(_backAndForth){
						_reverse = true;
					} else {
						_currentFrameID = 0;
					}
					
				}
			}
			
			 
		}
	}
}
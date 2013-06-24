package away3d.audio.drivers
{
	import flash.events.EventDispatcher;
	import flash.geom.*;
	import flash.media.*;
	
	public class AbstractSound3DDriver extends EventDispatcher
	{
		protected var _ref_v:Vector3D;
		protected var _src:Sound;
		protected var _volume:Number;
		protected var _scale:Number;
		
		protected var _mute:Boolean;
		protected var _paused:Boolean;
		protected var _playing:Boolean;
		
		public function AbstractSound3DDriver()
		{
			_volume = 1;
			_scale = 1000;
			_playing = false;
		}
		
		public function get sourceSound():Sound
		{
			return _src;
		}
		
		public function set sourceSound(val:Sound):void
		{
			if (_src == val)
				return;
			
			_src = val;
		}
		
		public function get volume():Number
		{
			return _volume;
		}
		
		public function set volume(val:Number):void
		{
			_volume = val;
		}
		
		public function get scale():Number
		{
			return _scale;
		}
		
		public function set scale(val:Number):void
		{
			_scale = val;
		}
		
		public function get mute():Boolean
		{
			return _mute;
		}
		
		public function set mute(val:Boolean):void
		{
			if (_mute == val)
				return;
			
			_mute = val;
		}
		
		public function updateReferenceVector(v:Vector3D):void
		{
			this._ref_v = v;
		}
	}
}

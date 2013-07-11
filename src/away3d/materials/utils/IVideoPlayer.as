package away3d.materials.utils
{
	import flash.display.Sprite;
	import flash.media.SoundTransform;
	
	public interface IVideoPlayer
	{
		
		/**
		 * The source, url, to the video file
		 */
		function get source():String;
		
		function set source(src:String):void;
		
		/**
		 * Indicates whether the player should loop when video finishes
		 */
		function get loop():Boolean;
		
		function set loop(val:Boolean):void;
		
		/**
		 * Master volume/gain
		 */
		function get volume():Number;
		
		function set volume(val:Number):void;
		
		/**
		 * Panning
		 */
		function get pan():Number;
		
		function set pan(val:Number):void;
		
		/**
		 * Mutes/unmutes the video's audio.
		 */
		function get mute():Boolean;
		
		function set mute(val:Boolean):void;
		
		/**
		 * Provides access to the SoundTransform of the video stream
		 */
		function get soundTransform():SoundTransform;
		
		function set soundTransform(val:SoundTransform):void;
		
		/**
		 * Get/Set access to the with of the video object
		 */
		function get width():int;
		
		function set width(val:int):void;
		
		/**
		 * Get/Set access to the height of the video object
		 */
		function get height():int;
		
		function set height(val:int):void;
		
		/**
		 * Provides access to the Video Object
		 */
		function get container():Sprite;
		
		/**
		 * Indicates whether the video is playing
		 */
		function get playing():Boolean;
		
		/**
		 * Indicates whether the video is paused
		 */
		function get paused():Boolean;
		
		/**
		 * Returns the actual time of the netStream
		 */
		function get time():Number;
		
		/**
		 * Start playing (or resume if paused) the video.
		 */
		function play():void;
		
		/**
		 * Temporarily pause playback. Resume using play().
		 */
		function pause():void;
		
		/**
		 *  Seeks to a given time in the video, specified in seconds, with a precision of three decimal places (milliseconds).
		 */
		function seek(val:Number):void;
		
		/**
		 * Stop playback and reset playhead.
		 */
		function stop():void;
		
		/**
		 * Called if the player is no longer needed
		 */
		function dispose():void;
	
	}
}

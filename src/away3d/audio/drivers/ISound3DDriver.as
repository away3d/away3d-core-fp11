package away3d.audio.drivers
{
	import flash.events.IEventDispatcher;
	import flash.geom.*;
	import flash.media.*;

	public interface ISound3DDriver extends IEventDispatcher
	{
		/**
		 * The sound object (flash.media.Sound) to play at the point of the sound
		 * source. The output of this sound is modified by the driver before actual
		 * sound output.
		*/
		function get sourceSound() : Sound;
		function set sourceSound(val:Sound) : void;
		
		
		/**
		 * Arbitrary value by which all distances are divided. The default value of 
		 * 1000 is usually suitable for scenes with a scale that roughly matches the
		 * standard Away3D scale, i.e. that look good from the default camera position.
		*/
		function get scale() : Number;
		function set scale(val:Number) : void;
		
		
		/**
		 * Master volume/gain after 3D modifications to pan/volume have been applied.
		 * Modify this to raise or lower the overall volume regardless of where the
		 * sound source is located.
		*/
		function get volume() : Number;
		function set volume(val:Number) : void;
		
		
		
		/**
		 * Mutes/unmutes the driver completely, which is typically only done (internally
		 * by Sound3D) whenever the sound source is removed from the scene. When true, 
		 * any values set to the volume property will be ignored.
		*/
		function get mute() : Boolean;
		function set mute(val : Boolean) : void;
		
		
		
		
		/**
		 * Start playing (or resume if paused) the audio. This is NOT The same thing
		 * as invoking play() on the flash.media.Sound object used as the source sound
		 * for the driver.
		*/
		function play() : void;
		
		/**
		 * Temporarily pause playback. Resume using play(). 
		*/
		function pause() : void;
		
		/**
		 * Stop playback and reset playhead. Subsequent play() calls will restart the
		 * playback from the beginning of the sound file.
		*/
		function stop() : void;
		
		/**
		 * Change the position of the sound source relative to the listener, known as
		 * the reference vector. This is invoked by the Sound3D object when it's position
		 * changes, and should typically not be called by any other code.
		 * 
		 * @param v Sound source position vector relative to the listener.
		*/
		function updateReferenceVector(v:Vector3D) : void;
	}
}
package away3d.audio
{
	import away3d.audio.drivers.*;
	import away3d.core.base.*;
	import away3d.events.*;
	import away3d.containers.ObjectContainer3D;
	
	import flash.geom.*;
	import flash.media.*;

	/**
	 * <p>A sound source/emitter object that can be positioned in 3D space, and from which all audio
	 * playback will be transformed to simulate orientation.</p>
	 * 
	 * <p>The Sound3D object works much in the same fashion as primitives, lights and cameras, in that
	 * it can be added to a scene and positioned therein. It is the main object, in the 3D sound API,
	 * which the programmer will interact with.</p>
	 * 
	 * <p>Actual sound transformation is performed by a driver object, which is defined at the time of
	 * creation by the driver ini variable, the default being a simple pan/volume driver.</p>
	 * 
	 * @see SimplePanVolumeDriver  
	*/
	public class Sound3D extends ObjectContainer3D
	{
		private var _refv : Vector3D;
		private var _inv_ref_mtx : Matrix3D;
		private var _driver : ISound3DDriver;
		private var _reference : ObjectContainer3D;
		private var _sound : Sound;
		
		private var _paused : Boolean;
		private var _playing : Boolean;
		
		
		
		/**
		 * Create a Sound3D object, representing the sound source used for playback of a flash Sound object. 
		 * 
		 * @param sound 		The flash Sound object that is played back from this Sound3D object's position.
		 * For realistic results, this should be a <em>mono</em> (single-channel, non-stereo) sound stream.
		 * @param reference 	The reference, or "listener" object, typically a camera.
		 * @param driver		Sound3D driver to use when applying simulation effects. Defaults to SimplePanVolumeDriver.
		 * @param init 			[optional] An initialisation object for specifying default instance properties.
		*/
		public function Sound3D(sound:Sound, reference:ObjectContainer3D, driver : ISound3DDriver = null, volume:Number = 1, scale:Number = 1000)
		{
			
			_sound = sound;
			_reference = reference;
			_driver = driver || new SimplePanVolumeDriver();
			_driver.sourceSound = _sound;
			_driver.volume = volume;
			_driver.scale = scale;
			
			_refv = new Vector3D;
			_inv_ref_mtx = new Matrix3D;
			
			
			//this.addEventListener(Object3DEvent.SCENE_CHANGED, _onSceneChanged);
			//this.addEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, _onSceneTransformChanged);
		}
		
		
		
		
		/**
		 * Defines the overall (master) volume of the 3D sound, after any
		 * positional adjustments to volume have been applied. This value can
		 * equally well be cotrolled by modifying the volume property on the
		 * driver used by this Sound3D instance.
		 * 
		 * @see ISound3DDriver.volume
		*/
		public function get volume() : Number
		{
			return _driver.volume;
		}
		public function set volume(val : Number) : void
		{
			_driver.volume = val;
		}
		
		
		
		/**
		 * Defines a scale value used by the driver when adjusting sound 
		 * intensity to simulate distance. The default number of 1000 means
		 * that sound volume will near the hearing threshold as the distance
		 * between listener and sound source approaches 1000 Away3D units.
		 * 
		 * @see ISound3DDriver.scale
		*/ 
		public function get scaleDistance() : Number
		{
			return _driver.scale;
		}
		public function set scaleDistance(val : Number) : void
		{
			_driver.scale = val;
		}
		
		
		/**
		 * Returns a boolean indicating whether or not the sound is currently
		 * playing.
		*/
		public function get playing() : Boolean
		{
			return _playing;
		}
		
		
		/**
		 * Returns a boolean indicating whether or not playback is currently
		 * paused.
		*/
		public function get paused() : Boolean
		{
			return _paused;
		}
		
		
		/**
		 * Start (or resume, if paused) playback. 
		*/
		public function play() : void
		{
			_playing = true;
			_paused = false;
			_driver.play();
		}
		
		
		/**
		 * Pause playback. Resume using play(). 
		*/
		public function pause() : void
		{
			_playing = false;
			_paused = true;
			_driver.pause();
		}
		
		
		/**
		 * Stop and rewind sound file. Replay (from the beginning) using play().
		 * To temporarily pause playback, allowing you to resume from the same point,
		 * use pause() instead.
		 * 
		 * @see pause()
		*/
		public function stop() : void
		{
			_playing = false;
			_paused = false;
			_driver.stop();
		}
		
		
		
		/**
		 * Alternate between pausing and resuming playback of this sound. If called
		 * while sound is paused (or stopped), this will resume playback. When 
		 * called during playback, it will pause it.
		*/
		public function togglePlayPause() : void
		{
			if (_playing)
				this.pause();
			else this.play();
		}
		
		
		
		
		/**
		 * @internal
		 * When scene changes, mute if object was removed from scene. 
		*/
		/*
		private function _onSceneChanged(ev : Object3DEvent) : void
		{
			// mute driver if there is no scene available, i.e. when the
			// sound3d object has been removed from the scene
			_driver.mute = (this.arcane::_scene == null);
			
			// Re-update reference vector to force changes to take effect
			_driver.updateReferenceVector(_refv);
		}
		*/
		
		/**
		 * @internal
		 * When scene transform changes, calculate the relative vector between the listener/reference object
		 * and the position of this sound source, and update the driver to use
		 * this as the reference vector.
		 */
		
		// WORK AROUND WHILE EVENTS ARE ADDED
		public function update():void
		{
			_inv_ref_mtx.rawData = _reference.sceneTransform.rawData;
			_inv_ref_mtx.invert();
			_refv = _inv_ref_mtx.deltaTransformVector(_reference.position);
			_refv = this.scenePosition.subtract(_refv);
			_driver.updateReferenceVector(_refv);
		}
		
		/*
		private function _onSceneTransformChanged(ev : Object3DEvent) : void
		{
			_inv_ref_mtx.rawData = _reference.sceneTransform.rawData;
			_inv_ref_mtx.invert();
			_refv = _inv_ref_mtx.deltaTransformVector(_reference.position);
			_refv = this.scenePosition.subtract(_refv);
			_driver.updateReferenceVector(_refv);
		}
		*/
	}
}
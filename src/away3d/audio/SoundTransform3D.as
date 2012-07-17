package away3d.audio
{
	import away3d.containers.ObjectContainer3D;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.media.SoundTransform;

	/**
	 * SoundTransform3D is a convinience class that helps adjust a Soundtransform's volume and pan according
	 * position and distance of a listener and emitter object. See SimplePanVolumeDriver for the limitations
	 * of this method.
	 */	
	public class SoundTransform3D
	{
		
		private var _scale : Number;
		private var _volume : Number;
		private var _soundTransform : SoundTransform;
		// TODO not used
		// private var _targetSoundTransform : SoundTransform;
		
		private var _emitter : ObjectContainer3D;
		private var _listener : ObjectContainer3D;
		
		
		private var _refv : Vector3D;
		private var _inv_ref_mtx : Matrix3D;
		private var _r : Number;
		private var _r2 : Number;
		private var _azimuth : Number;
		
		
		/**
		 * Creates a new SoundTransform3D. 
		 * @param emitter the ObjectContainer3D from which the sound originates.
		 * @param listener the ObjectContainer3D considered to be to position of the listener (usually, the camera)
		 * @param volume the maximum volume used. 
		 * @param scale the distance that the sound covers.
		 * 
		 */		
		public function SoundTransform3D(emitter:ObjectContainer3D = null, listener:ObjectContainer3D = null, volume:Number = 1, scale:Number = 1000)
		{
			
			_emitter = emitter;
			_listener = listener;
			_volume = volume;
			_scale = scale;
			
			_inv_ref_mtx = new Matrix3D();
			_refv = new Vector3D();
			_soundTransform = new SoundTransform(volume);
			
			_r = 0;
			_r2 = 0;
			_azimuth = 0;
			
		}
		
		
		/**
		 * updates the SoundTransform based on the emitter and listener. 
		 */
		public function update():void
		{
			
			if( _emitter && _listener )
			{
				_inv_ref_mtx.rawData = _listener.sceneTransform.rawData;
				_inv_ref_mtx.invert();
				_refv = _inv_ref_mtx.deltaTransformVector(_listener.position);
				_refv = _emitter.scenePosition.subtract(_refv);
			}
			
			updateFromVector3D( _refv );
		}
		
		/**
		 * udpates the SoundTransform based on the vector representing the distance and 
		 * angle between the emitter and listener.
		 *  
		 * @param v Vector3D
		 * 
		 */		
		public function updateFromVector3D(v:Vector3D):void
		{
			
			_azimuth = Math.atan2(v.x, v.z);
			if (_azimuth < -1.5707963)
				_azimuth = -(1.5707963 + (_azimuth % 1.5707963));
			else if (_azimuth > 1.5707963)
				_azimuth = 1.5707963 - (_azimuth % 1.5707963);
			
			// Divide by a number larger than pi/2, to make sure
			// that pan is never full +/-1.0, muting one channel
			// completely, which feels very unnatural. 
			_soundTransform.pan = (_azimuth/1.7);
			
			// Offset radius so that max value for volume curve is 1,
			// (i.e. y~=1 for r=0.) Also scale according to configured
			// driver scale value.
			_r = (v.length / _scale) + 0.28209479;
			_r2 = _r*_r;
			
			// Volume is calculated according to the formula for
			// sound intensity, I = P / (4 * pi * r^2)
			// Avoid division by zero.
			if (_r2>0) 	_soundTransform.volume = (1 / (12.566 * _r2));		// 1 / 4pi * r^2
			else  		_soundTransform.volume = 1;
			
			// Alter according to user-specified volume
			_soundTransform.volume *= _volume;
			
		}
		

		public function get soundTransform():SoundTransform
		{
			
			return _soundTransform;
		}

		public function set soundTransform(value:SoundTransform):void
		{
			_soundTransform = value;
			update();
		}

		public function get scale():Number
		{
			return _scale;
		}

		public function set scale(value:Number):void
		{
			_scale = value;
			update();
		}

		public function get volume():Number
		{
			return _volume;
		}

		public function set volume(value:Number):void
		{
			_volume = value;
			update();
		}

		public function get emitter():ObjectContainer3D
		{
			return _emitter;
		}

		public function set emitter(value:ObjectContainer3D):void
		{
			_emitter = value;
			update();
		}

		public function get listener():ObjectContainer3D
		{
			return _listener;
		}

		public function set listener(value:ObjectContainer3D):void
		{
			_listener = value;
			update();
		}

		
	}
}
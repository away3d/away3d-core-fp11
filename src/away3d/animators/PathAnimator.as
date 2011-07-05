package away3d.animators
{
	import away3d.core.base.Object3D;
	import away3d.events.PathEvent;
	import away3d.extrusions.utils.Path;
	import away3d.extrusions.utils.PathSegment;
	import away3d.extrusions.utils.PathUtils;

	import flash.events.EventDispatcher;
	import flash.geom.Vector3D;

	public class PathAnimator extends EventDispatcher
	{
		private var _path:Path;
		private var _time:Number;
		private var _index:uint = 0;
		private var _rotations:Vector.<Vector3D>;
		private var _lookAt:Boolean;
		private var _alignToPath:Boolean;
		private var _target:Object3D;
		private var _lookAtTarget:Object3D;
		private var _offset:Vector3D;
		private var _tmpOffset:Vector3D;
		private var _position:Vector3D = new Vector3D();
		private var _lastTime:Number;
		private var _from:Number;
		private var _to:Number;
		private var _bRange:Boolean;
		private var _bSegment:Boolean;
		private var _bCycle:Boolean;
		private var _lastSegment:uint = 0;
		private var _rot:Vector3D;
		private var _worldAxis:Vector3D;
		private var _basePosition:Vector3D = new Vector3D(0,0,0);
		 
		/**
		* Creates a new <PathAnimator>PathAnimator</code>
		* 
		* @param	 			[optional] path					The path to animate onto.
		* @param	 			[optional] target					An Object3D, the object to animate along the path. It can be Mesh, Camera, ObjectContainer3D...
		* @param	 			[optional] alignToPath			Defines if the object animated along the path is orientated to the path. Default is true.
		* @param	 			[optional] lookAtTarget		An Object3D that the target will constantly look at during animation.
		* @param	 			[optional] offset					A Vector3D to define the target offset to its location on the path.
		* @param	 			[optional] rotations				A Vector.<Vector3D> to define rotations per pathsegments. If PathExtrude is used to simulate the "road", use the very same rotations vector.
		*/
		function PathAnimator(path:Path = null, target:Object3D = null, offset:Vector3D = null, alignToPath:Boolean = true, lookAtTarget:Object3D = null, rotations:Vector.<Vector3D> = null)
		{
			_index = 0;
			_time= _lastTime=0;
			 
			_path = path;
			if(_path) _worldAxis = _path.worldAxis;
			
			_target = target;
			_alignToPath = alignToPath;
			_lookAtTarget = lookAtTarget;
			
			if(offset) setOffset(offset.x, offset.y, offset.z);
				 
			this.rotations = rotations;
			
			if(_lookAtTarget && _alignToPath) _alignToPath = false;
			
		}
		 
		/**
    	* sets an optional offset to the position on the path, ideal for cameras or reusing the same <code>Path</code> object for parallel animations
    	*/
		public function setOffset(x:Number = 0, y:Number = 0, z:Number = 0):void
		{
			if(!_offset) _offset = new Vector3D();
			
			_offset.x = x;
			_offset.y = y;
			_offset.z = z;
		}
		 
		/**
    	* Calculates the new position and set the object on the path accordingly
		*
		* @param t 	A Number  from 0 to 1  (less than one to allow alignToPath)
    	*/
		public function updateProgress(t:Number):void
		{
			if(!_path)  throw new Error("No Path object set for this class");
			
			if(t<= 0){
				t = 0;
				_lastSegment = 0;
			} else if( t>=1){
				t = 1;
				_lastSegment = _path.length-1;
			}
			
			if( _bCycle && t<=0.1 && _lastSegment == _path.length-1) 
				dispatchEvent(new PathEvent(PathEvent.CYCLE));
			
			_lastTime = t;
			
			var multi:Number = _path.length*t;
			_index = multi;
			
			if(_index == _path.length) index --;
			 
			if(_offset != null)
				_target.position = _basePosition;
			
			var nT:Number = multi-_index;
			updatePosition(nT, PathSegment(_path.segments[_index]) );
		
			var rotate:Boolean;
			if (_lookAtTarget) {
				if (_offset) {
					_target.moveRight(_offset.x);
					_target.moveUp(_offset.y);
					_target.moveForward(_offset.z);
				}
				_target.lookAt(_lookAtTarget.position);
				
			} else if (_alignToPath) {
	
				if(_rotations && _rotations.length>0 ){
					
					if(_rotations[_index+1] == null){
						
						 _rot.x = _rotations[_rotations.length-1].x*nT;
						 _rot.y = _rotations[_rotations.length-1].y*nT;
						 _rot.z = _rotations[_rotations.length-1].z*nT;
						 
					} else {
						 
						_rot.x = _rotations[_index].x +   ((_rotations[_index+1].x -_rotations[_index].x)*nT);
						_rot.y = _rotations[_index].y +   ((_rotations[_index+1].y -_rotations[_index].y)*nT);
						_rot.z = _rotations[_index].z +   ((_rotations[_index+1].z -_rotations[_index].z)*nT);
						 
					}
					 
					_worldAxis.x = 0;
					_worldAxis.y = 1;
					_worldAxis.z = 0;
					_worldAxis = PathUtils.rotatePoint(_worldAxis, _rot);
					
					_target.lookAt(_basePosition, _worldAxis);
					
					rotate = true;
					
				} else {
					 _target.lookAt(_position);
				}
				 
			}				
			
			updateObjectPosition(rotate);
			
			if(_bSegment && _index > 0 && _lastSegment != _index && t < 1)
				dispatchEvent(new PathEvent(PathEvent.CHANGE_SEGMENT));
			 
			if(_bRange &&(t >= _from && t <= _to))
				dispatchEvent(new PathEvent(PathEvent.RANGE));
					
			_time = t;
			_lastSegment = _index;
		}
		
		/**
    	* Updates a position Vector3D on the path at a given time. Do not use this handler to animate, it's in there to add dummy's or place camera before or after
		* the animated object. Use the update() or the automatic tweened animateOnPath() handlers instead.
		*
		* @param t		Number. A Number  from 0 to 1
		* @param out	Vector3D. The Vector3D to update according to the "t" time parameter.
    	*/
		public function getPositionOnPath( t:Number, out:Vector3D):Vector3D
		{
			if(!_path)  throw new Error("No Path object set for this class");
			
			t = (t<0)? 0 : (t>1)?1 : t;
			var m:Number = _path.length*t;
			var i:uint = m;
			var ps:PathSegment = _path.segments[i];
			 
			return calcPosition(m-i, ps, out);
		}
		
		/**
		 * Returns a position on the path according to duration/elapsed time. Duration variable must be set.
		 * 
		 * @param		ms			Number. A number representing milliseconds.
		 * @param		duration		Number. The total duration in milliseconds.
		 * @param		out			[optional] Vector3D. A Vector3D that will be used to return the position. If none provided, method returns a new Vector3D with this data.
		 *
		 * An example of use of this handler would be cases where a given "lap" must be done in a given amount of time and you would want to retrieve the "ideal" time
		 * based on elapsed time since start of the race. By comparing actual progress to ideal time, you could extract their classement, calculate distance/time between competitors,
		 * abort the race if goal is impossible to be reached in time etc...
		 *
		 *@ returns Vector3D The position at a given elapsed time, compared to total duration.
		 */
		public function getPositionOnPathMS( ms:Number, duration:Number, out:Vector3D):Vector3D
        {
			if(!_path) throw new Error("No Path object set for this class");
			
            var t:Number = Math.abs(ms)/duration;
            t = (t<0)? 0 : (t>1)?1 : t;
            var m:Number = _path.length*t;
            var i:uint = m;
            var ps:PathSegment = _path.segments[i];
            
			return calcPosition(m-i, ps, out);
        }
		
		/**
    	* defines if the object animated along the path must be aligned to the path.
    	*/
		public function set alignToPath(b:Boolean):void
		{
			_alignToPath = b;
		}
		public function get alignToPath():Boolean
		{
			return _alignToPath;
		}
		
		/**
    	* returns the current interpolated position on the path with no optional offset applied
    	*/
		public function get position():Vector3D
		{
			return _position;
		}
		
		/**
    	* defines the path to follow
		* @see Path
    	*/
		public function set path(p:Path):void
		{
			_path = p;
			_worldAxis = _path.worldAxis;
		}
		public function get path():Path
		{
			return _path;
		}

		/**
    	* Represents the progress of the animation playhead from the start (0) to the end (1) of the animation.
    	*/
        public function get progress():Number
        {
            return _time;
        }
        public function set progress(val:Number):void
        {
        	if (_time == val)
        		return;
        	
        	updateProgress(val);
        }
		
		/**
    	* returns the segment index that is used at a given time;
		* @param	 t		[Number]. A Number between 0 and 1. If no params, actual pathanimator time segment index is returned.
    	*/
		public function getTimeSegment(t:Number = NaN):Number
		{
			t = (isNaN(t))? _time : t;
			return Math.floor(path.length*t);
		}
		 
		/**
    	* returns the actual interpolated rotation along the path.
    	*/
		public function get orientation():Vector3D
		{
			return _rot;
		}
		 
		/**
    	* sets the object to be animated along the path.
    	*/
		public function set target(object3d:Object3D):void
		{
			_target = target;
		}
		public function get target():Object3D
		{
			return _target;
		}
		
		/**
    	* sets the object that the animated object will be looking at along the path
    	*/
		public function set lookAtObject(object3d:Object3D):void
		{
			_lookAtTarget = object3d;
			if(_alignToPath) _alignToPath = false;
		}
		public function get lookAtObject():Object3D
		{
			return _lookAtTarget;
		}
		
		/**
    	* sets an optional Vector.<Vector3D> of rotations. if the object3d is animated along a PathExtrude object, use the very same vector to follow the "curves".
    	*/
		public function set rotations(vRot:Vector.<Vector3D>):void
		{
			_rotations = vRot;
			
			if(_rotations && !_rot ) {
				_rot = new Vector3D();
				_tmpOffset = new Vector3D();
			}
		}
		 
		/**
    	* Set the pointer to a given segment along the path
    	*/
		public function set index(val:uint):void
		{
			_index = (val > _path.length - 1)? _path.length - 1 : (val > 0)? val : 0;
		}
		public function get index():uint
		{
			return _index;
		}
		
		/**
		 * Default method for adding a cycle event listener. Event fired when the time reaches 1.
		 * 
		 * @param	listener		The listener function
		 */
		public function addOnCycle(listener:Function):void
        {
			_lastTime = 0;
			_bCycle = true;
			this.addEventListener(PathEvent.CYCLE, listener);
        }
		
		/**
		 * Default method for removing a cycle event listener
		 * 
		 * @param		listener		The listener function
		 */
		public function removeOnCycle(listener:Function):void
        {
			_bCycle = false;
            this.removeEventListener(PathEvent.CYCLE, listener);
        }
		
		/**
		* Default method for adding a range event listener. Event fired when the time is >= from and <= to variables.
		* 
		* @param		listener		The listener function
		*/
		//note: If there are requests for this, it could be extended to more than one rangeEvent per path. 
		public function addOnRange(listener:Function, from:Number = 0, to:Number = 0):void
        {
			_from = from;
			_to = to;
			_bRange = true;
			this.addEventListener(PathEvent.RANGE, listener);
        }
		
		/**
		 * Default method for removing a range event listener
		 * 
		 * @param		listener		The listener function
		 */
		public function removeOnRange(listener:Function):void
        {
			_from = 0;
			_to = 0;
			_bRange = false;
            this.removeEventListener(PathEvent.RANGE, listener);
        }
		
		/**
		 * Default method for adding a segmentchange event listener. Event fired when the time pointer enters another PathSegment.
		 * 
		 * @param		listener		The listener function
		 */
		public function addOnChangeSegment(listener:Function):void
        {
			_bSegment = true;
			_lastSegment = 0;
			this.addEventListener(PathEvent.CHANGE_SEGMENT, listener);
        }
		
		/**
		* Default method for removing a range event listener
		* 
		* @param		listener		The listener function
		*/
		public function removeOnChangeSegment(listener:Function):void
        {
			_bSegment = false;
			_lastSegment = 0;
            this.removeEventListener(PathEvent.CHANGE_SEGMENT, listener, false);
        }
		
		private function calcPosition( t:Number, ps:PathSegment, out:Vector3D):Vector3D
        {
			var dt:Number = 2 * (1 - t);
			var v:Vector3D = out || new Vector3D();
            v.x = ps.pStart.x + t * (dt * (ps.pControl.x - ps.pStart.x) + t * (ps.pEnd.x - ps.pStart.x));
            v.y = ps.pStart.y + t * (dt * (ps.pControl.y - ps.pStart.y) + t * (ps.pEnd.y - ps.pStart.y));
            v.z = ps.pStart.z + t * (dt * (ps.pControl.z - ps.pStart.z) + t * (ps.pEnd.z - ps.pStart.z));
			
			return v;
        }
		 
		private function updatePosition(t:Number, ps:PathSegment ):void
		{
			_basePosition = calcPosition( t, ps, _basePosition);
			 
			_position.x = _basePosition.x;
			_position.y = _basePosition.y;
			_position.z = _basePosition.z;
		}
		
		private function updateObjectPosition(rotate:Boolean = false):void{
			
			if(rotate && _offset){
				
				 _tmpOffset.x = _offset.x;
				 _tmpOffset.y = _offset.y;
				 _tmpOffset.z = _offset.z;
				 _tmpOffset = PathUtils.rotatePoint(  _tmpOffset, _rot);
				 
				 _position.x += _tmpOffset.x;
				 _position.y += _tmpOffset.y;
				 _position.z += _tmpOffset.z;
				 
			} else if(_offset) {
				
				_position.x += _offset.x;
				_position.y += _offset.y;
				_position.z += _offset.z;
				
			} 
			_target.position = _position;
		}
		
	}
}
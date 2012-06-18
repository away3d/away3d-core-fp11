package away3d.extrusions.utils
{
	import away3d.extrusions.utils.QuadraticPathSegment;

	import flash.geom.Vector3D;

	//import away3d.containers.Scene3D;
	//import away3d.extrusions.utils.PathDebug;

	/**
	 * Holds information about a single Path definition.
	 * DEBUG OPTION OUT AT THIS TIME OF DEV
	 */
    public class QuadraticPath implements IPath
    {
		/**
		 * Creates a new <code>Path</code> object.
		 * 
		 * @param	 aVectors		[optional] An array of a series of Vector3D's organized in the following fashion. [a,b,c,a,b,c etc...] a = pEnd, b=pControl (control point), c = v2
		 */
		 
        public function QuadraticPath(aVectors:Vector.<Vector3D> = null)
        {
			_segments = new Vector.<IPathSegment>();
			
			if(aVectors)
				pointData = aVectors;
        }
		
		 
		//private var _pathDebug:PathDebug;
		 
        private var _segments:Vector.<IPathSegment>;
		
		/**
    	 * The worldAxis of reference
    	 */
		private var _worldAxis:Vector3D = new Vector3D(0,1,0);
    	
		
        private var _smoothed:Boolean;
		/**
    	 * returns true if the smoothPath handler is being used.
    	 */
		public function get smoothed():Boolean
		{
			return _smoothed;
		}
		
		private var _averaged:Boolean;
		/**
    	* returns true if the averagePath handler is being used.
    	*/
		public function get averaged():Boolean
		{
			return _averaged;
		}
		
		/**
		 * display the path in scene
		 */
		/*public function debugPath(scene:Scene3D):void
        {
			_pathDebug = new PathDebug(scene, this);
        }*/
		/**
		 * Defines if the anchors must be displayed if debugPath has been called. if false, only curves are displayed
		 */
		/*public function get showAnchors():Boolean
        {
			if(!_pathDebug)
				throw new Error("Patheditor not set yet! Use Path.debugPath() method first");
				
			return _pathDebug.showAnchors;
		}
		public function set showAnchors(b:Boolean):void
        {
			if(!_pathDebug)
				throw new Error("Patheditor not set yet! Use Path.debugPath() method first");
			
			_pathDebug.showAnchors = b;
        }
		 */
		/**
		 * Defines if the path data must be visible or not if debugPath has been called
		 */
		 /*
		public function get display():Boolean
        {
			return _pathDebug.display;
		}
		public function set display(b:Boolean):void
        {
			if(!_pathDebug)
				throw new Error("Patheditor not set yet! Use Path.debugPath() method first");
			
			_pathDebug.display = b;
        }*/
		
		 
		/**
		 * adds a PathSegment to the path
		 * @see QuadraticPathSegment:
		 */
		public function add(segment:IPathSegment):void
        {
			_segments.push(segment);
        }
		
		/**
		 * returns the length of the Path elements array
		 * 
		 * @return	an integer: the length of the Path elements array
		 */
		public function get length():uint
        {
			return _segments.length;
        }
		
		/**
		 * returns the Vector.&lt;PathSegment&gt; holding the elements (PathSegment) of the path
		 * 
		 * @return	a Vector.&lt;PathSegment&gt;: holding the elements (PathSegment) of the path
		 */
		public function get segments():Vector.<IPathSegment>
        {
			return _segments;
        }
		
		/**
		 * returns a given PathSegment from the path (PathSegment holds 3 Vector3D's)
		 * 
		 * @param	 indice uint. the indice of a given PathSegment		
		 * @return	given PathSegment from the path
		 */
		public function getSegmentAt(indice:uint):IPathSegment
        {
			return _segments[indice];
        }
        
		/**
		 * removes a segment in the path according to id.
		 *
		 * @param	 index	int. The index in path of the to be removed curvesegment 
		 * @param	 join 		Boolean. If true previous and next segments coordinates are reconnected
		 */
		public function removeSegment(index:int, join:Boolean = false):void
        {
			if(_segments.length == 0 || _segments[index ] == null )
				return;
			
			if(join && index < _segments.length-1 && index>0){
				var seg:QuadraticPathSegment = _segments[index] as QuadraticPathSegment;
				var prevSeg:QuadraticPathSegment = _segments[index-1] as QuadraticPathSegment;
				var nextSeg:QuadraticPathSegment = _segments[index+1] as QuadraticPathSegment;
				prevSeg.pControl.x = (prevSeg.pControl.x+seg.pControl.x)*.5;
				prevSeg.pControl.y = (prevSeg.pControl.y+seg.pControl.y)*.5;
				prevSeg.pControl.z = (prevSeg.pControl.z+seg.pControl.z)*.5;
				nextSeg.pControl.x = (nextSeg.pControl.x+seg.pControl.x)*.5;
				nextSeg.pControl.y = (nextSeg.pControl.y+seg.pControl.y)*.5;
				nextSeg.pControl.z = (nextSeg.pControl.z+seg.pControl.z)*.5;
				prevSeg.pEnd.x = (seg.pStart.x + seg.pEnd.x)*.5;
				prevSeg.pEnd.y = (seg.pStart.y + seg.pEnd.y)*.5;
				prevSeg.pEnd.z = (seg.pStart.z + seg.pEnd.z)*.5;
				nextSeg.pStart.x = prevSeg.pEnd.x;
				nextSeg.pStart.y = prevSeg.pEnd.y;
				nextSeg.pStart.z = prevSeg.pEnd.z;
				
				/*if(_pathDebug != null)
					_pathDebug.updateAnchorAt(index-1);
					_pathDebug.updateAnchorAt(index+1);*/
			}
			
			if(_segments.length > 1){
				_segments.splice(index, 1);
			} else{
				_segments = new Vector.<IPathSegment>();
			}
        }
		
		/**
		 * handler will smooth the path using anchors as control vector of the PathSegments 
		 * note that this is not dynamic, the PathSegments values are overwrited
		 */
		public function smoothPath():void
        {
			if(_segments.length <= 2)
				return;
			 
			_smoothed = true;
			_averaged = false;
			 
			var x:Number;
			var y:Number;
			var z:Number;
			var seg0:Vector3D;
			var seg1:Vector3D;
			var tmp:Vector.<Vector3D> = new Vector.<Vector3D>();
			var i:uint;

			var seg:QuadraticPathSegment = _segments[0] as QuadraticPathSegment;
			var segnext:QuadraticPathSegment = _segments[_segments.length-1] as QuadraticPathSegment;

			var startseg:Vector3D = new Vector3D(seg.pStart.x, seg.pStart.y, seg.pStart.z);
			var endseg:Vector3D = new Vector3D(segnext.pEnd.x, segnext.pEnd.y, segnext.pEnd.z);

			for(i = 0; i< length-1; ++i)
			{
				seg = _segments[i] as QuadraticPathSegment;
				segnext = _segments[i + 1] as QuadraticPathSegment;

				if(seg.pControl == null)
					seg.pControl = seg.pEnd;
				
				if(segnext.pControl == null)
					segnext.pControl = segnext.pEnd;
				
				seg0 = seg.pControl;
				seg1 = segnext.pControl;
				x = (seg0.x + seg1.x) * .5;
				y = (seg0.y + seg1.y) * .5;
				z = (seg0.z + seg1.z) * .5;
				
				tmp.push( startseg,  new Vector3D(seg0.x, seg0.y, seg0.z), new Vector3D(x, y, z));
				startseg = new Vector3D(x, y, z);
				seg = null;
			}
			
			seg0 = QuadraticPathSegment(_segments[_segments.length-1]).pControl;
			tmp.push( startseg,  new Vector3D((seg0.x+seg1.x)*.5, (seg0.y+seg1.y)*.5, (seg0.z+seg1.z)*.5), endseg);
			
			_segments = new Vector.<IPathSegment>();
			
			for(i = 0; i<tmp.length; i+=3)
				_segments.push( new QuadraticPathSegment(tmp[i], tmp[i+1], tmp[i+2]) );
			 
			tmp = null;
		}
		
		/**
		 * handler will average the path using averages of the PathSegments
		 * note that this is not dynamic, the path values are overwrited
		 */
		public function averagePath():void
        {
			_averaged = true;
			_smoothed = false;

			var seg:QuadraticPathSegment;

			for(var i:uint = 0; i<_segments.length; ++i){
				seg = _segments[i] as QuadraticPathSegment;
				seg.pControl.x = (seg.pStart.x+seg.pEnd.x)*.5;
				seg.pControl.y = (seg.pStart.y+seg.pEnd.y)*.5;
				seg.pControl.z = (seg.pStart.z+seg.pEnd.z)*.5;
			}
        }
        
  		public function continuousCurve(points:Vector.<Vector3D>, closed:Boolean = false):void
  		{
  			var aVectors:Vector.<Vector3D> = new Vector.<Vector3D>();
  			var i:uint;
  			var X:Number;
			var Y:Number;
			var Z:Number;
			var midPoint:Vector3D;
			
  			// Find the mid points and inject them into the array.
  			for(i = 0; i < points.length - 1; i++)
  			{
  				var currentPoint:Vector3D = points[i];
  				var nextPoint:Vector3D = points[i+1];
  				
  				X = (currentPoint.x + nextPoint.x)/2;
  				Y = (currentPoint.y + nextPoint.y)/2;
  				Z = (currentPoint.z + nextPoint.z)/2;
  				midPoint = new Vector3D(X, Y, Z);
  				
  				if (i) aVectors.push(midPoint);
  				
  				if (i < points.length - 2 || closed) {
	  				aVectors.push(midPoint);
	  				aVectors.push(nextPoint);
  				}
  			}
  			
  			if(closed) {
	  			currentPoint = points[points.length-1];
	  			nextPoint = points[0];
	  			X = (currentPoint.x + nextPoint.x)/2;
  				Y = (currentPoint.y + nextPoint.y)/2;
  				Z = (currentPoint.z + nextPoint.z)/2;
  				midPoint = new Vector3D(X, Y, Z);
  				
  				aVectors.push(midPoint);
  				aVectors.push(midPoint);
  				aVectors.push(points[0]);
  				aVectors.push(aVectors[0]);
	  		}
	  		
            _segments = new Vector.<IPathSegment>();
			
			for(i = 0; i< aVectors.length; i+=3)
				_segments.push( new QuadraticPathSegment(aVectors[i], aVectors[i+1], aVectors[i+2]));
  		}


		public function set pointData(aVectors:Vector.<Vector3D>):void
		{
			if(aVectors.length < 3)
				throw new Error("Path Vector.<Vector3D> must contain at least 3 Vector3D's");
			
			if(aVectors.length%3 != 0)
				throw new Error("Path Vector.<Vector3D> must contain series of 3 Vector3D's per segment");
				
			for(var i:uint = 0; i<aVectors.length; i+=3)
				_segments.push( new QuadraticPathSegment(aVectors[i], aVectors[i+1], aVectors[i+2]));
		}


		public function get worldAxis():Vector3D
		{
			return _worldAxis;
		}
		public function set worldAxis(value:Vector3D):void
		{
			_worldAxis = value;
		}

		//to do, remove removeSegment method
		public function remove(index:uint, join:Boolean = false):void
		{
			removeSegment(index, join);
		}

		public function dispose():void
		{
			var i:uint = 0;
			while(_segments.length !=0 ){
				QuadraticPathSegment(_segments[i]).dispose();
				_segments[i] = null;
				_segments.splice(0, 1);
			}
			
		}
	}
}
package away3d.extrusions
{
	
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.entities.Mesh;
	import away3d.paths.IPath;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	[Deprecated]
	public class PathDuplicator
	{
		private var _transform:Matrix3D;
		private var _upAxis:Vector3D = new Vector3D(0, 1, 0);
		private var _path:IPath;
		private var _scene:Scene3D;
		private var _meshes:Vector.<Mesh>;
		private var _clones:Vector.<Mesh>;
		private var _repeat:uint;
		private var _alignToPath:Boolean;
		private var _randomRotationY:Boolean;
		private var _segmentSpread:Boolean = false;
		private var _mIndex:uint;
		private var _count:uint;
		private var _container:ObjectContainer3D;
		
		/**
		 * Creates a new <code>PathDuplicator</code>
		 * Class replicates and distribute one or more mesh(es) along a path. The offsets are defined by the position of the object. 0,0,0 would place the center of the mesh exactly on Path.
		 *
		 * @param    path                [optional]    A Path object. The _path definition. either Cubic or Quadratic path
		 * @param    meshes                [optional]    Vector.&lt;Mesh&gt;. One or more meshes to repeat along the path.
		 * @param    scene                [optional]    Scene3D. The scene where to addchild the meshes if no ObjectContainer3D is provided.
		 * @param    repeat                [optional]    uint. How many times a mesh is cloned per PathSegment. Default is 1.
		 * @param    alignToPath            [optional]    Boolean. If the alignment of the clones must follow the path. Default is true.
		 * @param    segmentSpread        [optional]    Boolean. If more than one Mesh is passed, it defines if the clones alternate themselves per PathSegment or each repeat. Default is false.
		 * @param container                [optional]    ObjectContainer3D. If an ObjectContainer3D is provided, the meshes are addChilded to it instead of directly into the scene. The container is NOT addChilded to the scene by default.
		 * @param    randomRotationY    [optional]    Boolean. If the clones must have a random rotationY added to them.
		 *
		 */
		function PathDuplicator(path:IPath = null, meshes:Vector.<Mesh> = null, scene:Scene3D = null, repeat:uint = 1, alignToPath:Boolean = true, segmentSpread:Boolean = true, container:ObjectContainer3D = null, randomRotationY:Boolean = false)
		{
			_path = path;
			_meshes = meshes;
			_scene = scene;
			_repeat = repeat;
			_alignToPath = alignToPath;
			_segmentSpread = segmentSpread;
			_randomRotationY = randomRotationY;
			_container = container;
		}
		
		/**
		 * The up axis to which duplicated objects' Y axis will be oriented.
		 */
		public function get upAxis():Vector3D
		{
			return _upAxis;
		}
		
		public function set upAxis(value:Vector3D):void
		{
			_upAxis = value;
		}
		
		/**
		 * If a container is provided, the meshes are addChilded to it instead of directly into the scene. The container is NOT addChilded to the scene.
		 */
		public function set container(cont:ObjectContainer3D):void
		{
			_container = cont;
		}
		
		public function get container():ObjectContainer3D
		{
			return _container;
		}
		
		/**
		 * Defines the resolution between each PathSegments. Default 1, is also minimum.
		 */
		public function set repeat(val:uint):void
		{
			_repeat = (val < 1)? 1 : val;
		}
		
		public function get repeat():uint
		{
			return _repeat;
		}
		
		/**
		 * Defines if the profile point array should be orientated on path or not. Default true.
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
		 * Defines if a clone gets a random rotationY to break visual repetitions, usefull in case of vegetation for instance.
		 */
		public function set randomRotationY(b:Boolean):void
		{
			_randomRotationY = b;
		}
		
		public function get randomRotationY():Boolean
		{
			return _randomRotationY;
		}
		
		/**
		 * returns a vector with all meshes cloned since last time build method was called. Returns null if build hasn't be called yet.
		 * Another option to retreive the generated meshes is to pass an ObjectContainer3D to the class
		 */
		public function get clones():Vector.<Mesh>
		{
			return _clones;
		}
		
		/**
		 * Sets and defines the Path object. See extrusions.utils package. Required for this class.
		 */
		public function set path(p:IPath):void
		{
			_path = p;
		}
		
		public function get path():IPath
		{
			return _path;
		}
		
		/**
		 * Defines an optional Vector.&lt;Mesh&gt;. One or more meshes to repeat along the path.
		 * When the last in the vector is reached, the first in the array will be used, this process go on and on until the last segment.
		 *
		 * @param    ms    A Vector.<Mesh>. One or more meshes to repeat along the path. Required for this class.
		 */
		public function set meshes(ms:Vector.<Mesh>):void
		{
			_meshes = ms;
		}
		
		public function get meshes():Vector.<Mesh>
		{
			return _meshes;
		}
		
		public function clearData(destroyCachedMeshes:Boolean):void
		{
			if (destroyCachedMeshes) {
				var i:uint = 0;
				if (meshes) {
					for (i = 0; i < meshes.length; ++i)
						meshes[i] = null;
				}
				if (_clones) {
					for (i; i < _clones.length; ++i)
						_clones[i] = null;
				}
			}
			_meshes = _clones = null;
		}
		
		/**
		 * defines if the meshes[index] is repeated per segments or duplicated after each others. default = false.
		 */
		public function set segmentSpread(b:Boolean):void
		{
			_segmentSpread = b;
		}
		
		public function get segmentSpread():Boolean
		{
			return _segmentSpread;
		}
		
		/**
		 * Triggers the generation
		 */
		public function build():void
		{
			if (!_path || !_meshes || meshes.length == 0)
				throw new Error("PathDuplicator error: Missing Path or Meshes data.");
			if (!_scene && !_container)
				throw new Error("PathDuplicator error: Missing Scene3D or ObjectContainer3D.");
			
			_mIndex = _meshes.length - 1;
			_count = 0;
			_clones = new Vector.<Mesh>();
			
			var segments:Vector.<Vector.<Vector3D>> = _path.getPointsOnCurvePerSegment(_repeat);
			var tmppt:Vector3D = new Vector3D();
			
			var i:uint;
			var j:uint;
			var nextpt:Vector3D;
			var m:Mesh;
			var tPosi:Vector3D;
			
			for (i = 0; i < segments.length; ++i) {
				
				if (!_segmentSpread)
					_mIndex = (_mIndex + 1 != _meshes.length)? _mIndex + 1 : 0;
				
				for (j = 0; j < segments[i].length; ++j) {
					
					if (_segmentSpread)
						_mIndex = (_mIndex + 1 != _meshes.length)? _mIndex + 1 : 0;
					
					m = _meshes[_mIndex];
					tPosi = m.position;
					
					if (_alignToPath) {
						_transform = new Matrix3D();
						
						if (i == segments.length - 1 && j == segments[i].length - 1) {
							nextpt = segments[i][j - 1];
							orientateAt(segments[i][j], nextpt);
						} else {
							nextpt = (j < segments[i].length - 1)? segments[i][j + 1] : segments[i + 1][0];
							orientateAt(nextpt, segments[i][j]);
						}
					}
					
					if (_alignToPath) {
						tmppt.x = tPosi.x*_transform.rawData[0] + tPosi.y*_transform.rawData[4] + tPosi.z*_transform.rawData[8] + _transform.rawData[12];
						tmppt.y = tPosi.x*_transform.rawData[1] + tPosi.y*_transform.rawData[5] + tPosi.z*_transform.rawData[9] + _transform.rawData[13];
						tmppt.z = tPosi.x*_transform.rawData[2] + tPosi.y*_transform.rawData[6] + tPosi.z*_transform.rawData[10] + _transform.rawData[14];
						
						tmppt.x += segments[i][j].x;
						tmppt.y += segments[i][j].y;
						tmppt.z += segments[i][j].z;
					} else
						tmppt = new Vector3D(tPosi.x + segments[i][j].x, tPosi.y + segments[i][j].y, tPosi.z + segments[i][j].z);
					
					generate(m, tmppt);
				}
			}
			
			segments = null;
		}
		
		private function orientateAt(target:Vector3D, position:Vector3D):void
		{
			var xAxis:Vector3D;
			var yAxis:Vector3D;
			var zAxis:Vector3D = target.subtract(position);
			zAxis.normalize();
			
			if (zAxis.length > 0.1) {
				xAxis = _upAxis.crossProduct(zAxis);
				xAxis.normalize();
				
				yAxis = xAxis.crossProduct(zAxis);
				yAxis.normalize();
				
				var rawData:Vector.<Number> = _transform.rawData;
				
				rawData[0] = xAxis.x;
				rawData[1] = xAxis.y;
				rawData[2] = xAxis.z;
				
				rawData[4] = -yAxis.x;
				rawData[5] = -yAxis.y;
				rawData[6] = -yAxis.z;
				
				rawData[8] = zAxis.x;
				rawData[9] = zAxis.y;
				rawData[10] = zAxis.z;
				
				_transform.rawData = rawData;
			}
		}
		
		private function generate(m:Mesh, position:Vector3D):void
		{
			var clone:Mesh = m.clone() as Mesh;
			
			if (_alignToPath)
				clone.transform = _transform;
			else
				clone.position = position;
			
			clone.name = (m.name != null)? m.name + "_" + _count : "clone_" + _count;
			_count++;
			
			if (_randomRotationY)
				clone.rotationY = Math.random()*360;
			
			if (_container)
				_container.addChild(clone);
			else
				_scene.addChild(clone);
			
			_clones.push(clone);
		}
	
	}
}

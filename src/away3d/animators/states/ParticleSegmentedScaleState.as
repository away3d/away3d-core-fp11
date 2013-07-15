package away3d.animators.states {
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.nodes.ParticleSegmentedScaleNode;
	import away3d.animators.ParticleAnimator;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import flash.geom.Vector3D;
	
	use namespace arcane;

	public class ParticleSegmentedScaleState extends ParticleStateBase
	{
		private var _startScale:Vector3D;
		private var _endScale:Vector3D;
		private var _segmentPoints:Vector.<Vector3D>;
		private var _numSegmentPoint:int;
		
		
		private var _scaleData:Vector.<Number>;
		
		/**
		 * Defines the start scale of the state, when in global mode.
		 */
		public function get startScale():Vector3D
		{
			return _startScale;
		}
		
		public function set startScale(value:Vector3D):void
		{
			_startScale = value;
			
			updateScaleData();
		}
		
		/**
		 * Defines the end scale of the state, when in global mode.
		 */
		public function get endScale():Vector3D
		{
			return _endScale;
		}
		public function set endScale(value:Vector3D):void
		{
			_endScale = value;
			updateScaleData();
		}
		
		/**
		 * Defines the number of segments.
		 */
		public function get numSegmentPoint():int
		{
			return _numSegmentPoint;
		}
		
		/**
		 * Defines the key points of Scale
		 */
		public function get segmentPoints():Vector.<Vector3D>
		{
			return _segmentPoints;
		}
		
		public function set segmentPoints(value:Vector.<Vector3D>):void
		{
			_segmentPoints = value;
			updateScaleData();
		}
		
		
		public function ParticleSegmentedScaleState(animator:ParticleAnimator, particleSegmentedScaleNode:ParticleSegmentedScaleNode)
		{
			super(animator, particleSegmentedScaleNode);
			
			_startScale = particleSegmentedScaleNode._startScale;
			_endScale = particleSegmentedScaleNode._endScale;
			_segmentPoints = particleSegmentedScaleNode._segmentScales;
			_numSegmentPoint = particleSegmentedScaleNode._numSegmentPoint;
			updateScaleData();
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			animationRegisterCache.setVertexConstFromVector(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSegmentedScaleNode.START_INDEX), _scaleData);
		}
		
		private function updateScaleData():void
		{
			var _timeLifeData:Vector.<Number> = new Vector.<Number>;
			_scaleData = new Vector.<Number>;
			var i:int;
			for (i = 0; i < _numSegmentPoint; i++)
			{
				if (i == 0)
					_timeLifeData.push(_segmentPoints[i].w);
				else
					_timeLifeData.push(_segmentPoints[i].w - _segmentPoints[i - 1].w);
			}
			if (_numSegmentPoint == 0)
				_timeLifeData.push(1);
			else
				_timeLifeData.push(1 - _segmentPoints[i - 1].w);
				
			_scaleData.push(_startScale.x , _startScale.y , _startScale.z , 0);
			for (i = 0; i < _numSegmentPoint; i++)
			{
				if (i == 0)
					_scaleData.push((_segmentPoints[i].x - _startScale.x)/_timeLifeData[i] , (_segmentPoints[i].y - _startScale.y)/_timeLifeData[i] , (_segmentPoints[i].z - _startScale.z)/_timeLifeData[i] , _timeLifeData[i]);
				else
					_scaleData.push((_segmentPoints[i].x - _segmentPoints[i - 1].x)/_timeLifeData[i] , (_segmentPoints[i].y - _segmentPoints[i - 1].y)/_timeLifeData[i] , (_segmentPoints[i].z - _segmentPoints[i - 1].z)/_timeLifeData[i] , _timeLifeData[i]);
			}
			if (_numSegmentPoint == 0)
				_scaleData.push(_endScale.x - _startScale.x , _endScale.y - _startScale.y , _endScale.z - _startScale.z , 1);
			else
				_scaleData.push((_endScale.x - _segmentPoints[i - 1].x) / _timeLifeData[i] , (_endScale.y - _segmentPoints[i - 1].y) / _timeLifeData[i] , (_endScale.z - _segmentPoints[i - 1].z) / _timeLifeData[i] , _timeLifeData[i]);
				
		}
	}
}
package away3d.animators.states {
	import away3d.animators.ParticleAnimator;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.data.ColorSegmentPoint;
	import away3d.animators.nodes.ParticleSegmentedColorNode;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;

	import flash.geom.ColorTransform;
	
	use namespace arcane;
	

	public class ParticleSegmentedColorState extends ParticleStateBase
	{
		private var _usesMultiplier:Boolean;
		private var _usesOffset:Boolean;
		private var _startColor:ColorTransform;
		private var _endColor:ColorTransform;
		private var _segmentPoints:Vector.<ColorSegmentPoint>;
		private var _numSegmentPoint:int;
		
		
		private var _timeLifeData:Vector.<Number>;
		private var _multiplierData:Vector.<Number>;
		private var _offsetData:Vector.<Number>;
		
		/**
		 * Defines the start color transform of the state, when in global mode.
		 */
		public function get startColor():ColorTransform
		{
			return _startColor;
		}
		
		public function set startColor(value:ColorTransform):void
		{
			_startColor = value;
			
			updateColorData();
		}
		
		/**
		 * Defines the end color transform of the state, when in global mode.
		 */
		public function get endColor():ColorTransform
		{
			return _endColor;
		}
		public function set endColor(value:ColorTransform):void
		{
			_endColor = value;
			updateColorData();
		}
		
		/**
		 * Defines the number of segments.
		 */
		public function get numSegmentPoint():int
		{
			return _numSegmentPoint;
		}
		
		/**
		 * Defines the key points of color
		 */
		public function get segmentPoints():Vector.<ColorSegmentPoint>
		{
			return _segmentPoints;
		}
		
		public function set segmentPoints(value:Vector.<ColorSegmentPoint>):void
		{
			_segmentPoints = value;
			updateColorData();
		}
		
		public function get usesMultiplier():Boolean
		{
			return _usesMultiplier;
		}
		
		public function get usesOffset():Boolean
		{
			return _usesOffset;
		}
		
		
		public function ParticleSegmentedColorState(animator:ParticleAnimator, particleSegmentedColorNode:ParticleSegmentedColorNode)
		{
			super(animator, particleSegmentedColorNode);
			
			_usesMultiplier = particleSegmentedColorNode._usesMultiplier;
			_usesOffset = particleSegmentedColorNode._usesOffset;
			_startColor = particleSegmentedColorNode._startColor;
			_endColor = particleSegmentedColorNode._endColor;
			_segmentPoints = particleSegmentedColorNode._segmentPoints;
			_numSegmentPoint = particleSegmentedColorNode._numSegmentPoint;
			updateColorData();
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			if (animationRegisterCache.needFragmentAnimation)
			{
				if (_numSegmentPoint > 0)
					animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSegmentedColorNode.TIME_DATA_INDEX), _timeLifeData[0], _timeLifeData[1], _timeLifeData[2], _timeLifeData[3]);
				if(_usesMultiplier)
					animationRegisterCache.setVertexConstFromVector(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSegmentedColorNode.START_MULTIPLIER_INDEX), _multiplierData);
				if(_usesOffset)
					animationRegisterCache.setVertexConstFromVector(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSegmentedColorNode.START_OFFSET_INDEX),_offsetData);
			}
		}
		
		private function updateColorData():void
		{
			_timeLifeData = new Vector.<Number>;
			_multiplierData = new Vector.<Number>;
			_offsetData = new Vector.<Number>;
			var i:int;
			for (i = 0; i < _numSegmentPoint; i++)
			{
				if (i == 0)
					_timeLifeData.push(_segmentPoints[i].life);
				else
					_timeLifeData.push(_segmentPoints[i].life - _segmentPoints[i - 1].life);
			}
			if (_numSegmentPoint == 0)
				_timeLifeData.push(1);
			else
				_timeLifeData.push(1 - _segmentPoints[i - 1].life);
				
			if (_usesMultiplier)
			{
				_multiplierData.push(_startColor.redMultiplier , _startColor.greenMultiplier , _startColor.blueMultiplier , _startColor.alphaMultiplier);
				for (i = 0; i < _numSegmentPoint; i++)
				{
					if (i == 0)
						_multiplierData.push((_segmentPoints[i].color.redMultiplier - _startColor.redMultiplier)/_timeLifeData[i] , (_segmentPoints[i].color.greenMultiplier - _startColor.greenMultiplier)/_timeLifeData[i] , (_segmentPoints[i].color.blueMultiplier - _startColor.blueMultiplier)/_timeLifeData[i] , (_segmentPoints[i].color.alphaMultiplier - _startColor.alphaMultiplier)/_timeLifeData[i]);
					else
						_multiplierData.push((_segmentPoints[i].color.redMultiplier - _segmentPoints[i - 1].color.redMultiplier)/_timeLifeData[i] , (_segmentPoints[i].color.greenMultiplier - _segmentPoints[i - 1].color.greenMultiplier)/_timeLifeData[i] , (_segmentPoints[i].color.blueMultiplier - _segmentPoints[i - 1].color.blueMultiplier)/_timeLifeData[i] , (_segmentPoints[i].color.alphaMultiplier - _segmentPoints[i - 1].color.alphaMultiplier)/_timeLifeData[i]);
				}
				if (_numSegmentPoint == 0)
					_multiplierData.push(_endColor.redMultiplier - _startColor.redMultiplier , _endColor.greenMultiplier - _startColor.greenMultiplier , _endColor.blueMultiplier - _startColor.blueMultiplier , _endColor.alphaMultiplier - _startColor.alphaMultiplier);
				else
					_multiplierData.push((_endColor.redMultiplier - _segmentPoints[i-1].color.redMultiplier)/_timeLifeData[i] , (_endColor.greenMultiplier - _segmentPoints[i-1].color.greenMultiplier)/_timeLifeData[i] , (_endColor.blueMultiplier - _segmentPoints[i-1].color.blueMultiplier)/_timeLifeData[i] , (_endColor.alphaMultiplier - _segmentPoints[i-1].color.alphaMultiplier)/_timeLifeData[i]);
			}
			
			if (_usesOffset)
			{
				_offsetData.push(_startColor.redOffset / 255, _startColor.greenOffset / 255, _startColor.blueOffset / 255, _startColor.alphaOffset / 255);
				for (i = 0; i < _numSegmentPoint; i++)
				{
					if (i == 0)
						_offsetData.push((_segmentPoints[i].color.redOffset - _startColor.redOffset) / _timeLifeData[i] / 255 , (_segmentPoints[i].color.greenOffset - _startColor.greenOffset) / _timeLifeData[i] / 255 , (_segmentPoints[i].color.blueOffset - _startColor.blueOffset) / _timeLifeData[i] / 255 , (_segmentPoints[i].color.alphaOffset - _startColor.alphaOffset) / _timeLifeData[i] / 255);
					else
						_offsetData.push((_segmentPoints[i].color.redOffset - _segmentPoints[i - 1].color.redOffset) / _timeLifeData[i] / 255 , (_segmentPoints[i].color.greenOffset - _segmentPoints[i - 1].color.greenOffset) / _timeLifeData[i] / 255 , (_segmentPoints[i].color.blueOffset - _segmentPoints[i - 1].color.blueOffset) / _timeLifeData[i] / 255 , (_segmentPoints[i].color.alphaOffset - _segmentPoints[i - 1].color.alphaOffset) / _timeLifeData[i] / 255);
				}
				if (_numSegmentPoint == 0)
					_offsetData.push((_endColor.redOffset - _startColor.redOffset) / 255 , (_endColor.greenOffset - _startColor.greenOffset) / 255 , (_endColor.blueOffset - _startColor.blueOffset) / 255 , (_endColor.alphaOffset - _startColor.alphaOffset) / 255);
				else
					_offsetData.push((_endColor.redOffset - _segmentPoints[i - 1].color.redOffset) / _timeLifeData[i] / 255 , (_endColor.greenOffset - _segmentPoints[i - 1].color.greenOffset) / _timeLifeData[i] / 255 , (_endColor.blueOffset - _segmentPoints[i - 1].color.blueOffset) / _timeLifeData[i] / 255 , (_endColor.alphaOffset - _segmentPoints[i - 1].color.alphaOffset) / _timeLifeData[i] / 255);
			}
			//cut off the data
			_timeLifeData.length = 4;
		}
	}
}
package away3d.animators.states
{
	import away3d.arcane;
	import away3d.animators.data.ParticleAnimationData;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleFollowNode;
	import away3d.animators.ParticleAnimator;
	import away3d.core.base.Object3D;
	import away3d.core.math.MathConsts;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleFollowState extends ParticleStateBase
	{
		private var _particleFollowNode:ParticleFollowNode;
		private var _followTarget:Object3D;
		
		private var _targetPos:Vector3D = new Vector3D;
		private var _targetEuler:Vector3D = new Vector3D;
		private var _prePos:Vector3D;
		private var _preEuler:Vector3D;
		private var _smooth:Boolean;
		
		//temporary vector3D for calculation
		private var temp:Vector3D = new Vector3D();
		
		public function ParticleFollowState(animator:ParticleAnimator, particleFollowNode:ParticleFollowNode)
		{
			super(animator, particleFollowNode, true);
			
			_particleFollowNode = particleFollowNode;
			_smooth = particleFollowNode._smooth;
		}
		
		public function get followTarget():Object3D
		{
			return _followTarget;
		}
		
		public function set followTarget(value:Object3D):void
		{
			_followTarget = value;
		}
		
		public function get smooth():Boolean
		{
			return _smooth;
		}
		
		public function set smooth(value:Boolean):void
		{
			_smooth = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			// TODO: not used
			renderable=renderable;
			camera=camera;

			if (_followTarget)
			{
				if (_particleFollowNode._usesPosition)
				{
					_targetPos.x = _followTarget.position.x;
					_targetPos.y = _followTarget.position.y;
					_targetPos.z = _followTarget.position.z;
				}
				if (_particleFollowNode._usesRotation)
				{
					_targetEuler.x = _followTarget.rotationX;
					_targetEuler.y = _followTarget.rotationY;
					_targetEuler.z = _followTarget.rotationZ;
					_targetEuler.scaleBy(MathConsts.DEGREES_TO_RADIANS);
				}
			}
			//initialization
			if (!_prePos)
				_prePos = _targetPos.clone();
			if (!_preEuler)
				_preEuler = _targetEuler.clone();
			
			var currentTime:Number = _time / 1000;
			var previousTime:Number = animationSubGeometry.previousTime;
			var deltaTime:Number = currentTime - previousTime;
			
			var needProcess:Boolean = previousTime != currentTime;
			
			if (_particleFollowNode._usesPosition && _particleFollowNode._usesRotation)
			{
				if (needProcess)
					processPositionAndRotation(currentTime, deltaTime, animationSubGeometry);
				
				animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_POSITION_INDEX), _particleFollowNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
				animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_ROTATION_INDEX), _particleFollowNode.dataOffset+3, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			}
			else if (_particleFollowNode._usesPosition)
			{
				if (needProcess)
					processPosition(currentTime, deltaTime, animationSubGeometry);
				
				animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_POSITION_INDEX), _particleFollowNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			}
			else if (_particleFollowNode._usesRotation)
			{
				if (needProcess)
					precessRotation(currentTime, deltaTime, animationSubGeometry);
				
				animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_ROTATION_INDEX), _particleFollowNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			}
			
			_prePos.copyFrom(_targetPos);
			_targetEuler.copyFrom(_targetEuler);
			animationSubGeometry.previousTime = currentTime;
		}
		
		private function processPosition(currentTime:Number, deltaTime:Number, animationSubGeometry:AnimationSubGeometry):void
		{
			var data:Vector.<ParticleAnimationData> = animationSubGeometry.animationParticles;
			var vertexData:Vector.<Number> = animationSubGeometry.vertexData;
			
			var changed:Boolean = false;
			var len:uint = data.length;
			var interpolatedPos:Vector3D;
			var posVelocity:Vector3D;
			if (_smooth)
			{
				posVelocity = _prePos.subtract(_targetPos);
				posVelocity.scaleBy(1 / deltaTime);
			}
			else
			{
				interpolatedPos = _targetPos;
			}
			for (var i:uint = 0; i < len; i++)
			{
				var k:Number = (currentTime - data[i].startTime) / data[i].totalTime;
				var t:Number = (k - Math.floor(k)) * data[i].totalTime;
				if (t - deltaTime <= 0)
				{
					var inc:int = data[i].startVertexIndex * 3;
					
					if (_smooth)
					{
						temp.copyFrom(posVelocity);
						temp.scaleBy(t);
						interpolatedPos = _targetPos.add(temp);
					}
					
					if (vertexData[inc] != interpolatedPos.x || vertexData[inc + 1] != interpolatedPos.y || vertexData[inc + 2] != interpolatedPos.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].numVertices; j++)
						{
							vertexData[inc++] = interpolatedPos.x;
							vertexData[inc++] = interpolatedPos.y;
							vertexData[inc++] = interpolatedPos.z;
						}
					}
				}
			}
			if (changed)
				animationSubGeometry.invalidateBuffer();
		
		}
		
		private function precessRotation(currentTime:Number, deltaTime:Number, animationSubGeometry:AnimationSubGeometry):void
		{
			var data:Vector.<ParticleAnimationData> = animationSubGeometry.animationParticles;
			var vertexData:Vector.<Number> = animationSubGeometry.vertexData;
			
			var changed:Boolean = false;
			var len:uint = data.length;
			
			var interpolatedRotation:Vector3D;
			var rotationVelocity:Vector3D;
			
			if (_smooth)
			{
				rotationVelocity = _preEuler.subtract(_targetEuler);
				rotationVelocity.scaleBy(1 / deltaTime);
			}
			else
			{
				interpolatedRotation = _targetEuler;
			}
			
			for (var i:uint = 0; i < len; i++)
			{
				var k:Number = (currentTime - data[i].startTime) / data[i].totalTime;
				var t:Number = (k - Math.floor(k)) * data[i].totalTime;
				if (t - deltaTime <= 0)
				{
					var inc:int = data[i].startVertexIndex * 3;
					
					if (_smooth)
					{
						temp.copyFrom(rotationVelocity);
						temp.scaleBy(t);
						interpolatedRotation = _targetEuler.add(temp);
					}
					
					if (vertexData[inc] != interpolatedRotation.x || vertexData[inc + 1] != interpolatedRotation.y || vertexData[inc + 2] != interpolatedRotation.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].numVertices; j++)
						{
							vertexData[inc++] = interpolatedRotation.x;
							vertexData[inc++] = interpolatedRotation.y;
							vertexData[inc++] = interpolatedRotation.z;
						}
					}
				}
			}
			if (changed)
				animationSubGeometry.invalidateBuffer();
		
		}
		
		private function processPositionAndRotation(currentTime:Number, deltaTime:Number, animationSubGeometry:AnimationSubGeometry):void
		{
			var data:Vector.<ParticleAnimationData> = animationSubGeometry.animationParticles;
			var vertexData:Vector.<Number> = animationSubGeometry.vertexData;
			
			var changed:Boolean = false;
			var len:uint = data.length;
			
			var interpolatedPos:Vector3D;
			var interpolatedRotation:Vector3D;
			
			var posVelocity:Vector3D;
			var rotationVelocity:Vector3D;
			if (_smooth)
			{
				posVelocity = _prePos.subtract(_targetPos);
				posVelocity.scaleBy(1 / deltaTime);
				rotationVelocity = _preEuler.subtract(_targetEuler);
				rotationVelocity.scaleBy(1 / deltaTime);
			}
			else
			{
				interpolatedPos = _targetPos;
				interpolatedRotation = _targetEuler;
			}
			
			for (var i:uint = 0; i < len; i++)
			{
				var k:Number = (currentTime - data[i].startTime) / data[i].totalTime;
				var t:Number = (k - Math.floor(k)) * data[i].totalTime;
				if (t - deltaTime <= 0)
				{
					var inc:int = data[i].startVertexIndex * 6;
					if (_smooth)
					{
						temp.copyFrom(posVelocity);
						temp.scaleBy(t);
						interpolatedPos = _targetPos.add(temp);
						
						temp.copyFrom(rotationVelocity);
						temp.scaleBy(t);
						interpolatedRotation = _targetEuler.add(temp);
					}
					
					if (vertexData[inc] != interpolatedPos.x || vertexData[inc + 1] != interpolatedPos.y || vertexData[inc + 2] != interpolatedPos.z || vertexData[inc + 3] != interpolatedRotation.x || vertexData[inc + 4] != interpolatedRotation.y || vertexData[inc + 5] != interpolatedRotation.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].numVertices; j++)
						{
							vertexData[inc++] = interpolatedPos.x;
							vertexData[inc++] = interpolatedPos.y;
							vertexData[inc++] = interpolatedPos.z;
							vertexData[inc++] = interpolatedRotation.x;
							vertexData[inc++] = interpolatedRotation.y;
							vertexData[inc++] = interpolatedRotation.z;
						}
					}
				}
			}
			if (changed)
				animationSubGeometry.invalidateBuffer();
		}
	
	}

}
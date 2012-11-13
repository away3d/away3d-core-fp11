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
		
		public function ParticleFollowState(animator:ParticleAnimator, particleFollowNode:ParticleFollowNode)
		{
			super(animator, particleFollowNode, true);
			
			_particleFollowNode = particleFollowNode;
		}
		
		public function get followTarget():Object3D
		{
			return _followTarget;
		}
		
		public function set followTarget(value:Object3D):void
		{
			_followTarget = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
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
			
			animationSubGeometry.previousTime = currentTime;
		
		}
		
		private function processPosition(currentTime:Number, deltaTime:Number, animationSubGeometry:AnimationSubGeometry):void
		{
			var data:Vector.<ParticleAnimationData> = animationSubGeometry.animationParticles;
			var vertexData:Vector.<Number> = animationSubGeometry.vertexData;
			
			var changed:Boolean = false;
			var len:uint = data.length;
			for (var i:uint = 0; i < len; i++)
			{
				var k:Number = (currentTime - data[i].startTime) / data[i].totalTime;
				var t:Number = (k - Math.floor(k)) * data[i].totalTime;
				if (t - deltaTime <= 0)
				{
					var inc:int = data[i].startVertexIndex * 3;
					
					if (vertexData[inc] != _targetPos.x || vertexData[inc + 1] != _targetPos.y || vertexData[inc + 2] != _targetPos.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].numVertices; j++)
						{
							vertexData[inc++] = _targetPos.x;
							vertexData[inc++] = _targetPos.y;
							vertexData[inc++] = _targetPos.z;
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
			for (var i:uint = 0; i < len; i++)
			{
				var k:Number = (currentTime - data[i].startTime) / data[i].totalTime;
				var t:Number = (k - Math.floor(k)) * data[i].totalTime;
				if (t - deltaTime <= 0)
				{
					var inc:int = data[i].startVertexIndex * 3;
					
					if (vertexData[inc] != _targetEuler.x || vertexData[inc + 1] != _targetEuler.y || vertexData[inc + 2] != _targetEuler.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].numVertices; j++)
						{
							vertexData[inc++] = _targetEuler.x;
							vertexData[inc++] = _targetEuler.y;
							vertexData[inc++] = _targetEuler.z;
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
			for (var i:uint = 0; i < len; i++)
			{
				var k:Number = (currentTime - data[i].startTime) / data[i].totalTime;
				var t:Number = (k - Math.floor(k)) * data[i].totalTime;
				if (t - deltaTime <= 0)
				{
					var inc:int = data[i].startVertexIndex * 6;
					if (vertexData[inc] != _targetPos.x || vertexData[inc + 1] != _targetPos.y || vertexData[inc + 2] != _targetPos.z || vertexData[inc + 3] != _targetEuler.x || vertexData[inc + 4] != _targetEuler.y || vertexData[inc + 5] != _targetEuler.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].numVertices; j++)
						{
							vertexData[inc++] = _targetPos.x;
							vertexData[inc++] = _targetPos.y;
							vertexData[inc++] = _targetPos.z;
							vertexData[inc++] = _targetEuler.x;
							vertexData[inc++] = _targetEuler.y;
							vertexData[inc++] = _targetEuler.z;
						}
					}
				}
			}
			if (changed)
				animationSubGeometry.invalidateBuffer();
		}
	
	}

}
package away3d.animators.states
{
	import away3d.animators.data.ParticleFollowingItem;
	import away3d.animators.data.FollowSubGeometry;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleFollowNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import away3d.core.base.Object3D;
	import away3d.core.math.MathConsts;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 */
	public class ParticleFollowState extends ParticleStateBase
	{
		private var _particleFollowNode:ParticleFollowNode;
		private var _followTarget:Object3D;
		
		private var _targetPos:Vector3D = new Vector3D;
		private var _targetEuler:Vector3D = new Vector3D;
		
		private var followSubGeometries:Dictionary = new Dictionary(true);
		
		public function ParticleFollowState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode, true);
			_particleFollowNode = particleNode as ParticleFollowNode;
		}
		
		public function get followTarget():Object3D
		{
			return _followTarget;
		}
		
		public function set followTarget(value:Object3D):void
		{
			_followTarget = value;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			var followSubGeometry:FollowSubGeometry = followSubGeometries[renderable] ||= new FollowSubGeometry(animationSubGeometry.extraStorage[_animationNode]);
			
			if (_followTarget)
			{
				if (_particleFollowNode.needOffset)
				{
					_targetPos.x = _followTarget.position.x;
					_targetPos.y = _followTarget.position.y;
					_targetPos.z = _followTarget.position.z;
				}
				if (_particleFollowNode.needRotate)
				{
					_targetEuler.x = _followTarget.rotationX;
					_targetEuler.y = _followTarget.rotationY;
					_targetEuler.z = _followTarget.rotationZ;
					_targetEuler.scaleBy(MathConsts.DEGREES_TO_RADIANS);
				}
			}
			
			var currentTime:Number = _time / 1000;
			var previousTime:Number = followSubGeometry.previousTime;
			var deltaTime:Number = currentTime - previousTime;
			
			var needProcess:Boolean = previousTime != currentTime;
			
			var index:int;
			if (_particleFollowNode.needOffset && _particleFollowNode.needRotate)
			{
				if (needProcess)
					processOffsetAndRotation(currentTime, deltaTime, followSubGeometry);
				index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_OFFSET_STREAM_REGISTER);
				followSubGeometry.activateVertexBuffer(index, 0, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
				index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_ROTATION_STREAM_REGISTER);
				followSubGeometry.activateVertexBuffer(index, 3, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			}
			else if (_particleFollowNode.needOffset)
			{
				if (needProcess)
					processOffset(currentTime, deltaTime, followSubGeometry);
				index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_OFFSET_STREAM_REGISTER);
				followSubGeometry.activateVertexBuffer(index, 0, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			}
			else if (_particleFollowNode.needRotate)
			{
				if (needProcess)
					precessRotation(currentTime, deltaTime, followSubGeometry);
				index = animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_ROTATION_STREAM_REGISTER);
				followSubGeometry.activateVertexBuffer(index, 0, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			}
			
			followSubGeometry.previousTime = currentTime;
		
		}
		
		private function processOffset(currentTime:Number, deltaTime:Number, followSubGeometry:FollowSubGeometry):void
		{
			var data:Vector.<ParticleFollowingItem> = followSubGeometry.itemList;
			var vertexData:Vector.<Number> = followSubGeometry.vertexData;
			
			var changed:Boolean = false;
			var len:uint = data.length;
			for (var i:uint = 0; i < len; i++)
			{
				var k:Number = (currentTime - data[i].startTime) / data[i].lifeTime;
				var t:Number = (k - Math.floor(k)) * data[i].lifeTime;
				if (t - deltaTime <= 0)
				{
					var inc:int = data[i].startIndex * 3;
					
					if (vertexData[inc] != _targetPos.x || vertexData[inc + 1] != _targetPos.y || vertexData[inc + 2] != _targetPos.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].numVertex; j++)
						{
							vertexData[inc++] = _targetPos.x;
							vertexData[inc++] = _targetPos.y;
							vertexData[inc++] = _targetPos.z;
						}
					}
				}
			}
			if (changed)
				followSubGeometry.invalidateBuffer();
		
		}
		
		private function precessRotation(currentTime:Number, deltaTime:Number, followSubGeometry:FollowSubGeometry):void
		{
			var data:Vector.<ParticleFollowingItem> = followSubGeometry.itemList;
			var vertexData:Vector.<Number> = followSubGeometry.vertexData;
			
			var changed:Boolean = false;
			var len:uint = data.length;
			for (var i:uint = 0; i < len; i++)
			{
				var k:Number = (currentTime - data[i].startTime) / data[i].lifeTime;
				var t:Number = (k - Math.floor(k)) * data[i].lifeTime;
				if (t - deltaTime <= 0)
				{
					var inc:int = data[i].startIndex * 3;
					
					if (vertexData[inc] != _targetEuler.x || vertexData[inc + 1] != _targetEuler.y || vertexData[inc + 2] != _targetEuler.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].numVertex; j++)
						{
							vertexData[inc++] = _targetEuler.x;
							vertexData[inc++] = _targetEuler.y;
							vertexData[inc++] = _targetEuler.z;
						}
					}
				}
			}
			if (changed)
				followSubGeometry.invalidateBuffer();
		
		}
		
		private function processOffsetAndRotation(currentTime:Number, deltaTime:Number, followSubGeometry:FollowSubGeometry):void
		{
			var data:Vector.<ParticleFollowingItem> = followSubGeometry.itemList;
			var vertexData:Vector.<Number> = followSubGeometry.vertexData;
			
			var changed:Boolean = false;
			var len:uint = data.length;
			for (var i:uint = 0; i < len; i++)
			{
				var k:Number = (currentTime - data[i].startTime) / data[i].lifeTime;
				var t:Number = (k - Math.floor(k)) * data[i].lifeTime;
				if (t - deltaTime <= 0)
				{
					var inc:int = data[i].startIndex * 6;
					if (vertexData[inc] != _targetPos.x || vertexData[inc + 1] != _targetPos.y || vertexData[inc + 2] != _targetPos.z || vertexData[inc + 3] != _targetEuler.x || vertexData[inc + 4] != _targetEuler.y || vertexData[inc + 5] != _targetEuler.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].numVertex; j++)
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
				followSubGeometry.invalidateBuffer();
		}
	
	}

}
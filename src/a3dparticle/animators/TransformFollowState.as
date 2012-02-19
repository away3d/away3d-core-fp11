package a3dparticle.animators 
{
	import a3dparticle.animators.actions.TransformFollowAction;
	import a3dparticle.animators.ParticleAnimation;
	import a3dparticle.animators.ParticleAnimationState;
	import a3dparticle.core.SubContainer;
	import away3d.animators.data.AnimationStateBase;
	import away3d.core.base.IRenderable;
	import away3d.core.base.Object3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.MathConsts;
	import away3d.materials.passes.MaterialPassBase;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import away3d.arcane;
	use namespace arcane;
	
	/**
	 * ...
	 * @author liaocheng
	 */
	public class TransformFollowState extends ParticleAnimationState
	{
		private var _followTarget:Object3D;
		private var _followAction:TransformFollowAction;
		
		private var _followData:Dictionary = new Dictionary();
		
		private var _lastTime:Number = 0;
		
		private var _offest:Boolean;
		private var _rotation:Boolean;
		
		public function TransformFollowState(offest:Boolean, rotation:Boolean, animation : ParticleAnimation, isClone:Boolean = false)
		{
			super(animation);
			this._offest = offest;
			this._rotation = rotation;
			if (!isClone)
			{
				animation.addAction(_followAction = new TransformFollowAction(offest,rotation));
			}
		}
		
		override public function set time(value:Number):void
		{
			_lastTime = time;
			super.time = value;
		}
		
		public function set followTarget(value:Object3D):void
		{
			_followTarget = value;
		}
		
		public function get followTarget():Object3D
		{
			return _followTarget;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			var subContainer:SubContainer = renderable as SubContainer;
			if (_followAction.particlesData[subContainer.shareAtt])
			{
				if (_offest && _rotation)
				{
					processOffestAndRotation(stage3DProxy,subContainer);
				}
				else if(_offest)
				{
					processOffest(stage3DProxy,subContainer);
				}
				else if(_rotation)
				{
					precessRotation(stage3DProxy,subContainer);
				}
			}
			super.setRenderState(stage3DProxy, renderable, vertexConstantOffset, vertexStreamOffset);
		}
		
		private function processOffest(stage3DProxy : Stage3DProxy, subContainer : SubContainer):void
		{
			var position : Vector3D = new Vector3D();
			if (_followTarget) position = _followTarget.position.clone();
			
			var data:Vector.<Object> = _followAction.particlesData[subContainer.shareAtt];
			var last:Object = data[data.length - 1];
			if (!_followData[subContainer.shareAtt])
			{
				_followData[subContainer.shareAtt] = new Vector.<Number>((last.start + last.num) * 3, true);
			}
			for (var i:uint = 0; i < data.length; i++)
			{
				var k:Number = (time-data[i].startTime) / data[i].lifeTime;
				var t:Number = (k - Math.floor(k)) * data[i].lifeTime;
				if ( _followTarget && t - (time-_lastTime) <= 0)
				{
					for (var j:uint = 0; j < data[i].num; j++)
					{
						_followData[subContainer.shareAtt][(data[i].start + j) * 3] = position.x;
						_followData[subContainer.shareAtt][(data[i].start + j) * 3 + 1] = position.y;
						_followData[subContainer.shareAtt][(data[i].start + j) * 3 + 2] = position.z;
					}
				}
			}
			var buffer:VertexBuffer3D = stage3DProxy._context3D.createVertexBuffer(_followData[subContainer.shareAtt].length / 3, 3);
			buffer.uploadFromVector(_followData[subContainer.shareAtt], 0, _followData[subContainer.shareAtt].length / 3);
			stage3DProxy.setSimpleVertexBuffer(_followAction.offestAttribute.index, buffer, Context3DVertexBufferFormat.FLOAT_3, 0);
		}
		
		private function precessRotation(stage3DProxy : Stage3DProxy, subContainer : SubContainer):void
		{
			var euler : Vector3D = new Vector3D();
			if (_followTarget) euler = _followTarget.eulers.clone();
			euler.scaleBy(MathConsts.DEGREES_TO_RADIANS);
			
			var data:Vector.<Object> = _followAction.particlesData[subContainer.shareAtt];
			var last:Object = data[data.length - 1];
			if (!_followData[subContainer.shareAtt])
			{
				_followData[subContainer.shareAtt] = new Vector.<Number>((last.start + last.num) * 3, true);
			}
			
			for (var i:uint = 0; i < data.length; i++)
			{
				var k:Number = (time-data[i].startTime) / data[i].lifeTime;
				var t:Number = (k - Math.floor(k)) * data[i].lifeTime;
				if ( _followTarget && t - (time-_lastTime) <= 0)
				{
					for (var j:uint = 0; j < data[i].num; j++)
					{
						_followData[subContainer.shareAtt][(data[i].start + j) * 3] = euler.x;
						_followData[subContainer.shareAtt][(data[i].start + j) * 3 + 1] = euler.y;
						_followData[subContainer.shareAtt][(data[i].start + j) * 3 + 2] = euler.z;
					}
				}
			}
			var buffer:VertexBuffer3D = stage3DProxy._context3D.createVertexBuffer(_followData[subContainer.shareAtt].length / 3, 3);
			buffer.uploadFromVector(_followData[subContainer.shareAtt], 0, _followData[subContainer.shareAtt].length / 3);
			stage3DProxy.setSimpleVertexBuffer(_followAction.rotationAttribute.index, buffer, Context3DVertexBufferFormat.FLOAT_3, 0);
		}
		
		private function processOffestAndRotation(stage3DProxy : Stage3DProxy, subContainer : SubContainer):void
		{
			var position : Vector3D = new Vector3D();
			if (_followTarget) position = _followTarget.position.clone();
			var euler : Vector3D = new Vector3D();
			if (_followTarget) euler = _followTarget.eulers.clone();
			euler.scaleBy(MathConsts.DEGREES_TO_RADIANS);
			
			var data:Vector.<Object> = _followAction.particlesData[subContainer.shareAtt];
			var last:Object = data[data.length - 1];
			if (!_followData[subContainer.shareAtt])
			{
				_followData[subContainer.shareAtt] = new Vector.<Number>((last.start + last.num) * 6, true);
			}
			
			for (var i:uint = 0; i < data.length; i++)
			{
				var k:Number = (time-data[i].startTime) / data[i].lifeTime;
				var t:Number = (k - Math.floor(k)) * data[i].lifeTime;
				if ( _followTarget && t - (time-_lastTime) <= 0)
				{
					for (var j:uint = 0; j < data[i].num; j++)
					{
						_followData[subContainer.shareAtt][(data[i].start + j) * 6] = position.x;
						_followData[subContainer.shareAtt][(data[i].start + j) * 6 + 1] = position.y;
						_followData[subContainer.shareAtt][(data[i].start + j) * 6 + 2] = position.z;
						_followData[subContainer.shareAtt][(data[i].start + j) * 6 + 3] = euler.x;
						_followData[subContainer.shareAtt][(data[i].start + j) * 6 + 4] = euler.y;
						_followData[subContainer.shareAtt][(data[i].start + j) * 6 + 5] = euler.z;
					}
				}
			}
			var buffer:VertexBuffer3D = stage3DProxy._context3D.createVertexBuffer(_followData[subContainer.shareAtt].length / 6, 6);
			buffer.uploadFromVector(_followData[subContainer.shareAtt], 0, _followData[subContainer.shareAtt].length / 6);
			var context : Context3D = stage3DProxy._context3D;
			context.setVertexBufferAt(_followAction.offestAttribute.index, buffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(_followAction.rotationAttribute.index, buffer, 3, Context3DVertexBufferFormat.FLOAT_3);
		}
		
		override public function clone() : AnimationStateBase
		{
			var clone : TransformFollowState = new TransformFollowState(_offest, _rotation, ParticleAnimation(_animation), true);
			clone._followAction = _followAction;
			clone.time = time;
			return clone;
		}
		
	}

}
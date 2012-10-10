package a3dparticle.animators
{
	import a3dparticle.animators.actions.FollowingItem;
	import a3dparticle.animators.actions.TransformFollowAction;
	import a3dparticle.animators.ParticleAnimation;
	import a3dparticle.core.SubContainer;
	import away3d.core.base.IRenderable;
	import away3d.core.base.Object3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.MathConsts;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Cheng Liao
	 */
	public class TransformFollowAnimator extends ParticleAnimator
	{
		private var _followTarget:Object3D;
		private var _followAction:TransformFollowAction;
		
		private var _followData:Dictionary = new Dictionary();
		
		private var _lastTime:Number = 0;
		
		private var _offset:Boolean;
		private var _rotation:Boolean;
		
		private var _newBuffer:Boolean;
		
		private var _bufferDict:Dictionary=new Dictionary();
		private var _context3DDict:Dictionary = new Dictionary();
		
		public function TransformFollowAnimator(offset:Boolean, rotation:Boolean, animation : ParticleAnimation, isClone:Boolean = false, followAction:TransformFollowAction = null)
		{
			super(animation);
			this._offset = offset;
			this._rotation = rotation;
			if (!isClone)
			{
				animation.addAction(_followAction = new TransformFollowAction(offset,rotation));
			}
			else
			{
				_followAction = followAction;
			}
		}
		
		public function get followAction():TransformFollowAction
		{
			return _followAction;
		}
		
		public function get offset():Boolean
		{
			return _offset;
		}
		public function get rotation():Boolean
		{
			return _rotation;
		}
		
		override public function set animatorTime(value:Number):void
		{
			_lastTime = animatorTime;
			super.animatorTime = value;
		}
		
		
		public function set followTarget(value:Object3D):void
		{
			_followTarget = value;
		}
		
		public function get followTarget():Object3D
		{
			return _followTarget;
		}
		

		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable, vertexConstantOffset : int, vertexStreamOffset : int) : void
		{
			var subContainer:SubContainer = renderable as SubContainer;
			if (_followAction.particlesData[subContainer.shareAtt])
			{
				if (_offset && _rotation)
				{
					processOffsetAndRotation(stage3DProxy,subContainer);
				}
				else if(_offset)
				{
					processOffset(stage3DProxy,subContainer);
				}
				else if(_rotation)
				{
					precessRotation(stage3DProxy,subContainer);
				}
			}
			super.setRenderState(stage3DProxy, renderable, vertexConstantOffset, vertexStreamOffset);
		}
		
		private function processOffset(stage3DProxy : Stage3DProxy, subContainer : SubContainer):void
		{
			var position : Vector3D = new Vector3D();
			if (_followTarget) position = _followTarget.position.clone();
			
			var data:Vector.<FollowingItem> = _followAction.particlesData[subContainer.shareAtt];
			var last:FollowingItem = data[data.length - 1];
			
			var temp:Vector.<Number> = _followData[subContainer.shareAtt];
			if (!temp)
			{
				temp = _followData[subContainer.shareAtt] = new Vector.<Number>((last.start + last.num) * 3, true);
			}
			var changed:Boolean = false;
			
			for (var i:uint = 0; i < data.length; i++)
			{
				var k:Number = (_absoluteTime / 1000 - data[i].startTime) / data[i].lifeTime;
				var t:Number = (k - Math.floor(k)) * data[i].lifeTime;
				if ( _followTarget && t - (_absoluteTime-_lastTime)/1000 <= 0)
				{
					var inc:int = data[i].start * 3;
					
					if (temp[inc] != position.x || temp[inc + 1] != position.y || temp[inc + 2] != position.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].num; j++)
						{
							temp[inc++] = position.x;
							temp[inc++] = position.y;
							temp[inc++] = position.z;
						}
					}
				}
			}
			var buffer:VertexBuffer3D = getBuffer(stage3DProxy, subContainer);
			if (changed || _newBuffer)
			{
				buffer.uploadFromVector(temp, 0, temp.length / 3);
				_newBuffer = false;
			}
			stage3DProxy.setSimpleVertexBuffer(_followAction.offsetAttribute.index, buffer, Context3DVertexBufferFormat.FLOAT_3, 0);
		}
		
		private function precessRotation(stage3DProxy : Stage3DProxy, subContainer : SubContainer):void
		{
			var euler : Vector3D = new Vector3D();
			if (_followTarget) euler = _followTarget.eulers.clone();
			euler.scaleBy(MathConsts.DEGREES_TO_RADIANS);
			
			var data:Vector.<FollowingItem> = _followAction.particlesData[subContainer.shareAtt];
			var last:FollowingItem = data[data.length - 1];
			
			var temp:Vector.<Number> = _followData[subContainer.shareAtt];
			if (!temp)
			{
				temp = _followData[subContainer.shareAtt] = new Vector.<Number>((last.start + last.num) * 3, true);
			}
			var changed:Boolean = false;
			
			for (var i:uint = 0; i < data.length; i++)
			{
				var k:Number = (_absoluteTime/1000-data[i].startTime) / data[i].lifeTime;
				var t:Number = (k - Math.floor(k)) * data[i].lifeTime;
				if ( _followTarget && t - (_absoluteTime-_lastTime)/1000 <= 0)
				{
					var inc:int = data[i].start * 3;
					
					if (temp[inc] != euler.x || temp[inc + 1] != euler.y || temp[inc + 2] != euler.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].num; j++)
						{
							temp[inc++] = euler.x;
							temp[inc++] = euler.y;
							temp[inc++] = euler.z;
						}
					}
				}
			}
			var buffer:VertexBuffer3D = getBuffer(stage3DProxy, subContainer);
			if (changed || _newBuffer)
			{
				buffer.uploadFromVector(temp, 0, temp.length / 3);
				_newBuffer = false;
			}
			stage3DProxy.setSimpleVertexBuffer(_followAction.rotationAttribute.index, buffer, Context3DVertexBufferFormat.FLOAT_3, 0);
		}
		
		private function processOffsetAndRotation(stage3DProxy : Stage3DProxy, subContainer : SubContainer):void
		{
			var position : Vector3D = new Vector3D();
			if (_followTarget) position = _followTarget.position.clone();
			var euler : Vector3D = new Vector3D();
			if (_followTarget) euler = _followTarget.eulers.clone();
			euler.scaleBy(MathConsts.DEGREES_TO_RADIANS);
			
			var data:Vector.<FollowingItem> = _followAction.particlesData[subContainer.shareAtt];
			var last:FollowingItem = data[data.length - 1];
			
			var temp:Vector.<Number> = _followData[subContainer.shareAtt];
			if (!temp)
			{
				temp = _followData[subContainer.shareAtt] = new Vector.<Number>((last.start + last.num) * 6, true);
			}
			var changed:Boolean = false;
			
			for (var i:uint = 0; i < data.length; i++)
			{
				var k:Number = (_absoluteTime / 1000 - data[i].startTime) / data[i].lifeTime;
				var t:Number = (k - Math.floor(k)) * data[i].lifeTime;
				if ( _followTarget && t - (_absoluteTime-_lastTime)/1000 <= 0)
				{
					var inc:int = data[i].start * 6;
					if (temp[inc] != position.x || temp[inc + 1] != position.y || temp[inc + 2] != position.z ||
						temp[inc + 3] != euler.x || temp[inc + 4] != euler.y || temp[inc + 5] != euler.z)
					{
						changed = true;
						for (var j:uint = 0; j < data[i].num; j++)
						{
							temp[inc++] = position.x;
							temp[inc++] = position.y;
							temp[inc++] = position.z;
							temp[inc++] = euler.x;
							temp[inc++] = euler.y;
							temp[inc++] = euler.z;
						}
					}
				}
			}
			
			var buffer:VertexBuffer3D = getBuffer(stage3DProxy, subContainer);
			if (changed || _newBuffer)
			{
				buffer.uploadFromVector(temp, 0, temp.length / 6);
				_newBuffer = false;
			}

			stage3DProxy.setSimpleVertexBuffer(_followAction.offsetAttribute.index, buffer, Context3DVertexBufferFormat.FLOAT_3, 0);
			stage3DProxy.setSimpleVertexBuffer(_followAction.rotationAttribute.index, buffer, Context3DVertexBufferFormat.FLOAT_3, 3);
		}
		
		private function getBuffer(stage3DProxy:Stage3DProxy, subContainer:SubContainer):VertexBuffer3D
		{
			if (!_bufferDict[subContainer.shareAtt] || stage3DProxy.context3D != _context3DDict[subContainer.shareAtt])
			{
				if (_offset && _rotation)
				{
					_bufferDict[subContainer.shareAtt]=stage3DProxy.context3D.createVertexBuffer(_followData[subContainer.shareAtt].length / 6, 6);
				}
				else
				{
					_bufferDict[subContainer.shareAtt]=stage3DProxy.context3D.createVertexBuffer(_followData[subContainer.shareAtt].length / 3, 3);
				}
				_context3DDict[subContainer.shareAtt] = stage3DProxy.context3D;
				_newBuffer = true;
			}
			return _bufferDict[subContainer.shareAtt];
		}
		
	}

}
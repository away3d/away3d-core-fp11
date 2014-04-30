package away3d.animators.states
{
	import away3d.animators.data.ParticlePropertiesMode;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleUVNode;
	import away3d.animators.ParticleAnimator;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleUVState extends ParticleStateBase
	{
		
		private var _particleUVNode:ParticleUVNode;
		
		private var _cycle:Number;
		private var _scale:Number;
		
		public function ParticleUVState(animator:ParticleAnimator, particleUVNode:ParticleUVNode)
		{
			super(animator, particleUVNode);
			
			_particleUVNode = particleUVNode;
			_cycle = particleUVNode._cycle;
			_scale = particleUVNode._scale;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			if (animationRegisterCache.needUVAnimation) {
				var index:int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleUVNode.UV_INDEX);
				if (_particleUVNode.mode == ParticlePropertiesMode.GLOBAL) {
					switch(_particleUVNode._formula)
					{
						case ParticleUVNode.SINE_EASE:
							animationRegisterCache.setVertexConst(index, Math.PI * 2 /_cycle, _scale);
							break;
						case ParticleUVNode.LINEAR_EASE:
						default:
							animationRegisterCache.setVertexConst(index, 1 /_cycle, _scale);
					}		
				} else {
					animationSubGeometry.activateVertexBuffer(index, _particleUVNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_2);
				}
			}
		}
		
		public function get scale():Number 
		{
			return _scale;
		}
		
		public function set scale(value:Number):void 
		{
			_scale = value;
		}
		
		public function get cycle():Number 
		{
			return _cycle;
		}
		
		public function set cycle(value:Number):void 
		{
			_cycle = value;
		}
	
	}

}

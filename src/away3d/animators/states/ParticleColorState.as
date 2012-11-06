package away3d.animators.states
{
	import away3d.animators.data.ParticlePropertiesMode;
	import flash.geom.Vector3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleColorNode;
	import away3d.animators.ParticleAnimator;
	
	use namespace arcane;
	
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleColorState extends ParticleStateBase
	{
		private var _particleColorNode:ParticleColorNode;
		
		public function ParticleColorState(animator:ParticleAnimator, particleColorNode:ParticleColorNode)
		{
			super(animator, particleColorNode);
			
			_particleColorNode = particleColorNode;
			
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : void
		{
			if (animationRegisterCache.needFragmentAnimation)
			{
				var data:Vector3D;
				var dataOffset:uint = _particleColorNode.dataOffset;
				if (_particleColorNode._usesCycle) {
					data = _particleColorNode._cycleData;
					animationRegisterCache.setFragmentConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.CYCLE_INDEX), data.x, data.y, data.z, data.w);
				}
				
				if (_particleColorNode._usesMultiplier)
				{
					if (_particleColorNode.mode == ParticlePropertiesMode.LOCAL) {
						animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.START_MULTIPLIER_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
						dataOffset += 4;
						animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.DELTA_MULTIPLIER_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
						dataOffset += 4;
					} else {
						data = _particleColorNode._startMultiplierData;
						animationRegisterCache.setFragmentConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.START_MULTIPLIER_INDEX), data.x, data.y, data.z, data.w);
						data = _particleColorNode._deltaMultiplierData;
						animationRegisterCache.setFragmentConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.DELTA_MULTIPLIER_INDEX), data.x, data.y, data.z, data.w);
					}
				}
				if (_particleColorNode._usesOffset)
				{
					if (_particleColorNode.mode == ParticlePropertiesMode.LOCAL) {
						animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.START_OFFSET_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
						dataOffset += 4;
						animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.DELTA_OFFSET_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
						dataOffset += 4;
					} else {
						data = _particleColorNode._startOffsetData;
						animationRegisterCache.setFragmentConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.START_OFFSET_INDEX), data.x, data.y, data.z, data.w);
						data = _particleColorNode._deltaOffsetData;
						animationRegisterCache.setFragmentConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.DELTA_OFFSET_INDEX), data.x, data.y, data.z, data.w);
					}
				}
			}
		}
		
	}

}
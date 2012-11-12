package away3d.animators.states
{
	import away3d.arcane;
	import away3d.animators.data.ParticleAnimationData;
	import flash.utils.Dictionary;
	import flash.geom.Vector3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleStateBase extends AnimationStateBase
	{
		private var _particleNode:ParticleNodeBase;
		
		protected var _dynamicProperties:Vector.<Vector3D> = new Vector.<Vector3D>();
		protected var _dynamicPropertiesDirty:Dictionary = new Dictionary(true);
		
		protected var _needUpdateTime:Boolean;
		public function ParticleStateBase(animator:ParticleAnimator, particleNode:ParticleNodeBase, needUpdateTime:Boolean = false)
		{
			super(animator, particleNode);
			
			_particleNode = particleNode;
			_needUpdateTime = needUpdateTime;
		}
		
		public function get needUpdateTime():Boolean
		{
			return _needUpdateTime;
		}
		
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):void
		{
			
		}
		
		protected function updateDynamicProperties(animationSubGeometry:AnimationSubGeometry):void
		{
			_dynamicPropertiesDirty[animationSubGeometry] = true;
			
			var animationParticles:Vector.<ParticleAnimationData> = animationSubGeometry.animationParticles;
			var vertexData:Vector.<Number> = animationSubGeometry.vertexData;
			var totalLenOfOneVertex:uint = animationSubGeometry.totalLenOfOneVertex;
			var dataLength:uint = _particleNode.dataLength;
			var dataOffset:uint = _particleNode.dataOffset;
			var vertexLength:uint;
//			var particleOffset:uint;
			var startingOffset:uint;
			var vertexOffset:uint;
			var data:Vector3D;
			var animationParticle:ParticleAnimationData;
			
//			var numParticles:uint = _positions.length/dataLength;
			var numParticles:uint = _dynamicProperties.length;
			var i:uint = 0;
			var j:uint = 0;
			var k:uint = 0;
			
			//loop through all particles
			while (i < numParticles) {
				//loop through each particle data for the current particle
				while (j < numParticles && (animationParticle = animationParticles[j]).index == i) {
					data = _dynamicProperties[i];
					vertexLength = animationParticle.numVertices * totalLenOfOneVertex;
					startingOffset = animationParticle.startVertexIndex * totalLenOfOneVertex + dataOffset;
					//loop through each vertex in the particle data
					for (k = 0; k < vertexLength; k+=totalLenOfOneVertex) {
						vertexOffset = startingOffset + k;
//						particleOffset = i * dataLength;
						//loop through all vertex data for the current particle data
						for (k = 0; k < vertexLength; k+=totalLenOfOneVertex)
						{
							vertexOffset = startingOffset + k;
							vertexData[vertexOffset++] = data.x;
							vertexData[vertexOffset++] = data.y;
							vertexData[vertexOffset++] = data.z;
							
							if (dataLength == 4)
								vertexData[vertexOffset++] = data.w;
						}
						//loop through each value in the particle vertex
//						switch(dataLength) {
//							case 4:
//								vertexData[vertexOffset++] = _positions[particleOffset++];
//							case 3:
//								vertexData[vertexOffset++] = _positions[particleOffset++];
//							case 2:
//								vertexData[vertexOffset++] = _positions[particleOffset++];
//							case 1:
//								vertexData[vertexOffset++] = _positions[particleOffset++];
//						}
					}
					j++;
				}
				i++;
			}
			
			animationSubGeometry.invalidateBuffer();
		}
		
	}

}
package away3d.animators.data
{
	import away3d.core.base.data.ParticleData;
	
	/**
	 * ...
	 */
	public class ParticleAnimationData
	{
		public var index:uint;
		public var startTime:Number;
		public var totalTime:Number;
		public var duration:Number;
		public var delay:Number;
		public var startVertexIndex:uint;
		public var numVertices:uint;
		
		
		public function ParticleAnimationData(index:uint, startTime:Number, duration:Number, delay:Number, particle:ParticleData)
		{
			this.index = index;
			this.startTime = startTime;
			this.totalTime = duration + delay;
			this.duration = duration;
			this.delay = delay;
			this.startVertexIndex = particle.startVertexIndex;
			this.numVertices = particle.numVertices;
		}
	}

}
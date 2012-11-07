package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.materials.passes.MaterialPassBase;
	
	use namespace arcane;
	
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleNodeBase extends AnimationNodeBase
	{
		protected var _mode:uint;
		private var _priority:int;
		
		protected var _dataLength:uint = 3;
		protected var _oneData:Vector.<Number>;
		
		arcane var dataOffset:uint;
		
		/**
		 * 
		 */
		public function get mode():uint
		{
			return _mode;
		}
		
		/**
		 * 
		 */
		public function get priority():int
		{
			return _priority;
		}
		
		/**
		 * 
		 */
		public function get dataLength():int
		{
			return _dataLength;
		}
		
		/**
		 * 
		 */
		public function get oneData():Vector.<Number>
		{
			return _oneData;
		}
		
		public function ParticleNodeBase(name:String, mode:uint, dataLength:uint, priority:int = 1)
		{
			this.name = name;
			_mode = mode;
			_priority = priority;
			_dataLength = dataLength;
			
			_oneData = new Vector.<Number>(_dataLength, true);
		}
		
		arcane function generatePropertyOfOneParticle(param:ParticleProperties):void
		{
			
		}
		
		public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):void
		{
			
		}
		
		public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			return "";
		}
		
		public function getAGALFragmentCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			return "";
		}
		
		public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			return "";
		}
		
	}

}
package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.materials.passes.MaterialPassBase;
	import flash.utils.getQualifiedClassName;
	
	use namespace arcane;
	
	/**
	 * Provides an abstract base class for particle animation nodes.
	 */
	public class ParticleNodeBase extends AnimationNodeBase
	{
		protected var _mode:uint;
		private var _priority:int;
		
		protected var _dataLength:uint = 3;
		protected var _oneData:Vector.<Number>;
		
		arcane var dataOffset:uint;
		
		/**
		 * Returns the property mode of the particle animation node. Typically set in the node constructor
		 * 
		 * @see away3d.animators.data.ParticlePropertiesMode
		 */
		public function get mode():uint
		{
			return _mode;
		}
		
		/**
		 * Returns the priority of the particle animation node, used to order the agal generated in a particle animation set. Set automatically on instantiation.
		 * 
		 * @see away3d.animators.ParticleAnimationSet
		 * @see #getAGALVertexCode
		 */
		public function get priority():int
		{
			return _priority;
		}
		
		/**
		 * Returns the length of the data used by the node when in <code>LOCAL_STATIC</code> mode. Used to generate the local static data of the particle animation set.
		 * 
		 * @see away3d.animators.ParticleAnimationSet
		 * @see #getAGALVertexCode
		 */
		public function get dataLength():int
		{
			return _dataLength;
		}
		
		/**
		 * Returns the generated data vector of the node after one particle pass during the generation of all local static data of the particle animation set.
		 * 
		 * @see away3d.animators.ParticleAnimationSet
		 * @see #generatePropertyOfOneParticle
		 */
		public function get oneData():Vector.<Number>
		{
			return _oneData;
		}
		
		//modes alias
		private static var GLOBAL:String = 'Global';
		private static var LOCAL_STATIC:String = 'LocalStatic';
		private static var LOCAL_DYNAMIC:String = 'LocalDynamic';
		
		//modes list
		private static var MODES:Object = 
											{
												0:GLOBAL,
												1:LOCAL_STATIC,
												2:LOCAL_DYNAMIC
											};
		
		/**
		 * 
		 * @param	particleNodeClass - class of ParticleNodeBase child e.g ParticleBillboardNode, ParticleFollowNode...
		 * @param	particleNodeMode  - mode of particle node ParticlePropertiesMode.GLOBAL, ParticlePropertiesMode.LOCAL_DYNAMIC or ParticlePropertiesMode.LOCAL_STATIC
		 * @return 	particle node name
		 */
		public static function getParticleNodeName(particleNodeClass:Object, particleNodeMode:uint):String
		{
			var nodeName:String = particleNodeClass['ANIMATION_NODE_NAME'];
			
			if (!nodeName)
				nodeName = getNodeNameFromClass(particleNodeClass);
				
			return nodeName + MODES[particleNodeMode];
		}
		
		private static function getNodeNameFromClass(particleNodeClass:Object):String
		{
			return getQualifiedClassName(particleNodeClass).replace('Node', '').split('::')[1];
		}
		
		/**
		 * Creates a new <code>ParticleNodeBase</code> object.
		 * 
		 * @param               name            Defines the generic name of the particle animation node.
		 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
		 * @param               dataLength      Defines the length of the data used by the node when in <code>LOCAL_STATIC</code> mode.
		 * @param    [optional] priority        the priority of the particle animation node, used to order the agal generated in a particle animation set. Defaults to 1.
		 */
		public function ParticleNodeBase(name:String, mode:uint, dataLength:uint, priority:int = 1)
		{
			name = name + MODES[mode];
			
			this.name = name;
			_mode = mode;
			_priority = priority;
			_dataLength = dataLength;
			
			_oneData = new Vector.<Number>(_dataLength, true);
		}
		
		/**
		 * Returns the AGAL code of the particle animation node for use in the vertex shader.
		 */
		public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			pass=pass;
			animationRegisterCache=animationRegisterCache;
			return "";
		}
		
		/**
		 * Returns the AGAL code of the particle animation node for use in the fragment shader.
		 */
		public function getAGALFragmentCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			pass=pass;
			animationRegisterCache=animationRegisterCache;
			return "";
		}
		
		/**
		 * Returns the AGAL code of the particle animation node for use in the fragment shader when UV coordinates are required.
		 */
		public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			pass=pass;
			animationRegisterCache=animationRegisterCache;
			return "";
		}
		
		/**
		 * Called internally by the particle animation set when assigning the set of static properties originally defined by the initParticleFunc of the set.
		 * 
		 * @see away3d.animators.ParticleAnimationSet#initParticleFunc
		 */
		arcane function generatePropertyOfOneParticle(param:ParticleProperties):void
		{
			
		}
		
		/**
		 * Called internally by the particle animation set when determining the requirements of the particle animation node AGAL.
		 */
		arcane function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):void
		{
			
		}
	}
}
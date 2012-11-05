package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.states.ParticleBillboardState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleBillboardNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const MATRIX_INDEX:int = 0;
		
		/**
		 * Creates a new <code>ParticleBillboardNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation defaults to acting on local properties of a particle or global properties of the node.
		 */
		public function ParticleBillboardNode()
		{
			super("ParticleBillboardNode", 1, 0, 3);
			
			_stateClass = ParticleBillboardState;
		}
		
		/**
		 * @inheritDoc
		 */		
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			var rotationMatrixRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, MATRIX_INDEX, rotationMatrixRegister.index);
			animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.getFreeVertexConstant();
			
			var code:String = "m33 " + animationRegisterCache.scaleAndRotateTarget + "," + animationRegisterCache.scaleAndRotateTarget + "," + rotationMatrixRegister + "\n";
			var len:int = animationRegisterCache.rotationRegisters.length;
			for (var i:int = 0; i < len; i++)
			{
				code += "m33 " + animationRegisterCache.rotationRegisters[i].regName+animationRegisterCache.rotationRegisters[i].index + ".xyz," + animationRegisterCache.rotationRegisters[i] + "," + rotationMatrixRegister + "\n";
			}
			return code;
		}
	}
}
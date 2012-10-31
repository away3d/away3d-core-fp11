package away3d.animators.nodes
{
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.states.ParticleBillboardGlobalState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	/**
	 * ...
	 */
	public class ParticleBillboardGlobalNode extends GlobalParticleNodeBase
	{
		public static const NAME:String = "ParticleBillboardGlobalNode";
		public static const MATRIX_CONSTANT_REGISTER:int = 0;
		
		public function ParticleBillboardGlobalNode()
		{
			super(NAME, 3);
			_stateClass = ParticleBillboardGlobalState;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			var rotationMatrixRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, MATRIX_CONSTANT_REGISTER, rotationMatrixRegister.index);
			animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.getFreeVertexConstant();
			
			var code:String = "m33 " + animationRegisterCache.scaleAndRotateTarget.toString() + "," + animationRegisterCache.scaleAndRotateTarget.toString() + "," + rotationMatrixRegister.toString() + "\n";
			var len:int = animationRegisterCache.rotationRegisters.length;
			for (var i:int = 0; i < len; i++)
			{
				code += "m33 " + animationRegisterCache.rotationRegisters[i].regName+animationRegisterCache.rotationRegisters[i].index + ".xyz," + animationRegisterCache.rotationRegisters[i].toString() + "," + rotationMatrixRegister.toString() + "\n";
			}
			return code;
		}
		
	}

}
package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.states.ParticleBillboardGlobalState;
	import away3d.animators.utils.ParticleAnimationCompiler;
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
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler):String
		{
			var rotationMatrixRegister:ShaderRegisterElement = activatedCompiler.getFreeVertexConstant();
			activatedCompiler.setRegisterIndex(this, MATRIX_CONSTANT_REGISTER, rotationMatrixRegister.index);
			activatedCompiler.getFreeVertexConstant();
			activatedCompiler.getFreeVertexConstant();
			activatedCompiler.getFreeVertexConstant();
			
			var code:String = "m33 " + activatedCompiler.scaleAndRotateTarget.toString() + "," + activatedCompiler.scaleAndRotateTarget.toString() + "," + rotationMatrixRegister.toString() + "\n";
			var len:int = activatedCompiler.rotationRegisters.length;
			for (var i:int = 0; i < len; i++)
			{
				code += "m33 " + activatedCompiler.rotationRegisters[i].regName+activatedCompiler.rotationRegisters[i].index + ".xyz," + activatedCompiler.rotationRegisters[i].toString() + "," + rotationMatrixRegister.toString() + "\n";
			}
			return code;
		}
		
	}

}
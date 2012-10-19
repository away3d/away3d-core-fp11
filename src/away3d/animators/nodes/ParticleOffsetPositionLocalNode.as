package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleParamter;
	import away3d.animators.states.ParticleOffsetPositionLocalState;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleOffsetPositionLocalNode extends LocalParticleNodeBase
	{
		public static const NAME:String = "ParticleOffsetPositionLocalNode";
		public static const OFFSET_STREAM_REGISTER:int = 0;
		
		
		public function ParticleOffsetPositionLocalNode()
		{
			super(NAME, 0);
			_stateClass = ParticleOffsetPositionLocalState;
			_dataLenght = 3;
			initOneData();
		}
		
		override public function generatePorpertyOfOneParticle(param:ParticleParamter):void
		{
			var offset:Vector3D = param[NAME];
			if (!offset) throw(new Error("there is no " + NAME + " in param!"));
			
			_oneData[0] = offset.x;
			_oneData[1] = offset.y;
			_oneData[2] = offset.z;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			var offsetAttribute:ShaderRegisterElement = activatedCompiler.getFreeVertexAttribute();
			activatedCompiler.setRegisterIndex(this, OFFSET_STREAM_REGISTER, offsetAttribute.index);
			return "add " + activatedCompiler.offsetTarget.toString() +"," + offsetAttribute.toString() + ".xyz," + activatedCompiler.offsetTarget.toString() + "\n";
		}
		
	}

}
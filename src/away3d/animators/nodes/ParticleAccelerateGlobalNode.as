package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.states.ParticleAccelerateGlobalState;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleAccelerateGlobalNode extends GlobalParticleNodeBase
	{
		public static const NAME:String = "ParticleAccelerateGlobalNode";
		public static const ACCELERATE_CONSTANT_REGISTER:int = 0;
		
		private var _accelrate:Vector3D;
		private var _halfAccelerate:Vector3D;
		
		public function ParticleAccelerateGlobalNode(acc:Vector3D)
		{
			super(NAME);
			_stateClass = ParticleAccelerateGlobalState;
			
			_accelrate = acc.clone();
			_halfAccelerate = _accelrate.clone();
			_halfAccelerate.scaleBy(0.5);
		}
		
		public function get accelrate():Vector3D
		{
			return _accelrate;
		}
		
		public function get halfAccelerate():Vector3D
		{
			return _halfAccelerate;
		}
		
		public function set accelrate(value:Vector3D):void
		{
			_accelrate.x = value.x;
			_accelrate.y = value.y;
			_accelrate.z = value.z;
			_halfAccelerate.x = value.x / 2;
			_halfAccelerate.y = value.y / 2;
			_halfAccelerate.z = value.z / 2;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			var accVelConst:ShaderRegisterElement = activatedCompiler.getFreeVertexConstant();
			activatedCompiler.setRegisterIndex(this, ACCELERATE_CONSTANT_REGISTER, accVelConst.index);
			var temp:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			activatedCompiler.addVertexTempUsages(temp,1);
			var code:String = "";
			code += "mul " + temp.toString() +"," + activatedCompiler.vertexTime.toString() + "," + accVelConst.toString() + "\n";
			
			if (sharedSetting.needVelocity)
			{
				var temp2:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
				code += "mul " + temp2.toString() + "," + temp.toString() + "," + activatedCompiler.vertexTwoConst.toString() + "\n";
				code += "add " + activatedCompiler.velocityTarget.toString() + ".xyz," + temp2.toString() + ".xyz," + activatedCompiler.velocityTarget.toString() + "\n";
			}
			activatedCompiler.removeVertexTempUsage(temp);
			
			code += "mul " + temp.toString() +"," + temp.toString() + "," + activatedCompiler.vertexTime.toString() + "\n";
			code += "add " + activatedCompiler.offsetTarget.toString() +".xyz," + temp.toString() + "," + activatedCompiler.offsetTarget.toString() + ".xyz\n";
			return code;
		}
		
	}

}
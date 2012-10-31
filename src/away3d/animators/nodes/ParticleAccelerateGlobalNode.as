package away3d.animators.nodes
{
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.states.ParticleAccelerateGlobalState;
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
		
		private var _acceleration:Vector3D;
		private var _halfAcceleration:Vector3D;
		
		public function ParticleAccelerateGlobalNode(acceleration:Vector3D)
		{
			super(NAME);
			_stateClass = ParticleAccelerateGlobalState;
			
			_acceleration = acceleration.clone();
			_halfAcceleration = _acceleration.clone();
			_halfAcceleration.scaleBy(0.5);
		}
		
		public function get acceleration():Vector3D
		{
			return _acceleration;
		}
		
		public function get halfAcceleration():Vector3D
		{
			return _halfAcceleration;
		}
		
		public function set acceleration(value:Vector3D):void
		{
			_acceleration.x = value.x;
			_acceleration.y = value.y;
			_acceleration.z = value.z;
			_halfAcceleration.x = value.x / 2;
			_halfAcceleration.y = value.y / 2;
			_halfAcceleration.z = value.z / 2;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, animationRegisterCache:AnimationRegisterCache) : String
		{
			var accVelConst:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, ACCELERATE_CONSTANT_REGISTER, accVelConst.index);
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(temp,1);
			var code:String = "";
			code += "mul " + temp.toString() +"," + animationRegisterCache.vertexTime.toString() + "," + accVelConst.toString() + "\n";
			
			if (sharedSetting.needVelocity)
			{
				var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				code += "mul " + temp2.toString() + "," + temp.toString() + "," + animationRegisterCache.vertexTwoConst.toString() + "\n";
				code += "add " + animationRegisterCache.velocityTarget.toString() + ".xyz," + temp2.toString() + ".xyz," + animationRegisterCache.velocityTarget.toString() + "\n";
			}
			animationRegisterCache.removeVertexTempUsage(temp);
			
			code += "mul " + temp.toString() +"," + temp.toString() + "," + animationRegisterCache.vertexTime.toString() + "\n";
			code += "add " + animationRegisterCache.offsetTarget.toString() +".xyz," + temp.toString() + "," + animationRegisterCache.offsetTarget.toString() + ".xyz\n";
			return code;
		}
		
	}

}
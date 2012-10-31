package away3d.animators.nodes
{
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.states.ParticleAccelerateLocalState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleAccelerateLocalNode extends LocalParticleNodeBase
	{
		public static const NAME:String = "ParticleAccelerateLocalNode";
		public static const ACCELERATELOCAL_STREAM_REGISTER:int = 0;
		
		public function ParticleAccelerateLocalNode()
		{
			super(NAME);
			_stateClass = ParticleAccelerateLocalState;
			_dataLength = 3;
			initOneData();
		}
		
		override public function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			var _tempAccelerate:Vector3D = param[NAME];
			if (!_tempAccelerate)
				throw new Error("there is no " + NAME + " in param!");
			
			_oneData[0] = _tempAccelerate.x / 2;
			_oneData[1] = _tempAccelerate.y / 2;
			_oneData[2] = _tempAccelerate.z / 2;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var accAttribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, ACCELERATELOCAL_STREAM_REGISTER, accAttribute.index);
			
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(temp,1);
			
			
			var code:String = "mul " + temp.toString() +"," + animationRegisterCache.vertexTime.toString() + "," + accAttribute.toString() + "\n";
			
			if (animationRegisterCache.needVelocity)
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
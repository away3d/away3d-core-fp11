package away3d.animators.nodes
{
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleParamter;
	import away3d.animators.states.ParticleBezierCurvelByLifelocalState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	/**
	 * Bezier formula : P(t)=2t*(1-t)*P1+t*t*P2
	 */
	public class ParticleBezierCurvelByLifelocalNode extends LocalParticleNodeBase
	{
		public static const NAME:String = "ParticleBezierCurvelByLifelocalNode";
		public static const BEZIER_STREAM_REGISTER:int = 0;
		
		
		public function ParticleBezierCurvelByLifelocalNode()
		{
			super(NAME);
			_stateClass = ParticleBezierCurvelByLifelocalState;
			
			_dataLenght = 6;
			initOneData();
		}
		
		override public function generatePorpertyOfOneParticle(param:ParticleParamter):void
		{
			//[controlPoint:Vector3D,endPoint:Vector3D].
			var bezierPoints:Array = param[NAME];
			if (!bezierPoints)
				throw new Error("there is no " + NAME + " in param!");
			
			_oneData[0] = bezierPoints[0].x;
			_oneData[1] = bezierPoints[0].y;
			_oneData[2] = bezierPoints[0].z;
			_oneData[3] = bezierPoints[1].x;
			_oneData[4] = bezierPoints[1].y;
			_oneData[5] = bezierPoints[1].z;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, animationRegisterCache:AnimationRegisterCache) : String
		{
			var p1Attribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, BEZIER_STREAM_REGISTER, p1Attribute.index);
			var p2Attribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
			
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var rev_time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var time_2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var time_temp:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			animationRegisterCache.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "xyz");
			animationRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "sub " + rev_time.toString() + "," + animationRegisterCache.vertexOneConst.toString() + "," + animationRegisterCache.vertexLife.toString() + "\n";
			code += "mul " + time_2.toString() + "," + animationRegisterCache.vertexLife.toString() + "," + animationRegisterCache.vertexLife.toString() + "\n";
			
			code += "mul " + time_temp.toString() + "," + animationRegisterCache.vertexLife.toString() +"," + rev_time.toString() + "\n";
			code += "mul " + time_temp.toString() + "," + time_temp.toString() +"," + animationRegisterCache.vertexTwoConst.toString() + "\n";
			code += "mul " + distance.toString() + "," + time_temp.toString() +"," + p1Attribute.toString() + "\n";
			code += "add " + animationRegisterCache.offsetTarget.toString() +".xyz," + distance.toString() + "," + animationRegisterCache.offsetTarget.toString() + ".xyz\n";
			code += "mul " + distance.toString() + "," + time_2.toString() +"," + p2Attribute.toString() + "\n";
			code += "add " + animationRegisterCache.offsetTarget.toString() +".xyz," + distance.toString() + "," + animationRegisterCache.offsetTarget.toString() + ".xyz\n";
			
			if (sharedSetting.needVelocity)
			{
				code += "mul " + time_2.toString() + "," + animationRegisterCache.vertexLife.toString() + "," + animationRegisterCache.vertexTwoConst.toString() + "\n";
				code += "sub " + time_temp.toString() + "," + animationRegisterCache.vertexOneConst.toString() + "," + time_2.toString() + "\n";
				code += "mul " + time_temp.toString() + "," + animationRegisterCache.vertexTwoConst.toString() + "," + time_temp.toString() + "\n";
				code += "mul " + distance.toString() + "," + p1Attribute.toString() + "," + time_temp.toString() + "\n";
				code += "add " + animationRegisterCache.velocityTarget.toString() + ".xyz," + distance.toString() + "," + animationRegisterCache.velocityTarget.toString() + ".xyz\n";
				code += "mul " + distance.toString() + "," + p2Attribute.toString() + "," + time_2.toString() + "\n";
				code += "add " + animationRegisterCache.velocityTarget.toString() + ".xyz," + distance.toString() + "," + animationRegisterCache.velocityTarget.toString() + ".xyz\n";
			}
			
			return code;
		}
	}

}
package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.states.ParticleBezierCurvelByLifeGlobalState;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleBezierCurvelByLifeGlobalNode extends GlobalParticleNodeBase
	{
		public static const NAME:String = "ParticleBezierCurvelByLifeGlobalNode";
		public static const BEZIER_CONSTANT_REGISTER:int = 0;
		private var _controlPoint:Vector3D;
		private var _endPoint:Vector3D;
		
		public function ParticleBezierCurvelByLifeGlobalNode(control:Vector3D,end:Vector3D)
		{
			super(NAME);
			_stateClass = ParticleBezierCurvelByLifeGlobalState;
			
			_controlPoint = control;
			_endPoint = end;
		}
		
		public function get controlPoint():Vector3D
		{
			return _controlPoint;
		}
		
		public function set controlPoint(value:Vector3D):void
		{
			_controlPoint = value;
		}
		
		public function get endPoint():Vector3D
		{
			return _endPoint;
		}
		
		public function set endPoint(value:Vector3D):void
		{
			_endPoint = value;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			var _controlConst:ShaderRegisterElement = activatedCompiler.getFreeVertexConstant();
			activatedCompiler.setRegisterIndex(this, BEZIER_CONSTANT_REGISTER, _controlConst.index);
			var _endConst:ShaderRegisterElement = activatedCompiler.getFreeVertexConstant();
			
			var temp:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			var rev_time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var time_2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var time_temp:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			activatedCompiler.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "xyz");
			activatedCompiler.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "sub " + rev_time.toString() + "," + activatedCompiler.vertexOneConst.toString() + "," + activatedCompiler.vertexLife.toString() + "\n";
			code += "mul " + time_2.toString() + "," + activatedCompiler.vertexLife.toString() + "," + activatedCompiler.vertexLife.toString() + "\n";
			
			code += "mul " + time_temp.toString() + "," + activatedCompiler.vertexLife.toString() +"," + rev_time.toString() + "\n";
			code += "mul " + time_temp.toString() + "," + time_temp.toString() +"," + activatedCompiler.vertexTwoConst.toString() + "\n";
			code += "mul " + distance.toString() + "," + time_temp.toString() +"," + _controlConst.toString() + "\n";
			code += "add " + activatedCompiler.offsetTarget.toString() +".xyz," + distance.toString() + "," + activatedCompiler.offsetTarget.toString() + ".xyz\n";
			code += "mul " + distance.toString() + "," + time_2.toString() +"," + _endConst.toString() + "\n";
			code += "add " + activatedCompiler.offsetTarget.toString() +".xyz," + distance.toString() + "," + activatedCompiler.offsetTarget.toString() + ".xyz\n";
			
			if (sharedSetting.needVelocity)
			{
				code += "mul " + time_2.toString() + "," + activatedCompiler.vertexLife.toString() + "," + activatedCompiler.vertexTwoConst.toString() + "\n";
				code += "sub " + time_temp.toString() + "," + activatedCompiler.vertexOneConst.toString() + "," + time_2.toString() + "\n";
				code += "mul " + time_temp.toString() + "," + activatedCompiler.vertexTwoConst.toString() + "," + time_temp.toString() + "\n";
				code += "mul " + distance.toString() + "," + _controlConst.toString() + "," + time_temp.toString() + "\n";
				code += "add " + activatedCompiler.velocityTarget.toString() + ".xyz," + distance.toString() + "," + activatedCompiler.velocityTarget.toString() + ".xyz\n";
				code += "mul " + distance.toString() + "," + _endConst.toString() + "," + time_2.toString() + "\n";
				code += "add " + activatedCompiler.velocityTarget.toString() + ".xyz," + distance.toString() + "," + activatedCompiler.velocityTarget.toString() + ".xyz\n";
			}
			
			return code;
		}
		
		
	}

}
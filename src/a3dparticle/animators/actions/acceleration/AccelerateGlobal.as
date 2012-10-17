package a3dparticle.animators.actions.acceleration
{
	import a3dparticle.animators.actions.AllParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.compilation.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class AccelerateGlobal extends AllParticleAction
	{
		private var _data:Vector.<Number>;
		
		public function AccelerateGlobal(acc:Vector3D)
		{
			_data = new Vector.<Number>(4, true);
			_data[0] = acc.x / 2;
			_data[1] = acc.y / 2;
			_data[2] = acc.z / 2;
			_data[3] = 0;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var accVelConst:ShaderRegisterElement = shaderRegisterCache.getFreeVertexConstant();
			saveRegisterIndex("accVelConst", accVelConst.index);
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp,1);
			var code:String = "";
			code += "mul " + temp.toString() +"," + animationRegistersManager.vertexTime.toString() + "," + accVelConst.toString() + "\n";
			
			if (_animation.needVelocity)
			{
				var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
				code += "mul " + temp2.toString() + "," + temp.toString() + "," + animationRegistersManager.vertexTwoConst.toString() + "\n";
				code += "add " + animationRegistersManager.velocityTarget.toString() + ".xyz," + temp2.toString() + ".xyz," + animationRegistersManager.velocityTarget.toString() + "\n";
			}
			shaderRegisterCache.removeVertexTempUsage(temp);
			
			code += "mul " + temp.toString() +"," + temp.toString() + "," + animationRegistersManager.vertexTime.toString() + "\n";
			code += "add " + animationRegistersManager.offsetTarget.toString() +".xyz," + temp.toString() + "," + animationRegistersManager.offsetTarget.toString() + ".xyz\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, getRegisterIndex("accVelConst"), _data);
		}
		
	}

}
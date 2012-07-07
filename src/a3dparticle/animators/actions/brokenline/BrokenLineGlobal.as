package a3dparticle.animators.actions.brokenline 
{
	import a3dparticle.animators.actions.AllParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class BrokenLineGlobal extends AllParticleAction
	{
		private var vertices_vec:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
		private var _brokenRegisters:Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>();
		private var _brokenCount:uint;
		
		/**
		 * 
		 * @param	brokenData Array.the element of array is Vector3D which (x,y,z) is the velocity,w is the during time.Because agal only allow 200 opcode,the broken.lenght is limited.
		 */
		public function BrokenLineGlobal(brokenData:Array) 
		{
			_brokenCount = brokenData.length;
			for (var i:int; i < brokenData.length; i++)
			{
				vertices_vec.push(new Vector.<Number>());
				vertices_vec[i].push(brokenData[i].x)
				vertices_vec[i].push(brokenData[i].y)
				vertices_vec[i].push(brokenData[i].z)
				vertices_vec[i].push(brokenData[i].w)
			}
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			for (var j:int = 0; j < vertices_vec.length; j++)
			{
				_brokenRegisters.push(shaderRegisterCache.getFreeVertexConstant());
			}
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp, 1);
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "xyz");
			var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp2, 1);
			var time:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "x");
			var max:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "y");
			var sge:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "z");
			var slt:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "w");
			
			
			shaderRegisterCache.removeVertexTempUsage(temp);
			shaderRegisterCache.removeVertexTempUsage(temp2);
			

			var code:String = "";
			code += "mov " + time.toString() + "," + _animation.vertexTime.toString() + "\n";
			for (var i:int = 0; i < _brokenRegisters.length; i++)
			{
				code += "min " + max.toString() + "," + time.toString() + "," + _brokenRegisters[i].toString() + ".w\n";
				code += "max " + max.toString() + "," + max.toString() + "," + _animation.zeroConst.toString() + "\n";
				code += "mul " + distance.toString() + "," + _brokenRegisters[i].toString() + ".xyz," + max.toString() + "\n";
				code += "add " + _animation.offsetTarget.toString() + "," + distance.toString() + "," + _animation.offsetTarget.toString() + "\n";
				if (_animation.needVelocity)
				{
					code += "slt " + slt.toString() + "," + _animation.zeroConst.toString() + "," + time.toString() + "\n";
				}
				code += "sub " + time.toString() + "," + time.toString() + "," + _brokenRegisters[i].toString() + ".w\n";
				if (_animation.needVelocity)
				{
					code += "sge " + sge.toString() + "," + _animation.zeroConst.toString() + "," + time.toString() + "\n";
					code += "mul " + sge.toString() + "," + sge.toString() + "," + slt.toString() + "\n";
					code += "mul " + distance.toString() + "," + sge.toString() + "," + _brokenRegisters[i].toString() + ".xyz\n";
					code += "add " + _animation.velocityTarget.toString() + "," + _animation.velocityTarget.toString() + "," + distance.toString() + "\n";
				}
			}

			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			for (var i:int = 0; i < _brokenCount; i++)
			{
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _brokenRegisters[i].index, vertices_vec[i]);
			}
		}
	}

}
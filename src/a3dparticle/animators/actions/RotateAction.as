package a3dparticle.animators.actions 
{
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;

	/**
	 * ...
	 * @author ...
	 */
	public class RotateAction extends PerParticleAction
	{
		//the function return a Vector3D. (Vector3d.x,Vector3d.y,Vector3d.z) is roatate axis,Vector3d.w is cycle time
		private var _genFun:Function;
		
		private var _tempRotateAxis:Vector3D;
		
		private var _tempRotateRate:Number;
		
		private var roatateAttribute:ShaderRegisterElement;
		
		public function RotateAction(fun:Function) 
		{
			dataLenght = 4;
			_genFun = fun;
		}
		
		override public function genOne(index:uint):void
		{
			var temp:Vector3D = _genFun(index);
			_tempRotateAxis = new Vector3D(temp.x, temp.y, temp.z);
			_tempRotateAxis.normalize();
			_tempRotateRate = Math.PI*2/temp.w;
		}
		
		override public function distributeOne(index:int, verticeIndex:uint):void
		{
			_vertices.push(_tempRotateAxis.x);
			_vertices.push(_tempRotateAxis.y);
			_vertices.push(_tempRotateAxis.z);
			_vertices.push(_tempRotateRate);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			roatateAttribute = shaderRegisterCache.getFreeVertexAttribute();
			
			var matrix1:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			//make sure there are enough registers
			shaderRegisterCache.addVertexTempUsages(matrix1, 1);
			var matrix2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(matrix2, 1);
			var matrix3:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(matrix3, 1);
			var matrix4:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(matrix4, 1);
			

			var temp1:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp1, 1);
			var degree:ShaderRegisterElement = new ShaderRegisterElement(temp1.regName, temp1.index, "x");
			var cos_degree:ShaderRegisterElement = new ShaderRegisterElement(temp1.regName, temp1.index, "y");
			var sin_degree:ShaderRegisterElement = new ShaderRegisterElement(temp1.regName, temp1.index, "z");
			var _rev_cos_degree:ShaderRegisterElement = new ShaderRegisterElement(temp1.regName, temp1.index, "w");//1-cos_degree
			
			var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			
			shaderRegisterCache.removeVertexTempUsage(matrix1);
			shaderRegisterCache.removeVertexTempUsage(matrix2);
			shaderRegisterCache.removeVertexTempUsage(matrix3);
			shaderRegisterCache.removeVertexTempUsage(matrix4);
			shaderRegisterCache.removeVertexTempUsage(temp1);
			
			var code:String = "";
			code += "mul " + degree.toString() + "," + _animation.vertexTime.toString() + "," + roatateAttribute.toString() + ".w\n";
			code += "cos " + cos_degree.toString() + "," + degree.toString() + "\n";
			code += "sin " + sin_degree.toString() + "," + degree.toString() + "\n";
			
			code += "mov " + matrix1.toString() + ".xyz," + roatateAttribute.toString() + ".xxx\n";
			code += "mov " + matrix2.toString() + ".xyz," + roatateAttribute.toString() + ".yyy\n";
			code += "mov " + matrix3.toString() + ".xyz," + roatateAttribute.toString() + ".zzz\n";
			
			code += "sub " + temp2.toString() +".x," + _animation.OneConst.toString() + ".x," + cos_degree.toString() + "\n";
			code += "mov " + _rev_cos_degree.toString() +"," + temp2.toString() + ".x\n";
			
			
			code += "mul " + matrix1.toString() + ".xyz," + matrix1.toString() + ".xyz," + _rev_cos_degree.toString() + "\n";
			code += "mul " + matrix2.toString() + ".xyz," + matrix2.toString() + ".xyz," + _rev_cos_degree.toString() + "\n";
			code += "mul " + matrix3.toString() + ".xyz," + matrix3.toString() + ".xyz," + _rev_cos_degree.toString() + "\n";
			
			code += "mul " + matrix1.toString() + ".xyz," + matrix1.toString() + ".xyz," + roatateAttribute.toString() + ".xyz\n";
			code += "mul " + matrix2.toString() + ".xyz," + matrix2.toString() + ".xyz," + roatateAttribute.toString() + ".xyz\n";
			code += "mul " + matrix3.toString() + ".xyz," + matrix3.toString() + ".xyz," + roatateAttribute.toString() + ".xyz\n";
			
			code += "mov " +temp2.toString() + ".x," + cos_degree.toString() + "\n";
			code += "mul " +temp2.toString() + ".y," + roatateAttribute.toString() + ".z," + sin_degree.toString() + "\n";
			code += "mul " +temp2.toString() + ".z," + roatateAttribute.toString() + ".y," + sin_degree.toString() + "\n";
			code += "neg " +temp2.toString() + ".z," + temp2.toString() + ".z\n";
			code += "add " + matrix1.toString() +".xyz," + matrix1.toString() + ".xyz," + temp2.toString() + ".xyz\n";
			
			
			code += "mul " +temp2.toString() + ".x," + roatateAttribute.toString() + ".z," + sin_degree.toString() + "\n";
			code += "neg " +temp2.toString() + ".x," + temp2.toString() + ".x\n";
			code += "mov " +temp2.toString() + ".y," + cos_degree.toString() + "\n";
			code += "mul " +temp2.toString() + ".z," + roatateAttribute.toString() + ".x," + sin_degree.toString() + "\n";
			code += "add " + matrix2.toString() +".xyz," + matrix2.toString() + ".xyz," + temp2.toString() + ".xyz\n";
			
			code += "mul " +temp2.toString() + ".x," + roatateAttribute.toString() + ".y," + sin_degree.toString() + "\n";
			code += "mul " +temp2.toString() + ".y," + roatateAttribute.toString() + ".x," + sin_degree.toString() + "\n";
			code += "neg " +temp2.toString() + ".y," + temp2.toString() + ".y\n";
			code += "mov " +temp2.toString() + ".z," + cos_degree.toString() + "\n";
			code += "add " + matrix3.toString() +".xyz," + matrix3.toString() + ".xyz," + temp2.toString() + ".xyz\n";
			
			code += "mov " +matrix1.toString() + ".w," + _animation.zeroConst.toString() + "\n";
			code += "mov " +matrix2.toString() + ".w," + _animation.zeroConst.toString() + "\n";
			code += "mov " +matrix3.toString() + ".w," + _animation.zeroConst.toString() + "\n";
			code += "mov " +matrix4.toString() + ".w," + _animation.zeroConst.toString() + "\n";
			
			code += "m44 " + temp2.toString() +"," + _animation.positionAttribute.toString() + "," + matrix1.toString() + "\n";
			code += "sub " + temp2.toString() +"," + temp2.toString() + "," + _animation.positionAttribute.toString() + "\n";
			code += "add " + _animation.postionTarget.toString() +".xyz," + temp2.toString() + "," + _animation.postionTarget.toString() + ".xyz\n";
			
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(roatateAttribute.index, getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_4);
		}
		
	}

}
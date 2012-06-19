package a3dparticle.animators.actions.rotation 
{
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
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
	public class RandomRotateLocal extends PerParticleAction
	{
		private var _genFun:Function;
		
		private var _tempRotateAxis:Vector3D;
		
		private var _tempRotateRate:Number;
		
		private var roatateAttribute:ShaderRegisterElement;
		
		/**
		 * 
		 * @param	fun Function.the function return a Vector3D. (Vector3d.x,Vector3d.y,Vector3d.z) is roatate axis,Vector3d.w is cycle time
		 */
		public function RandomRotateLocal(fun:Function=null) 
		{
			dataLenght = 4;
			_name = "RandomRotateLocal";
			_genFun = fun;
		}
		
		override public function genOne(param:ParticleParam):void
		{
			var temp:Vector3D;
			if (_genFun != null)
			{
				temp = _genFun(param);
			}
			else
			{
				if (!param[_name]) throw new Error("there is no " + _name + " in param!");
				temp = param[_name];
			}
			_tempRotateAxis = new Vector3D(temp.x, temp.y, temp.z);
			_tempRotateAxis.normalize();
			_tempRotateRate = Math.PI/temp.w;
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(_tempRotateAxis.x);
			getExtraData(subContainer).push(_tempRotateAxis.y);
			getExtraData(subContainer).push(_tempRotateAxis.z);
			getExtraData(subContainer).push(_tempRotateRate);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			roatateAttribute = shaderRegisterCache.getFreeVertexAttribute();
			/*
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
			code += "add " + _animation.offsetTarget.toString() +".xyz," + temp2.toString() + "," + _animation.offsetTarget.toString() + ".xyz\n";
			*/
			
			var nrmVel:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(nrmVel, 1);
			
			var xAxis:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(xAxis, 1);
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp,1);
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var cos2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			var tempSingle:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "w");
			
			var R:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(R,1);
			var R_rev:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			
			shaderRegisterCache.removeVertexTempUsage(nrmVel);
			shaderRegisterCache.removeVertexTempUsage(xAxis);
			shaderRegisterCache.removeVertexTempUsage(temp);
			shaderRegisterCache.removeVertexTempUsage(R);
			
			var code:String = "";
			code += "mov " + nrmVel.toString() + ".xyz," + roatateAttribute.toString() + ".xyz\n";
			code += "mov " + nrmVel.toString() + ".w," + _animation.zeroConst.toString() + "\n";
			
			code += "mul " + tempSingle.toString() + "," + _animation.vertexTime.toString() + "," + roatateAttribute.toString() + ".w\n";
			
			code += "cos " + cos.toString() + "," + tempSingle.toString() + "\n";
			code += "sin " + sin.toString() + "," + tempSingle.toString() + "\n";
			
			
			code += "mul " + R.toString() + ".xyz," + sin.toString() +"," + nrmVel.toString() + ".xyz\n";
			//code += "mov " + R.toString() + ".w," + cos.toString() + "\n";
			//use cos as R.w
			
			code += "mul " + R_rev.toString() + ".xyz," + sin.toString() + "," + nrmVel.toString() + ".xyz\n";
			code += "neg " + R_rev.toString() + ".xyz," + R_rev.toString() + ".xyz\n";
			//code += "mov " + R_rev.toString() + ".w," + cos.toString() + "\n";
			//use cos as R_rev.w
			
			//nrmVel and xAxis are used as temp register
			code += "crs " + nrmVel.toString() + ".xyz," + R.toString() + ".xyz," +_animation.scaleAndRotateTarget.toString() + ".xyz\n";
			//code += "mul " + xAxis.toString() + ".xyz," + R.toString() +".w," + _animation.scaleAndRotateTarget.toString() + ".xyz\n";
			//use cos as R.w
			code += "mul " + xAxis.toString() + ".xyz," + cos.toString() +"," + _animation.scaleAndRotateTarget.toString() + ".xyz\n";
			code += "add " + nrmVel.toString() + ".xyz," + nrmVel.toString() +".xyz," + xAxis.toString() + ".xyz\n";
			code += "dp3 " + xAxis.toString() + ".w," + R.toString() + ".xyz," +_animation.scaleAndRotateTarget.toString() + ".xyz\n";
			code += "neg " + nrmVel.toString() + ".w," + xAxis.toString() + ".w\n";
			
			
			code += "crs " + R.toString() + ".xyz," + nrmVel.toString() + ".xyz," +R_rev.toString() + ".xyz\n";
			//code += "mul " + xAxis.toString() + ".xyzw," + nrmVel.toString() + ".xyzw," +R_rev.toString() + ".w\n";
			//use cos as R_rev.w
			code += "mul " + xAxis.toString() + ".xyzw," + nrmVel.toString() + ".xyzw," +cos.toString() + ".w\n";
			code += "add " + R.toString() + ".xyz," + R.toString() + ".xyz," + xAxis.toString() + ".xyz\n";
			code += "mul " + xAxis.toString() + ".xyz," + nrmVel.toString() + ".w," +R_rev.toString() + ".xyz\n";
			
			code += "add " + _animation.scaleAndRotateTarget.toString() + "," + R.toString() + ".xyz," + xAxis.toString() + ".xyz\n";
			
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(roatateAttribute.index, getExtraBuffer(stage3DProxy, SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_4, 0);
		}
		
	}

}
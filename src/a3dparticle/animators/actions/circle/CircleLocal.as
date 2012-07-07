package a3dparticle.animators.actions.circle 
{
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class CircleLocal extends PerParticleAction
	{
		private var _dataFun:Function;
		
		private var _eulers:Vector3D;
		private var _tempVelocity:Vector3D;
		
		private var _radius:Number;
		private var _cycle:Number;
		private var _eulersMatrix:Matrix3D;
		
		private var circleAttribute:ShaderRegisterElement;
		private var eulersMatrixRegister:ShaderRegisterElement;
		/**
		 * 
		 * @param	fun Function.The fun return a a Vector3D. Vector3D.x is radius,Vector3D.y is cycle
		 * @param	eulers Vector3D.The eulers of the rotate.
		 */
		public function CircleLocal(fun:Function=null,eulers:Vector3D=null) 
		{
			_name = "CircleLocal";
			_dataFun = fun;
			_eulers = new Vector3D();
			if (eulers)_eulers = eulers.clone();
			_eulersMatrix = new Matrix3D();
			_eulersMatrix.appendRotation(_eulers.x, new Vector3D(1, 0, 0));
			_eulersMatrix.appendRotation(_eulers.y, new Vector3D(0, 1, 0));
			_eulersMatrix.appendRotation(_eulers.z, new Vector3D(0, 0, 1));
		}
		
		override public function genOne(param:ParticleParam):void
		{
			var temp:Vector3D;
			if (_dataFun != null)
			{
				temp = _dataFun(param);
			}
			else
			{
				if (!param[_name]) throw(new Error("there is no " + _name + " in param!"));
				temp = param[_name];
			}
			_radius = temp.x;
			_cycle = temp.y;
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(_radius);
			getExtraData(subContainer).push(Math.PI * 2 / _cycle);
			if (_animation.needVelocity) getExtraData(subContainer).push(_radius * Math.PI * 2);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			if (_animation.needVelocity) dataLenght = 3
			else dataLenght = 2;
			
			
			circleAttribute = shaderRegisterCache.getFreeVertexAttribute();
			eulersMatrixRegister = shaderRegisterCache.getFreeVertexConstant();
			shaderRegisterCache.getFreeVertexConstant();
			shaderRegisterCache.getFreeVertexConstant();
			shaderRegisterCache.getFreeVertexConstant();
			
			var temp1:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp1,1);
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp1.regName, temp1.index);
			
			
			var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "x");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "y");
			var degree:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "z");
			shaderRegisterCache.removeVertexTempUsage(temp1);
			
			var code:String = "";
			code += "mul " + degree.toString() + "," + _animation.vertexTime.toString() + "," + circleAttribute.toString() + ".y\n";
			code += "cos " + cos.toString() +"," + degree.toString() + "\n";
			code += "sin " + sin.toString() +"," + degree.toString() + "\n";
			code += "mul " + distance.toString() +".x," + cos.toString() +"," + circleAttribute.toString() + ".x\n";
			code += "mul " + distance.toString() +".y," + sin.toString() +"," + circleAttribute.toString() + ".x\n";
			code += "mov " + distance.toString() + ".wz" + _animation.zeroConst.toString() + "\n";
			code += "m44 " + distance.toString() + "," + distance.toString() + "," +eulersMatrixRegister.toString() + "\n";
			code += "add " + _animation.offsetTarget.toString() + ".xyz," + distance.toString() + ".xyz," + _animation.offsetTarget.toString() + ".xyz\n";
			
			if (_animation.needVelocity)
			{
				code += "neg " + distance.toString() + ".x," + sin.toString() + "\n";
				code += "mov " + distance.toString() + ".y," + cos.toString() + "\n";
				code += "mov " + distance.toString() + ".zw," + _animation.zeroConst.toString() + "\n";
				code += "m44 " + distance.toString() + "," + distance.toString() + "," +eulersMatrixRegister.toString() + "\n";
				code += "mul " + distance.toString() + "," + distance.toString() + "," +circleAttribute.toString() + ".z\n";
				code += "div " + distance.toString() + "," + distance.toString() + "," +circleAttribute.toString() + ".y\n";
				code += "add " + _animation.velocityTarget.toString() + ".xyz," + _animation.velocityTarget.toString() + ".xyz," +distance.toString() + ".xyz\n";
			}
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			if (_animation.needVelocity) stage3DProxy.setSimpleVertexBuffer(circleAttribute.index, getExtraBuffer(stage3DProxy, SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_3, 0);
			else stage3DProxy.setSimpleVertexBuffer(circleAttribute.index, getExtraBuffer(stage3DProxy, SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_2, 0);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, eulersMatrixRegister.index, _eulersMatrix.rawData, 4);
		}
		
	}

}
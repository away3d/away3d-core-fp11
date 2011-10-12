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
	public class AccelerateForPerAction extends PerParticleAction
	{
		private var _accFun:Function;
		
		private var _tempAcc:Vector3D;
		
		private var accAttribute:ShaderRegisterElement;
		
		public function AccelerateForPerAction(fun:Function) 
		{
			dataLenght = 3;
			_accFun = fun;
		}
		
		override public function genOne(index:uint):void
		{
			_tempAcc = _accFun(index);
		}
		
		override public function distributeOne(index:int, verticeIndex:uint):void
		{
			_vertices.push(_tempAcc.x);
			_vertices.push(_tempAcc.y);
			_vertices.push(_tempAcc.z);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			accAttribute = shaderRegisterCache.getFreeVertexAttribute();
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "xyz");
			var squTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "w");
			
			var code:String = "";
			code += "mul " + squTime.toString() +"," + _animation.vertexTime.toString() + "," + _animation.vertexTime.toString() + "\n";
			code += "mul " + distance.toString() +"," + squTime.toString() + "," + accAttribute.toString() + "\n";
			code += "add " + _animation.postionTarget.toString() +".xyz," + distance.toString() + "," + _animation.postionTarget.toString() + ".xyz\n";		
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(accAttribute.index, getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3);
		}
		
	}

}
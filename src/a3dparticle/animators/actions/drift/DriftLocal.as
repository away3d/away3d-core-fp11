package a3dparticle.animators.actions.drift 
{
	import a3dparticle.animators.actions.PerParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class DriftLocal extends PerParticleAction
	{
		private var driftAttribute:ShaderRegisterElement;
		
		//return a Vector3D that (Vector3D.x,Vector3D.y,Vector3D.z) is drift position,Vector3D.w is drift cycle
		private var _driftFun:Function;
		
		private var _driftData:Vector3D;
		
		public function DriftLocal(fun:Function) 
		{
			dataLenght = 4;
			_driftFun = fun;
		}
		
		override public function genOne(index:uint):void
		{
			_driftData = _driftFun(index);
		}
		
		override public function distributeOne(index:int, verticeIndex:uint):void
		{
			_vertices.push(_driftData.x);
			_vertices.push(_driftData.y);
			_vertices.push(_driftData.z);
			_vertices.push(_driftData.w);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			driftAttribute = shaderRegisterCache.getFreeVertexAttribute();
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var frc:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index,"w");
			var dgree:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			shaderRegisterCache.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "xyz");
			shaderRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "div " + frc.toString() + "," + _animation.vertexTime.toString() + "," + driftAttribute.toString() + ".w\n";
			code += "frc " + frc.toString() + "," + frc.toString() + "\n";
			code += "mul " + dgree.toString() + "," + frc.toString() + "," + _animation.piConst.toString() + ".x\n";
			code += "sin " + sin.toString() + "," + dgree.toString() + "\n";
			code += "mul " + distance.toString() + "," + sin.toString() + "," + driftAttribute.toString() + ".xyz\n";
			code += "add " + _animation.offestTarget.toString() +".xyz," + distance.toString() + "," + _animation.offestTarget.toString() + ".xyz\n";
			
			if (_animation.needVelocity)
			{	code += "cos " + cos.toString() + "," + dgree.toString() + "\n";
				code += "mul " + distance.toString() + "," + cos.toString() + "," + driftAttribute.toString() + ".xyz\n";
				code += "add " + _animation.velocityTarget.toString() + ".xyz," + distance.toString() + "," + _animation.velocityTarget.toString() + ".xyz\n";
			}
			
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(driftAttribute.index, getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_4);
		}
	}

}
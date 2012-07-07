package a3dparticle.animators.actions.drift 
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
		
		public function DriftLocal(fun:Function=null) 
		{
			dataLenght = 4;
			_name = "DriftLocal";
			_driftFun = fun;
		}
		
		override public function genOne(param:ParticleParam):void
		{
			if (_driftFun != null)
			{
				_driftData = _driftFun(param);
			}
			else
			{
				if (!param[_name]) throw new Error("there is no " + _name + " in param!");
				_driftData = param[_name];
			}
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(_driftData.x);
			getExtraData(subContainer).push(_driftData.y);
			getExtraData(subContainer).push(_driftData.z);
			getExtraData(subContainer).push( Math.PI * 2 / _driftData.w);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			driftAttribute = shaderRegisterCache.getFreeVertexAttribute();
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var dgree:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			shaderRegisterCache.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "xyz");
			shaderRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "mul " + dgree.toString() + "," + _animation.vertexTime.toString() + "," + driftAttribute.toString() + ".w\n";
			code += "sin " + sin.toString() + "," + dgree.toString() + "\n";
			code += "mul " + distance.toString() + "," + sin.toString() + "," + driftAttribute.toString() + ".xyz\n";
			code += "add " + _animation.offsetTarget.toString() +"," + distance.toString() + "," + _animation.offsetTarget.toString() + "\n";
			
			if (_animation.needVelocity)
			{	code += "cos " + cos.toString() + "," + dgree.toString() + "\n";
				code += "mul " + distance.toString() + "," + cos.toString() + "," + driftAttribute.toString() + ".xyz\n";
				code += "add " + _animation.velocityTarget.toString() + ".xyz," + distance.toString() + "," + _animation.velocityTarget.toString() + ".xyz\n";
			}
			
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(driftAttribute.index, getExtraBuffer(stage3DProxy, SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_4, 0);
		}
	}

}
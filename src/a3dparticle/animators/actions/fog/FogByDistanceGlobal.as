package a3dparticle.animators.actions.fog 
{
	import a3dparticle.animators.actions.AllParticleAction;
	import a3dparticle.animators.ParticleAnimation;
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
	 * @author liaocheng
	 */
	public class FogByDistanceGlobal extends AllParticleAction
	{
		private var _camerVary:ShaderRegisterElement;
		private var _fogConst:ShaderRegisterElement;
		
		private var _fogData : Vector.<Number>;
		
		public function FogByDistanceGlobal(fogDistance : Number, fogColor : uint = 0x808080) 
		{
			_fogData = new Vector.<Number>(4, true);
			_fogData[0] = ((fogColor >> 16) & 0xff) / 0xff;
			_fogData[1] = ((fogColor >> 8) & 0xff) / 0xff;
			_fogData[2] = (fogColor & 0xff) / 0xff;
			_fogData[3] = 1 / fogDistance;
		}
		
		override public function set animation(value:ParticleAnimation):void
		{
			value.needCameraPosition = true;
			super.animation = value;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			_camerVary = shaderRegisterCache.getFreeVarying();
			_fogConst = shaderRegisterCache.getFreeFragmentConstant();
			
			var code:String = "";
			code += "sub " + _camerVary.toString() + "," + _animation.offsetTarget.toString() + "," + _animation.cameraPosConst.toString() + "\n";
			return code;
		}
		
		override public function getAGALFragmentCode(pass : MaterialPassBase) : String
		{
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeFragmentVectorTemp();
			var code:String = "";
			code += "dp3 " + temp.toString() + ".w," + _camerVary + ".xyz," + _camerVary.toString() + ".xyz\n";
			code += "sqt " + temp.toString() + ".w," + temp.toString() + ".w\n";
			code += "mul " + temp.toString() + ".w," + temp.toString() + ".w," + _fogConst.toString() + ".w\n";
			code += "sub " + temp.toString() + ".w," + temp.toString() + ".w," + _animation.fragmentOneConst.toString() + "\n";
			code += "max " + temp.toString() + ".w," + _animation.fragmentZeroConst.toString() + "," + temp.toString() + ".w\n";
			code += "neg " + temp.toString() + ".w," + temp.toString() + ".w\n";
			code += "exp " + temp.toString() + ".w," + temp.toString() + ".w\n";
			code += "sub " + temp.toString() + ".xyz," + _animation.colorTarget.toString() + ".xyz, " + _fogConst.toString() + ".xyz\n";
			code += "mul " + temp.toString() + ".xyz," + temp.toString() + ".xyz," + temp.toString() + ".w\n";
			code += "add " + _animation.colorTarget.toString() + ".xyz, " + _fogConst.toString() + ".xyz, " + temp.toString() + ".xyz\n";
			
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _fogConst.index, _fogData);
		}
		
	}

}
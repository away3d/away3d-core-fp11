package a3dparticle.animators.actions 
{
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	
	
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class ScaleByLifeAction extends AllParticleAction
	{
		private var _startScale:Number;
		private var _endScale:Number;
		
		private var scaleByLifeConst:ShaderRegisterElement;
		
		public function ScaleByLifeAction(startScale:Number,endScale:Number) 
		{
			_startScale = startScale;
			_endScale = endScale;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			scaleByLifeConst = shaderRegisterCache.getFreeVertexConstant();
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var scale:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index,"w");
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "xyz");
			
			var code:String = "";
			code += "mul " + scale.toString() + "," + _animation.vertexLife.toString() + "," + scaleByLifeConst.toString() + ".y\n";
			code += "add " + scale.toString() + "," + scale.toString() + "," + scaleByLifeConst.toString() + ".x\n";
			
			code += "mul " + distance.toString() + "," + scale.toString() +"," + _animation.positionAttribute.toString() + ".xyz\n";
			code += "sub " + distance.toString() + "," + distance.toString() +"," + _animation.positionAttribute.toString() + ".xyz\n";
			code += "add " + _animation.postionTarget.toString() +".xyz," +_animation.postionTarget.toString() + ".xyz," + distance.toString() + "\n";
			return code;
			
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			var _delta:Number = _endScale - _startScale;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, scaleByLifeConst.index, Vector.<Number>([_startScale,_delta,0,0]));
		}
		
	}

}
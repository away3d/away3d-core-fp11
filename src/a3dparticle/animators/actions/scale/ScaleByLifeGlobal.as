package a3dparticle.animators.actions.scale 
{
	import a3dparticle.animators.actions.AllParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class ScaleByLifeGlobal extends AllParticleAction
	{
		private var _startScale:Number;
		private var _endScale:Number;
		private var _delta:Number;
		
		private var scaleByLifeConst:ShaderRegisterElement;
		
		public function ScaleByLifeGlobal(startScale:Number,endScale:Number) 
		{
			priority = 3;
			_startScale = startScale;
			_endScale = endScale;
			_delta = _endScale - _startScale;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			scaleByLifeConst = shaderRegisterCache.getFreeVertexConstant();
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var scale:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index,"w");
			
			var code:String = "";
			code += "mul " + scale.toString() + "," + _animation.vertexLife.toString() + "," + scaleByLifeConst.toString() + ".y\n";
			code += "add " + scale.toString() + "," + scale.toString() + "," + scaleByLifeConst.toString() + ".x\n";
			
			code += "mul " + _animation.scaleAndRotateTarget.toString() +"," +_animation.scaleAndRotateTarget.toString() + "," + scale.toString() + "\n";
			return code;
			
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, scaleByLifeConst.index, Vector.<Number>([_startScale,_delta,0,0]));
		}
		
	}

}
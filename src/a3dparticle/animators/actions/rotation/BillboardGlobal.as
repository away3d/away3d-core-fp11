package a3dparticle.animators.actions.rotation 
{
	import a3dparticle.animators.actions.AllParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.MathConsts;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class BillboardGlobal extends AllParticleAction
	{
		private var rotationMatrixRegister:ShaderRegisterElement;
		
		public function BillboardGlobal() 
		{
			priority = 2;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			rotationMatrixRegister = shaderRegisterCache.getFreeVertexConstant();
			shaderRegisterCache.getFreeVertexConstant();
			shaderRegisterCache.getFreeVertexConstant();
			shaderRegisterCache.getFreeVertexConstant();
			
			var code:String = "";
			
			code += "m33 " + _animation.scaleAndRotateTarget.toString() + "," + _animation.scaleAndRotateTarget.toString() + "," + rotationMatrixRegister.toString() + "\n";
			
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var mvp :Matrix3D = renderable.getModelViewProjectionUnsafe();
			var comps : Vector.<Vector3D>;
			comps = mvp.decompose();
			var rotation :Matrix3D = new Matrix3D();
			rotation.appendRotation(-comps[1].z * MathConsts.RADIANS_TO_DEGREES, new Vector3D(0, 0, 1));
			rotation.appendRotation(-comps[1].y * MathConsts.RADIANS_TO_DEGREES, new Vector3D(0, 1, 0));
			rotation.appendRotation(-comps[1].x * MathConsts.RADIANS_TO_DEGREES, new Vector3D(1, 0, 0));
			
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, rotationMatrixRegister.index, rotation, true);
		}
		
	}

}
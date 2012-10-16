package a3dparticle.animators.actions.rotation
{
	import a3dparticle.animators.actions.AllParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.MathConsts;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.compilation.ShaderRegisterElement;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
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
		private var matrix:Matrix3D = new Matrix3D;
		
		public function BillboardGlobal()
		{
			priority = 3;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			rotationMatrixRegister = shaderRegisterCache.getFreeVertexConstant();
			shaderRegisterCache.getFreeVertexConstant();
			shaderRegisterCache.getFreeVertexConstant();
			shaderRegisterCache.getFreeVertexConstant();
			
			var code:String = "";
			
			code += "m33 " + animationRegistersManager.scaleAndRotateTarget.toString() + "," + animationRegistersManager.scaleAndRotateTarget.toString() + "," + rotationMatrixRegister.toString() + "\n";
			
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			matrix.copyFrom(renderable.sceneTransform);
			matrix.append(animationRegistersManager.camera.inverseSceneTransform);
			var comps : Vector.<Vector3D> = matrix.decompose(Orientation3D.AXIS_ANGLE);
			matrix.identity();
			matrix.appendRotation( -comps[1].w * MathConsts.RADIANS_TO_DEGREES, comps[1]);
			stage3DProxy._context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, rotationMatrixRegister.index, matrix, true);
		}
		
	}

}
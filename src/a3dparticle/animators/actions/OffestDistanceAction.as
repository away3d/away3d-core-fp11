package a3dparticle.animators.actions 
{
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
	public class OffestDistanceAction extends PerParticleAction
	{
		private var _offestFun:Function;
		
		private var _tempOffest:Vector3D;
		
		private var _offectAttribute:ShaderRegisterElement;
		
		public function OffestDistanceAction(offest:Function) 
		{
			dataLenght = 3;
			_offestFun = offest;
		}
		
		override public function genOne(index:uint):void
		{
			_tempOffest = _offestFun(index);
		}
		
		override public function distributeOne(index:int, verticeIndex:uint):void
		{
			_vertices.push(_tempOffest.x);
			_vertices.push(_tempOffest.y);
			_vertices.push(_tempOffest.z);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			_offectAttribute = shaderRegisterCache.getFreeVertexAttribute();
			var code:String = "";
			code += "add " + _animation.postionTarget.toString() +".xyz," + _offectAttribute.toString() + "," + _animation.postionTarget.toString() + ".xyz\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(_offectAttribute.index, getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3);
		}
		
	}

}
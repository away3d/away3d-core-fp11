package a3dparticle.animators.actions.position 
{
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.core.SubContainer;
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
	public class OffestPositionLocal extends PerParticleAction
	{
		private var _offestFun:Function;
		
		private var _tempOffest:Vector3D;
		
		private var _offectAttribute:ShaderRegisterElement;
		
		/**
		 * 
		 * @param	offest Function.It return a Vector3D that the (x,y,z) is the position.
		 */
		public function OffestPositionLocal(offest:Function) 
		{
			dataLenght = 3;
			_name = "OffestPositionLocal";
			_offestFun = offest;
		}
		
		override public function genOne(index:uint):void
		{
			_tempOffest = _offestFun(index);
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(_tempOffest.x);
			getExtraData(subContainer).push(_tempOffest.y);
			getExtraData(subContainer).push(_tempOffest.z);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			_offectAttribute = shaderRegisterCache.getFreeVertexAttribute();
			var code:String = "";
			code += "add " + _animation.offestTarget.toString() +"," + _offectAttribute.toString() + ".xyz," + _animation.offestTarget.toString() + "\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(_offectAttribute.index, getExtraBuffer(stage3DProxy,SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_3);
		}
		
	}

}
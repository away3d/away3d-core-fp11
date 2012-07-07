package a3dparticle.animators.actions.position 
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
	public class OffsetPositionLocal extends PerParticleAction
	{
		private var _offsetFun:Function;
		
		private var _tempOffset:Vector3D;
		
		private var _offsetAttribute:ShaderRegisterElement;
		
		/**
		 * 
		 * @param	offset Function.It return a Vector3D that the (x,y,z) is the position.
		 */
		public function OffsetPositionLocal(offset:Function=null) 
		{
			dataLenght = 3;
			_name = "OffsetPositionLocal";
			_offsetFun = offset;
		}
		
		override public function genOne(param:ParticleParam):void
		{
			if (_offsetFun != null)
			{
				_tempOffset = _offsetFun(param);
			}
			else
			{
				if (!param[_name]) throw(new Error("there is no " + _name + " in param!"));
				_tempOffset = param[_name];
			}
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(_tempOffset.x);
			getExtraData(subContainer).push(_tempOffset.y);
			getExtraData(subContainer).push(_tempOffset.z);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			_offsetAttribute = shaderRegisterCache.getFreeVertexAttribute();
			var code:String = "";
			code += "add " + _animation.offsetTarget.toString() +"," + _offsetAttribute.toString() + ".xyz," + _animation.offsetTarget.toString() + "\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(_offsetAttribute.index, getExtraBuffer(stage3DProxy, SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_3, 0);
		}
		
	}

}
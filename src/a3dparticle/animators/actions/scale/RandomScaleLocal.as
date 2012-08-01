package a3dparticle.animators.actions.scale
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
	/**
	 * ...
	 * @author ...
	 */
	public class RandomScaleLocal extends PerParticleAction
	{
		private var _scaleFun:Function;
		
		private var _tempScale:Vector3D;
		
		private var scaleAttribute:ShaderRegisterElement;
		/**
		 *
		 * @param	fun Function.The fun return a Vector3D which (x,y,z) is a (scaleX,scaleY,scaleZ)
		 */
		public function RandomScaleLocal(fun:Function = null)
		{
			priority = 3;
			dataLenght = 3;
			_name = "RandomScaleLocal";
			_scaleFun = fun;
		}
		
		override public function genOne(param:ParticleParam):void
		{
			if (_scaleFun != null)
			{
				_tempScale = _scaleFun(param);
			}
			else
			{
				if (!param[_name]) throw("there is no ", _name, " in param!");
				_tempScale = param[_name];
			}
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(_tempScale.x, _tempScale.y, _tempScale.z);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			scaleAttribute = shaderRegisterCache.getFreeVertexAttribute();
			var code:String = "";
			code += "mul " + _animation.scaleAndRotateTarget.toString() +"," +_animation.scaleAndRotateTarget.toString() + "," + scaleAttribute.toString() + "\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(scaleAttribute.index, getExtraBuffer(stage3DProxy, SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_3, 0);
		}
		
	}

}
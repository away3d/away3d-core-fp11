package a3dparticle.particle
{
	import a3dparticle.animators.ParticleAnimation;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import flash.display3D.Context3DProgramType;
	
	/**
	 * ...
	 * @author liaocheng
	 */
	public class ParticleColorMaterial extends ParticleMaterialBase
	{
		private var _color:uint;
		private var _colorData:Vector.<Number>=new Vector.<Number>();
		
		public function ParticleColorMaterial(color:uint=0xFFFFFFFF)
		{
			this.color = color;
		}
		
		public function set color(value:uint):void
		{
			this._color = value;
			_colorData[0] = ((_color >> 16) & 0xff)/0xff;
			_colorData[1] = ((_color >> 8) & 0xff)/0xff;
			_colorData[2] = (_color & 0xff) / 0xff;
			_colorData[3] = ((_color >> 24) & 0xff)/0xff;
		}
		
		override public function getFragmentCode(_particleAnimation:ParticleAnimation):String
		{
			var code:String = "";
			code += "mov " + _particleAnimation.colorTarget.toString() + "," +_particleAnimation.colorDefalut.toString() + "\n";
			return code;
		}
		
		override public function render(_particleAnimation:ParticleAnimation, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			super.render(_particleAnimation, renderable, stage3DProxy, camera);
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _particleAnimation.colorDefalut.index, _colorData, 1);
		}
		
	}

}
package a3dparticle.particle 
{
	import a3dparticle.animators.ParticleAnimation;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.managers.Texture3DProxy;
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class ParticleBitmapMaterial extends ParticleMaterialBase
	{
		private var _texture:Texture3DProxy;
		
		public function ParticleBitmapMaterial(bitmap:BitmapData)
		{
			this.numUsedTextures = 1;
			_texture = new Texture3DProxy(bitmap);
		}
		
		override public function initAnimation(particleAnimation:ParticleAnimation):void
		{
			particleAnimation.needUV = true;
		}
		
		public function set bitmapData(value:BitmapData):void
		{
			_texture.bitmapData = value;
		}
		
		override public function getFragmentCode(_particleAnimation:ParticleAnimation):String
		{
			var code:String = "";
			code += "tex " + _particleAnimation.colorTarget.toString() + "," + _particleAnimation.uvVar.toString() + "," + _particleAnimation.textSample.toString() + "<2d,linear,miplinear,clamp>\n";
			return code;
		}
		
		override public function render(_particleAnimation:ParticleAnimation, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			stage3DProxy.setTextureAt(_particleAnimation.textSample.index, _texture.getTextureForStage3D(stage3DProxy));
		}
		
	}

}
package a3dparticle.animators.actions.texture 
{
	import a3dparticle.animators.actions.AllParticleAction;
	import away3d.textures.BitmapTexture;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display.BitmapData;
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
	 * @author liaocheng
	 */
	public class ColorTextureByLifeGlobal extends AllParticleAction 
	{
		private var _texture:BitmapTexture;
		private var _smooth:Boolean;
		private var _mode:String;
		private var _textureRegister:ShaderRegisterElement;
		
		public static const MUL:String = "mul";
		public static const ADD:String = "add";
		/**
		 * 
		 * @param	bitmap BitmapData.A bitmapData which is 2 pixel height.We use it as a color lookup map.
		 */
		public function ColorTextureByLifeGlobal(bitmap:BitmapData,mode:String="mul",smooth:Boolean=false) 
		{
			this._mode = mode;
			this._smooth = smooth;
			_texture = new BitmapTexture(bitmap);
		}
		
		override public function getAGALFragmentCode(pass : MaterialPassBase) : String
		{
			_textureRegister = shaderRegisterCache.getFreeTextureReg();
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeFragmentVectorTemp();
			
			var code:String = "";
			//code += "mov " + temp.toString() + "," + _animation.fragmentZeroConst.toString() + "\n";
			code += "mov " + temp.toString() + ".y," + _animation.fragmentOneConst.toString() + "\n";
			code += "mov " + temp.toString() + ".x," + _animation.fragmentLife.toString() + "\n";
			code += "tex " + temp.toString() + "," + temp.toString() + ".xy," + _textureRegister.toString() + "<2d," + (_smooth?"linear":"nearest") + "clamp,nomip>\n";
			code += _mode + " " + _animation.colorTarget.toString() + "," + _animation.colorTarget.toString() + "," + temp.toString() + "\n";
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			stage3DProxy.setTextureAt(_textureRegister.index, _texture.getTextureForStage3D(stage3DProxy));
		}
		
	}

}
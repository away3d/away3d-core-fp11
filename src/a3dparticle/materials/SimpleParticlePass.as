package a3dparticle.materials 
{
	import a3dparticle.animators.ParticleAnimation;
	import away3d.animators.data.AnimationBase;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.BitmapDataTextureCache;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.managers.Texture3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;

	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class SimpleParticlePass extends MaterialPassBase
	{
		public var _texture:Texture3DProxy;
		
		public function SimpleParticlePass(bitmap:BitmapData=null) 
		{
			super();
			if (bitmap)
			{
				_texture = BitmapDataTextureCache.getInstance().getTexture(bitmap);
			}
		}
		
		override public function set animation(value : AnimationBase) : void
		{
			if (animation == value) return;
			if (value is ParticleAnimation)
			{
				super.animation = value;
			}
			else
			{
				throw(new Error("animation not match!"));
			}
		}
		
		private function get _particleAnimation():ParticleAnimation
		{
			return  animation as ParticleAnimation;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var _particleAnimation:ParticleAnimation = ParticleAnimation(animation);
			if (_particleAnimation && _particleAnimation.hasGen)
			{
				super.activate(stage3DProxy, camera);
				var context : Context3D = stage3DProxy._context3D;
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _particleAnimation.zeroConst.index, Vector.<Number>([ 0, 0, 0, 0 ]));
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _particleAnimation.fragmentZeroConst.index, Vector.<Number>([ 0, 0, 0, 0 ]));
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _particleAnimation.piConst.index, Vector.<Number>([ Math.PI * 2, Math.PI * 2, Math.PI * 2, Math.PI * 2 ]));
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _particleAnimation.OneConst.index, Vector.<Number>([ 1, 1, 1, 1 ]));
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _particleAnimation.TwoConst.index, Vector.<Number>([ 2, 2, 2, 2 ]));
				
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _particleAnimation.fragmentPiConst.index, Vector.<Number>([ Math.PI * 2, Math.PI * 2, Math.PI * 2, Math.PI * 2 ]));
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _particleAnimation.fragmentOneConst.index, Vector.<Number>([ 1, 1, 1, 1 ]));
				
				if (_texture) 
				{
					_numUsedTextures = 1;
					stage3DProxy.setTextureAt(_particleAnimation.textSample.index, _texture.getTextureForStage3D(stage3DProxy));
				}
				else 
				{
					context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _particleAnimation.colorDefalut.index, Vector.<Number>([1,1,1,1]), 1);
				}
			}
		}
		
		arcane override function getVertexCode() : String
		{
			return "";
		}
		
		arcane override function getFragmentCode() : String
		{
			var code:String = "";
			//if time=0,discard the fragment
			var temp:ShaderRegisterElement = _particleAnimation.shaderRegisterCache.getFreeFragmentSingleTemp();
			code += "neg " + temp.toString() + "," + _particleAnimation.fragmentTime + "\n";
			code += "sge " + temp.toString() + "," + temp.toString() + "," + _particleAnimation.fragmentZeroConst.toString() + "\n";
			code += "neg " + temp.toString() + "," + temp.toString() + "\n";
			code += "kil " + temp.toString() + "\n";
			
			
			if (_texture)
			{
				code += "tex " + _particleAnimation.colorTarget.toString() + "," + _particleAnimation.uvVar.toString() + "," + _particleAnimation.textSample.toString() + "<2d,linear,miplinear,clamp>\n";
			}
			else
			{
				code += "mov " + _particleAnimation.colorTarget.toString() + "," +_particleAnimation.colorDefalut.toString() + "\n";
			}
			
			code += _particleAnimation.getAGALFragmentCode(this);
			
			code += "mov oc," + _particleAnimation.colorTarget.toString() + "\n";
			trace("***************\n", code);
			return code;
		}
		
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			if (_particleAnimation && _particleAnimation.hasGen)
			{
				super.render(renderable, stage3DProxy , camera );
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose(deep : Boolean) : void
		{
			if (_texture) {
				BitmapDataTextureCache.getInstance().freeTexture(_texture);
				_texture = null;
			}
		}
		
	}

}
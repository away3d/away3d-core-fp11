package a3dparticle.core 
{
	import a3dparticle.animators.ParticleAnimation;
	import a3dparticle.particle.ParticleMaterialBase;
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
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Utils3D;
	import flash.geom.Vector3D;

	use namespace arcane;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class SimpleParticlePass extends MaterialPassBase
	{
		private var _particleMaterial:ParticleMaterialBase;
		
		public function SimpleParticlePass(particleMaterial:ParticleMaterialBase) 
		{
			super();
			this._particleMaterial = particleMaterial;
		}
		
		override public function set animation(value : AnimationBase) : void
		{
			if (animation == value) return;
			if (value is ParticleAnimation)
			{
				_particleMaterial.initAnimation(value as ParticleAnimation);
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
				_numUsedTextures = _particleMaterial.numUsedTextures;
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
			
			//set the init color
			code += _particleMaterial.getFragmentCode(_particleAnimation);
			//change the colorTarget
			code += _particleAnimation.getAGALFragmentCode(this);
			
			code += "mov oc," + _particleAnimation.colorTarget.toString() + "\n";

			return code;
		}
		
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			if (_particleAnimation && _particleAnimation.hasGen)
			{
				if (_particleAnimation.needCameraPosition)
				{
					var context : Context3D = stage3DProxy._context3D;
					var pos:Vector3D = Utils3D.projectVector(renderable.inverseSceneTransform, camera.scenePosition);
					context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _particleAnimation.cameraPosConst.index, Vector.<Number>([pos.x,pos.y,pos.z,0]));
				}
				if (_particleAnimation.needUV)
				{
					stage3DProxy.setSimpleVertexBuffer(_particleAnimation.uvAttribute.index, renderable.getUVBuffer(stage3DProxy),Context3DVertexBufferFormat.FLOAT_2);
				}
				_particleMaterial.render(_particleAnimation, renderable, stage3DProxy , camera );
				super.render(renderable, stage3DProxy , camera );
			}
		}
		
	}

}
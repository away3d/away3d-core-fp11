package a3dparticle.core
{
	import a3dparticle.animators.ParticleAnimation;
	import a3dparticle.particle.ParticleMaterialBase;
	import away3d.animators.IAnimationSet;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.lightpickers.LightPickerBase;
	import away3d.materials.passes.MaterialPassBase;
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
		
		override public function set animationSet(value : IAnimationSet) : void
		{
			if (animationSet == value) return;
			if (value is ParticleAnimation)
			{
				_particleMaterial.initAnimation(value as ParticleAnimation);
				super.animationSet = value;
			}
			else
			{
				throw(new Error("animationSet not match!"));
			}
		}
		
		private function get _particleAnimation():ParticleAnimation
		{
			return  animationSet as ParticleAnimation;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			if (_particleAnimation && _particleAnimation.hasGen)
			{
				super.activate(stage3DProxy, camera, textureRatioX, textureRatioY);
			}
		}
		
		override arcane function updateProgram(stage3DProxy : Stage3DProxy) : void
		{
			super.updateProgram(stage3DProxy);
			_numUsedTextures = _particleAnimation.shaderRegisterCache.numUsedTextures;
			_numUsedStreams = _particleAnimation.shaderRegisterCache.numUsedStreams;
			
		}
		
		arcane override function getVertexCode(code:String) : String
		{
			code += getProjectionCode(_animationTargetRegisters[0]);
			return code;
		}
		
		private function getProjectionCode(positionRegister : String) : String
		{
			var code : String = "m44 vt7, vt0, vc0\nmul op, vt7, vc4\n";
			return code;
		}
		
		arcane override function getFragmentCode() : String
		{
			var code:String = "";
			
			//set the init color
			code += _particleMaterial.getFragmentCode(_particleAnimation);
			//change the colorTarget
			code += _particleAnimation.getAGALFragmentCode(this);
			code += _particleMaterial.getPostFragmentCode(_particleAnimation);
			code += "mov oc," + _particleAnimation.colorTarget.toString() + "\n";
			
			return code;
		}
		
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D, lightPicker : LightPickerBase) : void
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
					stage3DProxy.setSimpleVertexBuffer(_particleAnimation.uvAttribute.index, renderable.getUVBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_2, 0);
				}
				_particleMaterial.render(_particleAnimation, renderable, stage3DProxy , camera );
				super.render(renderable, stage3DProxy , camera , lightPicker);
			}
		}
		
	}

}
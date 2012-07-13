package away3d.materials
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.methods.BasicAmbientMethod;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicNormalMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.methods.EffectMethodBase;
	import away3d.materials.methods.ShadowMapMethodBase;
	import away3d.materials.passes.DefaultScreenPass;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3D;
	import flash.geom.ColorTransform;

	use namespace arcane;

	/**
	 * DefaultMaterialBase forms an abstract base class for the default materials provided by Away3D and use methods
	 * to define their appearance.
	 */
	public class DefaultMaterialBase extends MaterialBase
	{
		protected var _screenPass : DefaultScreenPass;
		private var _alphaBlending : Boolean;

		/**
		 * Creates a new DefaultMaterialBase object.
		 */
		public function DefaultMaterialBase()
		{
			super();
			addPass(_screenPass = new DefaultScreenPass(this));
		}

		/**
		 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
		 * invisible or entirely opaque, often used with textures for foliage, etc.
		 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
		 */
		public function get alphaThreshold() : Number
		{
			return _screenPass.diffuseMethod.alphaThreshold;
		}

		public function set alphaThreshold(value : Number) : void
		{
			_screenPass.diffuseMethod.alphaThreshold = value;
			_depthPass.alphaThreshold = value;
			_distancePass.alphaThreshold = value;
		}

		arcane override function activateForDepth(stage3DProxy : Stage3DProxy, camera : Camera3D, distanceBased : Boolean = false, textureRatioX : Number = 1, textureRatioY : Number = 1) : void
		{
			if (distanceBased) {
				_distancePass.alphaMask = _screenPass.diffuseMethod.texture;
			}
			else {
				_depthPass.alphaMask = _screenPass.diffuseMethod.texture;
			}
			super.activateForDepth(stage3DProxy, camera, distanceBased, textureRatioX, textureRatioY);
		}

		public function get specularLightSources() : uint
		{
			return _screenPass.specularLightSources;
		}

		public function set specularLightSources(value : uint) : void
		{
			_screenPass.specularLightSources = value;
		}

		public function get diffuseLightSources() : uint
		{
			return _screenPass.diffuseLightSources;
		}

		public function set diffuseLightSources(value : uint) : void
		{
			_screenPass.diffuseLightSources = value;
		}

		/**
		 * The ColorTransform object to transform the colour of the material with.
		 */
		public function get colorTransform() : ColorTransform
		{
			return _screenPass.colorTransform;
		}

		public function set colorTransform(value : ColorTransform) : void
		{
			_screenPass.colorTransform = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function get requiresBlending() : Boolean
		{
			return super.requiresBlending || _alphaBlending || (_screenPass.colorTransform && _screenPass.colorTransform.alphaMultiplier < 1);
		}

		/**
		 * The method to perform ambient shading. Note that shading methods cannot
		 * be reused across materials.
		 */
		public function get ambientMethod() : BasicAmbientMethod
		{
			return _screenPass.ambientMethod;
		}

		public function set ambientMethod(value : BasicAmbientMethod) : void
		{
			_screenPass.ambientMethod = value;
		}

		/**
		 * The method to render shadows cast on this surface. Note that shading methods can not
		 * be reused across materials.
		 */
		public function get shadowMethod() : ShadowMapMethodBase
		{
			return _screenPass.shadowMethod;
		}

		public function set shadowMethod(value : ShadowMapMethodBase) : void
		{
			_screenPass.shadowMethod = value;
		}

		/**
		 * The method to perform diffuse shading. Note that shading methods can not
		 * be reused across materials.
		 */
		public function get diffuseMethod() : BasicDiffuseMethod
		{
			return _screenPass.diffuseMethod;
		}

		public function set diffuseMethod(value : BasicDiffuseMethod) : void
		{
			_screenPass.diffuseMethod = value;
		}

		/**
		 * The method to generate the (tangent-space) normal. Note that shading methods can not
		 * be reused across materials.
		 */
		public function get normalMethod() : BasicNormalMethod
		{
			return _screenPass.normalMethod;
		}

		public function set normalMethod(value : BasicNormalMethod) : void
		{
			_screenPass.normalMethod = value;
		}

		/**
		 * The method to perform specular shading. Note that shading methods can not
		 * be reused across materials.
		 */
		public function get specularMethod() : BasicSpecularMethod
		{
			return _screenPass.specularMethod;
		}

		public function set specularMethod(value : BasicSpecularMethod) : void
		{
			_screenPass.specularMethod = value;
		}
		
 		/**
		 * Adds a shading method to the end of the shader. Note that shading methods can
		 * not be reused across materials.
		*/
		public function addMethod(method : EffectMethodBase) : void
		{
			_screenPass.addMethod(method);
		}

		public function get numMethods() : int
		{
			return _screenPass.numMethods;
		}

		public function hasMethod(method : EffectMethodBase) : Boolean
		{
			return _screenPass.hasMethod(method);
		}

		public function getMethodAt(index : int) : EffectMethodBase
		{
			return _screenPass.getMethodAt(index);
		}

		/**
		 * Adds a shading method to the end of a shader, at the specified index amongst
		 * the methods in that section of the shader. Note that shading methods can not
		 * be reused across materials.
		*/
		public function addMethodAt(method : EffectMethodBase, index : int) : void
		{
			_screenPass.addMethodAt(method, index);
		}

		public function removeMethod(method : EffectMethodBase) : void
		{
			_screenPass.removeMethod(method);
		}

		/**
		 * @inheritDoc
		 */
		override public function set mipmap(value : Boolean) : void
		{
			if (_mipmap == value) return;
			super.mipmap = value;
		}

		/**
		 * The tangent space normal map to influence the direction of the surface for each texel.
		 */
		public function get normalMap() : Texture2DBase
		{
			return _screenPass.normalMap;
		}

		public function set normalMap(value : Texture2DBase) : void
		{
			_screenPass.normalMap = value;
		}

		/**
		 * A specular map that defines the strength of specular reflections for each texel in the red channel, and the gloss factor in the green channel.
		 * You can use SpecularBitmapTexture if you want to easily set specular and gloss maps from greyscale images, but prepared images are preffered.
		 */
		public function get specularMap() : Texture2DBase
		{
			return _screenPass.specularMethod.texture;
		}

		public function set specularMap(value : Texture2DBase) : void
		{
			if (_screenPass.specularMethod) _screenPass.specularMethod.texture = value;
			else throw new Error("No specular method was set to assign the specularGlossMap to");
		}

		/**
		 * The sharpness of the specular highlight.
		 */
		public function get gloss() : Number
		{
			return _screenPass.specularMethod? _screenPass.specularMethod.gloss : 0;
		}

		public function set gloss(value : Number) : void
		{
			if (_screenPass.specularMethod) _screenPass.specularMethod.gloss = value;
		}

		/**
		 * The strength of the ambient reflection.
		 */
		public function get ambient() : Number
		{
			return _screenPass.ambientMethod.ambient;
		}

		public function set ambient(value : Number) : void
		{
			_screenPass.ambientMethod.ambient = value;
		}

		/**
		 * The overall strength of the specular reflection.
		 */
		public function get specular() : Number
		{
			return _screenPass.specularMethod? _screenPass.specularMethod.specular : 0;
		}

		public function set specular(value : Number) : void
		{
			if (_screenPass.specularMethod) _screenPass.specularMethod.specular = value;
		}

		/**
		 * The colour of the ambient reflection.
		 */
		public function get ambientColor() : uint
		{
			return _screenPass.ambientMethod.ambientColor;
		}

		public function set ambientColor(value : uint) : void
		{
			_screenPass.ambientMethod.ambientColor = value;
		}

		/**
		 * The colour of the specular reflection.
		 */
		public function get specularColor() : uint
		{
			return _screenPass.specularMethod.specularColor;
		}

		public function set specularColor(value : uint) : void
		{
			_screenPass.specularMethod.specularColor = value;
		}

		/**
		 * Indicate whether or not the material has transparency. If binary transparency is sufficient, for
		 * example when using textures of foliage, consider using alphaThreshold instead.
		 */
		public function get alphaBlending() : Boolean
		{
			return _alphaBlending;
		}

		public function set alphaBlending(value : Boolean) : void
		{
			_alphaBlending = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function updateMaterial(context : Context3D) : void
		{
			if (_screenPass._passesDirty) {
				clearPasses();
				if (_screenPass._passes) {
					var len : uint = _screenPass._passes.length;
					for (var i : uint = 0; i < len; ++i)
						addPass(_screenPass._passes[i]);
				}

				addPass(_screenPass);
				_screenPass._passesDirty = false;
			}
		}
	}
}
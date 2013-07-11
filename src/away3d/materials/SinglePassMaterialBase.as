package away3d.materials
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.lightpickers.LightPickerBase;
	import away3d.materials.methods.BasicAmbientMethod;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicNormalMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.methods.EffectMethodBase;
	import away3d.materials.methods.ShadowMapMethodBase;
	import away3d.materials.passes.SuperShaderPass;
	import away3d.textures.Texture2DBase;
	
	import flash.display.BlendMode;
	
	import flash.display3D.Context3D;
	import flash.geom.ColorTransform;
	
	use namespace arcane;
	
	/**
	 * SinglePassMaterialBase forms an abstract base class for the default single-pass materials provided by Away3D,
	 * using material methods to define their appearance.
	 */
	public class SinglePassMaterialBase extends MaterialBase
	{
		protected var _screenPass:SuperShaderPass;
		private var _alphaBlending:Boolean;
		
		/**
		 * Creates a new SinglePassMaterialBase object.
		 */
		public function SinglePassMaterialBase()
		{
			super();
			addPass(_screenPass = new SuperShaderPass(this));
		}
		
		/**
		 * Whether or not to use fallOff and radius properties for lights. This can be used to improve performance and
		 * compatibility for constrained mode.
		 */
		public function get enableLightFallOff():Boolean
		{
			return _screenPass.enableLightFallOff;
		}
		
		public function set enableLightFallOff(value:Boolean):void
		{
			_screenPass.enableLightFallOff = value;
		}
		
		/**
		 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
		 * invisible or entirely opaque, often used with textures for foliage, etc.
		 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
		 */
		public function get alphaThreshold():Number
		{
			return _screenPass.diffuseMethod.alphaThreshold;
		}
		
		public function set alphaThreshold(value:Number):void
		{
			_screenPass.diffuseMethod.alphaThreshold = value;
			_depthPass.alphaThreshold = value;
			_distancePass.alphaThreshold = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function set blendMode(value:String):void
		{
			super.blendMode = value;
			_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending? BlendMode.LAYER : blendMode);
		}

		/**
		 * @inheritDoc
		 */
		override public function set depthCompareMode(value:String):void
		{
			super.depthCompareMode = value;
			_screenPass.depthCompareMode = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activateForDepth(stage3DProxy:Stage3DProxy, camera:Camera3D, distanceBased:Boolean = false):void
		{
			if (distanceBased)
				_distancePass.alphaMask = _screenPass.diffuseMethod.texture;
			else
				_depthPass.alphaMask = _screenPass.diffuseMethod.texture;
			super.activateForDepth(stage3DProxy, camera, distanceBased);
		}

		/**
		 * Define which light source types to use for specular reflections. This allows choosing between regular lights
		 * and/or light probes for specular reflections.
		 *
		 * @see away3d.materials.LightSources
		 */
		public function get specularLightSources():uint
		{
			return _screenPass.specularLightSources;
		}
		
		public function set specularLightSources(value:uint):void
		{
			_screenPass.specularLightSources = value;
		}

		/**
		 * Define which light source types to use for diffuse reflections. This allows choosing between regular lights
		 * and/or light probes for diffuse reflections.
		 *
		 * @see away3d.materials.LightSources
		 */
		public function get diffuseLightSources():uint
		{
			return _screenPass.diffuseLightSources;
		}
		
		public function set diffuseLightSources(value:uint):void
		{
			_screenPass.diffuseLightSources = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function get requiresBlending():Boolean
		{
			return super.requiresBlending || _alphaBlending || (_screenPass.colorTransform && _screenPass.colorTransform.alphaMultiplier < 1);
		}

		/**
		 * The ColorTransform object to transform the colour of the material with. Defaults to null.
		 */
		public function get colorTransform():ColorTransform
		{
			return _screenPass.colorTransform;
		}

		public function set colorTransform(value:ColorTransform):void
		{
			_screenPass.colorTransform = value;
		}

		/**
		 * The method that provides the ambient lighting contribution. Defaults to BasicAmbientMethod.
		 */
		public function get ambientMethod():BasicAmbientMethod
		{
			return _screenPass.ambientMethod;
		}
		
		public function set ambientMethod(value:BasicAmbientMethod):void
		{
			_screenPass.ambientMethod = value;
		}
		
		/**
		 * The method used to render shadows cast on this surface, or null if no shadows are to be rendered. Defaults to null.
		 */
		public function get shadowMethod():ShadowMapMethodBase
		{
			return _screenPass.shadowMethod;
		}
		
		public function set shadowMethod(value:ShadowMapMethodBase):void
		{
			_screenPass.shadowMethod = value;
		}
		
		/**
		 * The method that provides the diffuse lighting contribution. Defaults to BasicDiffuseMethod.
		 */
		public function get diffuseMethod():BasicDiffuseMethod
		{
			return _screenPass.diffuseMethod;
		}
		
		public function set diffuseMethod(value:BasicDiffuseMethod):void
		{
			_screenPass.diffuseMethod = value;
		}
		
		/**
		 * The method used to generate the per-pixel normals. Defaults to BasicNormalMethod.
		 */
		public function get normalMethod():BasicNormalMethod
		{
			return _screenPass.normalMethod;
		}
		
		public function set normalMethod(value:BasicNormalMethod):void
		{
			_screenPass.normalMethod = value;
		}
		
		/**
		 * The method that provides the specular lighting contribution. Defaults to BasicSpecularMethod.
		 */
		public function get specularMethod():BasicSpecularMethod
		{
			return _screenPass.specularMethod;
		}
		
		public function set specularMethod(value:BasicSpecularMethod):void
		{
			_screenPass.specularMethod = value;
		}
		
		/**
		 * Appends an "effect" shading method to the shader. Effect methods are those that do not influence the lighting
		 * but modulate the shaded colour, used for fog, outlines, etc. The method will be applied to the result of the
		 * methods added prior.
		 */
		public function addMethod(method:EffectMethodBase):void
		{
			_screenPass.addMethod(method);
		}

		/**
		 * The number of "effect" methods added to the material.
		 */
		public function get numMethods():int
		{
			return _screenPass.numMethods;
		}

		/**
		 * Queries whether a given effect method was added to the material.
		 *
		 * @param method The method to be queried.
		 * @return true if the method was added to the material, false otherwise.
		 */
		public function hasMethod(method:EffectMethodBase):Boolean
		{
			return _screenPass.hasMethod(method);
		}

		/**
		 * Returns the method added at the given index.
		 * @param index The index of the method to retrieve.
		 * @return The method at the given index.
		 */
		public function getMethodAt(index:int):EffectMethodBase
		{
			return _screenPass.getMethodAt(index);
		}

		/**
		 * Adds an effect method at the specified index amongst the methods already added to the material. Effect
		 * methods are those that do not influence the lighting but modulate the shaded colour, used for fog, outlines,
		 * etc. The method will be applied to the result of the methods with a lower index.
		 */
		public function addMethodAt(method:EffectMethodBase, index:int):void
		{
			_screenPass.addMethodAt(method, index);
		}

		/**
		 * Removes an effect method from the material.
		 * @param method The method to be removed.
		 */
		public function removeMethod(method:EffectMethodBase):void
		{
			_screenPass.removeMethod(method);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set mipmap(value:Boolean):void
		{
			if (_mipmap == value)
				return;
			super.mipmap = value;
		}

		/**
		 * The normal map to modulate the direction of the surface for each texel. The default normal method expects
		 * tangent-space normal maps, but others could expect object-space maps.
		 */
		public function get normalMap():Texture2DBase
		{
			return _screenPass.normalMap;
		}
		
		public function set normalMap(value:Texture2DBase):void
		{
			_screenPass.normalMap = value;
		}
		
		/**
		 * A specular map that defines the strength of specular reflections for each texel in the red channel,
		 * and the gloss factor in the green channel. You can use SpecularBitmapTexture if you want to easily set
		 * specular and gloss maps from grayscale images, but correctly authored images are preferred.
		 */
		public function get specularMap():Texture2DBase
		{
			return _screenPass.specularMethod.texture;
		}
		
		public function set specularMap(value:Texture2DBase):void
		{
			if (_screenPass.specularMethod)
				_screenPass.specularMethod.texture = value;
			else
				throw new Error("No specular method was set to assign the specularGlossMap to");
		}
		
		/**
		 * The glossiness of the material (sharpness of the specular highlight).
		 */
		public function get gloss():Number
		{
			return _screenPass.specularMethod? _screenPass.specularMethod.gloss : 0;
		}
		
		public function set gloss(value:Number):void
		{
			if (_screenPass.specularMethod)
				_screenPass.specularMethod.gloss = value;
		}
		
		/**
		 * The strength of the ambient reflection.
		 */
		public function get ambient():Number
		{
			return _screenPass.ambientMethod.ambient;
		}
		
		public function set ambient(value:Number):void
		{
			_screenPass.ambientMethod.ambient = value;
		}
		
		/**
		 * The overall strength of the specular reflection.
		 */
		public function get specular():Number
		{
			return _screenPass.specularMethod? _screenPass.specularMethod.specular : 0;
		}
		
		public function set specular(value:Number):void
		{
			if (_screenPass.specularMethod)
				_screenPass.specularMethod.specular = value;
		}
		
		/**
		 * The colour of the ambient reflection.
		 */
		public function get ambientColor():uint
		{
			return _screenPass.ambientMethod.ambientColor;
		}
		
		public function set ambientColor(value:uint):void
		{
			_screenPass.ambientMethod.ambientColor = value;
		}
		
		/**
		 * The colour of the specular reflection.
		 */
		public function get specularColor():uint
		{
			return _screenPass.specularMethod.specularColor;
		}
		
		public function set specularColor(value:uint):void
		{
			_screenPass.specularMethod.specularColor = value;
		}
		
		/**
		 * Indicates whether or not the material has transparency. If binary transparency is sufficient, for
		 * example when using textures of foliage, consider using alphaThreshold instead.
		 */
		public function get alphaBlending():Boolean
		{
			return _alphaBlending;
		}
		
		public function set alphaBlending(value:Boolean):void
		{
			_alphaBlending = value;
			_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending? BlendMode.LAYER : blendMode);
			_screenPass.preserveAlpha = requiresBlending;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function updateMaterial(context:Context3D):void
		{
			if (_screenPass._passesDirty) {
				clearPasses();
				if (_screenPass._passes) {
					var len:uint = _screenPass._passes.length;
					for (var i:uint = 0; i < len; ++i)
						addPass(_screenPass._passes[i]);
				}
				
				addPass(_screenPass);
				_screenPass._passesDirty = false;
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function set lightPicker(value:LightPickerBase):void
		{
			super.lightPicker = value;
			_screenPass.lightPicker = value;
		}
	}
}

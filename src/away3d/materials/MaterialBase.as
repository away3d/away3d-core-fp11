package away3d.materials
{
	import away3d.animators.IAnimationSet;
	import away3d.animators.IAnimator;
	import away3d.arcane;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.pool.IMaterialData;
	import away3d.core.pool.IMaterialPassData;
    import away3d.core.pool.MaterialPassData;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
	import away3d.core.library.AssetType;
	import away3d.core.library.IAsset;
	import away3d.core.library.NamedAssetBase;
	import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.lightpickers.LightPickerBase;
	import away3d.materials.passes.IMaterialPass;
	import away3d.textures.Texture2DBase;

	import flash.display.BlendMode;
	import flash.events.Event;
	import flash.geom.Matrix3D;

	use namespace arcane;

	/**
	 * MaterialBase forms an abstract base class for any material.
	 * A material consists of several passes, each of which constitutes at least one render call. Several passes could
	 * be used for special effects (render lighting for many lights in several passes, render an outline in a separate
	 * pass) or to provide additional render-to-texture passes (rendering diffuse light to texture for texture-space
	 * subsurface scattering, or rendering a depth map for specialized self-shadowing).
	 *
	 * Away3D provides default materials trough SinglePassMaterialBase and TriangleMaterial, which use modular
	 * methods to build the shader code. MaterialBase can be extended to build specific and high-performant custom
	 * shaders, or entire new material frameworks.
	 */
	public class MaterialBase extends NamedAssetBase implements IAsset
	{
		private var _materialPassData:Vector.<IMaterialPassData> = new Vector.<IMaterialPassData>();
		private var _materialData:Vector.<IMaterialData> = new Vector.<IMaterialData>();

		protected var _alphaThreshold:Number = 0;
		protected var _animateUVs:Boolean = false;
		private var _enableLightFallOff:Boolean = true;
		private var _specularLightSources:Number = 0x01;
		private var _diffuseLightSources:Number = 0x03;

		/**
		 * An object to contain any extra data.
		 */
		public var extra:Object;

		/**
		 * A value that can be used by materials that only work with a given type of renderer. The renderer can test the
		 * classification to choose which render path to use. For example, a deferred material could set this value so
		 * that the deferred renderer knows not to take the forward rendering path.
		 *
		 * @private
		 */
		arcane var classification:String;


		/**
		 * An id for this material used to sort the renderables by shader program, which reduces Program state changes.
		 *
		 * @private
		 */
		arcane var materialId:uint = 0;

		arcane var baseScreenPassIndex:Number = 0;

		private var _bothSides:Boolean = false; // update
		private var _animationSet:IAnimationSet;
		protected var _screenPassesInvalid:Boolean = true;

		/**
		 * A list of material owners, renderables or custom Entities.
		 */
		private var _owners:Vector.<IMaterialOwner>;

		private var _alphaPremultiplied:Boolean;

		protected var _blendMode:String = BlendMode.NORMAL;

		private var _numPasses:uint = 0;
		private var _passes:Vector.<IMaterialPass>;

		private var _mipmap:Boolean = false;
		private var _smooth:Boolean = true;
		private var _repeat:Boolean = false;
		private var _color:Number = 0xFFFFFF;
		protected var _texture:Texture2DBase;

		protected var _lightPicker:LightPickerBase;

		protected var _width:Number = 1;
		protected var _height:Number = 1;
		protected var _requiresBlending:Boolean = false;

		/**
		 * Creates a new MaterialBase object.
		 */
		public function MaterialBase()
		{
			materialId = id;

			_owners = new Vector.<IMaterialOwner>();
			_passes = new Vector.<IMaterialPass>();

			alphaPremultiplied = false; //TODO: work out why this is different for WebGL
		}

		/**
		 * @inheritDoc
		 */
		override public function get assetType():String
		{
			return AssetType.MATERIAL;
		}

		/**
		 *
		 */
		public function get height():Number
		{
			return _height;
		}

		/**
		 *
		 */
		public function get animationSet():IAnimationSet
		{
			return _animationSet;
		}


		/**
		 * The light picker used by the material to provide lights to the material if it supports lighting.
		 *
		 * @see LightPickerBase
		 * @see StaticLightPicker
		 */
		public function get lightPicker():LightPickerBase
		{
			return _lightPicker;
		}

		public function set lightPicker(value:LightPickerBase):void
		{
			if (_lightPicker == value)
				return;

			if (_lightPicker)
				_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);

			_lightPicker = value;

			if (_lightPicker)
				_lightPicker.addEventListener(Event.CHANGE, onLightsChange);

			invalidateScreenPasses();
		}

		/**
		 * Indicates whether or not any used textures should use mipmapping. Defaults to true.
		 */
		public function get mipmap():Boolean
		{
			return _mipmap;
		}

		public function set mipmap(value:Boolean):void
		{
			if (_mipmap == value)
				return;

			_mipmap = value;

			invalidatePasses();
		}

		/**
		 * Indicates whether or not any used textures should use smoothing.
		 */
		public function get smooth():Boolean
		{
			return _smooth;
		}

		public function set smooth(value:Boolean):void
		{
			if (_smooth == value)
				return;

			_smooth = value;

			invalidatePasses();
		}

		/**
		 * Indicates whether or not any used textures should be tiled. If set to false, texture samples are clamped to
		 * the texture's borders when the uv coordinates are outside the [0, 1] interval.
		 */
		public function get repeat():Boolean
		{
			return _repeat;
		}

		public function set repeat(value:Boolean):void
		{
			if (_repeat == value)
				return;

			_repeat = value;

			invalidatePasses();
		}

		/**
		 * The diffuse reflectivity color of the surface.
		 */
		public function get color():Number
		{
			return _color;
		}

		public function set color(value:Number):void
		{
			if (_color == value)
				return;

			_color = value;

			invalidatePasses();
		}

		/**
		 * The texture object to use for the albedo colour.
		 */
		public function get texture():Texture2DBase
		{
			return _texture;
		}

		public function set texture(value:Texture2DBase):void
		{
			if (_texture == value)
				return;

			_texture = value;

			invalidatePasses();
		}

		/**
		 * Specifies whether or not the UV coordinates should be animated using a transformation matrix.
		 */
		public function get animateUVs():Boolean
		{
			return  _animateUVs;
		}

		public function set animateUVs(value:Boolean):void
		{
			if (_animateUVs == value)
				return;

			_animateUVs = value;

			invalidatePasses();
		}

		/**
		 * Whether or not to use fallOff and radius properties for lights. This can be used to improve performance and
		 * compatibility for constrained mode.
		 */
		public function get enableLightFallOff():Boolean
		{
			return _enableLightFallOff;
		}

		public function set enableLightFallOff(value:Boolean):void
		{
			if (_enableLightFallOff == value)
				return;

			_enableLightFallOff = value;

			invalidatePasses();
		}

		/**
		 * Define which light source types to use for diffuse reflections. This allows choosing between regular lights
		 * and/or light probes for diffuse reflections.
		 *
		 * @see away3d.materials.LightSources
		 */
		public function get diffuseLightSources():Number
		{
			return _diffuseLightSources;
		}

		public function set diffuseLightSources(value:Number):void
		{
			if (_diffuseLightSources == value)
				return;

			_diffuseLightSources = value;

			invalidatePasses();
		}

		/**
		 * Define which light source types to use for specular reflections. This allows choosing between regular lights
		 * and/or light probes for specular reflections.
		 *
		 * @see away3d.materials.LightSources
		 */
		public function get specularLightSources():Number
		{
			return _specularLightSources;
		}

		public function set specularLightSources(value:Number):void
		{
			if (_specularLightSources == value)
				return;

			_specularLightSources = value;

			invalidatePasses();
		}

		/**
		 * Cleans up resources owned by the material, including passes. Textures are not owned by the material since they
		 * could be used by other materials and will not be disposed.
		 */
		override public function dispose():void
		{
			var i:Number;
			var len:Number;

			clearScreenPasses();

			len = _materialData.length;
			for (i = 0; i < len; i++)
				_materialData[i].dispose();

			_materialData = new Vector.<IMaterialData>();

			len = _materialPassData.length;
			for (i = 0; i < len; i++)
				_materialPassData[i].dispose();

			_materialPassData = new Vector.<IMaterialPassData>();
		}

		/**
		 * Defines whether or not the material should cull triangles facing away from the camera.
		 */
		public function get bothSides():Boolean
		{
			return _bothSides;
		}

		public function set bothSides(value:Boolean):void
		{
			if (_bothSides == value)
				return;

			_bothSides = value;

			invalidatePasses();
		}

		/**
		 * The blend mode to use when drawing this renderable. The following blend modes are supported:
		 * <ul>
		 * <li>BlendMode.NORMAL: No blending, unless the material inherently needs it</li>
		 * <li>BlendMode.LAYER: Force blending. This will draw the object the same as NORMAL, but without writing depth writes.</li>
		 * <li>BlendMode.MULTIPLY</li>
		 * <li>BlendMode.ADD</li>
		 * <li>BlendMode.ALPHA</li>
		 * </ul>
		 */
		public function get blendMode():String
		{
			return _blendMode;
		}

		public function set blendMode(value:String):void
		{
			if (_blendMode == value)
				return;

			_blendMode = value;

			invalidatePasses();
		}

		/**
		 * Indicates whether visible textures (or other pixels) used by this material have
		 * already been premultiplied. Toggle this if you are seeing black halos around your
		 * blended alpha edges.
		 */
		public function get alphaPremultiplied():Boolean
		{
			return _alphaPremultiplied;
		}

		public function set alphaPremultiplied(value:Boolean):void
		{
			if (_alphaPremultiplied == value)
				return;

			_alphaPremultiplied = value;

			invalidatePasses();
		}

		/**
		 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
		 * invisible or entirely opaque, often used with textures for foliage, etc.
		 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
		 */
		public function get alphaThreshold():Number
		{
			return _alphaThreshold;
		}

		public function set alphaThreshold(value:Number):void
		{
			if (value < 0)
				value = 0; else
				if (value > 1)
					value = 1;

			if (_alphaThreshold == value)
				return;

			_alphaThreshold = value;

			invalidatePasses();
		}

		/**
		 * Indicates whether or not the material requires alpha blending during rendering.
		 */
		public function get requiresBlending():Boolean
		{
			return _requiresBlending;
		}

		/**
		 *
		 */
		public function get width():Number
		{
			return _width;
		}

		/**
		 * Sets the render state for a pass that is independent of the rendered object. This needs to be called before
		 * calling renderPass. Before activating a pass, the previously used pass needs to be deactivated.
		 * @param pass The pass data to activate.
		 * @param stage The Stage object which is currently used for rendering.
		 * @param camera The camera from which the scene is viewed.
		 * @private
		 */
		arcane function activatePass(pass:MaterialPassData, stage:Stage3DProxy, camera:Camera3D):void
		{
			pass.materialPass.activate(pass, stage, camera);
		}

		/**
		 * Clears the render state for a pass. This needs to be called before activating another pass.
		 * @param pass The pass to deactivate.
		 * @param stage The Stage used for rendering
		 *
		 * @internal
		 */
		arcane function deactivatePass(pass:MaterialPassData, stage:Stage3DProxy):void
		{
			pass.materialPass.deactivate(pass, stage);
		}

		/**
		 * Renders the current pass. Before calling renderPass, activatePass needs to be called with the same index.
		 * @param pass The pass used to render the renderable.
		 * @param renderable The IRenderable object to draw.
		 * @param stage The Stage object used for rendering.
		 * @param entityCollector The EntityCollector object that contains the visible scene data.
		 * @param viewProjection The view-projection matrix used to project to the screen. This is not the same as
		 * camera.viewProjection as it includes the scaling factors when rendering to textures.
		 *
		 * @internal
		 */
		arcane function renderPass(pass:MaterialPassData, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
		{
			if (_lightPicker)
				_lightPicker.collectLights(renderable);

			pass.materialPass.render(pass, renderable, stage, camera, viewProjection);
		}

		//
		// MATERIAL MANAGEMENT
		//
		/**
		 * Mark an IMaterialOwner as owner of this material.
		 * Assures we're not using the same material across renderables with different animations, since the
		 * Programs depend on animation. This method needs to be called when a material is assigned.
		 *
		 * @param owner The IMaterialOwner that had this material assigned
		 *
		 * @internal
		 */
		arcane function addOwner(owner:IMaterialOwner):void
		{
			_owners.push(owner);

			var animationSet:IAnimationSet;
			var animator:IAnimator = owner.animator;

			if (animator)
				animationSet = animator.animationSet as IAnimationSet;

			if (owner.animator) {
				if (_animationSet && animationSet != _animationSet) {
					throw new Error("A Material instance cannot be shared across material owners with different animation sets");
				} else {
					if (_animationSet != animationSet) {
						_animationSet = animationSet;
						invalidateAnimation();
					}
				}
			}
		}

		/**
		 * Removes an IMaterialOwner as owner.
		 * @param owner
		 *
		 * @internal
		 */
		arcane function removeOwner(owner:IMaterialOwner):void
		{
			_owners.splice(_owners.indexOf(owner), 1);

			if (_owners.length == 0) {
				_animationSet = null;
				invalidateAnimation();
			}
		}

		/**
		 * A list of the IMaterialOwners that use this material
		 *
		 * @private
		 */
		arcane function get owners():Vector.<IMaterialOwner>
		{
			return _owners;
		}

		/**
		 * The amount of passes used by the material.
		 *
		 * @private
		 */
		arcane function get numScreenPasses():uint
		{
			return _numPasses;
		}

		/**
		 * A list of the screen passes used in this material
		 *
		 * @private
		 */
		arcane function get screenPasses():Vector.<IMaterialPass>
		{
			return _passes;
		}

		/**
		 * Marks the shader programs for all passes as invalid, so they will be recompiled before the next use.
		 *
		 * @private
		 */
		protected function invalidatePasses():void
		{
			var len:int = _materialPassData.length;
			for (var i:int = 0; i < len; i++)
				_materialPassData[i].invalidate();

			invalidateMaterial();
		}

		/**
		 * Flags that the screen passes have become invalid and need possible re-ordering / adding / deleting
		 */
		protected function invalidateScreenPasses():void
		{
			_screenPassesInvalid = true;
		}

		/**
		 * Removes a pass from the material.
		 * @param pass The pass to be removed.
		 */
		protected function removeScreenPass(pass:IMaterialPass):void
		{
			pass.removeEventListener(Event.CHANGE, onPassChange);
			_passes.splice(_passes.indexOf(pass), 1);

			_numPasses--;
		}

		/**
		 * Removes all passes from the material
		 */
		protected function clearScreenPasses():void
		{
			for (var i:Number = 0; i < _numPasses; ++i)
				_passes[i].removeEventListener(Event.CHANGE, onPassChange);

			_passes.length = _numPasses = 0;
		}

		/**
		 * Adds a pass to the material
		 * @param pass
		 */
		protected function addScreenPass(pass:IMaterialPass):void
		{
			_passes[_numPasses++] = pass;

			pass.lightPicker = _lightPicker;
			pass.addEventListener(Event.CHANGE, onPassChange);

			invalidateMaterial();
		}

		arcane function addMaterialData(materialData:IMaterialData):IMaterialData
		{
			_materialData.push(materialData);

			return materialData;
		}

		arcane function removeMaterialData(materialData:IMaterialData):IMaterialData
		{
			_materialData.splice(_materialData.indexOf(materialData), 1);

			return materialData;
		}

		/**
		 * Performs any processing that needs to occur before any of its passes are used.
		 *
		 * @private
		 */
		arcane function updateMaterial():void
		{
		}

		/**
		 * Listener for when a pass's shader code changes. It recalculates the render order id.
		 */
		private function onPassChange(event:Event):void
		{
			invalidateMaterial();
		}

		private function invalidateAnimation():void
		{
			var len:int = _materialData.length;
			for (var i:int = 0; i < len; i++)
				_materialData[i].invalidateAnimation();
		}

		private function invalidateMaterial():void
		{
			var len:int = _materialData.length;
			for (var i:int = 0; i < len; i++)
				_materialData[i].invalidateMaterial();
		}

		/**
		 * Called when the light picker's configuration changed.
		 */
		private function onLightsChange(event:Event):void
		{
			invalidateScreenPasses();
		}


		arcane function addMaterialPassData(materialPassData:IMaterialPassData):IMaterialPassData
		{
			_materialPassData.push(materialPassData);

			return materialPassData;
		}

		arcane function removeMaterialPassData(materialPassData:IMaterialPassData):IMaterialPassData
		{
			_materialPassData.splice(_materialPassData.indexOf(materialPassData), 1);
			return materialPassData;
		}

        arcane function getVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }

        arcane function getFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return "";
        }
	}
}
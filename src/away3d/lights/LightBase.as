package away3d.lights
{
	import away3d.arcane;
	import away3d.core.base.IRenderable;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.LightNode;
	import away3d.entities.Entity;
	import away3d.errors.AbstractMethodError;
	import away3d.events.LightEvent;
	import away3d.library.assets.AssetType;
	import away3d.lights.shadowmaps.ShadowMapperBase;
	
	import flash.geom.Matrix3D;
	
	use namespace arcane;
	
	/**
	 * LightBase provides an abstract base class for subtypes representing lights.
	 */
	public class LightBase extends Entity
	{
		private var _color:uint = 0xffffff;
		private var _colorR:Number = 1;
		private var _colorG:Number = 1;
		private var _colorB:Number = 1;
		
		private var _ambientColor:uint = 0xffffff;
		private var _ambient:Number = 0;
		arcane var _ambientR:Number = 0;
		arcane var _ambientG:Number = 0;
		arcane var _ambientB:Number = 0;
		
		private var _specular:Number = 1;
		arcane var _specularR:Number = 1;
		arcane var _specularG:Number = 1;
		arcane var _specularB:Number = 1;
		
		private var _diffuse:Number = 1;
		arcane var _diffuseR:Number = 1;
		arcane var _diffuseG:Number = 1;
		arcane var _diffuseB:Number = 1;
		
		private var _castsShadows:Boolean;
		
		private var _shadowMapper:ShadowMapperBase;
		
		/**
		 * Create a new LightBase object.
		 * @param positionBased Indicates whether or not the light has a valid position, or is "infinite" such as a DirectionalLight.
		 */
		public function LightBase()
		{
			super();
		}
		
		public function get castsShadows():Boolean
		{
			return _castsShadows;
		}
		
		public function set castsShadows(value:Boolean):void
		{
			if (_castsShadows == value)
				return;
			
			_castsShadows = value;
			
			if (value) {
				_shadowMapper ||= createShadowMapper();
				_shadowMapper.light = this;
			} else {
				_shadowMapper.dispose();
				_shadowMapper = null;
			}
			
			dispatchEvent(new LightEvent(LightEvent.CASTS_SHADOW_CHANGE));
		}
		
		protected function createShadowMapper():ShadowMapperBase
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * The specular emission strength of the light. Default value is <code>1</code>.
		 */
		public function get specular():Number
		{
			return _specular;
		}
		
		public function set specular(value:Number):void
		{
			if (value < 0)
				value = 0;
			_specular = value;
			updateSpecular();
		}
		
		/**
		 * The diffuse emission strength of the light. Default value is <code>1</code>.
		 */
		public function get diffuse():Number
		{
			return _diffuse;
		}
		
		public function set diffuse(value:Number):void
		{
			if (value < 0)
				value = 0;
			//else if (value > 1) value = 1;
			_diffuse = value;
			updateDiffuse();
		}
		
		/**
		 * The color of the light. Default value is <code>0xffffff</code>.
		 */
		public function get color():uint
		{
			return _color;
		}
		
		public function set color(value:uint):void
		{
			_color = value;
			_colorR = ((_color >> 16) & 0xff)/0xff;
			_colorG = ((_color >> 8) & 0xff)/0xff;
			_colorB = (_color & 0xff)/0xff;
			updateDiffuse();
			updateSpecular();
		}
		
		/**
		 * The ambient emission strength of the light. Default value is <code>0</code>.
		 */
		public function get ambient():Number
		{
			return _ambient;
		}
		
		public function set ambient(value:Number):void
		{
			if (value < 0)
				value = 0;
			else if (value > 1)
				value = 1;
			_ambient = value;
			updateAmbient();
		}
		
		/**
		 * The ambient emission color of the light. Default value is <code>0xffffff</code>.
		 */
		public function get ambientColor():uint
		{
			return _ambientColor;
		}
		
		public function set ambientColor(value:uint):void
		{
			_ambientColor = value;
			updateAmbient();
		}
		
		private function updateAmbient():void
		{
			_ambientR = ((_ambientColor >> 16) & 0xff)/0xff*_ambient;
			_ambientG = ((_ambientColor >> 8) & 0xff)/0xff*_ambient;
			_ambientB = (_ambientColor & 0xff)/0xff*_ambient;
		}
		
		/**
		 * Gets the optimal projection matrix to render a light-based depth map for a single object.
		 *
		 * @param renderable The IRenderable object to render to a depth map.
		 * @param target An optional target Matrix3D object. If not provided, an instance will be created.
		 * @return A Matrix3D object containing the projection transformation.
		 */
		arcane function getObjectProjectionMatrix(renderable:IRenderable, target:Matrix3D = null):Matrix3D
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function createEntityPartitionNode():EntityNode
		{
			return new LightNode(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get assetType():String
		{
			return AssetType.LIGHT;
		}
		
		/**
		 * Updates the total specular components of the light.
		 */
		private function updateSpecular():void
		{
			_specularR = _colorR*_specular;
			_specularG = _colorG*_specular;
			_specularB = _colorB*_specular;
		}
		
		/**
		 * Updates the total diffuse components of the light.
		 */
		private function updateDiffuse():void
		{
			_diffuseR = _colorR*_diffuse;
			_diffuseG = _colorG*_diffuse;
			_diffuseB = _colorB*_diffuse;
		}
		
		public function get shadowMapper():ShadowMapperBase
		{
			return _shadowMapper;
		}
		
		public function set shadowMapper(value:ShadowMapperBase):void
		{
			_shadowMapper = value;
			_shadowMapper.light = this;
		}
	}
}

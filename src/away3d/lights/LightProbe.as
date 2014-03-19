package away3d.lights
{
	import away3d.*;
	import away3d.bounds.*;
	import away3d.cameras.*;
	import away3d.core.base.*;
	import away3d.core.partition.*;
	import away3d.textures.*;
	
	import flash.geom.*;
	
	use namespace arcane;
	
	public class LightProbe extends LightBase
	{
		private var _diffuseMap:CubeTextureBase;
		private var _specularMap:CubeTextureBase;
		
		/**
		 * Creates a new LightProbe object.
		 */
		public function LightProbe(diffuseMap:CubeTextureBase, specularMap:CubeTextureBase = null)
		{
			super();
			_diffuseMap = diffuseMap;
			_specularMap = specularMap;
		}
		
		override protected function createEntityPartitionNode():EntityNode
		{
			return new LightProbeNode(this);
		}
		
		public function get diffuseMap():CubeTextureBase
		{
			return _diffuseMap;
		}
		
		public function set diffuseMap(value:CubeTextureBase):void
		{
			_diffuseMap = value;
		}
		
		public function get specularMap():CubeTextureBase
		{
			return _specularMap;
		}
		
		public function set specularMap(value:CubeTextureBase):void
		{
			_specularMap = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateBounds():void
		{
			//			super.updateBounds();
			_boundsInvalid = false;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function getDefaultBoundingVolume():BoundingVolumeBase
		{
			// todo: consider if this can be culled?
			return new NullBounds();
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getObjectProjectionMatrix(renderable:IRenderable, camera:Camera3D, target:Matrix3D = null):Matrix3D
		{
			// TODO: not used
			renderable = renderable;
			target = target;
			
			throw new Error("Object projection matrices are not supported for LightProbe objects!");
			return null;
		}
	}
}

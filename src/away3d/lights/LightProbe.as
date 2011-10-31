package away3d.lights
{
	import away3d.arcane;
	import away3d.bounds.BoundingSphere;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.bounds.NullBounds;
	import away3d.core.base.IRenderable;
	import away3d.core.math.Matrix3DUtils;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.CubeTextureProxyBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.CubeTexture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace arcane;

	public class LightProbe extends LightBase
	{
		private var _diffuseMap : CubeTextureProxyBase;
		private var _specularMap : CubeTextureProxyBase;

		/**
		 * Creates a new LightProbe object.
		 */
		public function LightProbe(diffuseMap : CubeTextureProxyBase, specularMap : CubeTextureProxyBase = null)
		{
			super();
			_diffuseMap = diffuseMap;
			_specularMap = specularMap;
		}

		public function get diffuseMap() : CubeTextureProxyBase
		{
			return _diffuseMap;
		}

		public function set diffuseMap(value : CubeTextureProxyBase) : void
		{
			_diffuseMap = value;
		}

		public function get specularMap() : CubeTextureProxyBase
		{
			return _specularMap;
		}

		public function set specularMap(value : CubeTextureProxyBase) : void
		{
			_specularMap = value;
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateBounds() : void
		{
//			super.updateBounds();
			_boundsInvalid = false;
		}

		/**
		 * @inheritDoc
		 */
		override protected function getDefaultBoundingVolume() : BoundingVolumeBase
		{
			// todo: consider if this can be culled?
			return new NullBounds();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getObjectProjectionMatrix(renderable : IRenderable, target : Matrix3D = null) : Matrix3D
		{
			throw new Error("Object projection matrices are not supported for LightProbe objects!");
			return null;
		}
	}
}
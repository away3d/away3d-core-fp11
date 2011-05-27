package away3d.bounds
{
	import away3d.core.base.Geometry;

	import away3d.primitives.WireframePrimitiveBase;

	import away3d.primitives.WireframeSphere;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	/**
	 * NullBounds represents a debug bounding "volume" that is either considered always in, or always out of the frustum.
	 * NullBounds is useful for entities that are always considered in the frustum, such as directional lights or skyboxes.
	 */
	public class NullBounds extends BoundingVolumeBase
	{
		private var _alwaysIn : Boolean;
		private var _renderable : WireframePrimitiveBase;

		public function NullBounds(alwaysIn : Boolean = true, renderable : WireframePrimitiveBase = null)
		{
			super();
			_alwaysIn = alwaysIn;
			_renderable = renderable;
		}

		override protected function createBoundingRenderable() : WireframePrimitiveBase
		{
			return _renderable || new WireframeSphere(100);
		}

		/**
		 * @inheritDoc
		 */
		override public function isInFrustum(mvpMatrix : Matrix3D) : Boolean
		{
			return _alwaysIn;
		}

		override public function intersectsLine(p : Vector3D, dir : Vector3D) : Boolean
		{
			return _alwaysIn;
		}

		/**
		 * @inheritDoc
		 */
		override public function fromGeometry(geometry : Geometry) : void {}

		/**
		 * @inheritDoc
		 */
		override public function fromSphere(center : Vector3D, radius : Number) : void {}

		/**
		 * @inheritDoc
		 */
		override public function fromExtremes(minX : Number, minY : Number, minZ : Number, maxX : Number, maxY : Number, maxZ : Number) : void {}
	}
}
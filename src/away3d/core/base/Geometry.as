package away3d.core.base
{
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.NullAnimation;
	import away3d.arcane;
	import away3d.events.GeometryEvent;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;
	
	import flash.events.EventDispatcher;

	use namespace arcane;

	/**
	 * Geometry is a collection of SubGeometries, each of which contain the actual geometrical data such as vertices,
	 * normals, uvs, etc. It also contains a reference to an animation class, which defines how the geometry moves.
	 * A Geometry object is assigned to a Mesh, a scene graph occurence of the geometry, which in turn assigns
	 * the SubGeometries to its respective SubMesh objects.
	 *
	 * @see away3d.core.base.SubGeometry
	 * @see away3d.scenegraph.Mesh
	 */
	public class Geometry extends NamedAssetBase implements IAsset
	{
		private var _subGeometries : Vector.<SubGeometry>;
		arcane var _animation : AnimationBase;

		/**
		 * Creates a new Geometry object.
		 */
		public function Geometry()
		{
			_subGeometries = new Vector.<SubGeometry>();
			_animation = new NullAnimation();
		}
		
		
		public function get assetType() : String
		{
			return AssetType.GEOMETRY;
		}

		/**
		 * The AnimationBase object used to animate the geometry.
		 */
		public function get animation() : AnimationBase
		{
			return _animation;
		}

		public function set animation(value : AnimationBase) : void
		{
			_animation = value;
			if (hasEventListener(GeometryEvent.ANIMATION_CHANGED))
				dispatchEvent(new GeometryEvent(GeometryEvent.ANIMATION_CHANGED));
		}

		/**
		 * A collection of SubGeometry objects, each of which contain geometrical data such as vertices, normals, etc.
		 */
		public function get subGeometries() : Vector.<SubGeometry>
		{
			return _subGeometries;
		}

		/**
		 * Adds a new SubGeometry object to the list.
		 * @param subGeometry The SubGeometry object to be added.
		 */
		public function addSubGeometry(subGeometry : SubGeometry) : void
		{
			_subGeometries.push(subGeometry);

			subGeometry.parentGeometry = this;
			if (hasEventListener(GeometryEvent.SUB_GEOMETRY_ADDED))
				dispatchEvent(new GeometryEvent(GeometryEvent.SUB_GEOMETRY_ADDED, subGeometry));

			invalidateBounds(subGeometry);
		}

		/**
		 * Removes a new SubGeometry object from the list.
		 * @param subGeometry The SubGeometry object to be removed.
		 *
		 * todo: consider signals instead of events?
		 */
		public function removeSubGeometry(subGeometry : SubGeometry) : void
		{
			_subGeometries.splice(_subGeometries.indexOf(subGeometry), 1);
			subGeometry.parentGeometry = null;
			if (hasEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED))
				dispatchEvent(new GeometryEvent(GeometryEvent.SUB_GEOMETRY_REMOVED, subGeometry));

			invalidateBounds(subGeometry);
		}

		/**
		 * Clones the geometry.
		 * @return An exact duplicate of the current Geometry object.
		 */
		public function clone() : Geometry
		{
			var clone : Geometry = new Geometry();
			clone._animation = _animation;
			var len : uint = _subGeometries.length;
			for (var i : int = 0; i < len; ++i) {
				clone.addSubGeometry(_subGeometries[i].clone());
			}
			return clone;
		}

		/**
		 * Scales the geometry.
		 * @param scale The amount by which to scale.
		 */
        public function scale(scale : Number):void
        {
            var numSubGeoms : uint = _subGeometries.length;
            for (var i : uint = 0; i < numSubGeoms; ++i)
                _subGeometries[i].scale(scale);
        }

		/**
		 * Clears all resources used by the Geometry object, including SubGeometries.
		 */
		public function dispose() : void
		{
			var numSubGeoms : uint = _subGeometries.length;
            for (var i : uint = 0; i < numSubGeoms; ++i)
                _subGeometries[i].dispose();
		}

		/**
		 * Scales the uv coordinates.
		 * @param scale The amount by which to scale.
		 */
		public function scaleUV(scale : Number) : void
		{
			var numSubGeoms : uint = _subGeometries.length;
            for (var i : uint = 0; i < numSubGeoms; ++i)
                _subGeometries[i].scaleUV(scale);
		}

		arcane function invalidateBounds(subGeom : SubGeometry) : void
		{
			if (hasEventListener(GeometryEvent.BOUNDS_INVALID))
				dispatchEvent(new GeometryEvent(GeometryEvent.BOUNDS_INVALID, subGeom));
		}
	}
}

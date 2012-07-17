package away3d.materials.methods
{
	public class MethodVO
	{
		public var vertexConstantsOffset : int;
		public var vertexData : Vector.<Number>;
		public var fragmentData : Vector.<Number>;

		// public register indices
		public var texturesIndex : int;
		public var secondaryTexturesIndex : int;	// sometimes needed for composites
		public var vertexConstantsIndex : int;
		public var secondaryVertexConstantsIndex : int;	// sometimes needed for composites
		public var fragmentConstantsIndex : int;
		public var secondaryFragmentConstantsIndex : int;	// sometimes needed for composites

		public var useMipmapping : Boolean;
		public var useSmoothTextures : Boolean;
		public var repeatTextures : Boolean;

		// internal stuff for the material to know before assembling code
		public var needsProjection : Boolean;
		public var needsView : Boolean;
		public var needsNormals : Boolean;
		public var needsTangents : Boolean;
		public var needsUV : Boolean;
		public var needsSecondaryUV : Boolean;
		public var needsGlobalPos : Boolean;

		public var numLights : int;

		public function reset() : void
		{
			vertexConstantsOffset = 0;
			texturesIndex = -1;
			vertexConstantsIndex = -1;
			fragmentConstantsIndex = -1;

			useMipmapping = true;
			useSmoothTextures = true;
			repeatTextures = false;

			needsProjection = false;
			needsView = false;
			needsNormals = false;
			needsTangents = false;
			needsUV = false;
			needsSecondaryUV = false;
			needsGlobalPos = false;

			numLights = 0;
		}
	}
}

package away3d.materials.compilation
{
    import away3d.materials.methods.ShadingMethodBase;

    /**
	 * MethodVO contains data for a given method for the use within a single material.
	 * This allows methods to be shared across materials while their non-public state differs.
	 */
	public class MethodVO
	{
        public var useMethod:Boolean = true;
        public var method:ShadingMethodBase;

		// public register indices
		public var texturesIndex:int;
		public var secondaryTexturesIndex:int; // sometimes needed for composites
		public var vertexConstantsIndex:int;
		public var secondaryVertexConstantsIndex:int; // sometimes needed for composites
		public var fragmentConstantsIndex:int;
		public var secondaryFragmentConstantsIndex:int; // sometimes needed for composites
		
		// internal stuff for the material to know before assembling code
		public var needsProjection:Boolean;
		public var needsView:Boolean;
		public var needsNormals:Boolean;
		public var needsTangents:Boolean;
		public var needsUV:Boolean;
		public var needsSecondaryUV:Boolean;
		public var needsGlobalVertexPos:Boolean;
		public var needsGlobalFragmentPos:Boolean;

		/**
		 * Creates a new MethodVO object.
		 */
		public function MethodVO(method:ShadingMethodBase)
		{
            this.method = method;
		}

		/**
		 * Resets the values of the value object to their "unused" state.
		 */
		public function reset():void
		{
			texturesIndex = -1;
			vertexConstantsIndex = -1;
			fragmentConstantsIndex = -1;

			needsProjection = false;
			needsView = false;
			needsNormals = false;
			needsTangents = false;
			needsUV = false;
			needsSecondaryUV = false;
			needsGlobalVertexPos = false;
			needsGlobalFragmentPos = false;
		}
	}
}
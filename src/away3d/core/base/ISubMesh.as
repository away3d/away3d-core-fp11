package away3d.core.base
{
    import away3d.entities.Mesh;
    import away3d.materials.MaterialBase;

    /**
	 * ISubMeshClass is an interface for the constructable class definition SubMesh that is used to
	 * create apply a marterial to a SubGeometry class
	 */
	public interface ISubMesh extends IMaterialOwner
	{
		function get subGeometry():SubGeometryBase;

		function get parentMesh():Mesh;

		function get index():Number;

		function set index(value:Number):void;

		function invalidateRenderableGeometry():void;

		function getExplicitMaterial():MaterialBase;
	}
}

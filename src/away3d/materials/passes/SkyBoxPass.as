package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.pool.RenderableBase;
	import away3d.entities.Camera3D;
	import away3d.core.pool.IRenderable;
	import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.textures.CubeTextureBase;
	
	import flash.display3D.Context3D;
	
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * SkyBoxPass provides a material pass exclusively used to render sky boxes from a cube texture.
	 */
	public class SkyBoxPass extends MaterialPassBase
	{

		/**
		 * Creates a new SkyBoxPass object.
		 */
		public function SkyBoxPass()
		{
			super();
		}


        override public function includeDependencies(shaderObject:ShaderObjectBase):void
        {
            shaderObject.useMipmapping = false;
        }
    }
}

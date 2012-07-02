package away3d.materials
{
	import away3d.arcane;
	import away3d.textures.Texture2DBase;

	import flash.geom.ColorTransform;

	use namespace arcane;

	/**
	 * TextureMaterial is a material that uses a texture as the surface's diffuse colour.
	 */
	public class TextureMaterial extends DefaultMaterialBase
	{
		/**
		 * Creates a new TextureMaterial.
		 */
		public function TextureMaterial(texture : Texture2DBase = null, smooth : Boolean = true, repeat : Boolean = false, mipmap : Boolean = true)
		{
			super();
			this.texture = texture;
			this.smooth = smooth;
			this.repeat = repeat;
			this.mipmap = mipmap;
		}

		public function get animateUVs() : Boolean
		{
			return _screenPass.animateUVs;
		}

		public function set animateUVs(value : Boolean) : void
		{
			_screenPass.animateUVs = value;
		}

		/**
		 * The alpha of the surface.
		 */
		public function get alpha() : Number
		{
			return _screenPass.colorTransform? _screenPass.colorTransform.alphaMultiplier : 1;
		}

		public function set alpha(value : Number) : void
		{
			if (value > 1) value = 1;
			else if (value < 0) value = 0;

			colorTransform ||= new ColorTransform();
			colorTransform.alphaMultiplier = value;
		}

//		arcane override function activatePass(index : uint, context : Context3D, contextIndex : uint, camera : Camera3D) : void
//		{
//			super.arcane::activatePass(index, context, contextIndex, camera);
//		}

		/**
		 * The texture object to use for the albedo colour.
		 */
		public function get texture() : Texture2DBase
		{
			return _screenPass.diffuseMethod.texture;
		}

		public function set texture(value : Texture2DBase) : void
		{
			_screenPass.diffuseMethod.texture = value;
		}
		
		/**
		 * The texture object to use for the ambient colour.
		 */
		public function get ambientTexture() : Texture2DBase
		{
			return _screenPass.ambientMethod.texture;
		}
		
		public function set ambientTexture(value : Texture2DBase) : void
		{
			_screenPass.diffuseMethod._useDiffuseTexture = true;
			_screenPass.ambientMethod.texture = value;
		}
	}
}
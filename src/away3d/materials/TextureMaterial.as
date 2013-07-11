package away3d.materials
{
	import away3d.*;
	import away3d.textures.*;
	
	import flash.display.*;
	import flash.geom.*;
	
	use namespace arcane;
	
	/**
	 * TextureMaterial is a single-pass material that uses a texture to define the surface's diffuse reflection colour (albedo).
	 */
	public class TextureMaterial extends SinglePassMaterialBase
	{
		/**
		 * Creates a new TextureMaterial.
		 * @param texture The texture used for the material's albedo color.
		 * @param smooth Indicates whether the texture should be filtered when sampled. Defaults to true.
		 * @param repeat Indicates whether the texture should be tiled when sampled. Defaults to true.
		 * @param mipmap Indicates whether or not any used textures should use mipmapping. Defaults to true.
		 */
		public function TextureMaterial(texture:Texture2DBase = null, smooth:Boolean = true, repeat:Boolean = false, mipmap:Boolean = true)
		{
			super();
			this.texture = texture;
			this.smooth = smooth;
			this.repeat = repeat;
			this.mipmap = mipmap;
		}

		/**
		 * Specifies whether or not the UV coordinates should be animated using IRenderable's uvTransform matrix.
		 *
		 * @see IRenderable.uvTransform
		 */
		public function get animateUVs():Boolean
		{
			return _screenPass.animateUVs;
		}
		
		public function set animateUVs(value:Boolean):void
		{
			_screenPass.animateUVs = value;
		}
		
		/**
		 * The alpha of the surface.
		 */
		public function get alpha():Number
		{
			return _screenPass.colorTransform? _screenPass.colorTransform.alphaMultiplier : 1;
		}
		
		public function set alpha(value:Number):void
		{
			if (value > 1)
				value = 1;
			else if (value < 0)
				value = 0;
			
			colorTransform ||= new ColorTransform();
			colorTransform.alphaMultiplier = value;
			_screenPass.preserveAlpha = requiresBlending;
			_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending? BlendMode.LAYER : blendMode);
		}
		
		/**
		 * The texture object to use for the albedo colour.
		 */
		public function get texture():Texture2DBase
		{
			return _screenPass.diffuseMethod.texture;
		}
		
		public function set texture(value:Texture2DBase):void
		{
			_screenPass.diffuseMethod.texture = value;
		}
		
		/**
		 * The texture object to use for the ambient colour.
		 */
		public function get ambientTexture():Texture2DBase
		{
			return _screenPass.ambientMethod.texture;
		}
		
		public function set ambientTexture(value:Texture2DBase):void
		{
			_screenPass.ambientMethod.texture = value;
			_screenPass.diffuseMethod.useAmbientTexture = Boolean(value);
		}
	}
}

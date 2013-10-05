package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.Matrix3DUtils;
	import away3d.textures.Texture2DBase;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.geom.Matrix3D;
	
	use namespace arcane;

	/**
	 * DepthMapPass is a pass that writes depth values to a depth map as a 32-bit value exploded over the 4 texture channels.
	 * This is used to render shadow maps, depth maps, etc.
	 */
	public class DepthMapPass extends MaterialPassBase
	{
		private var _data:Vector.<Number>;
		private var _alphaThreshold:Number = 0;
		private var _alphaMask:Texture2DBase;

		/**
		 * Creates a new DepthMapPass object.
		 */
		public function DepthMapPass()
		{
			super();
			_data = Vector.<Number>([    1.0, 255.0, 65025.0, 16581375.0,
				1.0/255.0, 1.0/255.0, 1.0/255.0, 0.0,
				0.0, 0.0, 0.0, 0.0]);
		}
		
		/**
		 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
		 * invisible or entirely opaque, often used with textures for foliage, etc.
		 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
		 */
		public function get alphaThreshold():Number
		{
			return _alphaThreshold;
		}
		
		public function set alphaThreshold(value:Number):void
		{
			if (value < 0)
				value = 0;
			else if (value > 1)
				value = 1;
			if (value == _alphaThreshold)
				return;
			
			if (value == 0 || _alphaThreshold == 0)
				invalidateShaderProgram();
			
			_alphaThreshold = value;
			_data[8] = _alphaThreshold;
		}

		/**
		 * A texture providing alpha data to be able to prevent semi-transparent pixels to write to the alpha mask.
		 * Usually the diffuse texture when alphaThreshold is used.
		 */
		public function get alphaMask():Texture2DBase
		{
			return _alphaMask;
		}
		
		public function set alphaMask(value:Texture2DBase):void
		{
			_alphaMask = value;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode():String
		{
			var code:String;
			// project
			code = "m44 vt1, vt0, vc0		\n" +
				"mov op, vt1	\n";
			
			if (_alphaThreshold > 0) {
				_numUsedTextures = 1;
				_numUsedStreams = 2;
				code += "mov v0, vt1\n" +
					"mov v1, va1\n";
				
			} else {
				_numUsedTextures = 0;
				_numUsedStreams = 1;
				code += "mov v0, vt1\n";
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(code:String):String
		{
			var codeF:String =
				"div ft2, v0, v0.w		\n" +
				"mul ft0, fc0, ft2.z	\n" +
				"frc ft0, ft0			\n" +
				"mul ft1, ft0.yzww, fc1	\n";
			
			if (_alphaThreshold > 0) {
				var wrap:String = _repeat ? "wrap" : "clamp";
				var filter:String, format:String;
				var enableMipMaps:Boolean = _mipmap && _alphaMask.hasMipMaps;
				
				if (_smooth)
					filter = enableMipMaps ? "linear,miplinear" : "linear";
				else
					filter = enableMipMaps ? "nearest,mipnearest" : "nearest";
				
				switch (_alphaMask.format) {
					case Context3DTextureFormat.COMPRESSED:
						format = "dxt1,";
						break;
					case "compressedAlpha":
						format = "dxt5,";
						break;
					default:
						format = "";
				}
				codeF += "tex ft3, v1, fs0 <2d," + filter + "," + format + wrap + ">\n" +
					"sub ft3.w, ft3.w, fc2.x\n" +
					"kil ft3.w\n";
			}
			
			codeF += "sub oc, ft0, ft1		\n";
			
			return codeF;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
		{
			if (_alphaThreshold > 0)
				renderable.activateUVBuffer(1, stage3DProxy);
			
			var context:Context3D = stage3DProxy._context3D;
			var matrix:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
			matrix.copyFrom(renderable.getRenderSceneTransform(camera));
			matrix.append(viewProjection);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
			renderable.activateVertexBuffer(0, stage3DProxy);
			context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			var context:Context3D = stage3DProxy._context3D;
			super.activate(stage3DProxy, camera);
			
			if (_alphaThreshold > 0) {
				context.setTextureAt(0, _alphaMask.getTextureForStage3D(stage3DProxy));
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 3);
			} else
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 2);
		}
	}
}

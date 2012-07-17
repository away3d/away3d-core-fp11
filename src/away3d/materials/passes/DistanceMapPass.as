package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.lightpickers.LightPickerBase;
	import away3d.textures.Texture2DBase;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class DistanceMapPass extends MaterialPassBase
	{
		private var _fragmentData : Vector.<Number>;
		private var _vertexData : Vector.<Number>;
		private var _alphaThreshold : Number;
		private var _alphaMask : Texture2DBase;

		public function DistanceMapPass()
		{
			super();
			_fragmentData = Vector.<Number>([	1.0, 255.0, 65025.0, 16581375.0,
												1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0,
												0.0, 0.0, 0.0, 0.0]);
			_vertexData = new Vector.<Number>(4, true);
			_vertexData[3] = 1;
			_numUsedVertexConstants = 9;
		}

		/**
		 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
		 * invisible or entirely opaque, often used with textures for foliage, etc.
		 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
		 */
		public function get alphaThreshold() : Number
		{
			return _alphaThreshold;
		}

		public function set alphaThreshold(value : Number) : void
		{
			if (value < 0) value = 0;
			else if (value > 1) value = 1;
			if (value == _alphaThreshold) return;

			if (value == 0 || _alphaThreshold == 0)
				invalidateShaderProgram();

			_alphaThreshold = value;
			_fragmentData[8] = _alphaThreshold;
		}

		public function get alphaMask() : Texture2DBase
		{
			return _alphaMask;
		}

		public function set alphaMask(value : Texture2DBase) : void
		{
			_alphaMask = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode(code:String) : String
		{
			code += "m44 vt7, vt0, vc0		\n" +
					"mul op, vt7, vc4		\n" +
					"m44 vt1, vt0, vc5		\n" +
					"sub v0, vt1, vc9		\n";

			if (_alphaThreshold > 0) {
				code += "mov v1, va1\n";
				_numUsedTextures = 1;
				_numUsedStreams = 2;
			}
			else {
				_numUsedTextures = 0;
				_numUsedStreams = 1;
			}

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : String
		{
			var code : String;
			var wrap : String = _repeat ? "wrap" : "clamp";
			var filter : String;

			if (_smooth) filter = _mipmap ? "linear,miplinear" : "linear";
			else filter = _mipmap ? "nearest,mipnearest" : "nearest";

			// squared distance to view
			code =	"dp3 ft2.z, v0.xyz, v0.xyz	\n" +
					"mul ft0, fc0, ft2.z	\n" +
					"frc ft0, ft0			\n" +
					"mul ft1, ft0.yzww, fc1	\n";

			if (_alphaThreshold > 0) {
				code += "tex ft3, v1, fs0 <2d,"+filter+","+wrap+">\n" +
						"sub ft3.w, ft3.w, fc2.x\n" +
						"kil ft3.w\n";
			}

			code += "sub oc, ft0, ft1		\n";

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D, lightPicker : LightPickerBase) : void
		{
			var pos : Vector3D = camera.scenePosition;

			_vertexData[0] = pos.x;
			_vertexData[1] = pos.y;
			_vertexData[2] = pos.z;
			_vertexData[3] = 1;

			stage3DProxy._context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 5, renderable.sceneTransform, true);
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 9, _vertexData, 1);

			if (_alphaThreshold > 0)
				stage3DProxy.setSimpleVertexBuffer(1, renderable.getUVBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_2, renderable.UVBufferOffset);

			super.render(renderable, stage3DProxy, camera, lightPicker);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			super.activate(stage3DProxy, camera, textureRatioX, textureRatioY);

			var f : Number = camera.lens.far;

			f = 1/(2*f*f);
			// sqrt(f*f+f*f) is largest possible distance for any frustum, so we need to divide by it. Rarely a tight fit, but with 32 bits precision, it's enough.
			_fragmentData[0] = 1*f;
			_fragmentData[1] = 255.0*f;
			_fragmentData[2] = 65025.0*f;
			_fragmentData[3] = 16581375.0*f;


			if (_alphaThreshold > 0) {
				stage3DProxy.setTextureAt(0, _alphaMask.getTextureForStage3D(stage3DProxy));
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentData, 3);
			}
			else {
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentData, 2);
			}
		}
	}
}
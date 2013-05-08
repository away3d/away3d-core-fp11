package away3d.materials.passes {
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.LightBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;

	use namespace arcane;

	/**
	 * The SingleObjectDepthPass provides a material pass that renders a single object to a depth map from the point
	 * of view from a light.
	 */
	public class SingleObjectDepthPass extends MaterialPassBase
	{
		private var _textures : Vector.<Dictionary>;
		private var _projections : Dictionary;
		private var _textureSize : uint;
		private var _polyOffset : Vector.<Number>;
		private var _enc : Vector.<Number>;
		private var _projectionTexturesInvalid : Boolean = true;

		/**
		 * Creates a new SingleObjectDepthPass object.
		 * @param textureSize The size of the depth map texture to render to.
		 * @param polyOffset The amount by which the rendered object will be inflated, to prevent depth map rounding errors.
		 *
		 * todo: provide custom vertex code to assembler
		 */
		public function SingleObjectDepthPass(textureSize : uint = 512, polyOffset : Number = 15)
		{
			super(true);
			_textureSize = textureSize;
			_numUsedStreams = 2;
			_numUsedVertexConstants = 7;
			_polyOffset = new <Number>[polyOffset, 0, 0, 0];
			_enc = Vector.<Number>([	1.0, 255.0, 65025.0, 16581375.0,
										1.0 / 255.0,1.0 / 255.0,1.0 / 255.0,0.0
									]);
			
			_animatableAttributes = Vector.<String>(["va0", "va1"]);
			_animationTargetRegisters = Vector.<String>(["vt0", "vt1"]);
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
			if (_textures) {
				for (var i : uint = 0; i < _textures.length; ++i) {
					for each(var vec : Vector.<Texture> in _textures[i]) {
						for (var j : uint = 0; j < vec.length; ++j) {
							vec[j].dispose();
						}
					}
				}
				_textures = null;
			}
		}

		private function updateProjectionTextures() : void
		{
			if (_textures) {
				for (var i : uint = 0; i < _textures.length; ++i) {
					for each(var vec : Vector.<Texture> in _textures[i]) {
						for (var j : uint = 0; j < vec.length; ++j) {
							vec[j].dispose();
						}
					}
				}
			}

			_textures = new Vector.<Dictionary>(8);
			_projections = new Dictionary();
			_projectionTexturesInvalid = false;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode() : String
		{
			var code : String;
			// offset
			code = 	"mul vt7, vt1, vc4.x	\n" +
					"add vt7, vt7, vt0		\n" +
					"mov vt7.w, vt0.w		\n";
			// project
			code += "m44 vt2, vt7, vc0		\n" +
					"mov op, vt2			\n";

			// perspective divide
			code += "div v0, vt2, vt2.w \n";

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(animationCode:String) : String
		{
			// TODO: not used
			animationCode=animationCode;
			var code : String = "";

			// encode float -> rgba
			code += "mul ft0, fc0, v0.z     \n" +
                    "frc ft0, ft0           \n" +
                    "mul ft1, ft0.yzww, fc1 \n" +
                    "sub ft0, ft0, ft1      \n" +
                    "mov oc, ft0            \n";

			return code;
		}

		/**
		 * Gets the depth maps rendered for this object from all lights.
		 * @param renderable The renderable for which to retrieve the depth maps
		 * @return A list of depth map textures for all supported lights.
		 */
		arcane function getDepthMap(renderable : IRenderable, stage3DProxy : Stage3DProxy) : Texture
		{
			return _textures[stage3DProxy._stage3DIndex][renderable];
		}

		/**
		 * Retrieves the depth map projection maps for all lights.
		 * @param renderable The renderable for which to retrieve the projection maps.
		 * @return A list of projection maps for all supported lights.
		 */
		arcane function getProjection(renderable : IRenderable) : Matrix3D
		{
			return _projections[renderable];
		}

		/**
		 * @inheritDoc
		 */
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D, viewProjection : Matrix3D) : void
		{
			var matrix : Matrix3D;
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;
			var len : uint;
			var light : LightBase;
			var lights : Vector.<LightBase> = _lightPicker.allPickedLights;

			_textures[contextIndex] ||= new Dictionary();

			if (!_projections[renderable])
				_projections[renderable] = new Matrix3D();

			len = lights.length;
			// local position = enough
			light = lights[0];

			matrix = light.getObjectProjectionMatrix(renderable, _projections[renderable]);

			// todo: use texture proxy?
			var target : Texture = _textures[contextIndex][renderable] ||= context.createTexture(_textureSize, _textureSize, Context3DTextureFormat.BGRA, true);

			stage3DProxy.setRenderTarget(target, true);
			context.clear(1.0, 1.0, 1.0);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _enc, 2);
			renderable.activateVertexBuffer(0, stage3DProxy);
			renderable.activateVertexNormalBuffer(1, stage3DProxy);
			context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			if (_projectionTexturesInvalid) updateProjectionTextures();
			// never scale
			super.activate(stage3DProxy, camera);
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _polyOffset, 1);
		}
	}
}

package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.Stage3DEvent;
	import away3d.lights.LightBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
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
		private var _lightPosData : Vector.<Number>;
		private var _polyOffset : Vector.<Number>;
		private var _enc : Vector.<Number>;
		private var _listensForDispose : Vector.<Boolean>;

		/**
		 * Creates a new SingleObjectDepthPass object.
		 * @param textureSize The size of the depth map texture to render to.
		 * @param polyOffset The amount by which the rendered object will be inflated, to prevent depth map rounding errors.
		 */
		public function SingleObjectDepthPass(textureSize : uint = 512, polyOffset : Number = 15)
		{
			super();
			_textureSize = textureSize;
			_numUsedStreams = 2;
			_numUsedVertexConstants = 6;
			_lightPosData = new Vector.<Number>(8, true);
			_animatableAttributes = ["va0", "va1"];
			_targetRegisters = ["vt0", "vt1"];
			_polyOffset = Vector.<Number>([polyOffset, 0, 0, 0]);
			_enc = Vector.<Number>([	1.0, 255.0, 65025.0, 16581375.0,
										1.0 / 255.0,1.0 / 255.0,1.0 / 255.0,0.0
			]);
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose(deep : Boolean) : void
		{
			if (_textures) {
				for (var i : uint = 0; i < _textures.length; ++i) {
					for each(var vec : Vector.<Texture> in _textures[i]) {
						for (var j : uint = 0; j < vec.length; ++i) {
							vec[j].dispose();
						}
					}
				}
				_textures = null;
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function set lights(value : Vector.<LightBase>) : void
		{
			super.lights = value;

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
//			_textures = new Vector.<Texture>(value, true);

//			for (i = 0; i < _numLights; ++i) _projections[i] = new Matrix3D();
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode() : String
		{
			_projectedTargetRegister = "vt2";
			var code : String = "";

			code += "rcp vt2.w, vt2.w           \n" +
                    "mul v0.xyz, vt2.xyz, vt2.w \n" +
                    "mov v0.w, vt0.w            \n";

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : String
		{
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
		arcane function getDepthMaps(renderable : IRenderable, stage3DProxy : Stage3DProxy) : Vector.<Texture>
		{
			return _textures[stage3DProxy._stage3DIndex][renderable];
		}

		/**
		 * Retrieves the depth map projection maps for all lights.
		 * @param renderable The renderable for which to retrieve the projection maps.
		 * @return A list of projection maps for all supported lights.
		 */
		arcane function getProjections(renderable : IRenderable) : Vector.<Matrix3D>
		{
			return _projections[renderable];
		}

		/**
		 * @inheritDoc
		 * todo: keep maps in dictionary per renderable
		 */
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var matrix : Matrix3D;
			var len : int = lights.length;
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;
			var j : uint, i : uint;
			var light : LightBase;
			var vec : Vector.<Matrix3D>;

			if (_numLights < len) len = _numLights;

			_textures[contextIndex] ||= new Dictionary();
			_textures[contextIndex][renderable] ||= new Vector.<Texture>(_numLights);

			if (!_listensForDispose[contextIndex]) {
				_listensForDispose[contextIndex] = true;
				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);
			}

			if (!_projections[renderable]) {
				vec = _projections[renderable] = new Vector.<Matrix3D>();
				for (i = 0; i < _numLights; ++i) {
					vec[i] = new Matrix3D();
				}
			}

			for (i = 0; i < len; ++i) {
				// local position = enough
				light = _lights[i];
//				posMult = light.positionBasedMultiplier;
//				lightPos = renderable.inverseSceneTransform.transformVector(light.scenePosition);
//				lightDir = renderable.inverseSceneTransform.deltaTransformVector(light.sceneDirection);

				matrix = light.getObjectProjectionMatrix(renderable, _projections[renderable][i]);

				// todo: clean up when context is disposed or does this happen automatically?
				_textures[contextIndex][renderable][i] ||= context.createTexture(_textureSize, _textureSize, Context3DTextureFormat.BGRA, true);
				j = 0;

				context.setRenderToTexture(_textures[contextIndex][renderable][i], true, 0, 0);
				context.clear(1.0, 1.0, 1.0);

				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _lightPosData, 2);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _enc, 2);
				stage3DProxy.setSimpleVertexBuffer(0, renderable.getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3);
				stage3DProxy.setSimpleVertexBuffer(1, renderable.getVertexNormalBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3);
				context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
			}
		}

		private function onContext3DDisposed(event : Stage3DEvent) : void
		{
			var stage3DProxy : Stage3DProxy = Stage3DProxy(event.target);
			var contextIndex : int = stage3DProxy._stage3DIndex;

			if (_textures) {
				for each(var vec : Vector.<Texture> in _textures[contextIndex]) {
					for (var j : uint = 0; j < vec.length; ++j) {
						vec[j].dispose();
					}
				}
			}

			_listensForDispose[contextIndex] = false;

			stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			super.activate(stage3DProxy, camera);
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 6, _polyOffset, 1);
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateProgram(stage3DProxy : Stage3DProxy, polyOffsetReg : String = null) : void
		{
			super.updateProgram(stage3DProxy, "vc6.x");
		}
	}
}
package away3d.materials.passes
{
	import away3d.animators.data.AnimationBase;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.base.SubGeometry;
	import away3d.core.managers.AGALProgram3DCache;
	import away3d.core.managers.Stage3DProxy;
	import away3d.errors.AbstractMethodError;
	import away3d.lights.LightBase;
	import away3d.materials.MaterialBase;

	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	use namespace arcane;

	/**
	 * MaterialPassBase provides an abstract base class for material shader passes.
	 */
	public class MaterialPassBase extends EventDispatcher
	{
		protected var _material : MaterialBase;
		private var _animation : AnimationBase;

		arcane var _program3Ds : Vector.<Program3D> = new Vector.<Program3D>(8);
		arcane var _program3Dids : Vector.<int> = Vector.<int>([-1, -1, -1, -1, -1, -1, -1, -1]);
		private var _programInvalids : Vector.<Boolean> = new Vector.<Boolean>(8);

		// agal props. these NEED to be set by subclasses!
		protected var _numUsedStreams : uint;
		protected var _numUsedTextures : uint;
		protected var _numUsedVertexConstants : uint;

		protected var _smooth : Boolean = true;
		protected var _repeat : Boolean = false;
		protected var _mipmap : Boolean = false;

		private var _mipmapBitmap : BitmapData;
		private var _bothSides : Boolean;

		protected var _animatableAttributes : Array = ["va0"];
		protected var _targetRegisters : Array = ["vt0"];
		protected var _projectedTargetRegister : String;

		protected var _lights : Vector.<LightBase>;
		protected var _numLights : uint;

		// keep track of previously rendered usage for faster cleanup of old vertex buffer streams and textures
		private static var _previousUsedStreams : Vector.<int> = Vector.<int>([0, 0, 0, 0, 0, 0, 0, 0]);
		private static var _previousUsedTexs : Vector.<int> = Vector.<int>([0, 0, 0, 0, 0, 0, 0, 0]);


		/**
		 * Creates a new MaterialPassBase object.
		 */
		public function MaterialPassBase()
		{
			_numUsedStreams = 1;
			_numUsedVertexConstants = 4;
		}

		/**
		 * The material to which this pass belongs.
		 */
		public function get material() : MaterialBase
		{
			return _material;
		}

		public function set material(value : MaterialBase) : void
		{
			_material = value;
		}

		/**
		 * Defines whether any used textures should use mipmapping.
		 */
		public function get mipmap() : Boolean
		{
			return _mipmap;
		}

		public function set mipmap(value : Boolean) : void
		{
			if (_mipmap == value) return;
			_mipmap = value;
			if (_mipmapBitmap) _mipmapBitmap.dispose();
			else _mipmapBitmap = null;
			invalidateShaderProgram();
		}

		/**
		 * Defines whether smoothing should be applied to any used textures.
		 */
		public function get smooth() : Boolean
		{
			return _smooth;
		}

		public function set smooth(value : Boolean) : void
		{
			if (_smooth == value) return;
			_smooth = value;
			invalidateShaderProgram();
		}

		/**
		 * Defines whether textures should be tiled.
		 */
		public function get repeat() : Boolean
		{
			return _repeat;
		}

		public function set repeat(value : Boolean) : void
		{
			if (_repeat == value) return;
			_repeat = value;
			invalidateShaderProgram();
		}

		/**
		 * Defines whether or not the material should perform backface culling.
		 */
		public function get bothSides() : Boolean
		{
			return _bothSides;
		}

		public function set bothSides(value : Boolean) : void
		{
			_bothSides = value;
		}

		/**
		 * The animation used to add vertex code to the shader code.
		 */
		public function get animation() : AnimationBase
		{
			return _animation;
		}

		public function set animation(value : AnimationBase) : void
		{
			if (_animation == value) return;
			_animation = value;
			invalidateShaderProgram();
		}

		/**
		 * Cleans up any resources used by the current object.
		 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
		 */
		public function dispose(deep : Boolean) : void
		{
			for (var i : uint = 0; i < 8; ++i) {
				if (_program3Ds[i]) _program3Ds[i].dispose();
			}
		}

// AGAL RELATED STUFF

		/**
		 * The amount of used vertex streams in the vertex code. Used by the animation code generation to know from which index on streams are available.
		 */
		public function get numUsedStreams() : uint
		{
			return _numUsedStreams;
		}

		/**
		 * The amount of used vertex constants in the vertex code. Used by the animation code generation to know from which index on registers are available.
		 */
		public function get numUsedVertexConstants() : uint
		{
			return _numUsedVertexConstants;
		}

		/**
		 * Renders an object to the current render target.
		 * @param renderable The IRenderable object to render.
		 * @param context The context which is performing the rendering.
		 * @param camera The camera from which the scene is viewed.
		 * @param lights The lights which influence the rendered scene.
		 *
		 * @private
		 */
		arcane function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var context : Context3D = stage3DProxy._context3D;

			context.setCulling(_bothSides? Context3DTriangleFace.NONE : Context3DTriangleFace.BACK);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, renderable.modelViewProjection, true);

			stage3DProxy.setSimpleVertexBuffer(0, renderable.getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3);

			context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
		}

		/**
		 * If the pass requires the projected position, this method will return the target register's name, or null otherwise.
		 * @private
		 */
		arcane function getProjectedTargetRegister() : String
		{
			return _projectedTargetRegister;
		}

		/**
		 * Lists the attribute registers that need to be transformed by animation first
 		 * position always needs to be listed first! Typical use cases are vertex normals and tangents.
		 * @private
		 */
		arcane function getAnimationSourceRegisters() : Array
		{
			return _animatableAttributes;
		}

		/**
		 * Specifies which registers to store the respective animated attributes in, so it can be used in the material's
		 * vertex shader code (as well as the projection, which takes the first one for position projection)
		 * For vertex normals, it's possible to simply set a varying register instead of a temporary one, if the
		 * material's vertex shader code doesn't have to do anything with it
		 * @private
		 */
		arcane function getAnimationTargetRegisters() : Array
		{
			return _targetRegisters;
		}

		arcane function getVertexCode() : String
		{
			throw new AbstractMethodError();
		}

		arcane function getFragmentCode() : String
		{
			throw new AbstractMethodError();
		}

		arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (!_program3Ds[contextIndex]) {
				initPass(stage3DProxy);
			}

			if (_programInvalids[contextIndex]) {
				updateProgram(stage3DProxy);
				_programInvalids[contextIndex] = false;
			}

			var prevUsed : int = _previousUsedStreams[contextIndex];
			var i : uint;
			for (i = _numUsedStreams; i < prevUsed; ++i) {
				stage3DProxy.setSimpleVertexBuffer(i, null);
			}

			prevUsed = _previousUsedTexs[contextIndex];

			for (i = _numUsedTextures; i < prevUsed; ++i) {
				stage3DProxy.setTextureAt(i, null);
			}

			// todo: do same for textures

			_animation.activate(stage3DProxy, this);
			stage3DProxy.setProgram(_program3Ds[contextIndex]);
			dispatchEvent(new Event(Event.CHANGE));
		}

		/**
		 * Turns off streams starting from a certain offset
		 *
		 * @private
		 */
		arcane function deactivate(stage3DProxy : Stage3DProxy) : void
		{
//			for (var i : uint = 1; i < _numUsedStreams; ++i)
//				context.setVertexBufferAt(i, null);

			var index : uint = stage3DProxy._stage3DIndex;
			_previousUsedStreams[index] = _numUsedStreams;
			_previousUsedTexs[index] = _numUsedTextures;

			if (_animation) _animation.deactivate(stage3DProxy, this);
		}

		/**
		 * Marks the shader program as invalid, so it will be recompiled before the next render.
		 */
		arcane function invalidateShaderProgram() : void
		{
			for (var i : uint = 0; i < 8; ++i)
				_programInvalids[i] = true;
		}

		/**
		 * Compiles the shader program.
		 * @param context The context for which to compile the shader program.
		 * @param polyOffsetReg An optional register that contains an amount by which to inflate the model (used in single object depth map rendering).
		 */
		protected function updateProgram(stage3DProxy : Stage3DProxy, polyOffsetReg : String = null) : void
		{
			AGALProgram3DCache.getInstance(stage3DProxy).setProgram3D(this, _animation, polyOffsetReg);
		}

		/**
		 * Initializes the shader program object.
		 * @param context
		 */
		protected function initPass(stage3DProxy : Stage3DProxy) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			_program3Ds[contextIndex] = stage3DProxy._context3D.createProgram();
			_programInvalids[contextIndex] = true;
		}

		public function get lights() : Vector.<LightBase>
		{
			return _lights;
		}

		public function set lights(value : Vector.<LightBase>) : void
		{
			_lights = value;
			_numLights = value? lights.length : 0;
		}
	}
}
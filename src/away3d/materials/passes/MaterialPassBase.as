package away3d.materials.passes
{
	import away3d.animators.data.AnimationBase;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.AGALProgram3DCache;
	import away3d.core.managers.Stage3DProxy;
	import away3d.debug.Debug;
	import away3d.errors.AbstractMethodError;
	import away3d.materials.MaterialBase;
	import away3d.materials.lightpickers.LightPickerBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;

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
		// todo: can we perhaps figure these out manually by checking read operations in the bytecode, so other sources can be safely updated?
		protected var _numUsedStreams : uint;
		protected var _numUsedTextures : uint;
		protected var _numUsedVertexConstants : uint;

		protected var _smooth : Boolean = true;
		protected var _repeat : Boolean = false;
		protected var _mipmap : Boolean = true;

		private var _bothSides : Boolean;

		protected var _numPointLights : uint;
		protected var _numDirectionalLights : uint;
		protected var _numLightProbes : uint;

		// keep track of previously rendered usage for faster cleanup of old vertex buffer streams and textures
		private static var _previousUsedStreams : Vector.<int> = Vector.<int>([0, 0, 0, 0, 0, 0, 0, 0]);
		private static var _previousUsedTexs : Vector.<int> = Vector.<int>([0, 0, 0, 0, 0, 0, 0, 0]);
		protected var _defaultCulling : String = Context3DTriangleFace.BACK;

		private var _renderToTexture : Boolean;
		private var _oldTarget : TextureBase;
		private var _oldSurface : int;
		private var _oldDepthStencil : Boolean;
		private var _oldRect : Rectangle;
		private static var _rttData : Vector.<Number>;

		/**
		 * Creates a new MaterialPassBase object.
		 */
		public function MaterialPassBase(renderToTexture : Boolean = false)
		{
			_renderToTexture = renderToTexture;
			_numUsedStreams = 1;
			_numUsedVertexConstants = 5;
			if (!_rttData) _rttData = new <Number>[1, 1, 1, 1];
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
		public function dispose() : void
		{
			for (var i : uint = 0; i < 8; ++i) {
				if (_program3Ds[i]) AGALProgram3DCache.getInstanceFromIndex(i).freeProgram3D(_program3Dids[i]);
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
		 *
		 * @private
		 */
		arcane function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D, lightPicker : LightPickerBase) : void
		{
			// TODO: not used
			camera = camera;
			lightPicker = lightPicker; 
			
			var context : Context3D = stage3DProxy._context3D;

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, renderable.getModelViewProjectionUnsafe(), true);

			if (renderable.animationState)
				renderable.animationState.setRenderState(stage3DProxy, renderable, _numUsedVertexConstants, _numUsedStreams);

			stage3DProxy.setSimpleVertexBuffer(0, renderable.getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.vertexBufferOffset);

			context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
		}

		arcane function getVertexCode() : String
		{
			throw new AbstractMethodError();
		}

		arcane function getFragmentCode() : String
		{
			throw new AbstractMethodError();
		}

		arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			// TODO: not used
			camera = camera;
			 
			var contextIndex : int = stage3DProxy._stage3DIndex;

			if (_programInvalids[contextIndex] || !_program3Ds[contextIndex]) {
				updateProgram(stage3DProxy);
				dispatchEvent(new Event(Event.CHANGE));
			}

			var prevUsed : int = _previousUsedStreams[contextIndex];
			var i : uint;
			for (i = _numUsedStreams; i < prevUsed; ++i) {
				stage3DProxy.setSimpleVertexBuffer(i, null, null, 0);
			}

			prevUsed = _previousUsedTexs[contextIndex];

			for (i = _numUsedTextures; i < prevUsed; ++i) {
				stage3DProxy.setTextureAt(i, null);
			}

			_animation.activate(stage3DProxy, this);
			stage3DProxy.setProgram(_program3Ds[contextIndex]);

			stage3DProxy._context3D.setCulling(_bothSides? Context3DTriangleFace.NONE : _defaultCulling);

			if (_renderToTexture) {
				_rttData[0] = 1;
				_rttData[1] = 1;
				_oldTarget = stage3DProxy.renderTarget;
				_oldSurface = stage3DProxy.renderSurfaceSelector;
				_oldDepthStencil = stage3DProxy.enableDepthAndStencil;
				_oldRect = stage3DProxy.scissorRect;
			}
			else {
				_rttData[0] = textureRatioX;
				_rttData[1] = textureRatioY;
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _rttData, 1);
			}
		}

		/**
		 * Turns off streams starting from a certain offset
		 *
		 * @private
		 */
		arcane function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			var index : uint = stage3DProxy._stage3DIndex;
			_previousUsedStreams[index] = _numUsedStreams;
			_previousUsedTexs[index] = _numUsedTextures;

			if (_animation) _animation.deactivate(stage3DProxy, this);

			if (_renderToTexture) {
				// kindly restore state
				stage3DProxy.setRenderTarget(_oldTarget, _oldDepthStencil, _oldSurface);
				stage3DProxy.scissorRect = _oldRect;
			}
		}

		/**
		 * Marks the shader program as invalid, so it will be recompiled before the next render.
		 *
		 * @param updateMaterial Indicates whether the invalidation should be performed on the entire material. Should always pass "true" unless it's called from the material itself.
		 */
		arcane function invalidateShaderProgram(updateMaterial : Boolean = true) : void
		{
			for (var i : uint = 0; i < 8; ++i)
				_programInvalids[i] = true;

			if (_material && updateMaterial)
				_material.invalidatePasses(this);
		}

		/**
		 * Compiles the shader program.
		 * @param polyOffsetReg An optional register that contains an amount by which to inflate the model (used in single object depth map rendering).
		 */
		arcane function updateProgram(stage3DProxy : Stage3DProxy) : void
		{
			var vertexCode : String = getVertexCode();
			var fragmentCode : String = getFragmentCode();
			if (Debug.active) {
				trace ("Compiling AGAL Code:");
				trace ("--------------------")
				trace (vertexCode);
				trace ("--------------------")
				trace (fragmentCode);
			}
			AGALProgram3DCache.getInstance(stage3DProxy).setProgram3D(this, vertexCode, fragmentCode);
			_programInvalids[stage3DProxy.stage3DIndex] = false;
		}

		arcane function get numPointLights() : uint
		{
			return _numPointLights;
		}

		arcane function set numPointLights(value : uint) : void
		{
			_numPointLights = value;
		}

		arcane function get numDirectionalLights() : uint
		{
			return _numDirectionalLights;
		}

		arcane function set numDirectionalLights(value : uint) : void
		{
			_numDirectionalLights = value;
		}

		arcane function set numLightProbes(value : uint) : void
		{
			_numLightProbes = value;
		}
	}
}
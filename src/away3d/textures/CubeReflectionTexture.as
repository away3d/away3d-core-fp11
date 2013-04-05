package away3d.textures
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.render.DefaultRenderer;
	import away3d.core.render.RendererBase;
	import away3d.core.traverse.EntityCollector;

	import flash.display.BitmapData;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * CubeReflectionTexture provides a cube map texture for real-time reflections, used for any method that uses environment maps,
	 * such as EnvMapMethod.
	 *
	 * @see away3d.materials.methods.EnvMapMethod
	 */
	public class CubeReflectionTexture extends RenderCubeTexture
	{
		private var _mockTexture : BitmapCubeTexture;
		private var _mockBitmapData : BitmapData;
		private var _renderer : RendererBase;
		private var _entityCollector : EntityCollector;
		private var _cameras : Vector.<Camera3D>;
		private var _lenses : Vector.<PerspectiveLens>;
		private var _nearPlaneDistance : Number = .01;
		private var _farPlaneDistance : Number = 2000;
		private var _position : Vector3D;
		private var _isRendering : Boolean;

		/**
		 * Creates a new CubeReflectionTexture object
		 * @param size The size of the cube texture
		 */
		public function CubeReflectionTexture(size : int)
		{
			super(size);
			_renderer = new DefaultRenderer();
			_entityCollector = _renderer.createEntityCollector();
			_position = new Vector3D();
			initMockTexture();
			initCameras();
		}

		/**
		 * @inheritDoc
		 */
		override public function getTextureForStage3D(stage3DProxy : Stage3DProxy) : TextureBase
		{
			return _isRendering? _mockTexture.getTextureForStage3D(stage3DProxy) : super.getTextureForStage3D(stage3DProxy);
		}

		/**
		 * The origin where the environment map will be rendered. This is usually in the centre of the reflective object.
		 */
		public function get position() : Vector3D
		{
			return _position;
		}

		public function set position(value : Vector3D) : void
		{
			_position = value;
		}

		/**
		 * The near plane used by the camera lens.
		 */
		public function get nearPlaneDistance() : Number
		{
			return _nearPlaneDistance;
		}

		public function set nearPlaneDistance(value : Number) : void
		{
			_nearPlaneDistance = value;
		}

		/**
		 * The far plane of the camera lens. Can be used to cut off objects that are too far to be of interest in reflections
		 */
		public function get farPlaneDistance() : Number
		{
			return _farPlaneDistance;
		}

		public function set farPlaneDistance(value : Number) : void
		{
			_farPlaneDistance = value;
		}

		/**
		 * Renders the scene in the given view for reflections.
		 * @param view The view containing the scene to render.
		 */
		public function render(view : View3D) : void
		{
			var stage3DProxy : Stage3DProxy = view.stage3DProxy;
			var scene : Scene3D = view.scene;
			var targetTexture : TextureBase = super.getTextureForStage3D(stage3DProxy);

			_isRendering = true;
			_renderer.stage3DProxy = stage3DProxy;

			for (var i : uint = 0; i < 6; ++i)
				renderSurface(i, scene, targetTexture);

			_isRendering = false;
		}

		/**
		 * The renderer to use.
		 */
		public function get renderer() : RendererBase
		{
			return _renderer;
		}

		public function set renderer(value : RendererBase) : void
		{
			_renderer.dispose();
			_renderer = value;
			_entityCollector = _renderer.createEntityCollector();
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
			super.dispose();
			_mockTexture.dispose();
			for (var i : int = 0; i < 6; ++i)
				_cameras[i].dispose();

			_mockBitmapData.dispose();
		}

		private function renderSurface(surfaceIndex : uint, scene : Scene3D, targetTexture : TextureBase) : void
		{
			var camera : Camera3D = _cameras[surfaceIndex];

			camera.lens.near = _nearPlaneDistance;
			camera.lens.far = _farPlaneDistance;
			camera.position = position;

			_entityCollector.camera = camera;
			_entityCollector.clear();
			scene.traversePartitions(_entityCollector);

			_renderer.render(_entityCollector, targetTexture, null, surfaceIndex);

			_entityCollector.cleanUp();
		}



		private function initMockTexture() : void
		{
			// use a completely transparent map to prevent anything from using this texture when updating map
			_mockBitmapData = new BitmapData(2, 2, true, 0x00000000);
			_mockTexture = new BitmapCubeTexture(_mockBitmapData, _mockBitmapData, _mockBitmapData, _mockBitmapData, _mockBitmapData, _mockBitmapData);
		}

		private function initCameras() : void
		{
			_cameras = new Vector.<Camera3D>();
			_lenses = new Vector.<PerspectiveLens>();
			// posX, negX, posY, negY, posZ, negZ
			addCamera(0, 90, 0);
			addCamera(0, -90, 0);
			addCamera(-90, 0, 0);
			addCamera(90, 0, 0);
			addCamera(0, 0, 0);
			addCamera(0, 180, 0);
		}

		private function addCamera(rotationX : Number, rotationY : Number, rotationZ : Number) : void
		{
			var cam : Camera3D = new Camera3D();
			cam.rotationX = rotationX;
			cam.rotationY = rotationY;
			cam.rotationZ = rotationZ;
			cam.lens.near = .01;
			PerspectiveLens(cam.lens).fieldOfView = 90;
			_lenses.push(PerspectiveLens(cam.lens));
			cam.lens.aspectRatio = 1;
			_cameras.push(cam);
		}
	}
}

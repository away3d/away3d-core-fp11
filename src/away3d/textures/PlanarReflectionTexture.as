package away3d.textures
{
	import away3d.arcane;
	import away3d.entities.Camera3D;
	import away3d.projections.ObliqueNearPlaneLens;
	import away3d.containers.View3D;
	import away3d.managers.Stage3DProxy;
	import away3d.core.geom.Matrix3DUtils;
	import away3d.core.geom.Plane3D;
	import away3d.core.render.DefaultRenderer;
	import away3d.core.render.RendererBase;
	import away3d.core.traverse.EntityCollector;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * PlanarReflectionTexture is a Texture that can be used for material-based planar reflections, as provided by PlanarReflectionMethod, FresnelPlanarReflectionMethod.
	 *
	 * @see away3d.materials.methods.PlanarReflectionMethod
	 */
	public class PlanarReflectionTexture extends RenderTexture
	{
		private var _mockTexture:BitmapTexture;
		private var _mockBitmapData:BitmapData;
		private var _renderer:RendererBase;
		private var _scale:Number = 1;
		private var _isRendering:Boolean;
		private var _entityCollector:EntityCollector;
		private var _camera:Camera3D;
		private var _plane:Plane3D;
		private var _matrix:Matrix3D;
		private var _vector:Vector3D;
		private var _scissorRect:Rectangle;
		private var _lens:ObliqueNearPlaneLens;
		private var _viewWidth:Number;
		private var _viewHeight:Number;
		
		/**
		 * Creates a new PlanarReflectionTexture object.
		 */
		public function PlanarReflectionTexture()
		{
			super(2, 2);
			_camera = new Camera3D();
			_lens = new ObliqueNearPlaneLens(null, null);
			_camera.projection = _lens;
			_matrix = new Matrix3D();
			_vector = new Vector3D();
			_plane = new Plane3D();
			_scissorRect = new Rectangle();
			_renderer = new DefaultRenderer();
			_entityCollector = _renderer.createEntityCollector() as EntityCollector;
			initMockTexture();
		}
		
		/**
		 * The plane to reflect with.
		 */
		public function get plane():Plane3D
		{
			return _plane;
		}
		
		public function set plane(value:Plane3D):void
		{
			_plane = value;
		}
		
		/**
		 * Sets the plane to match a given matrix. This is used to easily match a Mesh using a PlaneGeometry and yUp = false.
		 * @param matrix The transformation matrix to rotate the plane with.
		 */
		public function applyTransform(matrix:Matrix3D):void
		{
			//var rawData : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			_matrix.copyFrom(matrix);
			// invert transpose
			_matrix.invert();
			_matrix.copyRowTo(2, _vector);
			
			_plane.a = -_vector.x;
			_plane.b = -_vector.y;
			_plane.c = -_vector.z;
			_plane.d = -_vector.w;
		}

		/**
		 * The renderer to use.
		 */
		public function get renderer():RendererBase
		{
			return _renderer;
		}
		
		public function set renderer(value:RendererBase):void
		{
			_renderer.dispose();
			_renderer = value;
			_entityCollector = _renderer.createEntityCollector() as EntityCollector;
		}
		
		/**
		 * A scale factor to reduce the quality of the reflection. Default value is 1 (same quality as the View)
		 */
		public function get scale():Number
		{
			return _scale;
		}
		
		public function set scale(value:Number):void
		{
			_scale = value > 1? 1 :
				value < 0? 0 :
				value;
		}
		
		/**
		 * Renders the scene in the given view for reflections.
		 * @param view The view containing the Scene to render.
		 */
		public function render(view:View3D):void
		{
			var camera:Camera3D = view.camera;
			if (isCameraBehindPlane(camera))
				return;
			_isRendering = true;
			updateSize(view.width, view.height);
			updateCamera(camera);
			
			_entityCollector.camera = _camera;
			_entityCollector.clear();
			view.scene.traversePartitions(_entityCollector);
			_renderer.stage3DProxy = view.stage3DProxy;
			_renderer.renderScene(_entityCollector, _mockTexture, _scissorRect);
			_isRendering = false;
		}
		
		override public function dispose():void
		{
			super.dispose();
			_mockTexture.dispose();
			_camera.dispose();
			_mockBitmapData.dispose();
		}
		
		arcane function get textureRatioX():Number
		{
			return _renderer.textureRatioX;
		}
		
		arcane function get textureRatioY():Number
		{
			return _renderer.textureRatioY;
		}
		
		private function updateCamera(camera:Camera3D):void
		{
			Matrix3DUtils.reflection(_plane, _matrix);
			_matrix.prepend(camera.sceneTransform);
			_matrix.prependScale(1, -1, 1);
			_camera.transform = _matrix;
			_lens.baseProjection = camera.projection;
			_lens.aspectRatio = _viewWidth/_viewHeight;
			_lens.plane = transformPlane(_plane, _matrix, _lens.plane);
		}
		
		private function isCameraBehindPlane(camera:Camera3D):Boolean
		{
			return camera.x*_plane.a + camera.y*_plane.b + camera.z*_plane.c + _plane.d < 0;
		}
		
		private function transformPlane(plane:Plane3D, matrix:Matrix3D, result:Plane3D = null):Plane3D
		{
			if(!result) result = new Plane3D();
			// actually transposed inverseSceneTransform is used, but since sceneTransform is already the inverse of the inverse
			var rawData:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var a:Number = plane.a, b:Number = plane.b, c:Number = plane.c, d:Number = plane.d;
			matrix.copyRawDataTo(rawData);
			result.a = a*rawData[0] + b*rawData[1] + c*rawData[2] + d*rawData[3],
			result.b = a*rawData[4] + b*rawData[5] + c*rawData[6] + d*rawData[7],
			result.c = a*rawData[8] + b*rawData[9] + c*rawData[10] + d*rawData[11],
			result.d = -(a*rawData[12] + b*rawData[13] + c*rawData[14] + d*rawData[15])
			result.normalize();
			return result;
		}
		
		private function updateSize(width:Number, height:Number):void
		{
			if (width > 2048)
				width = 2048;
			if (height > 2048)
				height = 2048;
			_viewWidth = width*_scale;
			_viewHeight = height*_scale;
			var textureWidth:Number = TextureUtils.getBestPowerOf2(_viewWidth);
			var textureHeight:Number = TextureUtils.getBestPowerOf2(_viewHeight);
			setSize(textureWidth, textureHeight);
			
			var textureRatioX:Number = _viewWidth/textureWidth;
			var textureRatioY:Number = _viewHeight/textureHeight;
			_renderer.textureRatioX = textureRatioX;
			_renderer.textureRatioY = textureRatioY;
			_scissorRect.x = (textureWidth - _viewWidth)*.5;
			_scissorRect.y = (textureHeight - _viewHeight)*.5;
			_scissorRect.width = _viewWidth;
			_scissorRect.height = _viewHeight;
		}
		
		private function initMockTexture():void
		{
			// use a completely transparent map to prevent anything from using this texture when updating map
			_mockBitmapData = new BitmapData(2, 2, true, 0x00000000);
			_mockTexture = new BitmapTexture(_mockBitmapData);
		}
	}
}

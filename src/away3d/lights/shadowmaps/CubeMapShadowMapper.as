package away3d.lights.shadowmaps
{
	import away3d.arcane;
	import away3d.entities.Camera3D;
	import away3d.projections.PerspectiveProjection;
	import away3d.containers.Scene3D;
	import away3d.core.render.DepthRenderer;
	import away3d.lights.PointLight;
	import away3d.textures.RenderCubeTexture;
	import away3d.textures.TextureProxyBase;
	
	import flash.display3D.textures.TextureBase;
	
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	public class CubeMapShadowMapper extends ShadowMapperBase
	{
		private var _depthCameras:Vector.<Camera3D>;
		private var _lenses:Vector.<PerspectiveProjection>;
		private var _needsRender:Vector.<Boolean>;
		
		public function CubeMapShadowMapper()
		{
			super();
			
			_depthMapSize = 512;
			
			_needsRender = new Vector.<Boolean>(6, true);
			initCameras();
		}
		
		private function initCameras():void
		{
			_depthCameras = new Vector.<Camera3D>();
			_lenses = new Vector.<PerspectiveProjection>();
			// posX, negX, posY, negY, posZ, negZ
			addCamera(0, 90, 0);
			addCamera(0, -90, 0);
			addCamera(-90, 0, 0);
			addCamera(90, 0, 0);
			addCamera(0, 0, 0);
			addCamera(0, 180, 0);
		}
		
		private function addCamera(rotationX:Number, rotationY:Number, rotationZ:Number):void
		{
			var cam:Camera3D = new Camera3D();
			cam.rotationX = rotationX;
			cam.rotationY = rotationY;
			cam.rotationZ = rotationZ;
			cam.projection.near = .01;
			PerspectiveProjection(cam.projection).fieldOfView = 90;
			_lenses.push(PerspectiveProjection(cam.projection));
			cam.projection.aspectRatio = 1;
			_depthCameras.push(cam);
		}
		
		override protected function createDepthTexture():TextureProxyBase
		{
			return new RenderCubeTexture(_depthMapSize);
		}
		
		override protected function updateDepthProjection(viewCamera:Camera3D):void
		{
			var maxDistance:Number = PointLight(_light)._fallOff;
			var pos:Vector3D = _light.scenePosition;
			
			// todo: faces outside frustum which are pointing away from camera need not be rendered!
			for (var i:uint = 0; i < 6; ++i) {
				_lenses[i].far = maxDistance;
				_depthCameras[i].position = pos;
				_needsRender[i] = true;
			}
		}
		
		override protected function drawDepthMap(target:TextureBase, scene:Scene3D, renderer:DepthRenderer):void
		{
			for (var i:uint = 0; i < 6; ++i) {
				if (_needsRender[i]) {
					_casterCollector.camera = _depthCameras[i];
					_casterCollector.clear();
					scene.traversePartitions(_casterCollector);
					renderer.render(_casterCollector, target, null, i);
					_casterCollector.cleanUp();
				}
			}
		}
	}
}

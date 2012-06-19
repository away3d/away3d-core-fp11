package 
{
	import a3dparticle.animators.actions.color.FlickerGlobal;
	import a3dparticle.animators.actions.color.RandomColorLocal;
	import a3dparticle.animators.actions.fog.FogByDistanceGlobal;
	import a3dparticle.animators.actions.position.OffsetPositionLocal;
	import a3dparticle.animators.actions.scale.RandomScaleLocal;
	import a3dparticle.generater.MutiWeightGenerater;
	import a3dparticle.particle.ParticleColorMaterial;
	import a3dparticle.particle.ParticleParam;
	import a3dparticle.particle.ParticleSample;
	import a3dparticle.ParticlesContainer;
	import away3d.containers.View3D;
	import away3d.core.base.SubGeometry;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.library.assets.AssetType;
	import away3d.loaders.AssetLoader;
	import away3d.loaders.parsers.Max3DSParser;
	import away3d.primitives.WireframeAxesGrid;
	import away3d.tools.helpers.MeshHelper
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;
	import flash.utils.setTimeout;
	/**
	 * ...
	 * @author liaocheng
	 */
	[SWF(width="1024", height="768", frameRate="60")]
	public class Main extends Sprite 
	{
		
		[Embed(source = "model/star.3ds", mimeType = "application/octet-stream")]
		private var Star:Class;
		
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		private var geometry:SubGeometry;
		
		private var mesh:Mesh;
		
		public function Main():void 
		{
			if (stage) setTimeout(init, 0);
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onStageResize);
			
			// entry point
			_view = new View3D();
			_view.width = 1024;
			_view.height = 768;
			_view.antiAlias = 4;
			_view.camera.lens.far = 5000;
			addChild(_view);
			addEventListener(Event.ENTER_FRAME, onRender);
			addChild(new AwayStats(_view));
			new HoverDragController(_view.camera, stage);
			_view.scene.addChild(new WireframeAxesGrid(4, 1000));
			var loader:AssetLoader = new AssetLoader();
			loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, initScene);
			loader.loadData(new Star(), '', null, null, new Max3DSParser());
		}
		
		private function onAssetComplete(e:AssetEvent):void
		{
			switch(e.asset.assetType)
			{
				case AssetType.MESH:
					mesh = Mesh(e.asset);
					mesh.rotationX = 180;
					MeshHelper.applyRotations(mesh);
					break;
			}
		}
		
		
		private function initScene(e:Event):void
		{
			var material1:ParticleColorMaterial = new ParticleColorMaterial();
			var sample1:ParticleSample = new ParticleSample(mesh.geometry.subGeometries[0], material1);
			
			var generater:MutiWeightGenerater = new MutiWeightGenerater([sample1], [1], 800);
			
			particle = new ParticlesContainer();
			particle.loop = false;
			
			var action1:OffsetPositionLocal = new OffsetPositionLocal();
			particle.addAction(action1);
			
			var action2:RandomScaleLocal = new RandomScaleLocal();
			particle.addAction(action2);
			
			var action3:FlickerGlobal = new FlickerGlobal(new ColorTransform(1, 1, 1), new ColorTransform(0, 0, 0), 2);
			particle.addAction(action3);
			
			var action4:RandomColorLocal = new RandomColorLocal(null,true,false);
			particle.addAction(action4);
			
			var action5:FogByDistanceGlobal = new FogByDistanceGlobal(2500,0x202020);
			particle.addAction(action5);
			
			particle.initParticleFun = initParticleParam;
			
			particle.generate(generater);
			particle.start();
			
			_view.scene.addChild(particle);
			
		}
		
		private function initParticleParam(param:ParticleParam):void
		{
			param.startTime = Math.random();
			var degree1:Number = Math.random() * Math.PI * 2;
			var degree2:Number = Math.random() * Math.PI / 2;
			var r:Number = 2000 + Math.random() * 1000;
			param["OffsetPositionLocal"] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.sin(degree2), r * Math.cos(degree1) * Math.cos(degree2) );
			var scale:Number = 0.3 + Math.random() * 0.7;
			param["RandomScaleLocal"] = new Vector3D(scale, scale, scale);
			param["RandomColorLocal"] = new ColorTransform(Math.random(),Math.random(),Math.random());
		}
		
		private function onRender(e:Event):void
		{
			_view.render();
		}
		private function onStageResize(e:Event):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
		}
		
	}
	
}
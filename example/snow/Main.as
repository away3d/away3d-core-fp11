package 
{
	import a3dparticle.animators.actions.drift.DriftLocal;
	import a3dparticle.animators.actions.fog.FogByDistanceGlobal;
	import a3dparticle.animators.actions.position.OffsetPositionLocal;
	import a3dparticle.animators.actions.rotation.RandomRotateLocal;
	import a3dparticle.animators.actions.scale.RandomScaleLocal;
	import a3dparticle.animators.actions.velocity.VelocityGlobal;
	import a3dparticle.generater.SingleGenerater;
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
	import away3d.primitives.SkyBox;
	import away3d.primitives.WireframeAxesGrid;
	import away3d.textures.BitmapCubeTexture;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.utils.setTimeout;
	/**
	 * ...
	 * @author liaocheng
	 */
	[SWF(width="1024", height="768", frameRate="60")]
	public class Main extends Sprite 
	{
		// Environment map.
		[Embed(source="skybox/snow_positive_x.jpg")]
		private var EnvPosX : Class;
		[Embed(source="skybox/snow_positive_y.jpg")]
		private var EnvPosY : Class;
		[Embed(source="skybox/snow_positive_z.jpg")]
		private var EnvPosZ : Class;
		[Embed(source="skybox/snow_negative_x.jpg")]
		private var EnvNegX : Class;
		[Embed(source="skybox/snow_negative_y.jpg")]
		private var EnvNegY : Class;
		[Embed(source="skybox/snow_negative_z.jpg")]
		private var EnvNegZ : Class;
		
		[Embed(source = "model/snow.3ds", mimeType = "application/octet-stream")]
		private var Snow:Class;
		
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
			loader.loadData(new Snow(), '', null, null, new Max3DSParser());
			
			
			var _cubeMap:BitmapCubeTexture = new BitmapCubeTexture(new EnvPosX().bitmapData, new EnvNegX().bitmapData,
					new EnvPosY().bitmapData, new EnvNegY().bitmapData,
					new EnvPosZ().bitmapData, new EnvNegZ().bitmapData);

			_view.scene.addChild(new SkyBox(_cubeMap));
		}
		
		private function onAssetComplete(e:AssetEvent):void
		{
			switch(e.asset.assetType)
			{
				case AssetType.MESH:
					mesh = Mesh(e.asset);
					break;
			}
		}
		
		private function initScene(e:Event):void
		{
			var material:ParticleColorMaterial = new ParticleColorMaterial();
			var sample:ParticleSample = new ParticleSample(mesh.geometry.subGeometries[0], material);
			var generater:SingleGenerater = new SingleGenerater(sample, 1500);
			
			particle = new ParticlesContainer();
			particle.loop = true;
			
			var action1:VelocityGlobal = new VelocityGlobal( new Vector3D(0,-100,0) );
			particle.addAction(action1);
			
			var action2:DriftLocal = new DriftLocal();
			particle.addAction(action2);
			
			var action3:OffsetPositionLocal = new OffsetPositionLocal();
			particle.addAction(action3);
			
			var action4:RandomRotateLocal = new RandomRotateLocal();
			particle.addAction(action4);
			
			var action5:RandomScaleLocal = new RandomScaleLocal();
			particle.addAction(action5);
			
			var action6:FogByDistanceGlobal = new FogByDistanceGlobal(1000,0x606060);
			particle.addAction(action6);
			
			particle.initParticleFun = initParticleParam;
			
			particle.generate(generater);
			particle.start();
			particle.time = 20;
			
			_view.scene.addChild(particle);
			
		}
		
		private function initParticleParam(param:ParticleParam):void
		{
			param.startTime = Math.random()*20;
			param.duringTime = 20;
			param["DriftLocal"] = new Vector3D(Math.random() * 100 - 50, 0, Math.random() * 100 - 50, Math.random() * 2 + 3);
			param["OffsetPositionLocal"] = new Vector3D(Math.random() * 10000 - 5000, 1200, Math.random() * 10000 - 5000);
			param["RandomRotateLocal"] = new Vector3D(Math.random(), Math.random(), Math.random(), Math.random() * 2 + 2);
			var scale:Number = 2 + Math.random() * 2;
			param["RandomScaleLocal"] = new Vector3D(scale, scale, scale);
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
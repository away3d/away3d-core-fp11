package 
{
	import a3dparticle.animators.actions.DriftAction;
	import a3dparticle.animators.actions.OffestDistanceAction;
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.animators.actions.RandomScaleAction;
	import a3dparticle.animators.actions.RotateAction;
	import a3dparticle.animators.actions.VelocityAction;
	import a3dparticle.materials.SimpleParticleMaterial;
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
	public class SnowModel extends Sprite 
	{
		[Embed(source = "model/snow.3ds", mimeType = "application/octet-stream")]
		private var Snow:Class;
		
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		private var geometry:SubGeometry;
		
		private var mesh:Mesh;
		
		public function SnowModel():void 
		{
			if (stage) init();
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
			addChild(_view);
			addEventListener(Event.ENTER_FRAME, onRender);
			addChild(new AwayStats(_view));
			new HoverDragController(_view.camera, stage);
			_view.scene.addChild(new WireframeAxesGrid(4, 1000));
			var loader:AssetLoader = new AssetLoader();
			loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, initScene);
			loader.loadData(new Snow(), '', new Max3DSParser());
			//initScene();
		}
		
		private function onAssetComplete(e:AssetEvent):void
		{
			switch(e.asset.assetType)
			{
				case AssetType.MESH:
					mesh = Mesh(e.asset);
					//initScene();
					break;
			}
		}
		
		private function start():void
		{
			trace(mesh.geometry);
		}
		
		
		
		private function initScene(e:Event):void
		{
			var material:SimpleParticleMaterial = new SimpleParticleMaterial();
			particle = new ParticlesContainer(200,material);
			//_view.scene.addChild(particle);
			
			particle.startTimeFun = function(index:uint):Number { return Math.random()*20-20; };
			particle.endTimeFun = function(index:uint):Number { return 20; };
			particle.loop = true;
			
			var action1:PerParticleAction = new VelocityAction(function(index:uint):Vector3D { return new Vector3D(0,-100,0); } );
			particle.addPerParticleAction(action1);
			
			var action2:DriftAction = new DriftAction(function(index:uint):Vector3D { return new Vector3D(Math.random()*50-25,0,Math.random()*50-25,Math.random()*2+3); } );
			particle.addPerParticleAction(action2);
			
			var action3:OffestDistanceAction = new OffestDistanceAction(function(index:uint):Vector3D { return new Vector3D(Math.random()*1000-500,1000,Math.random()*10000-500); } );
			particle.addPerParticleAction(action3);
			
			var action4:RotateAction = new RotateAction(function(index:uint):Vector3D { return new Vector3D(Math.random(),Math.random(),Math.random(),Math.random()*2+2); } );
			particle.addPerParticleAction(action4);
			
			var action5:RandomScaleAction = new RandomScaleAction(function(index:uint):Vector3D 
				{
					var scale:Number = Math.random()*3;
					return new Vector3D(scale, scale, scale); 
				});
			particle.addPerParticleAction(action5);
			

			particle.generate(mesh.geometry.subGeometries[0]);
			particle.start();
			
			for (var i:int = -5; i <= 5; i++)
			{
				for (var j:int = -5; j <= 5; j++)
				{
					var clone:ParticlesContainer = particle.clone() as ParticlesContainer;
					clone.position = new Vector3D(i * 500+Math.random()*100, 0, j * 500+Math.random()*100);
					setTimeout(clone.start,Math.random()*1000);
					_view.scene.addChild(clone);
				}
			}
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
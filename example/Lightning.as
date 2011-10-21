package 
{
	import a3dparticle.animators.actions.color.FlickerLocal;
	import a3dparticle.animators.actions.position.OffestPositionLocal;
	import a3dparticle.animators.actions.rotation.AutoRotateGlobal;
	import a3dparticle.animators.actions.scale.ScaleByLifeGlobal;
	import a3dparticle.animators.actions.velocity.VelocityLocal;
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
	import away3d.tools.MeshHelper;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;
	
	/**
	 * ...
	 * @author liaocheng
	 */
	[SWF(width="1024", height="768", frameRate="60")]
	public class Lightning extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		[Embed(source = "model/lightning.3DS", mimeType = "application/octet-stream")]
		private var Model:Class;
		
		private var geometry:SubGeometry;
		
		private var mesh:Mesh;
		
		public function Lightning():void 
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
			new HoverDragController(_view.camera, _view);
			_view.scene.addChild(new WireframeAxesGrid(4,1000));

			var loader:AssetLoader = new AssetLoader();
			loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, initScene);
			loader.loadData(new Model(), '', new Max3DSParser());
			
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
			mesh.rotationZ = -90;
			MeshHelper.applyRotations(mesh);
			
			var material:SimpleParticleMaterial = new SimpleParticleMaterial();
			material.bothSides = false;
			particle = new ParticlesContainer(500,material);
			_view.scene.addChild(particle);
			
			
			particle.startTimeFun = function(index:uint):Number { return Math.random()*7; };
			particle.endTimeFun = function(index:uint):Number { return 0.5; };
			particle.sleepTimeFun = function(index:uint):Number { return Math.random()*2+5; };
			particle.loop = true;
			
			var action:VelocityLocal = new VelocityLocal(function(index:uint):Vector3D { return new Vector3D(Math.random()*20-10,-10,Math.random()*20-10); } );
			particle.addAction(action);
			
			var action2:OffestPositionLocal = new OffestPositionLocal(function(index:uint):Vector3D { return new Vector3D(Math.random()*1000-500, Math.random()*100+200, Math.random()*1000-500);} );
			particle.addAction(action2);
			
			var action3:AutoRotateGlobal = new AutoRotateGlobal();
			particle.addAction(action3);
			
			var action4:FlickerLocal = new FlickerLocal(new ColorTransform(0.8, 0.8, 1,0), new ColorTransform(0.8, 0.8, 1,1), 0.25);
			particle.addAction(action4);
			
			var action5:ScaleByLifeGlobal = new ScaleByLifeGlobal(1,2);
			particle.addAction(action5);
			
			particle.generate(mesh.geometry.subGeometries[0]);
			particle.start();
			
			
			var ui:PlayUI = new PlayUI(particle);
			ui.y = 700;
			ui.x = 260;
			addChild(ui);
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
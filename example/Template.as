package 
{
	import a3dparticle.animators.actions.velocity.VelocityLocal;
	import a3dparticle.materials.SimpleParticleMaterial;
	import a3dparticle.ParticlesContainer;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.primitives.Sphere;
	import away3d.primitives.WireframeAxesGrid;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	/**
	 * ...
	 * @author liaocheng
	 */
	[SWF(width="1024", height="768", frameRate="60")]
	public class Template extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		public function Template():void 
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
			_view.scene.addChild(new WireframeAxesGrid(4,1000));
			initScene();
		}
		
		
		
		private function initScene():void
		{
			var material:SimpleParticleMaterial = new SimpleParticleMaterial(new BitmapData(2, 2, true, 0xFFFFFFFF));
			particle = new ParticlesContainer(1800,material);
			_view.scene.addChild(particle);
			
			var sphere:Sphere = new Sphere(null, 10, 3, 3);
			
			particle.startTimeFun = function(index:uint):Number { return 1+Math.random()*3; };
			particle.endTimeFun = function(index:uint):Number { return Math.random() * 2; };
			particle.loop = true;
			
			var action:VelocityLocal = new VelocityLocal(function(index:uint):Vector3D { return new Vector3D(Math.random()*100-50,Math.random()*20+150,Math.random()*100-50); } );
			particle.addAction(action);
			
			particle.generate(sphere.geometry.subGeometries[0]);
			particle.start();
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
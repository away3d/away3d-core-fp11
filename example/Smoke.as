package 
{
	import a3dparticle.animators.actions.color.ChangeColorByLifeGlobal;
	import a3dparticle.animators.actions.drift.DriftLocal;
	import a3dparticle.animators.actions.rotation.AutoRotateGlobal;
	import a3dparticle.animators.actions.rotation.RandomRotateLocal;
	import a3dparticle.animators.actions.scale.ScaleByLifeGlobal;
	import a3dparticle.animators.actions.velocity.VelocityLocal;
	import a3dparticle.materials.SimpleParticleMaterial;
	import a3dparticle.ParticlesContainer;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.primitives.Cylinder;
	import away3d.primitives.Sphere;
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
	public class Smoke extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		[Embed(source = "yan.png")]
		private var Img:Class;
		
		public function Smoke():void 
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
			initScene();
			var ui:PlayUI = new PlayUI(particle,5);
			ui.y = 700;
			ui.x = 260;
			addChild(ui);
		}
		
		
		
		private function initScene():void
		{
			var material:SimpleParticleMaterial = new SimpleParticleMaterial(new Img().bitmapData);
			particle = new ParticlesContainer(2500,material);
			_view.scene.addChild(particle);
			
			var sphere:Sphere = new Sphere(null, 10,3,3);

			
			particle.startTimeFun = function(index:uint):Number { return Math.random()*4; };
			particle.endTimeFun = function(index:uint):Number { return 4; };
			particle.loop = true;
			
			var circle_fn:Function = function(index:uint):Vector3D
			{
				var degree:Number = Math.random() * Math.PI * 2;
				var r:Number = Math.random()*20;
				return new Vector3D(r * Math.cos(degree), 50, r * Math.sin(degree));
			}
			
			var action:VelocityLocal = new VelocityLocal(circle_fn);
			particle.addAction(action);
			
			var action2:ChangeColorByLifeGlobal = new ChangeColorByLifeGlobal(new ColorTransform(2, 2, 2,1),new ColorTransform(2, 2, 2,0));
			particle.addAction(action2);
			
			var action3:RandomRotateLocal = new RandomRotateLocal(function(index:uint):Vector3D { return new Vector3D(Math.random(), Math.random(), Math.random(), Math.random()*5+5);} );
			particle.addAction(action3);
			
			var action4:ScaleByLifeGlobal = new ScaleByLifeGlobal(1,2);
			particle.addAction(action4);
			
			var action5:DriftLocal = new DriftLocal(function(index:uint):Vector3D { return new Vector3D(Math.random()*10, Math.random()*10, Math.random()*10, Math.random()*5+2);});
			particle.addAction(action5);
			
			
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
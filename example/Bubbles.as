package 
{
	import a3dparticle.animators.actions.color.FlickerLocal;
	import a3dparticle.animators.actions.drift.DriftLocal;
	import a3dparticle.animators.actions.position.OffestPositionLocal;
	import a3dparticle.animators.actions.rotation.AlwayFaceToCameraGlobal;
	import a3dparticle.animators.actions.scale.ScaleByLifeGlobal;
	import a3dparticle.animators.actions.velocity.VelocityLocal;
	import a3dparticle.materials.SimpleParticleMaterial;
	import a3dparticle.ParticlesContainer;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.primitives.Plane;
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
	public class Bubbles extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		[Embed(source = "./pp.png")]
		private var IMG:Class;
		
		public function Bubbles():void 
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
			var ui:PlayUI = new PlayUI(particle);
			ui.y = 700;
			ui.x = 260;
			addChild(ui);
		}
		
		
		
		private function initScene():void
		{
			var material:SimpleParticleMaterial = new SimpleParticleMaterial(new IMG().bitmapData);
			material.bothSides = false;
			particle = new ParticlesContainer(500,material);
			_view.scene.addChild(particle);
			
			var plane:Plane = new Plane(null, 20, 20);
			plane.rotationX = -90;
			MeshHelper.applyRotations(plane);
			
			particle.startTimeFun = function(index:uint):Number { return Math.random()*8; };
			particle.endTimeFun = function(index:uint):Number { return 8; };
			particle.loop = true;
			
			var action:VelocityLocal = new VelocityLocal(function(index:uint):Vector3D { return new Vector3D(0,Math.random()*50+50,0); } );
			particle.addAction(action);
			
			var action2:OffestPositionLocal = new OffestPositionLocal(function(index:uint):Vector3D { return new Vector3D(Math.random()*1000-500, 0, Math.random()*1000-500);} );
			particle.addAction(action2);
			
			var action3:AlwayFaceToCameraGlobal = new AlwayFaceToCameraGlobal();
			particle.addAction(action3);
			
			var action4:FlickerLocal = new FlickerLocal(new ColorTransform(1.5,1.5,1.5,1),new ColorTransform(2,2,2,1),1);
			particle.addAction(action4);
			
			var action5:DriftLocal = new DriftLocal(function(index:uint):Vector3D { return new Vector3D(Math.random() * 50, 0, Math.random() * 50, Math.random() * 5 + 2);});
			particle.addAction(action5);
			
			var action6:ScaleByLifeGlobal = new ScaleByLifeGlobal(1,2);
			particle.addAction(action6);

			particle.generate(plane.geometry.subGeometries[0]);
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
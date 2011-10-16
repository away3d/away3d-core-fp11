package 
{
	import a3dparticle.animators.actions.circle.CircleLocal;
	import a3dparticle.animators.actions.color.ChangeColorByLifeGlobal;
	import a3dparticle.animators.actions.color.ChangeColorByVelocityGlobal;
	import a3dparticle.animators.actions.color.RandomColorLocal;
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
	import flash.display.BitmapData;
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
	public class ColorVelocity extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		
		public function ColorVelocity():void 
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
			var material:SimpleParticleMaterial = new SimpleParticleMaterial(new BitmapData(2, 2, false, 0xFF0000));
			particle = new ParticlesContainer(1000,material);
			_view.scene.addChild(particle);
			
			var sphere:Sphere = new Sphere(null, 10,5,5);

			
			particle.startTimeFun = function(index:uint):Number { return Math.random()*10; };
			particle.endTimeFun = function(index:uint):Number { return 30; };
			particle.loop = true;
			
			var circle_fn:Function = function(index:uint):Vector3D
			{
				var r:Number = Math.random()*400+250;
				return new Vector3D(r, 10);
			}
			
			var action:CircleLocal = new CircleLocal(circle_fn);
			particle.addAction(action);
			
			
			var action2:ChangeColorByVelocityGlobal = new ChangeColorByVelocityGlobal(new ColorTransform(0,0,0,0,-1,0,1),0,0.03);
			particle.addAction(action2);
		
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
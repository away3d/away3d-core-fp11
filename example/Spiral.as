package 
{
	import a3dparticle.animators.actions.ChangeColorByLifeAction;
	import a3dparticle.animators.actions.CircleAction;
	import a3dparticle.animators.actions.VelocityAction;
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
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;
	
	/**
	 * ...
	 * @author liaocheng
	 */
	[SWF(width="1024", height="768", frameRate="60")]
	public class Spiral extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		public function Spiral():void 
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
			var material:SimpleParticleMaterial = new SimpleParticleMaterial(new BitmapData(2, 2, true, 0xFF00FF00));
			particle = new ParticlesContainer(1000,material);
			_view.scene.addChild(particle);
			
			var sphere:Sphere = new Sphere(null, 10, 6, 6);
			
			particle.startTimeFun = function(index:uint):Number { return Math.random()*5; };
			particle.endTimeFun = function(index:uint):Number { return 5; };
			particle.loop = true;
			
			var action:CircleAction = new CircleAction(function(index:uint):Vector3D { return new Vector3D(200, 1);},new Vector3D(90 ));
			particle.addPerParticleAction(action);
			
			var action2:VelocityAction = new VelocityAction(function(index:uint):Vector3D { return new Vector3D(0,100,0);});
			particle.addPerParticleAction(action2);
			
			var action3:ChangeColorByLifeAction = new ChangeColorByLifeAction(new ColorTransform(0.2,0.2,0.2,0.2),new ColorTransform(1,1,1,1));
			particle.addAllParticleAction(action3);
			
			
			particle.generate(sphere.geometry.subGeometries[0]);
			particle.start();
			
			var clone:ParticlesContainer = particle.clone() as ParticlesContainer;
			var material2:SimpleParticleMaterial = new SimpleParticleMaterial(new BitmapData(2, 2, true, 0xFFFF0000));
			clone.rotationZ = 90;
			clone.material = material2;
			_view.scene.addChild(clone);
			clone.start();
			
			clone = particle.clone() as ParticlesContainer;
			var material3:SimpleParticleMaterial = new SimpleParticleMaterial(new BitmapData(2, 2, true, 0xFF0000FF));
			clone.rotationZ = -90;
			clone.material = material3;
			_view.scene.addChild(clone);
			clone.start();
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
package 
{
	import a3dparticle.animators.actions.color.ChangeColorByLifeGlobal;
	import a3dparticle.animators.actions.rotation.AutoRotateGlobal;
	import a3dparticle.animators.actions.scale.ScaleByLifeGlobal;
	import a3dparticle.animators.actions.velocity.VelocityLocal;
	import a3dparticle.materials.SimpleParticleMaterial;
	import a3dparticle.ParticlesContainer;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.primitives.Cylinder;
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
	public class Explode extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		public function Explode():void 
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
			var material:SimpleParticleMaterial = new SimpleParticleMaterial();
			particle = new ParticlesContainer(500,material);
			_view.scene.addChild(particle);
			
			var cy:Cylinder = new Cylinder(null, 2, 2, 20);
			cy.rotationZ = 90;
			MeshHelper.applyRotations(cy);
			
			particle.startTimeFun = function(index:uint):Number { return Math.random()*1; };
			particle.endTimeFun = function(index:uint):Number { return 1; };
			particle.loop = false;
			
			var sphere_fn:Function = function(index:uint):Vector3D
			{
				var degree1:Number = Math.random() * Math.PI * 2;
				var degree2:Number = Math.random() * Math.PI * 2;
				var r:Number = 400;
				return new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2));
			}
			
			var action:VelocityLocal = new VelocityLocal(sphere_fn);
			particle.addAction(action);
			
			var action2:ChangeColorByLifeGlobal = new ChangeColorByLifeGlobal(new ColorTransform(1, 0.9, 0,1),new ColorTransform(0.5, 0, 0,0));
			particle.addAction(action2);
			
			var action3:AutoRotateGlobal = new AutoRotateGlobal();
			particle.addAction(action3);
			
			var action4:ScaleByLifeGlobal = new ScaleByLifeGlobal(2,0.5);
			particle.addAction(action4);
			
			
			particle.generate(cy.geometry.subGeometries[0]);
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
package 
{
	import a3dparticle.animators.actions.bezier.BezierCurvelocal;
	import a3dparticle.animators.actions.color.ChangeColorByLifeGlobal;
	import a3dparticle.animators.actions.rotation.AutoRotateGlobal;
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
	public class Bezier extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		public function Bezier():void 
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
			var material:SimpleParticleMaterial = new SimpleParticleMaterial();
			particle = new ParticlesContainer(1000,material);
			_view.scene.addChild(particle);
			
			var sphere:Sphere = new Sphere(null, 10, 6, 6);
			
			particle.startTimeFun = function(index:uint):Number { return Math.random()*4; };
			particle.endTimeFun = function(index:uint):Number { return 4; };
			particle.loop = true;
			
			var gen_fn:Function = function(index:uint):Array
			{
				var degree:Number = 0;
				var r:Number = 500;
				return [new Vector3D(0, 600, 0),new Vector3D(500, 0, 0)];
			}
			
			var action:BezierCurvelocal = new BezierCurvelocal(gen_fn);
			particle.addAction(action);
			
			var action2:ChangeColorByLifeGlobal = new ChangeColorByLifeGlobal(new ColorTransform(1, 0.9, 0,1),new ColorTransform(0.5, 0, 0));
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
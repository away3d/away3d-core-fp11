package 
{
	import a3dparticle.animators.actions.brokenline.BrokenLineGlobal;
	import a3dparticle.animators.actions.color.RandomColorLocal;
	import a3dparticle.animators.actions.scale.RandomScaleLocal;
	import a3dparticle.materials.SimpleParticleMaterial;
	import a3dparticle.ParticlesContainer;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.primitives.Sphere;
	import away3d.primitives.WireframeAxesGrid;
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
	public class BrokenLineExample extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		public function BrokenLineExample():void 
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
		}
		
		
		
		private function initScene():void
		{
			var sphere:Sphere = new Sphere(null, 5, 6, 6);
			
			//triangle 
			var material:SimpleParticleMaterial = new SimpleParticleMaterial();
			material.bothSides = false;
			particle = new ParticlesContainer(50,material);
			_view.scene.addChild(particle);
			
			particle.startTimeFun = function(index:uint):Number { return index*0.1; };
			particle.endTimeFun = function(index:uint):Number { return 15; };
			particle.loop = true;
			var action:BrokenLineGlobal = new BrokenLineGlobal([new Vector3D(-1*50,-1.732*50,0,5),new Vector3D(2*50,0,0,5),new Vector3D(-1*50,1.732*50,0,5)]);
			particle.addAction(action);
			var scaleFn:Function = function(index:uint):Vector3D
			{
				var factor:Number = Math.exp(-index*0.1)*2;
				return new Vector3D(factor+0.2, factor+0.2, factor+0.2);
			}
			var action2:RandomScaleLocal = new RandomScaleLocal(scaleFn);
			particle.addAction(action2);
			var colorFn:Function = function(index:uint):ColorTransform
			{
				var factor:Number = Math.exp(-index*0.1);
				return new ColorTransform(factor+0.2, factor+0.2, factor*0.8+0.2, factor+0.1);
			}
			var action3:RandomColorLocal = new RandomColorLocal(colorFn,true,false );
			particle.addAction(action3);
			particle.generate(sphere.geometry.subGeometries[0]);
			particle.start();
			particle.y = 1.732 * 5 * 50 / 2;
			
			//square 
			material = new SimpleParticleMaterial();
			material.bothSides = false;
			particle = new ParticlesContainer(50,material);
			_view.scene.addChild(particle);
			
			particle.startTimeFun = function(index:uint):Number { return index*0.1; };
			particle.endTimeFun = function(index:uint):Number { return 20; };
			particle.loop = true;
			action = new BrokenLineGlobal([new Vector3D(2*50,0,0,5),new Vector3D(0,-2*50,0,5),new Vector3D(-2*50,0,0,5),new Vector3D(0,2*50,0,5)]);
			particle.addAction(action);
			action2 = new RandomScaleLocal(scaleFn);
			particle.addAction(action2);
			colorFn = function(index:uint):ColorTransform
			{
				var factor:Number = Math.exp(-index*0.1);
				return new ColorTransform(factor+0.2, 0, 0, factor+0.1);
			}
			action3 = new RandomColorLocal(colorFn,true,false );
			particle.addAction(action3);
			particle.generate(sphere.geometry.subGeometries[0]);
			particle.start();
			particle.x = -2 * 5 * 50 / 2;
			particle.y = 2 * 5 * 50 / 2;
			
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
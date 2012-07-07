package 
{
	import a3dparticle.animators.actions.brokenline.BrokenLineLocal;
	import a3dparticle.animators.actions.position.OffsetPositionLocal;
	import a3dparticle.animators.actions.texture.ColorTextureByLifeGlobal;
	import a3dparticle.animators.actions.texture.TextureHelper;
	import a3dparticle.generater.SingleGenerater;
	import a3dparticle.particle.ParticleColorMaterial;
	import a3dparticle.particle.ParticleParam;
	import a3dparticle.particle.ParticleSample;
	import a3dparticle.ParticlesContainer;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.primitives.SphereGeometry;
	import away3d.primitives.WireframeAxesGrid;
	import flash.display.BlendMode;
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
	public class Main extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		public function Main():void 
		{
			if (stage) setTimeout(init, 0);
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
			var material:ParticleColorMaterial = new ParticleColorMaterial(0x66FFB151);
			material.blendMode = BlendMode.ADD;
			var sphere:SphereGeometry = new SphereGeometry( 2, 5, 5);
			
			var sample:ParticleSample = new ParticleSample(sphere.subGeometries[0], material);
			
			var generater:SingleGenerater = new SingleGenerater(sample, 500);
			
			particle = new ParticlesContainer();
			particle.loop = true;
			particle.hasDuringTime = true;
			particle.hasSleepTime = true;
			
			var action1:OffsetPositionLocal = new OffsetPositionLocal();
			particle.addAction(action1);
			var action2:BrokenLineLocal = new BrokenLineLocal(2);
			particle.addAction(action2);
			var action3:ColorTextureByLifeGlobal = new ColorTextureByLifeGlobal(TextureHelper.hori2jump(0x88888888,0xFFFFFFFF,0x55555555,0.33));
			particle.addAction(action3);
			
			particle.initParticleFun = initParticleParam;
			particle.generate(generater);
			particle.start();
			
			for (var i:int = -1; i <= 1; i++)
				for (var j:int = -1; j <= 1; j++)
				{
					var clone:ParticlesContainer = particle.clone() as ParticlesContainer;
					clone.time = Math.random() * 6;
					clone.start();
					clone.x = i * 300;
					clone.z = j * 300;
					_view.scene.addChild(clone);
				}
		}
		
		private function initParticleParam(param:ParticleParam):void
		{
			param.startTime = 0;
			param.duringTime = 3;
			param.sleepTime = 1;
			
			var maxR:Number = 5;
			
			var degree1:Number = int(Math.random()*12)/12 * Math.PI * 2;
			var degree2:Number = int(Math.random()*12)/12 * Math.PI * 2;
			var r:Number = Math.random() * maxR;
			param["OffsetPositionLocal"] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2));
			r = Math.random() * 200 ;
			param["BrokenLineLocal"] = [new Vector3D(0, 400, 0, 1), new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2),3)];
			
			
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
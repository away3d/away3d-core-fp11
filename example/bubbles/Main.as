package 
{
	import a3dparticle.animators.actions.color.ChangeColorByLifeGlobal;
	import a3dparticle.animators.actions.drift.DriftLocal;
	import a3dparticle.animators.actions.position.OffsetPositionLocal;
	import a3dparticle.animators.actions.rotation.BillboardGlobal;
	import a3dparticle.animators.actions.scale.ScaleByLifeGlobal;
	import a3dparticle.animators.actions.velocity.VelocityLocal;
	import a3dparticle.generater.SingleGenerater;
	import a3dparticle.particle.ParticleBitmapMaterial;
	import a3dparticle.particle.ParticleParam;
	import a3dparticle.particle.ParticleSample;
	import a3dparticle.ParticlesContainer;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.WireframeAxesGrid;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.ColorTransform;
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
		[Embed(source = "./pp.png")]
		private var IMG:Class;
		
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
			//_view.backgroundColor = 0x888888;
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
			var material:ParticleBitmapMaterial = new ParticleBitmapMaterial(new IMG().bitmapData);
			var plane:PlaneGeometry = new PlaneGeometry( 20, 20, 1, 1, false);
			
			var sample:ParticleSample = new ParticleSample(plane.subGeometries[0], material);
			var generater:SingleGenerater = new SingleGenerater(sample, 1000);
			
			particle = new ParticlesContainer();
			_view.scene.addChild(particle);
			
			particle.loop = true;
			
			var action:VelocityLocal = new VelocityLocal();
			particle.addAction(action);
			
			var action2:OffsetPositionLocal = new OffsetPositionLocal();
			particle.addAction(action2);
			
			var action3:BillboardGlobal = new BillboardGlobal();
			particle.addAction(action3);
			
			var action4:ChangeColorByLifeGlobal = new ChangeColorByLifeGlobal(new ColorTransform(1.5, 1.5, 1.5), new ColorTransform(2, 2, 2));
			particle.addAction(action4);
			
			var action5:DriftLocal = new DriftLocal();
			particle.addAction(action5);
			
			var action6:ScaleByLifeGlobal = new ScaleByLifeGlobal(1,2);
			particle.addAction(action6);
			
			particle.initParticleFun = initParticleParam;
			particle.generate(generater);
			particle.start();
			
			
		}
		
		private function initParticleParam(param:ParticleParam):void
		{
			param.startTime = Math.random()*8;
			param.duringTime = 8;
			param["VelocityLocal"] = new Vector3D(0, Math.random() * 50 + 50, 0);
			param["OffsetPositionLocal"] = new Vector3D(Math.random() * 1000 - 500, 0, Math.random() * 1000 - 500);
			param["DriftLocal"] = new Vector3D(Math.random() * 50, 0, Math.random() * 50, Math.random() * 5 + 2);
			param["RandomRotateLocal"] = new Vector3D(0,0,1,5);
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
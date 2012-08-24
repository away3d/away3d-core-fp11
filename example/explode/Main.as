package explode
{
	import a3dparticle.animators.actions.color.ChangeColorByLifeGlobal;
	import a3dparticle.animators.actions.rotation.AutoRotateGlobal;
	import a3dparticle.animators.actions.scale.ScaleByLifeGlobal;
	import a3dparticle.animators.actions.velocity.VelocityLocal;
	import a3dparticle.generater.MutiWeightGenerater;
	import a3dparticle.particle.ParticleColorMaterial;
	import a3dparticle.particle.ParticleParam;
	import a3dparticle.particle.ParticleSample;
	import a3dparticle.ParticlesContainer;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.primitives.CylinderGeometry;
	import away3d.primitives.SphereGeometry;
	import away3d.debug.WireframeAxesGrid
	import away3d.tools.helpers.MeshHelper;
	import flash.display.BlendMode;
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
		private var sample1:ParticleSample;
		private var sample2:ParticleSample;
		
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
			var material:ParticleColorMaterial = new ParticleColorMaterial();
			material.blendMode = BlendMode.ADD;
			var cy:Mesh = new Mesh(new CylinderGeometry( 1, 1, 20));
			cy.rotationZ = 90;
			MeshHelper.applyRotations(cy);
			var sphere:SphereGeometry = new SphereGeometry(1, 6, 6);
			
			sample1 = new ParticleSample(cy.geometry.subGeometries[0], material);
			sample2 = new ParticleSample(sphere.subGeometries[0], material);
			
			var generater:MutiWeightGenerater = new MutiWeightGenerater([sample1, sample2], [5, 1], 400);
			
			particle = new ParticlesContainer();
			particle.loop = false;
			particle.hasDuringTime = true;
			
			var action:VelocityLocal = new VelocityLocal();
			particle.addAction(action);
			
			var action2:ChangeColorByLifeGlobal = new ChangeColorByLifeGlobal(new ColorTransform(1, 0.9, 0,1),new ColorTransform(0.5, 0, 0,0));
			particle.addAction(action2);
			
			var action3:AutoRotateGlobal = new AutoRotateGlobal();
			particle.addAction(action3);
			
			var action4:ScaleByLifeGlobal = new ScaleByLifeGlobal(2,0.5);
			particle.addAction(action4);
			
			particle.initParticleFun = initParticleParam;
			particle.generate(generater);
			particle.start();
			
			_view.scene.addChild(particle);
		}
		
		private function initParticleParam(param:ParticleParam):void
		{
			param.startTime = 0;
			param.duringTime = 1;
			
			var degree1:Number = Math.random() * Math.PI * 2;
			var degree2:Number = Math.random() * Math.PI * 2;
			var r:Number = 400 + Math.random() * 50;
			param["VelocityLocal"] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2));
			if (param.sample == sample2) Vector3D(param["VelocityLocal"]).scaleBy(0.5);
		}
		
		private function onRender(e:Event):void
		{
			if (particle.time > 2) particle.time = 0;
			_view.render();
		}
		private function onStageResize(e:Event):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
		}
		
	}
	
}
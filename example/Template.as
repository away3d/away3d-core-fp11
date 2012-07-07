package 
{
	import a3dparticle.animators.actions.color.ChangeColorByLifeGlobal;
	import a3dparticle.animators.actions.position.OffsetPositionLocal;
	import a3dparticle.animators.actions.velocity.VelocityLocal;
	import a3dparticle.generater.MutiWeightGenerater;
	import a3dparticle.particle.ParticleColorMaterial;
	import a3dparticle.particle.ParticleParam;
	import a3dparticle.particle.ParticleSample;
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
	 * @author liaocheng.Email:liaocheng210@126.com
	 */
	[SWF(width="1024", height="768", frameRate="60")]
	public class Template extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		public function Template():void 
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
			//step 1: we create some samples which group the geometry and material.
			//the geometry can be got from the primitives of away3d or models which is createed by tools like max or maya .
			//the material can be ParticleColorMaterial which set color directly or ParticleBitmapMaterial which set color using texture.
			var material:ParticleColorMaterial = new ParticleColorMaterial();
			var sphereLarge:Sphere = new Sphere(null, 10, 6, 6);
			var sphereSmall:Sphere = new Sphere(null, 5, 4, 4);
			var sample1:ParticleSample = new ParticleSample(sphereLarge.geometry.subGeometries[0], material);
			var sample2:ParticleSample = new ParticleSample(sphereSmall.geometry.subGeometries[0], material);
			
			//step 2: we create a generater which group the samples.
			//The generater will provide a samples list for container.
			var generater:MutiWeightGenerater = new MutiWeightGenerater([sample1, sample2], [2, 1], 1000);
			
			//step 3: we create a container and set some attributes.
			particle = new ParticlesContainer();
			particle.loop = true;
			particle.hasDuringTime = true;
			
			//step 4:we add some actions to the container.
			var action1:VelocityLocal = new VelocityLocal();
			particle.addAction(action1);
			
			var action2:OffsetPositionLocal = new OffsetPositionLocal();
			particle.addAction(action2);
			
			var action3:ChangeColorByLifeGlobal = new ChangeColorByLifeGlobal(new ColorTransform(1, 1, 0.2, 0.8, 0, 0), new ColorTransform(1, 0, 0, 0.1, 0, 0) );
			particle.addAction(action3);
			
			//step 5:we set the param function whose return value will be used for actions
			particle.initParticleFun = initParticleParam;
			
			//finally,we generate the particles,and start
			particle.generate(generater);
			particle.start();
			
			_view.scene.addChild(particle);
			
			//we can clone it to create many instances to add different position.
		}
		
		private function initParticleParam(param:ParticleParam):void
		{
			param.startTime = Math.random() * 3;
			param.duringTime = Math.random() * 2 + 1;
			param["VelocityLocal"] = new Vector3D(Math.random() * 100 - 50, Math.random() * 300, Math.random() * 100 - 50);
			param["OffsetPositionLocal"] = new Vector3D(Math.random() * 70 - 35, 0, Math.random() * 70 - 35);
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
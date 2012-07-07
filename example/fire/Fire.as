package 
{
	import a3dparticle.animators.actions.acceleration.AccelerateGlobal;
	import a3dparticle.animators.actions.color.ChangeColorByLifeGlobal;
	import a3dparticle.animators.actions.position.OffsetPositionLocal;
	import a3dparticle.animators.actions.velocity.VelocityLocal;
	import a3dparticle.generater.MutiWeightGenerater;
	import a3dparticle.particle.ParticleColorMaterial;
	import a3dparticle.particle.ParticleParam;
	import a3dparticle.particle.ParticleSample;
	import a3dparticle.ParticlesContainer;
	import away3d.containers.ObjectContainer3D;
	import away3d.primitives.SphereGeometry;
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;
	
	/**
	 * ...
	 * @author liaocheng
	 */
	public class Fire extends ObjectContainer3D 
	{
		
		private var particle:ParticlesContainer;
		
		private var sample1:ParticleSample;
		
		private var sample2:ParticleSample;
		
		public function Fire():void 
		{
			//step 1:we create two samples
			var material:ParticleColorMaterial = new ParticleColorMaterial();
			var sphereLarge:SphereGeometry = new SphereGeometry(5, 6, 6);
			//sphereLarge.scaleY = 1.5;
			var sphereSmall:SphereGeometry = new SphereGeometry(2, 4, 4);
			sample1 = new ParticleSample(sphereLarge.subGeometries[0], material);
			sample2 = new ParticleSample(sphereSmall.subGeometries[0], material);
			
			//step 2:we create a generater which will group the samples.
			var generater:MutiWeightGenerater = new MutiWeightGenerater([sample1, sample2], [5, 1], 500);
			
			//step 3: we create a container and set some attributes.
			particle = new ParticlesContainer();
			particle.loop = true;
			particle.hasDuringTime = true;
			
			//step 4:we add some actions to the container.
			var action1:VelocityLocal = new VelocityLocal();
			particle.addAction(action1);
			
			var action2:OffsetPositionLocal = new OffsetPositionLocal();
			particle.addAction(action2);
			
			var action3:ChangeColorByLifeGlobal = new ChangeColorByLifeGlobal(new ColorTransform(0.8, 0.7, 0, 0.8), new ColorTransform(0.8, 0, 0, 0) );
			particle.addAction(action3);
			
			var action4:AccelerateGlobal = new AccelerateGlobal(new Vector3D(0,-30,0));
			particle.addAction(action4);
			
			//step 5:we set the param function whose return value will be used for actions
			particle.initParticleFun = initParticleParam;
			
			//finally,we generate the particles,and start
			particle.generate(generater);
			particle.start();
			
			addChild(particle);
		}
		
		private function initParticleParam(param:ParticleParam):void
		{
			param.startTime = Math.random() * 3;
			param.duringTime = Math.random() * 2 + 1;
			var degree:Number = Math.random() * Math.PI*2;
			var cos:Number = Math.cos(degree);
			var sin:Number = Math.sin(degree);
			var r1:Number = Math.random() * 20;
			var r2:Number = Math.random()*10;
			param["VelocityLocal"] = new Vector3D(r1 * cos, Math.random() * 50 + 80, r1 * sin);
			param["OffsetPositionLocal"] = new Vector3D(r2 * cos, 0, r2 * sin);
			if (param.sample == sample2) Vector3D(param["VelocityLocal"]).scaleBy(1.4);
		}
		
	}
	
}
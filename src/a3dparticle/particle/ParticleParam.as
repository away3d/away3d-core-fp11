package a3dparticle.particle 
{
	/**
	 * ...
	 * @author liaocheng.Email:liaocheng210@126.com.
	 */
	dynamic public class ParticleParam 
	{
		//the single particle's sample,which contains its geometry and material.
		public var sample:ParticleSample;
		
		//the single's index of the container
		public var index:uint;
		
		//the total count of the container particles
		public var total:uint;
		
		//the single particle's startTime.If the startTimeFun of container isn't set,this value is used for TimeAction.
		public var startTime:Number;
		//the single particle's duringTime.If the duringTimeFun of container isn't set,this value is used for TimeAction.
		public var duringTime:Number;
		//the single particle's sleepTime.If the sleepTimeFun of container isn't set,this value is used for TimeAction.
		public var sleepTime:Number;
		
		/**
		 * auto used attributes for actions:(If the action's generate function isn't set,there value will be used.These can be set in the initParticleFun.)
		 * 
		 * VelocityLocal Vector3D. (x,y,z) is the particle's velocity.
		 * 
		 * RandomScaleLocal Vector3D. (x,y,z) is the particle's scaleX,scaleY,scaleZ.
		 * 
		 * RandomRotateLocal Vector3D. (x,y,z) is the rotation axis of the particle, w is the cycle time of rotation.The w must be greater than 0.
		 * 
		 * OffsetPositionLocal Vector3D. (x,y,z) is the offset position of the particle.
		 * 
		 * DriftLocal Vector3D. (x,y,z) is the max drift position,w is the cycle time of drift.It use the sin to cacluate output.So the max offset is (x,y,z),min offset
		 * 						is (-x,-y,-z).
		 * 
		 * RandomColorLocal ColorTransform.This will effect the original color of the particle.
		 * 
		 * CircleLocal Vector3D. x is the radius of the circular motion. y is the cycle time of the circular motion.Both x and y must be greater than 0.
		 * 
		 * BrokenLineLocal Array. The element of the Array is Vector3D which (x,y,z) is the velocity and the w is the time for the velocity.
		 * 
		 * BezierCurvelocal Array. It has two elements which are Vector3D. The first element's (x,y,z) is the control point of the BezierCurve.The last element's (x,y,z)
		 * 							is the end point of the BezierCurve.
		 * 
		 * AccelerateLocal Vector3D. (x,y,z) is the acceleration of the particle.
		 */
	}

}
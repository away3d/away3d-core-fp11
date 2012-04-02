package away3d.controllers 
{
	
	import away3d.containers.ObjectContainer3D;
	import away3d.core.math.MathConsts;
	import away3d.entities.Entity;
	import flash.geom.Vector3D;
	
	/**
	 * Extended camera used to smooth follow a character.
	 * 
	 * @see	away3d.containers.View3D
	 */
	public class CharacterFollowController extends LookAtController
	{
		public var height:Number;
		public var radius:Number;
		public var cameraSpeed:Number;
		public var maxCameraSpeed:Number;
		public var rotation:Number;
		
		public function CharacterFollowController(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null, height:Number = 1000, radius:Number = 700, cameraSpeed:Number = .05, maxCameraSpeed:Number = 40, rotation:Number = 0 ) 
		{
			this.targetObject = targetObject;
			this.lookAtObject = lookAtObject;
			this.height = height;
			this.radius = radius;
			this.cameraSpeed = cameraSpeed;
			this.maxCameraSpeed = maxCameraSpeed;
			this.rotation = rotation;
			this.autoUpdate = false;
		}
		
		override public function update():void 
		{
			if (!lookAtObject)
				return;			
			var radians:Number;
			radians = MathConsts.DEGREES_TO_RADIANS*(lookAtObject.rotationY + 180+rotation);
			var targetX:Number = lookAtObject.position.x + Math.sin(radians) * radius;
			if (lookAtObject.forwardVector.z <0) {
				radians = (lookAtObject.rotationY+rotation)*MathConsts.DEGREES_TO_RADIANS;
			}
			var targetZ:Number = lookAtObject.position.z + Math.cos(radians) * radius;			
			var dx:Number = targetX - targetObject.position.x;
			var dy:Number = (lookAtObject.position.y + height) - targetObject.position.y;
			var dz:Number = targetZ - targetObject.position.z;
			var vx:Number = dx * cameraSpeed * 2;
			var vy:Number = dy * cameraSpeed;
			var vz:Number = dz * cameraSpeed * 2;
			if (vx > maxCameraSpeed || vx < -maxCameraSpeed)
			{
				vx = vx < 1 ? -maxCameraSpeed : maxCameraSpeed;
			}
			
			if (vy > maxCameraSpeed || vy < -maxCameraSpeed)
			{
				vy = vy < 1 ? -maxCameraSpeed : maxCameraSpeed;
			}
			
			if (vz > maxCameraSpeed || vz < -maxCameraSpeed)
			{
				vz = vz < 1 ? -maxCameraSpeed : maxCameraSpeed;
			}
			targetObject.position = new Vector3D(targetObject.position.x + vx, targetObject.position.y + vy, targetObject.position.z + vz);
			super.update();
			
			targetObject.rotationX += -10;
		}		
	}
}
package away3d.cameras
{
	import away3d.cameras.lenses.LensBase;
	import away3d.containers.*;
	import away3d.core.base.*;
	
	import flash.geom.*;
	
	
    /**
    * Extended camera used to automatically look at a specified target object.
    * 
    * @see away3d.containers.View3D
    */
    public class TargetCamera3D extends Camera3D
    {
        /**
        * The 3d object targeted by the camera.
        */
        public var target:ObjectContainer3D;
    	
	    /**
	    * Creates a new <code>TargetCamera3D</code> object.
		 * @param lens An optional lens object that will perform the projection. Defaults to PerspectiveLens.
		 *
		 * @see away3d.cameras.lenses.PerspectiveLens
		 */
        public function TargetCamera3D(lens : LensBase = null, target:ObjectContainer3D = null)
        {
            super(lens);
			
			this.target = target || new ObjectContainer3D();
        }
        
		/**
		 * @inheritDoc
		 */
		public override function get viewProjection() : Matrix3D
		{
			if (target != null)
				lookAt(target.scene ? target.scenePosition : target.position);
			
			return super.viewProjection;
		}
    }
}   

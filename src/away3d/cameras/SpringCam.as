package away3d.cameras
{
  import away3d.cameras.Camera3D;
  import away3d.cameras.lenses.LensBase;
  import away3d.core.base.Object3D;
  import flash.geom.Matrix3D;
  import flash.geom.Vector3D;
  
	/**  
   * v1 - 2009-01-21 b at turbulent dot ca - http://agit8.turbulent.ca
   * v2 - 2011-03-06 Ringo - http://www.ringo.nl/en/
   **/
   
  /**
   * A 1st and 3d person camera(depending on positionOffset!), hooked on a physical spring on an optional target.
   */
  public class SpringCam extends Camera3D
  {
    /**
     * [optional] Target object3d that camera should follow. If target is null, camera behaves just like a normal Camera3D.
     */
    public var target:Object3D;
    
    //spring stiffness
    /**
     * Stiffness of the spring, how hard is it to extend. The higher it is, the more "fixed" the cam will be.
     * A number between 1 and 20 is recommended.
     */
    public var stiffness:Number = 1;
    
    /**
     * Damping is the spring internal friction, or how much it resists the "boinggggg" effect. Too high and you'll lose it!
     * A number between 1 and 20 is recommended.
     */
    public var damping:Number = 4;
    
    /**
     * Mass of the camera, if over 120 and it'll be very heavy to move.
     */
    public var mass:Number = 40;
    
    /**
     * Offset of spring center from target in target object space, ie: Where the camera should ideally be in the target object space.
     */
    public var positionOffset:Vector3D = new Vector3D(0,5,-50);
    
    /**
     * offset of facing in target object space, ie: where in the target object space should the camera look.
     */
    public var lookOffset:Vector3D = new Vector3D(0,2,10);
    
    //zrot to apply to the cam
    private var _zrot:Number = 0;
    
    //private physics members
    private var _velocity:Vector3D = new Vector3D();
    private var _dv:Vector3D = new Vector3D();
    private var _stretch:Vector3D = new Vector3D();
    private var _force:Vector3D = new Vector3D();
    private var _acceleration:Vector3D = new Vector3D();
    
    //private target members
    private var _desiredPosition:Vector3D = new Vector3D();
    private var _lookAtPosition:Vector3D = new Vector3D();
    
    //private transformed members
    private var _xPositionOffset:Vector3D = new Vector3D();
    private var _xLookOffset:Vector3D = new Vector3D();
    private var _xPosition:Vector3D = new Vector3D();
 
 	private var _viewProjection : Matrix3D = new Matrix3D();
    
    public function SpringCam(lens : LensBase = null)
    {
    	super(lens);
    }
    
    /**
     * Rotation in degrees along the camera Z vector to apply to the camera after it turns towards the target .
     */
    public function set zrot(n:Number):void
    {
      _zrot = n;
      if(_zrot < 0.001) n = 0;
    }
    public function get zrot():Number
    {
      return _zrot;
    }
    
    
    public override function get viewProjection():Matrix3D
    {
      if(target != null)
      {
      	
      	_xPositionOffset = target.transform.deltaTransformVector(positionOffset);
      	_xLookOffset = target.transform.deltaTransformVector(lookOffset);
      	
      	_desiredPosition = target.position.add(_xPositionOffset);
      	_lookAtPosition = target.position.add(_xLookOffset);
      	
      	_stretch = this.position.subtract(_desiredPosition);
      	_stretch.scaleBy(-stiffness);
      	_dv = _velocity.clone();
      	_dv.scaleBy(damping);
      	_force = _stretch.subtract(_dv);
      	
      	_acceleration = _force.clone();
      	_acceleration.scaleBy(1/mass);
      	_velocity = _velocity.add(_acceleration);
      	
      	_xPosition = position.add(_velocity);
      	x = _xPosition.x;
      	y = _xPosition.y;
      	z = _xPosition.z;
      	
      	lookAt(_lookAtPosition);
      	
      	if(Math.abs(_zrot) > 0)
			rotate(Vector3D.Z_AXIS, _zrot);
			
		_viewProjection.copyFrom(inverseSceneTransform);
		_viewProjection.append(this.lens.matrix);
				
      }
      
      return this._viewProjection;
    }
    
  }
}
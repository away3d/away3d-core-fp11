package away3d.tools.serialize
{
	import away3d.core.math.Quaternion;
	import away3d.entities.Mesh;
	import away3d.errors.AbstractMethodError;
	
	import flash.geom.Vector3D;
	import flash.utils.getQualifiedClassName;

  public class SerializerBase
  {
    public function SerializerBase()
    {
    }
    
		public function beginObject(className:String, instanceName:String):void
		{
			throw new AbstractMethodError();
		}
		
		public function writeUint(name:String, value:uint):void
		{
			throw new AbstractMethodError();
		}
		
		public function writeBoolean(name:String, value:Boolean):void
		{
			throw new AbstractMethodError();
		}
		
		public function writeString(name:String, value:String):void
		{
			throw new AbstractMethodError();
		}
		
		public function writeVector3D(name:String, value:Vector3D):void
		{
			throw new AbstractMethodError();
		}
		
		public function writeTransform(name:String, value:Vector.<Number>):void
		{
			throw new AbstractMethodError();
		}
		
		public function writeQuaternion(name:String, value:Quaternion):void
		{
			throw new AbstractMethodError();
		}
		
		public function endObject():void
		{
			throw new AbstractMethodError();
		}
  }
}
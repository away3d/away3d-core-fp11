package away3d.debug
{
	import away3d.animators.data.SkeletonAnimationSequence;
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.core.base.SubGeometry;
	import away3d.debug.SerializerBase;
	import away3d.entities.Mesh;
	
	use namespace arcane;
  
  import flash.utils.getQualifiedClassName;
  import away3d.animators.skeleton.SkeletonPose;
  import away3d.animators.skeleton.JointPose;
  import away3d.core.base.Object3D;

  public class Serialize
  {
		public static var tabSize:uint = 2;
		
    public function Serialize()
    {
    }
    
    public static function serializeScene(scene:Scene3D, serializer:SerializerBase):void
    {
      for (var i:uint = 0; i < scene.numChildren; i++)
      {
				serializeObjectContainer(scene.getChildAt(i), serializer);
      }
    }
    
		public static function serializeObjectContainer(objectContainer3D:ObjectContainer3D, serializer:SerializerBase):void
		{
			if (objectContainer3D is Mesh)
			{
				serializeMesh(objectContainer3D as Mesh, serializer); // do not indent any extra for first level here
			}
			else
			{
				serializeObjectContainerInternal(objectContainer3D, serializer, true /* serializeChildrenAndEnd */);
			}
		}
		
    public static function serializeMesh(mesh:Mesh, serializer:SerializerBase):void
    {
			serializeObjectContainerInternal(mesh as ObjectContainer3D, serializer, false /* serializeChildrenAndEnd */);
      
      if (mesh.geometry.subGeometries.length)
      {
        for (var i:uint = 0; i < mesh.geometry.subGeometries.length; i++)
        {
					serializeSubGeometry(mesh.geometry.subGeometries[i], serializer);
        }
      }
      
			serializeChildren(mesh as ObjectContainer3D, serializer);
			serializer.endObject();
    }
    
    public static function serializeSubGeometry(subGeometry:SubGeometry, serializer:SerializerBase):void
    {
			serializer.beginObject(classNameFromInstance(subGeometry), null);
			serializer.writeUint("numTriangles", subGeometry.numTriangles);
			if (subGeometry.indexData)
			{
				serializer.writeUint("numIndices", subGeometry.indexData.length);
			}
			serializer.writeUint("numVertices", subGeometry.numVertices);
			if (subGeometry.UVData)
			{
				serializer.writeUint("numUVs", subGeometry.UVData.length);
			}
			serializer.endObject();
    }
		
		public static function serializeJointPose(jointPose:JointPose, serializer:SerializerBase):void
		{
			serializer.beginObject(classNameFromInstance(jointPose), jointPose.name);
			serializer.writeVector3D("translation", jointPose.translation);
			serializer.writeQuaternion("orientation", jointPose.orientation);
			serializer.endObject();
		}
		
		public static function serializeSkeletonPose(skeletonPose:SkeletonPose, serializer:SerializerBase):void
		{
			serializer.beginObject(classNameFromInstance(skeletonPose), "" /*skeletonPose.name*/);
			serializer.writeUint("numJointPoses", skeletonPose.numJointPoses);
			for each (var jointPose:JointPose in skeletonPose.jointPoses)
			{
				serializeJointPose(jointPose, serializer);
			}
			serializer.endObject();
		}
		
		public static function serializeSkeletonAnimationSequence(skeletonAnimationSequence:SkeletonAnimationSequence, serializer:SerializerBase):void
		{
			serializer.beginObject(classNameFromInstance(skeletonAnimationSequence), skeletonAnimationSequence.name);
			serializer.writeUint("duration", skeletonAnimationSequence.duration);
			serializer.writeBoolean("fixedFrameRate", skeletonAnimationSequence.fixedFrameRate);
			serializer.writeBoolean("looping", skeletonAnimationSequence.looping);
			for each (var skeletonPose:SkeletonPose in skeletonAnimationSequence._frames)
			{
				serializeSkeletonPose(skeletonPose, serializer);
			}
			serializer.endObject();
		}

		// private stuff - shouldn't ever need to call externally
		
		private static function serializeChildren(parent:ObjectContainer3D, serializer:SerializerBase):void
		{
			for (var i:uint = 0; i < parent.numChildren; i++)
			{
				serializeObjectContainer(parent.getChildAt(i), serializer);
			}
		}
		
		private static function classNameFromInstance(instance:*):String
		{
			return flash.utils.getQualifiedClassName(instance).split("::").pop()
		}
		
		private static function serializeObjectContainerInternal(objectContainer:ObjectContainer3D, serializer:SerializerBase, serializeChildrenAndEnd:Boolean):void
		{
			serializer.beginObject(classNameFromInstance(objectContainer), objectContainer.name);
			serializer.writeTransform("transform", objectContainer.transform.rawData);
			if (serializeChildrenAndEnd)
			{
				serializeChildren(objectContainer, serializer);
				serializer.endObject();
			}
		}
  }
}
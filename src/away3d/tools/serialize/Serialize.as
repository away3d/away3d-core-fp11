package away3d.tools.serialize
{
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.animators.data.SkeletonAnimationSequence;
	import away3d.animators.skeleton.JointPose;
	import away3d.animators.skeleton.Skeleton;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.animators.skeleton.SkeletonPose;
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.core.base.SkinnedSubGeometry;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.SubMesh;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;

	import flash.utils.getQualifiedClassName;

	use namespace arcane;
	
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
			serializer.writeUint("mouseHitMethod", mesh.mouseHitMethod);
			serializer.writeBoolean("castsShadows", mesh.castsShadows);
			
			if (mesh.animationState)
			{
				serializeAnimationState(mesh.animationState, serializer);
			}
			
			if (mesh.material)
			{
				serializeMaterial(mesh.material, serializer);
			}
			
			if (mesh.subMeshes.length)
			{
				for each (var subMesh:SubMesh in mesh.subMeshes)
				{
					serializeSubMesh(subMesh, serializer);
				}
			}
			serializeChildren(mesh as ObjectContainer3D, serializer);
			serializer.endObject();
		}
		
		public static function serializeAnimationState(animationState:AnimationStateBase, serializer:SerializerBase):void
		{
			serializer.beginObject(classNameFromInstance(animationState), null);
			serializeAnimation(animationState.animation, serializer);
			serializer.endObject();
		}
		
		public static function serializeAnimation(animation:AnimationBase, serializer:SerializerBase):void
		{
			serializer.beginObject(classNameFromInstance(animation), null);
			serializer.endObject();
		}
		
		public static function serializeSubMesh(subMesh:SubMesh, serializer:SerializerBase):void
		{
			serializer.beginObject(classNameFromInstance(subMesh), null);
			if (subMesh.material)
			{
				serializeMaterial(subMesh.material, serializer);
			}
			if (subMesh.subGeometry)
			{
				serializeSubGeometry(subMesh.subGeometry, serializer);
			}
			serializer.endObject();
		}
		
		public static function serializeMaterial(material:MaterialBase, serializer:SerializerBase):void
		{
			serializer.beginObject(classNameFromInstance(material), material.name);

			if (material.lightPicker is StaticLightPicker) {
				serializer.writeString("lights", String(StaticLightPicker(material.lightPicker).lights));
			}
			serializer.writeBoolean("mipmap", material.mipmap);
			serializer.writeBoolean("smooth", material.smooth);
			serializer.writeBoolean("repeat", material.repeat);
			serializer.writeBoolean("bothSides", material.bothSides);
			serializer.writeString("blendMode", material.blendMode);
			serializer.writeBoolean("requiresBlending", material.requiresBlending);
			serializer.writeUint("uniqueId", material.uniqueId);
			serializer.writeUint("numPasses", material.numPasses);
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
			var skinnedSubGeometry:SkinnedSubGeometry = subGeometry as SkinnedSubGeometry;
			if (skinnedSubGeometry)
			{
				if (skinnedSubGeometry.jointWeightsData)
				{
					serializer.writeUint("numJointWeights", skinnedSubGeometry.jointWeightsData.length);
				}
				if (skinnedSubGeometry.jointIndexData)
				{
					serializer.writeUint("numJointIndexes", skinnedSubGeometry.jointIndexData.length);
				}
			}
			serializer.endObject();
		}
		
		public static function serializeSkeletonJoint(skeletonJoint:SkeletonJoint, serializer:SerializerBase):void
		{
			serializer.beginObject(classNameFromInstance(skeletonJoint), skeletonJoint.name);
      serializer.writeInt("parentIndex", skeletonJoint.parentIndex);
			serializer.writeTransform("inverseBindPose", skeletonJoint.inverseBindPose);
			serializer.endObject();
		}
		
		public static function serializeSkeleton(skeleton:Skeleton, serializer:SerializerBase):void
		{
			serializer.beginObject(classNameFromInstance(skeleton), skeleton.name);
			for each (var skeletonJoint:SkeletonJoint in skeleton.joints)
			{
				serializeSkeletonJoint(skeletonJoint, serializer);
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
			return getQualifiedClassName(instance).split("::").pop();
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
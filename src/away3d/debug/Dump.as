package away3d.debug
{
	import away3d.animators.data.SkeletonAnimationSequence;
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;
	
	use namespace arcane;
  
  import flash.utils.getQualifiedClassName;
  import away3d.animators.skeleton.SkeletonPose;
  import away3d.animators.skeleton.JointPose;

  public class Dump
  {
		public static var tabSize:uint = 2;
		
    public function Dump()
    {
    }
    
		private static function _indentString(indent:uint):String
		{
			var indentString:String = "";
			for (var i:uint = 0; i < indent; i++)
			{
				indentString += " ";
			}
			return indentString;
		}
		
    public static function dumpScene(scene:Scene3D, indent:uint):void
    {
      for (var i:uint = 0; i < scene.numChildren; i++)
      {
        var obj:ObjectContainer3D = scene.getChildAt(i);
        
        if (obj is Mesh)
        {
          dumpMesh(obj as Mesh, indent); // do not indent any extra for first level here
        }
        else
        {
          dumpObjectContainer(obj, indent, true /* dumpChildren */);  // do not indent any extra for first level here
        }
      }
    }
    
    public static function dumpChildren(parent:ObjectContainer3D, indent:uint):void
    {
      for (var i:uint = 0; i < parent.numChildren; i++)
      {
        var obj:ObjectContainer3D = parent.getChildAt(i);
        
        if (obj is Mesh)
        {
          dumpMesh(obj as Mesh, indent+tabSize);
        }
        else
        {
          dumpObjectContainer(obj, indent+tabSize, true /* dumpChildren */);
        }
      }
    }
    
    public static function dumpObjectContainer(objectContainer:ObjectContainer3D, indent:uint, callDumpChildren:Boolean = true):void
    {
      var outputString:String = _indentString(indent);
      outputString += flash.utils.getQualifiedClassName(objectContainer).split("::").pop();
      outputString += ": ";
      outputString += objectContainer.name;
      outputString += " transform: ";
      
      var matrixIndent:uint = outputString.length;
      
      for (var i:uint = 0; i < objectContainer.transform.rawData.length; i++)
      {
        outputString += objectContainer.transform.rawData[i];
        if (((i + 1) % 4) == 0)
        {
          outputString += "\n";
          for (var j:uint = 0; j < matrixIndent; j++)
          {
            outputString += " ";
          }
        }
        else
        {
          outputString += " ";
        }
      }
      
      trace(outputString);
      if (callDumpChildren)
      {
        dumpChildren(objectContainer, indent);
      }
    }
    
    public static function dumpMesh(mesh:Mesh, indent:uint):void
    {
      dumpObjectContainer(mesh as ObjectContainer3D, indent, false /* don't dumpChildren - we'll call it below */);
      
      if (mesh.geometry.subGeometries.length)
      {
        for (var i:uint = 0; i < mesh.geometry.subGeometries.length; i++)
        {
          dumpSubGeometry(mesh.geometry.subGeometries[i], indent+tabSize);
        }
      }
      
      dumpChildren(mesh as ObjectContainer3D, indent);
    }
    
    public static function dumpSubGeometry(subGeometry:SubGeometry, indent:uint):void
    {
			var outputString:String = _indentString(indent);
      outputString += flash.utils.getQualifiedClassName(subGeometry).split("::").pop();
      outputString += " numTriangles:";
      outputString += subGeometry.numTriangles;
      outputString += " numIndices:";
      outputString += subGeometry.indexData.length;
      outputString += " numVertices:";
      outputString += subGeometry.numVertices;
      if (subGeometry.UVData)
      {
        outputString += " numUVs:";
        outputString += subGeometry.UVData.length;
      }
      //      outputString += " '";
      //      outputString += this.name;
      //      outputString += "'";
      
      trace(outputString); 
    }
		
		public static function dumpJointPose(jointPose:JointPose, indent:uint):void
		{
			var outputString:String = _indentString(indent);
			outputString += "JointPose ";
			outputString += jointPose.name;
			trace(outputString);
			outputString = _indentString(indent+tabSize);
			outputString += "translation ";
			outputString += jointPose.translation;
			trace(outputString);
			outputString = _indentString(indent+tabSize);
			outputString += "orientation ";
			outputString += jointPose.orientation;
			trace(outputString);
		}
		
		public static function dumpSkeletonPose(skeletonPose:SkeletonPose, indent:uint):void
		{
			var outputString:String = _indentString(indent);
			outputString += "SkeletonPose";
			trace(outputString);
			outputString = _indentString(indent+tabSize);
			outputString += "numJointPoses";
			outputString += skeletonPose.numJointPoses;
			trace(outputString);
			for each (var jointPose:JointPose in skeletonPose.jointPoses)
			{
				dumpJointPose(jointPose, indent+tabSize);
			}
		}
		
		public static function dumpSkeletonAnimationSequence(skeletonAnimationSequence:SkeletonAnimationSequence, indent:uint):void
		{
			var outputString:String = _indentString(indent);
			outputString += "SkeletonAnimationSequence ";
			outputString += skeletonAnimationSequence.name;
			trace(outputString);
			outputString = _indentString(indent+tabSize);
			outputString += "duration";
			outputString += skeletonAnimationSequence.duration;
			trace(outputString);
			outputString = _indentString(indent+tabSize);
			outputString += "fixedFrameRate";
			outputString += skeletonAnimationSequence.fixedFrameRate;
			trace(outputString);
			outputString = _indentString(indent+tabSize);
			outputString += "looping";
			outputString += skeletonAnimationSequence.looping;
			trace(outputString);
			for each (var skeletonPose:SkeletonPose in skeletonAnimationSequence._frames)
			{
				dumpSkeletonPose(skeletonPose, indent+tabSize);
			}
		}
  }
}
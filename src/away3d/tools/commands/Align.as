package away3d.tools.commands
{
	import away3d.arcane;
	import away3d.entities.Mesh;
	import away3d.tools.utils.Bounds;
	
	use namespace arcane;
	
	/**
	* Class Aligns an arrays of Object3Ds, Vector3D's or Vertexes compaired to each other.<code>Align</code>
	*/
	public class Align {
		
		public static const X_AXIS:String = "x";
		public static const Y_AXIS:String = "y";
		public static const Z_AXIS:String = "z";
		
		public static const POSITIVE:String = "+";
		public static const NEGATIVE:String = "-";
		public static const AVERAGE:String = "av";
		
		private static var _axis:String;
		private static var _condition:String;
		
		/**
		* Aligns a series of meshes to their bounds along a given axis.
		*
		* @param	 meshes		A Vector of Mesh objects
		* @param	 axis		Represent the axis to align on.
		* @param	 condition	Can be POSITIVE ('+') or NEGATIVE ('-'), Default is POSITIVE ('+')
		*/		
		public static function alignMeshes(meshes:Vector.<Mesh>, axis:String, condition:String = POSITIVE):void
		{
			checkAxis(axis);
			checkCondition(condition);
			var base:Number;
			var bounds:Vector.<MeshBound> = getMeshesBounds(meshes);
			var i:uint;
			var prop:String = getProp();
			var mb:MeshBound;
			var m:Mesh;
			var val:Number;
			
			switch(_condition){
				case POSITIVE:
					base = getMaxBounds(bounds);
					
					for(i = 0;i<meshes.length;++i){
						m = meshes[i];
						mb = bounds[i];
						val = m[_axis];
						val -= base - mb[prop]+m[_axis];
						m[_axis] = -val;
						bounds[i] = null;
					}
					
					break;
				
				case NEGATIVE:
					base = getMinBounds(bounds);
					
					for(i = 0;i<meshes.length;++i){
						m = meshes[i];
						mb = bounds[i];
						val = m[_axis];
						val -= base + mb[prop]+m[_axis];
						m[_axis] = -val;
						bounds[i] = null;
					}
			}
			
			bounds = null;
		}
		
		/**
		* Place one or more meshes at y 0 using their min bounds
		*/
		public static function alignToFloor(meshes:Vector.<Mesh>):void
		{
			if(meshes.length == 0) return;
			
			for(var i:uint = 0;i<meshes.length;++i){
				Bounds.getMeshBounds(meshes[i]);
				meshes[i].y = Bounds.minY+ (Bounds.maxY - Bounds.minY);
			}
		}
		
		/**
		* Applies to array elements the alignment according to axis, x, y or z and a condition.
		* each element must have public x,y and z  properties. In case elements are meshes only their positions is affected. Method doesn't take in account their respective bounds
		* String condition:
		* "+" align to highest value on a given axis
		* "-" align to lowest value on a given axis
		* "" align to a given axis on 0; This is the default.
		* "av" align to average of all values on a given axis
		*
		* @param	 aObjs		Array. An array with elements with x,y and z public properties such as Mesh, Object3D, ObjectContainer3D,Vector3D or Vertex
		* @param	 axis			String. Represent the axis to align on.
		* @param	 condition	[optional]. String. Can be '+", "-", "av" or "", Default is "", aligns to given axis at 0.
		*/		
		public static function align(aObjs:Array, axis:String, condition:String = ""):void
		{
			checkAxis(axis);
			checkCondition(condition);
			var base:Number;			
			
			switch(_condition){
				case POSITIVE:
					base = getMax(aObjs, _axis);
					break;
				
				case NEGATIVE:
					base = getMin(aObjs, _axis);
					break;
				
				case AVERAGE:
					base = getAverage(aObjs, _axis);
					break;
				
				case "":
					base = 0;
			}
			
			for(var i:uint = 0;i<aObjs.length;++i)
				aObjs[i][_axis] = base;
		}
		
		/**
		* Applies to array elements a distributed alignment according to axis, x,y or z. In case elements are meshes only their positions is affected. Method doesn't take in account their respective bounds
		* each element must have public x,y and z  properties
		* @param	 aObjs		Array. An array with elements with x,y and z public properties such as Mesh, Object3D, ObjectContainer3D,Vector3D or Vertex
		* @param	 axis			String. Represent the axis to align on.
		*/		
		public static function distribute(aObjs:Array, axis:String):void
		{
			checkAxis(axis);

			var max:Number = getMax(aObjs, _axis);
			var min:Number = getMin(aObjs, _axis);
			var unit:Number = (max - min) / aObjs.length;
			aObjs.sortOn(axis, 16);
			
			var step:Number = 0;
			for(var i:uint = 0;i<aObjs.length;++i){
				aObjs[i][_axis] = min+step;
				step+=unit;
			}
		}
		
		private static function checkAxis(axis:String):void
		{
			axis = axis.substring(0, 1).toLowerCase();
			if(axis == X_AXIS || axis == Y_AXIS || axis == Z_AXIS){
				_axis = axis;
				return;
			}
			
			throw new Error("Invalid axis: string value must be 'x', 'y' or 'z'");
		}
		
		private static function checkCondition(condition:String):void
		{
			condition = condition.toLowerCase();
			var aConds:Array = [POSITIVE, NEGATIVE, "", AVERAGE];
			for(var i:uint = 0;i<aConds.length;++i){
				if(aConds[i] == condition){
					_condition = condition;
					return;
				}
			}
			
			throw new Error("Invalid condition: possible string value are '+', '-', 'av' or '' ");
		}
		
		private static function getMin(a:Array, prop:String):Number
		{
			var min:Number = Infinity;
			for(var i:uint = 0;i<a.length;++i)
				min = Math.min(a[i][prop], min);
			
			return min;
		}
		
		private static function getMax(a:Array, prop:String):Number
		{
			var max:Number = -Infinity;
			for(var i:uint = 0;i<a.length;++i)
				max = Math.max(a[i][prop], max);
			
			return max;
		}
		
		private static function getAverage(a:Array, prop:String):Number
		{
			var av:Number = 0;
			var loop:int = a.length;
			for(var i:uint = 0;i<loop;++i)
				av += a[i][prop];
			
			return av/loop;
		}
		
		private static function getMeshesBounds(meshes:Vector.<Mesh>):Vector.<MeshBound>
		{
			var mbs:Vector.<MeshBound> = new Vector.<MeshBound>();
			var mb:MeshBound;
			for(var i:uint = 0;i<meshes.length;++i){
				Bounds.getMeshBounds(meshes[i]);
				
				mb = new MeshBound();
				mb.mesh = meshes[i];
				mb.minX = Bounds.minX;
				mb.minY = Bounds.minY;
				mb.minZ = Bounds.minZ;
				mb.maxX = Bounds.maxX;
				mb.maxY = Bounds.maxY;
				mb.maxZ = Bounds.maxZ;
				mbs.push(mb);
			}
			
			return mbs;
		}
		 
		 private static function getProp():String
		{
			var prop:String;
			
			switch(_axis){
				case X_AXIS:
					prop = (_condition == POSITIVE)? "maxX" : "minX";
				break;
			
				case Y_AXIS:
					prop = (_condition == POSITIVE)? "maxY" : "minY";
				break;
				
				case Z_AXIS:
					prop = (_condition == POSITIVE)? "maxZ" : "minZ";
			}
			 
			return prop;
		}
		
		private static function getMinBounds(bounds:Vector.<MeshBound>):Number
		{
			var min:Number = Infinity;
			var mb:MeshBound;
			
			for(var i:uint = 0;i<bounds.length;++i){
				mb = bounds[i];
				switch(_axis){
					case X_AXIS:
						min = Math.min(mb.maxX+mb.mesh.x, min);
					break;
				
					case Y_AXIS:
						min = Math.min(mb.maxY+mb.mesh.y, min);
					break;
					
					case Z_AXIS:
						min = Math.min(mb.maxZ+mb.mesh.z, min);
				}
			}
			
			return min;
		}
		
		private static function getMaxBounds(bounds:Vector.<MeshBound>):Number
		{
			var max:Number = -Infinity;
			var mb:MeshBound;
			
			for(var i:uint = 0;i<bounds.length;++i){
				mb = bounds[i];
				switch(_axis){
					case X_AXIS:
						max = Math.max(mb.maxX+mb.mesh.x, max);
					break;
				
					case Y_AXIS:
						max = Math.max(mb.maxY+mb.mesh.y, max);
					break;
					
					case Z_AXIS:
						max = Math.max(mb.maxZ+mb.mesh.z, max);
				}
			}
			
			return max;
		}
		
	}
}

class MeshBound {
	import away3d.entities.Mesh;
	
	public var mesh:Mesh;
	public var minX:Number;
	public var minY:Number;
	public var minZ:Number;
	public var maxX:Number;
	public var maxY:Number;
	public var maxZ:Number;
}
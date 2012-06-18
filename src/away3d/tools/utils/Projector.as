package away3d.tools.utils
{
	import away3d.core.base.data.UV;
	import away3d.entities.Mesh;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.tools.utils.Bounds;
	
	import flash.geom.Vector3D;
	 
	public class Projector
	{
		public static const FRONT:String = "front";
		public static const BACK:String = "back";
		public static const TOP:String = "top";
		public static const BOTTOM:String = "bottom";
		public static const LEFT:String = "left";
		public static const RIGHT:String = "right";
		public static const CYLINDRICAL_X:String = "cylindricalx";
		public static const CYLINDRICAL_Y:String = "cylindricaly";
		public static const CYLINDRICAL_Z:String = "cylindricalz";
		public static const SPHERICAL:String = "spherical";
		
		private static var _width:Number;
		private static var _height:Number;
		private static var _depth:Number;
		private static var _offsetW:Number;
		private static var _offsetH:Number;
		private static var _offsetD:Number;
		private static var _orientation:String;
		private static var _center:Vector3D;
		private static var _vn:Vector3D;
		private static var _ve:Vector3D;
		private static var _vp:Vector3D;
		private static var _dir:Vector3D;
		private static var _radius:Number;
		private static var _uv:UV;
		
		private static const PI:Number = Math.PI;
		private static const DOUBLEPI:Number = Math.PI <<1;
		
		/**
		* Class remaps the uv data of a mesh
		*
		* @param	 orientation	String. Defines the projection direction and methods.
		* Note: As we use triangles, cylindrical and spherical projections might require correction,
		* as some faces, may have vertices pointing at other side of the map, causing some faces to be rendered as a whole reverted map.
		*
		* @param	 obj		ObjectContainer3D. The ObjectContainer3D to remap.
		*/
		public static function project(orientation:String, obj:ObjectContainer3D):void
		{
			_orientation = orientation.toLowerCase();
			parse(obj);
		}
		
		private static function parse(obj:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			if(obj is Mesh && obj.numChildren == 0)
				remapMesh(Mesh(obj));
				 
			for(var i:uint = 0;i<obj.numChildren;++i){
				child = obj.getChildAt(i);
				parse(child);
			}
		}
		
		private static function remapMesh(mesh:Mesh):void
		{
			var minX:Number = Infinity;
			var minY:Number = Infinity;
			var minZ:Number = Infinity;
			var maxX:Number = -Infinity;
			var maxY:Number = -Infinity;
			var maxZ:Number = -Infinity;
			
			Bounds.getMeshBounds(mesh);
			minX = Bounds.minX;
			minY = Bounds.minY;
			minZ = Bounds.minZ;
			maxX = Bounds.maxX;
			maxY = Bounds.maxY;
			maxZ = Bounds.maxZ;
			 
			if(_orientation == FRONT || _orientation == BACK || _orientation == CYLINDRICAL_X){
				_width = maxX - minX;
				_height = maxY - minY;
				_depth = maxZ - minZ;
				_offsetW = (minX>0)? -minX : Math.abs(minX);
				_offsetH= (minY>0)? -minY : Math.abs(minY);
				_offsetD= (minZ>0)? -minZ : Math.abs(minZ);	
			}
			
			if(_orientation == LEFT || _orientation == RIGHT || _orientation == CYLINDRICAL_Z){
				_width = maxZ - minZ;
				_height = maxY - minY;
				_depth = maxX - minX;
				_offsetW = (minZ>0)? -minZ : Math.abs(minZ);
				_offsetH= (minY>0)? -minY : Math.abs(minY);
				_offsetD= (minX>0)? -minX : Math.abs(minX);	
			}
			
			if(_orientation == TOP || _orientation == BOTTOM || _orientation == CYLINDRICAL_Y){
				_width = maxX - minX;
				_height = maxZ - minZ;
				_depth = maxY - minY;
				_offsetW = (minX>0)? -minX : Math.abs(minX);
				_offsetH= (minZ>0)? -minZ : Math.abs(minZ);
				_offsetD= (minY>0)? -minY : Math.abs(minY);	
			}
			 
			var geometry:Geometry = mesh.geometry;
			var geometries:Vector.<SubGeometry> = geometry.subGeometries;
			
			if(_orientation == SPHERICAL){
				if(!_center) _center = new Vector3D();
				_width = maxX - minX;
				_height = maxZ - minZ;
				_depth = maxY - minY;
				_radius = Math.max(_width,_depth,_height)+10;
				_center.x = _center.y = _center.z = .0001;
				
				remapSpherical(geometries, mesh.scenePosition);
			} else if(_orientation.indexOf("cylindrical") != -1){
				remapCylindrical(geometries, mesh.scenePosition);
			} else {
				remapLinear(geometries, mesh.scenePosition);
			}
		}
		
		private static function remapLinear(geometries:Vector.<SubGeometry>, position:Vector3D):void
		{
			var numSubGeoms:uint = geometries.length;
			var sub_geom:SubGeometry;
			
			var vertices:Vector.<Number>;
			var indices:Vector.<uint>;
			var uvs:Vector.<Number>;
			
			var i:uint;
			var j:uint;
			var xindex:uint;
			var uindex:uint;
			var indLoop:uint;
			
			var offsetU:Number;
			var offsetV:Number;
			 
			 for (i = 0; i<numSubGeoms; ++i){					 
				sub_geom = geometries[i];
				vertices = sub_geom.vertexData;
				indices = sub_geom.indexData;
				uvs = sub_geom.UVData;
				indLoop = indices.length;
				 
				switch(_orientation){
					case FRONT:
						offsetU = _offsetW+position.x;
						offsetV = _offsetH+position.y;
						for (j = 0; j<indLoop; ++j){
							xindex = indices[j]*3;
							uindex = indices[j]<<1;
							uvs[uindex] = (vertices[xindex]+offsetU)/_width;
							uvs[uindex+1] = 1- (vertices[xindex+1]+offsetV)/_height;
						}
						break;
						
					case BACK:
						offsetU = _offsetW+position.x;
						offsetV = _offsetH+position.y;
						for (j = 0; j<indLoop; ++j){
							xindex = indices[j]*3;
							uindex = indices[j]<<1;
							uvs[uindex] = 1-(vertices[xindex]+offsetU)/_width;
							uvs[uindex+1] = 1- (vertices[xindex+1]+offsetV)/_height;
						}
						break;
					
					case RIGHT:
						offsetU = _offsetW+position.z;
						offsetV = _offsetH+position.y;
						for (j = 0; j<indLoop; ++j){
							xindex = indices[j]*3 + 1;
							uindex = indices[j]<<1;
							uvs[uindex] = (vertices[xindex+1]+offsetU)/_width;
							uvs[uindex+1] = 1- (vertices[xindex]+offsetV)/_height;
						}
						break;
						
					case LEFT:
						offsetU = _offsetW+position.z;
						offsetV = _offsetH+position.y;
						for (j = 0; j<indLoop; ++j){
							xindex = indices[j]*3 + 1;
							uindex = indices[j]<<1;
							uvs[uindex] = 1-(vertices[xindex+1]+offsetU)/_width;
							uvs[uindex+1] = 1- (vertices[xindex]+offsetV)/_height;
						}
						break;
						
					case TOP:
						offsetU = _offsetW+position.x;
						offsetV = _offsetH+position.z;
						for (j = 0; j<indLoop; ++j){
							xindex = indices[j]*3;
							uindex = indices[j]<<1;
							uvs[uindex] = (vertices[xindex]+offsetU)/_width;
							uvs[uindex+1] = 1- (vertices[xindex+2]+offsetV)/_height;
						}
						break;
						
					case BOTTOM:
						offsetU = _offsetW+position.x;
						offsetV = _offsetH+position.z;
						for (j = 0; j<indLoop; ++j){
							xindex = indices[j]*3;
							uindex = indices[j]<<1;
							uvs[uindex] = 1-(vertices[xindex]+offsetU)/_width;
							uvs[uindex+1] = 1- (vertices[xindex+2]+offsetV)/_height;
						}
				}
				
				sub_geom.updateUVData(uvs);
			}
		}
		
		private static function remapCylindrical(geometries:Vector.<SubGeometry>, position:Vector3D):void
		{
			var numSubGeoms:uint = geometries.length;
			var sub_geom:SubGeometry;
			
			var vertices:Vector.<Number>;
			var indices:Vector.<uint>;
			var uvs:Vector.<Number>;
			
			var i:uint;
			var j:uint;
			var xindex:uint;
			var uindex:uint;
			var indLoop:uint;
			
			var offset:Number;
			
			 for (i = 0; i<numSubGeoms; ++i){					 
				sub_geom = geometries[i];
				vertices = sub_geom.vertexData;
				indices = sub_geom.indexData;
				uvs = sub_geom.UVData;
				indLoop = indices.length;
				
				switch(_orientation){

					case CYLINDRICAL_X:
					 
						offset = _offsetW+position.x;
						for (j = 0; j<indLoop; j+=3){
							xindex = indices[j]*3;
							uindex = indices[j]<<1;
							uvs[uindex] = (vertices[xindex]+offset)/_width;
							uvs[uindex+1] = (PI + Math.atan2( vertices[xindex+1], vertices[xindex+2]))/DOUBLEPI;
							
							xindex = indices[j+1]*3;
							uindex = indices[j+1]<<1;
							uvs[uindex] = (vertices[xindex]+offset)/_width;
							uvs[uindex+1] = (PI + Math.atan2( vertices[xindex+1], vertices[xindex+2]))/DOUBLEPI;
							
							xindex = indices[j+2]*3;
							uindex = indices[j+2]<<1;
							uvs[uindex] = (vertices[xindex]+offset)/_width;
							uvs[uindex+1] = (PI + Math.atan2( vertices[xindex+1], vertices[xindex+2]))/DOUBLEPI;
						}
						break;
						
					case CYLINDRICAL_Y:
						offset = _offsetD+position.y;
						for (j = 0; j<indLoop; j+=3){
							xindex = indices[j]*3;
							uindex = indices[j]<<1;
							uvs[uindex] = (PI + Math.atan2(vertices[xindex], vertices[xindex+2]))/DOUBLEPI;
							uvs[uindex+1]  = 1- (vertices[xindex+1]+offset)/_depth;
							 
							xindex = indices[j+1]*3;
							uindex = indices[j+1]<<1;
							uvs[uindex] =  (PI + Math.atan2(vertices[xindex], vertices[xindex+2]))/DOUBLEPI;
							uvs[uindex+1]  = 1- (vertices[xindex+1]+offset)/_depth;
							 
							xindex = indices[j+2]*3;
							uindex = indices[j+2]<<1;
							uvs[uindex] = (PI + Math.atan2(vertices[xindex], vertices[xindex+2]))/DOUBLEPI;
							uvs[uindex+1]  = 1- (vertices[xindex+1]+offset)/_depth;
						}
						break;
						
					case CYLINDRICAL_Z:
						offset = _offsetW+position.z;
						for (j = 0; j<indLoop; j+=3){
							xindex = indices[j]*3;
							uindex = indices[j]<<1;
							uvs[uindex+1]  = (vertices[xindex+2]+offset)/_width;
							uvs[uindex] = (PI + Math.atan2(vertices[xindex+1], vertices[xindex]))/DOUBLEPI;
							xindex = indices[j+1]*3;
							uindex = indices[j+1]<<1;
							uvs[uindex+1]  = (vertices[xindex+2]+offset)/_width;
							uvs[uindex] = (PI + Math.atan2(vertices[xindex+1], vertices[xindex]))/DOUBLEPI;
							xindex = indices[j+2]*3;
							uindex = indices[j+2]<<1;
							uvs[uindex+1]  = (vertices[xindex+2]+offset)/_width;
							uvs[uindex] = (PI + Math.atan2(vertices[xindex+1], vertices[xindex]))/DOUBLEPI;
						}
						
				}
				
				sub_geom.updateUVData(uvs);
				
			}
		}
		 
		private static function remapSpherical(geometries:Vector.<SubGeometry>, position:Vector3D):void
		{
			// TODO: not used
			position = position;
			var numSubGeoms:uint = geometries.length;
			var sub_geom:SubGeometry;
			
			var vertices:Vector.<Number>;
			var indices:Vector.<uint>;
			var uvs:Vector.<Number>;
			
			var i:uint;
			var j:uint;
			var xindex:uint;
			var uindex:uint;
			var indLoop:uint;
			 
			 for (i = 0; i<numSubGeoms; ++i){					 
				sub_geom = geometries[i];
				vertices = sub_geom.vertexData;
				indices = sub_geom.indexData;
				uvs = sub_geom.UVData;
				indLoop = indices.length;
			
				 for (j = 0; j<indLoop; ++j){
					xindex = indices[j]*3;
					uindex = indices[j]<<1;
				 
					projectVertex(vertices[xindex], vertices[xindex+1], vertices[xindex+2]);
					uvs[uindex] = _uv.u;
					uvs[uindex+1] = _uv.v;
				}
				sub_geom.updateUVData(uvs);
			}
		}
		 
		private static function projectVertex(x:Number, y:Number, z:Number):void
		{
			if(!_dir){
				_dir = new Vector3D(x , y, z);
				_uv = new UV();
				_vn = new Vector3D(0,-1,0);
				_ve = new Vector3D(.1,0,.9);
				_vp = new Vector3D();
			} else {
				_dir.x = x;
				_dir.y = y;
				_dir.z = z;
			}
			 
			_dir.normalize();
			 
			_vp.x = _dir.x*_radius;
			_vp.y = _dir.y*_radius;
			_vp.z = _dir.z*_radius;			
			_vp.normalize();
			
			var phi:Number = Math.acos( -_vn.dotProduct(_vp) );
			
			_uv.v = phi / PI;
			
			var theta:Number = Math.acos( _vp.dotProduct(_ve) / Math.sin(phi) ) / DOUBLEPI;
 
			var _crp:Vector3D = _vn.crossProduct(_ve);
			
			if (_crp.dotProduct(_vp) < 0)
				_uv.u = 1 - theta;
			else
				_uv.u = theta;
			 
		} 
		 
	}
}
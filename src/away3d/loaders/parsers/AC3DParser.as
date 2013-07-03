package away3d.loaders.parsers
{
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.Geometry;
	import away3d.core.base.data.UV;
	import away3d.core.base.data.Vertex;
	import away3d.entities.Mesh;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.loaders.parsers.utils.ParserUtil;
	import away3d.materials.ColorMaterial;
	import away3d.materials.ColorMultiPassMaterial;
	import away3d.materials.MaterialBase;
	import away3d.materials.TextureMaterial;
	import away3d.materials.TextureMultiPassMaterial;
	import away3d.materials.utils.DefaultMaterialManager;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;
	
	/**
	 * AC3DParser provides a parser for the AC3D data type.
	 *
	 * unsupported tags: "numsurf","crease","texrep","refs lines of","url","data" and "numvert lines of":
	 */
	public class AC3DParser extends ParserBase
	{
		private const LIMIT:uint = 65535;
		private const CR:String = String.fromCharCode(10);
		
		private var _textData:String;
		private var _startedParsing:Boolean;
		private var _activeContainer:ObjectContainer3D;
		private var _meshList:Vector.<Mesh>;
		private var _trunk:Array;
		private var _containersList:Array = [];
		private var _tmpcontainerpos:Vector3D = new Vector3D(0.0, 0.0, 0.0);
		private var _tmpos:Vector3D = new Vector3D(0.0, 0.0, 0.0);
		private var _kidsCount:int = 0;
		private var _activeMesh:Mesh;
		private var _vertices:Vector.<Vertex>;
		private var _uvs:Array;
		private var _parsesV:Boolean;
		private var _isQuad:Boolean;
		private var _quadCount:int;
		private var _lastType:String = "";
		private var _charIndex:uint;
		private var _oldIndex:uint;
		private var _stringLen:uint;
		private var _materialList:Array;
		
		private var _groupCount:uint;
		
		/**
		 * Creates a new AC3DParser object.
		 */
		
		public function AC3DParser()
		{
			super(ParserDataFormat.PLAIN_TEXT);
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension:String):Boolean
		{
			extension = extension.toLowerCase();
			return extension == "ac";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data:*):Boolean
		{
			var ba:ByteArray;
			var str:String;
			
			ba = ParserUtil.toByteArray(data);
			if (ba) {
				ba.position = 0;
				str = ba.readUTFBytes(4);
			} else
				str = (data is String)? String(data).substr(0, 4) : null;
			
			if (str == 'AC3D')
				return true;
			
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependency(resourceDependency:ResourceDependency):void
		{
			var mesh:Mesh;
			var asset:Texture2DBase;
			
			if (resourceDependency.assets.length == 1) {
				asset = resourceDependency.assets[0] as Texture2DBase;
				mesh = retrieveMeshFromID(resourceDependency.id);
			}
			if (mesh && asset) {
				if (materialMode < 2)
					TextureMaterial(mesh.material).texture = asset;
				else
					TextureMultiPassMaterial(mesh.material).texture = asset;
			}
		}
		
		override arcane function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{
			//handled with default material
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function proceedParsing():Boolean
		{
			var line:String;
			
			if (!_startedParsing) {
				_groupCount = 0;
				_activeContainer = null;
				
				_textData = getTextData();
				var re:RegExp = new RegExp(String.fromCharCode(13), "g");
				_textData = _textData.replace(re, "");
				_materialList = [];
				_startedParsing = true;
				
				_meshList = new Vector.<Mesh>();
				_stringLen = _textData.length;
				_charIndex = _textData.indexOf(CR, 0);
				_oldIndex = _charIndex;
					//skip the version header line
					//version ac3d --> AC3D[b] --> hex value for file format
					//If we once need to check version in future
					//line = _textData.substring(0, _charIndex-1);
					//var version:String = line.substring(line.length-1, line.length);
					//ac3d version = getVersionFromHex(version);
			}
			
			var nameid:String;
			var refscount:int;
			var tUrl:String = "";
			//var m:Mesh;
			var cont:ObjectContainer3D;
			var nextObject:uint;
			var nextSurface:uint;
			
			while (_charIndex < _stringLen && hasTime()) {
				
				_charIndex = _textData.indexOf(CR, _oldIndex);
				
				if (_charIndex == -1)
					_charIndex = _stringLen;
				
				line = _textData.substring(_oldIndex, _charIndex);
				
				if (line.indexOf("texture ") != -1)
					tUrl = line.substring(line.indexOf('"') + 1, line.length - 1);
				_trunk = line.replace("  ", " ").replace("  ", " ").replace("  ", " ").split(" ");
				
				if (_charIndex != _stringLen)
					_oldIndex = _charIndex + 1;
				
				switch (_trunk[0]) {
					case "MATERIAL":
						generateMaterial(line);
						break;
					case "numsurf": //integer
					case "crease": //45.000000. 
					case "texrep": // %f %f tiling
					case "refs lines of":
					case "url":
					case "data":
					case "numvert lines of":
					case "SURF": //0x30
						break;
					
					case "kids": //howmany children in the upcomming object. Probably need it later on, to couple with container/group generation
						_kidsCount = parseInt(_trunk[1]);
						
						if (_lastType == "group")
							_groupCount = _kidsCount;
						
						break;
					
					case "OBJECT":
						
						if (_activeMesh != null) {
							buildMeshGeometry(_activeMesh);
							_tmpos.x = _tmpos.y = _tmpos.z = 0;
							_activeMesh = null;
						}
						
						if (_trunk[1] == "world")
							_lastType = "world";
						
						else if (_trunk[1] == "group") {
							cont = new ObjectContainer3D();
							if (_activeContainer)
								_activeContainer.addChild(cont);
							cont.name = "c_" + _containersList.length;
							_containersList.push(cont);
							_activeContainer = cont;
							
							finalizeAsset(cont);
							
							_lastType = "group";
							
						} else {
							//validate if it's a definition that we can use
							nextObject = _textData.indexOf("OBJECT", _oldIndex);
							nextSurface = _textData.indexOf("numsurf", _oldIndex);
							
							if (nextSurface == -1 || nextSurface > _stringLen) {
								//we're done here, we do not need the following stuff anyway
								_charIndex = _oldIndex = _stringLen;
								break;
								
							} else if (nextObject < nextSurface) {
								//some floating vertex/line lets skip this part
								_charIndex = _oldIndex = nextObject - 1;
								break;
							}
						}
						
						if (_trunk[1] == "poly") {
							var geometry:Geometry = new Geometry();
							_activeMesh = new Mesh(geometry, null);
							if (_vertices)
								cleanUpBuffers();
							_vertices = new Vector.<Vertex>();
							_uvs = [];
							_activeMesh.name = "m_" + _meshList.length;
							_meshList[_meshList.length] = _activeMesh;
							//in case of groups, numvert might not be there
							_parsesV = true;
							_lastType = "poly";
						}
						break;
					
					case "name":
						nameid = line.substring(6, line.length - 1);
						if (_lastType == "poly")
							_activeMesh.name = nameid;
						else
							_activeContainer.name = nameid;
						break;
					
					case "numvert":
						if (parseInt(_trunk[1]) >= 3)
							_parsesV = true;
						break;
					
					case "refs":
						refscount = parseInt(_trunk[1]);
						if (refscount == 4) {
							_isQuad = true;
							_quadCount = 0;
						} else if (refscount < 3 || refscount > 4)
							continue;
						else
							_isQuad = false;
						_parsesV = false;
						break;
					
					case "mat":
						if (!_activeMesh.material)
							_activeMesh.material = _materialList[ parseInt(_trunk[1]) ];
						break;
					
					case "texture":
						if (materialMode < 2)
							_activeMesh.material = new TextureMaterial(DefaultMaterialManager.getDefaultTexture());
						else
							_activeMesh.material = new TextureMultiPassMaterial(DefaultMaterialManager.getDefaultTexture());
						_activeMesh.material.name = "m_" + _activeMesh.name;
						addDependency(String(_meshList.length - 1), new URLRequest(tUrl));
						break;
					
					case "loc": //%f %f %f
						/*
						 The translation of the object.  Effectively the definition of the centre of the object.  This is
						 relative to the parent - i.e. not a global position.  If this is not found then
						 the default centre of the object will be 0, 0, 0.
						 */
						
						if (_lastType == "group") {
							_tmpcontainerpos.x = parseFloat(_trunk[1]);
							_tmpcontainerpos.y = parseFloat(_trunk[2]);
							_tmpcontainerpos.z = parseFloat(_trunk[3]);
							
						} else {
							_tmpos.x = parseFloat(_trunk[1]);
							_tmpos.y = parseFloat(_trunk[2]);
							_tmpos.z = parseFloat(_trunk[3]);
						}
					
					case "rot": //%f %f %f  %f %f %f  %f %f %f
						/*The 3x3 rotation matrix for this objects vertices.  Note that the rotation is relative
						 to the object's parent i.e. it is not a global rotation matrix.  If this token
						 is not specified then the default rotation matrix is 1 0 0, 0 1 0, 0 0 1 */
						//Not required as ac 3d applys rotation to _vertices during export
						//Might be required for containers later on
						//matrix = new Matrix3D();
						
						/*matrix.rawData = Vector.<Number>([parseFloat(_trunk[1]),parseFloat(_trunk[2]),parseFloat(_trunk[3]),0,
						 parseFloat(_trunk[4]),parseFloat(_trunk[5]),parseFloat(_trunk[6]),0,
						 parseFloat(_trunk[7]),parseFloat(_trunk[8]),parseFloat(_trunk[9]),0,
						 0,0,0,1]);*/
						
						//_activeMesh.transform = matrix;
						break;
					
					default:
						if (_trunk[0] == "")
							break;
						
						if (_parsesV)
							_vertices.push(new Vertex(-(parseFloat(_trunk[0])), parseFloat(_trunk[1]), parseFloat(_trunk[2])));
						
						else {
							
							if (_isQuad) {
								_quadCount++;
								if (_quadCount == 4) {
									_uvs.push(_uvs[_uvs.length - 2], _uvs[_uvs.length - 1]);
									_uvs.push(parseInt(_trunk[0]), new UV(parseFloat(_trunk[1]), 1 - parseFloat(_trunk[2])));
									_uvs.push(_uvs[_uvs.length - 10], _uvs[_uvs.length - 9]);
									
								} else
									_uvs.push(parseInt(_trunk[0]), new UV(parseFloat(_trunk[1]), 1 - parseFloat(_trunk[2])));
								
							} else
								_uvs.push(parseInt(_trunk[0]), new UV(parseFloat(_trunk[1]), 1 - parseFloat(_trunk[2])));
						}
				}
				
			}
			
			if (_charIndex >= _stringLen) {
				
				if (_activeMesh != null)
					buildMeshGeometry(_activeMesh);
				
				//finalizeAsset(_container);
				cleanUP();
				
				return PARSING_DONE;
			}
			
			return MORE_TO_PARSE;
		}
		
		private function checkGroup(mesh:Mesh):void
		{
			mesh = mesh;
			if (_groupCount > 0)
				_groupCount--;
			
			if (_activeContainer)
				_activeContainer.addChild(_activeMesh);
			
			if (_activeContainer && _groupCount == 0) {
				_activeContainer = null;
				_tmpcontainerpos.x = _tmpcontainerpos.y = _tmpcontainerpos.z = 0;
			}
		}
		
		private function buildMeshGeometry(mesh:Mesh):void
		{
			var v0:Vertex;
			var v1:Vertex;
			var v2:Vertex;
			
			var uv0:UV;
			var uv1:UV;
			var uv2:UV;
			
			var vertices:Vector.<Number> = new Vector.<Number>();
			var indices:Vector.<uint> = new Vector.<uint>();
			var uvs:Vector.<Number> = new Vector.<Number>();
			
			var subGeomsData:Array = [vertices, indices, uvs];
			//var j:uint;
			var dic:Dictionary = new Dictionary();
			var ref:String;
			
			for (var i:uint = 0; i < _uvs.length; i += 6) {
				
				if (indices.length + 3 > LIMIT) {
					vertices = new Vector.<Number>();
					indices = new Vector.<uint>();
					uvs = new Vector.<Number>();
					subGeomsData.push(vertices, indices, uvs);
					dic = null;
					dic = new Dictionary();
				}
				
				uv0 = _uvs[i + 1];
				uv1 = _uvs[i + 3];
				uv2 = _uvs[i + 5];
				
				v0 = _vertices[_uvs[i]];
				v1 = _vertices[_uvs[i + 2]];
				v2 = _vertices[_uvs[i + 4]];
				
				//face order other than away
				ref = v1.toString() + uv1.toString();
				if (dic[ref])
					indices.push(dic[ref]);
				else {
					dic[ref] = vertices.length/3;
					indices.push(dic[ref]);
					vertices.push(v1.x, v1.y, v1.z);
					uvs.push(uv1.u, uv1.v);
				}
				
				ref = v0.toString() + uv0.toString();
				if (dic[ref])
					indices.push(dic[ref]);
				else {
					dic[ref] = vertices.length/3;
					indices.push(dic[ref]);
					vertices.push(v0.x, v0.y, v0.z);
					uvs.push(uv0.u, uv0.v);
				}
				
				ref = v2.toString() + uv2.toString();
				if (dic[ref])
					indices.push(dic[ref]);
				else {
					dic[ref] = vertices.length/3;
					indices.push(dic[ref]);
					vertices.push(v2.x, v2.y, v2.z);
					uvs.push(uv2.u, uv2.v);
				}
			}
			
			var sub_geom:CompactSubGeometry;
			var geom:Geometry = mesh.geometry;
			
			for (i = 0; i < subGeomsData.length; i += 3) {
				sub_geom = new CompactSubGeometry();
				sub_geom.fromVectors(subGeomsData[i], subGeomsData[i + 2], null, null);
				sub_geom.updateIndexData(subGeomsData[i + 1]);
				geom.addSubGeometry(sub_geom);
			}
			
			mesh.x = -_tmpos.x;
			mesh.y = _tmpos.y;
			mesh.z = _tmpos.z;
			
			mesh.x -= _tmpcontainerpos.x;
			mesh.y += _tmpcontainerpos.y;
			mesh.z += _tmpcontainerpos.z;
			
			checkGroup(_activeMesh);
			
			finalizeAsset(mesh);
			
			dic = null;
		}
		
		private function retrieveMeshFromID(id:String):Mesh
		{
			if (_meshList[parseInt(id)])
				return _meshList[parseInt(id)];
			
			return null;
		}
		
		/*
		 private function getVersionFromHex(char:String):int
		 {
		 switch (char)
		 {
		 case "A":
		 case "a":
		 return 10;
		 case "B":
		 case "b":
		 return 11;
		 case "C":
		 case "c":
		 return 12;
		 case "D":
		 case "d":
		 return 13;
		 case "E":
		 case "e":
		 return 14;
		 case "F":
		 case "f":
		 return 15;
		 default:
		 return new Number(char);
		 }
		 }
		 *
		 */
		
		private function generateMaterial(materialString:String):void
		{
			_materialList.push(parseMaterialLine(materialString));
		}
		
		private function parseMaterialLine(materialString:String):MaterialBase
		{
			var trunk:Array = materialString.split(" ");
			
			var color:uint = 0x000000;
			var name:String = "";
			var ambient:Number = 0;
			var specular:Number = 0;
			var gloss:Number = 0;
			var alpha:Number = 0;
			
			for (var i:uint = 0; i < trunk.length; ++i) {
				
				if (trunk[i] == "")
					continue;
				
				if (trunk[i].indexOf("\"") != -1 || trunk[i].indexOf("\'") != -1) {
					name = trunk[i].substring(1, trunk[i].length - 1);
					continue;
				}
				
				switch (trunk[i]) {
					case "rgb":
						var r:uint = (parseFloat(trunk[i + 1])*255);
						var g:uint = (parseFloat(trunk[i + 2])*255);
						var b:uint = (parseFloat(trunk[i + 3])*255);
						i += 3;
						color = r << 16 | g << 8 | b;
						break;
					
					case "amb":
						ambient = parseFloat(trunk[i + 1]);
						i += 2;
						break;
					
					case "spec":
						specular = parseFloat(trunk[i + 1]);
						i += 2;
						break;
					
					case "shi":
						gloss = parseFloat(trunk[i + 1])/255;
						i += 2;
						break;
					
					case "trans":
						alpha = (1 - parseFloat(trunk[i + 1]));
						break;
				}
			}
			
			var colorMaterial:MaterialBase;
			
			if (materialMode < 2) {
				colorMaterial = new ColorMaterial(0xFFFFFF);
				ColorMaterial(colorMaterial).name = name;
				ColorMaterial(colorMaterial).color = color;
				ColorMaterial(colorMaterial).ambient = ambient;
				ColorMaterial(colorMaterial).specular = specular;
				ColorMaterial(colorMaterial).gloss = gloss;
				ColorMaterial(colorMaterial).alpha = alpha;
			} else {
				colorMaterial = new ColorMultiPassMaterial(0xFFFFFF);
				ColorMultiPassMaterial(colorMaterial).name = name;
				ColorMultiPassMaterial(colorMaterial).color = color;
				ColorMultiPassMaterial(colorMaterial).ambient = ambient;
				ColorMultiPassMaterial(colorMaterial).specular = specular;
				ColorMultiPassMaterial(colorMaterial).gloss = gloss;
					//ColorMultiPassMaterial(colorMaterial).alpha=alpha;
			}
			return colorMaterial;
		}
		
		private function cleanUP():void
		{
			_materialList = null;
			cleanUpBuffers();
		}
		
		private function cleanUpBuffers():void
		{
			for (var i:uint = 0; i < _vertices.length; ++i)
				_vertices[i] = null;
			
			for (i = 0; i < _uvs.length; ++i)
				_uvs[i] = null;
			
			_vertices = null;
			_uvs = null;
		}
	
	}
}

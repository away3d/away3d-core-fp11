package away3d.loaders.parsers
{
	import away3d.materials.utils.DefaultMaterialManager;
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.data.UV;
	import away3d.core.base.data.Vertex;
	import away3d.entities.Mesh;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.loaders.parsers.utils.ParserUtil;
	import away3d.materials.TextureMaterial;
	import away3d.materials.ColorMaterial;
	import away3d.textures.BitmapTexture;
	import away3d.textures.Texture2DBase;
	
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	use namespace arcane;
	
	/**
	 * AC3DParser provides a parser for the AC3D data type.
	 * 
	 * unsupported tags at this state: "MATERIAL", "numsurf","kids","crease","texrep","refs lines of","url","data" and "numvert lines of":
	 */
	public class AC3DParser extends ParserBase
	{
		private const LIMIT:uint = 196605;
		
		private var _textData:String;
		private var _startedParsing : Boolean;
		private var _container:ObjectContainer3D;
		private var _activeContainer:ObjectContainer3D;
		private var _meshList:Vector.<Mesh>;
		private var _inited:Boolean;
		private var _trunk:Array;
		private var _containersList:Array = [];
		private var _tmpos:Vector3D = new Vector3D(0.0,0.0,0.0);
		private var _kidsCount:int = 0;
		private var _activeMesh:Mesh;
		private var _vertices:Vector.<Vertex>;
		private var _indices:Vector.<uint>;
		private var _uvs:Array;
		private var _parsesV:Boolean;
		private var _isQuad:Boolean;
		private var _quadCount:int;
		private var _lastType:String = "";
		private var _charIndex:uint;
		private var _oldIndex:uint;
		private var _stringLen:uint;
		private var _materialList:Array;
		
		/**
		 * Creates a new AC3DParser object.
		 * @param uri The url or id of the data or file to be parsed.
		 * @param extra The holder for extra contextual data that the parser might need.
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
		public static function supportsType(extension : String) : Boolean
		{
			extension = extension.toLowerCase();
			return extension == "ac";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data : *) : Boolean
		{
			var ba : ByteArray;
			var str : String;
			
			ba = ParserUtil.toByteArray(data);
			if (ba) {
				ba.position = 0;
				str = ba.readUTFBytes(4);
			}
			else {
				str = (data is String)? String(data).substr(0, 4) : null;
			}
			
			if (str == 'AC3D') return true;
			
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependency(resourceDependency:ResourceDependency):void
		{
			var mesh : Mesh;
			var asset : Texture2DBase;
			
			if (resourceDependency.assets.length == 1) {
				asset = resourceDependency.assets[0] as Texture2DBase;
				mesh = retrieveMeshFromID(resourceDependency.id);
			}
			
			if(mesh && asset)
				TextureMaterial(mesh.material).texture = asset;
		}
		
		override arcane function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{
			//handled with default material
		}
		 
		/**
		 * @inheritDoc
		 */
		protected override function proceedParsing() : Boolean
		{
			var line:String;
			var creturn:String = String.fromCharCode(10);
			
			// TODO: Remove root container (if it makes sense for this format) and
			// instead return each asset individually using finalizeAsset()
			if (!_container)
				_container = new ObjectContainer3D();
			
			if(!_startedParsing) {
				_textData = getTextData();
				var re:RegExp = new RegExp(String.fromCharCode(13),"g");
				_textData = _textData.replace(re, "");
				_materialList = [];
				_startedParsing = true;
			}
			
			if(!_inited){
				_inited = true;
				_meshList = new Vector.<Mesh>();
				_stringLen = _textData.length;
				_charIndex = _textData.indexOf(creturn, 0);
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
			var m:Mesh;
			var cont:ObjectContainer3D;
			
			while(_charIndex<_stringLen && hasTime()){
				
				_charIndex = _textData.indexOf(creturn, _oldIndex);
				
				if(_charIndex == -1)
					_charIndex = _stringLen;
				
				line = _textData.substring(_oldIndex, _charIndex);
				if(line.indexOf("texture ") != -1) tUrl = line.substring(line.indexOf('"')+1, line.length-1);
				_trunk = line.replace("  "," ").replace("  "," ").replace("  "," ").split(" ");
				
				if(_charIndex != _stringLen)
					_oldIndex = _charIndex+1;
				
				switch (_trunk[0])
				{
					case "MATERIAL":
						generateMaterial(line);
						break;
					case "numsurf"://integer
					case "crease"://45.000000. 
					case "texrep":// %f %f tiling
					case "refs lines of":
					case "url":
					case "data":
					case "numvert lines of":
					case "SURF"://0x30
						break;
					
					case "kids"://howmany children in the upcomming object. Probably need it later on, to couple with container/group generation
						_kidsCount = parseInt(_trunk[1]);
						break;
					
					case "OBJECT":
					
						if(_activeMesh != null){
							buildMeshGeometry(_activeMesh);
							_tmpos.x = _tmpos.y = _tmpos.z = 0;
							_activeMesh = null;
						}
						
						if(_trunk[1] == "world"){
							_lastType = "world";
							_activeContainer = _container;
						}
						
						if(_trunk[1] == "poly"){
							var geometry:Geometry = new Geometry();
							_activeMesh = new Mesh(geometry, null );
							if(_vertices) cleanUpBuffers();
							_vertices = new Vector.<Vertex>();
							_indices = new Vector.<uint>();
							_uvs = [];
							_activeMesh.name = "m_"+_meshList.length;
							_meshList[_meshList.length] = _activeMesh;
							//in case of groups, numvert might not be there
							_parsesV = true;
							_lastType = "poly";
						}
						
						if(_trunk[1] == "group"){
							cont = new ObjectContainer3D();
							_activeContainer.addChild(cont);
							cont.name = "c_"+_containersList.length;
							_containersList.push(cont);
							_activeContainer = cont;
							_lastType = "group";
						}
						break;
					
					case "name":
						nameid = line.substring(6, line.length-1);
						if(_lastType == "poly"){
							_activeMesh.name = nameid;
						} else{
							_activeContainer.name = nameid;
						}
						break;
					
					case "numvert":
						_parsesV = true;
						break;
					
					case "refs":
						refscount = parseInt(_trunk[1]);
						if(refscount == 4){
							_isQuad = true;
							_quadCount = 0;
						} else if( refscount<3 || refscount > 4){
							trace("AC3D Parser: Unsupported polygon type with "+refscount+" sides found. Triangulate in AC3D!");
							continue;
						} else{
							_isQuad = false;
						}
						_parsesV = false;
						break;
					
					case "mat":
						if(!_activeMesh.material)
							_activeMesh.material = _materialList[ parseInt(_trunk[1]) ];
						break;
					
					case "texture":
						_activeMesh.material = DefaultMaterialManager.getDefaultMaterial();
						addDependency(String(_meshList.length-1), new URLRequest(tUrl));
						break;
					
					case "loc"://%f %f %f
						/*
						The translation of the object.  Effectively the definition of the centre of the object.  This is
						relative to the parent - i.e. not a global position.  If this is not found then
						the default centre of the object will be 0, 0, 0.
						*/
						_tmpos.x = parseFloat(_trunk[1]);
						_tmpos.y = parseFloat(_trunk[2]);
						_tmpos.z = parseFloat(_trunk[3]);
					
					case "rot"://%f %f %f  %f %f %f  %f %f %f
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
						if(_trunk[0] == "")
							break;
						
						if(_parsesV){
							_vertices.push(new Vertex( -(parseFloat(_trunk[0])), parseFloat(_trunk[1]), parseFloat(_trunk[2])));
							
						} else {
							
							if(_isQuad){
								_quadCount++;
								if(_quadCount == 4){
									_indices.push(_indices[_indices.length-1]);
									_uvs.push(_uvs[_uvs.length-2], _uvs[_uvs.length-1]);
									_indices.push(parseInt(_trunk[0]));
									_uvs.push(parseInt(_trunk[0]), new UV(parseFloat(_trunk[1]), 1-parseFloat(_trunk[2])));
									_indices.push(_indices[_indices.length-5]);
									_uvs.push(_uvs[_uvs.length-10], _uvs[_uvs.length-9]);
									
								} else {
									_indices.push(parseInt(_trunk[0]));
									_uvs.push(parseInt(_trunk[0]), new UV(parseFloat(_trunk[1]), 1-parseFloat(_trunk[2])));
								}
								
							} else {
								_indices.push(parseInt(_trunk[0]));
								_uvs.push(parseInt(_trunk[0]), new UV(parseFloat(_trunk[1]), 1-parseFloat(_trunk[2])));
							}
						}
				}
				
			}
			
			if(_charIndex >= _stringLen){
				
				if(_activeMesh != null)
					buildMeshGeometry(_activeMesh);
				
				finalizeAsset(_container);
				
				cleanUP();
				
				return PARSING_DONE;
			} 
			
			return MORE_TO_PARSE;
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
			var vuv:Vector.<Number> = new Vector.<Number>();
			var index:uint = 0;
			var vertLength:uint ;
			
			var subGeomsData:Array = [vertices,indices,vuv];
			
			var j:uint;
			
			for (var i:uint = 0;i<_uvs.length;i+=6){
				
				if(vertLength+9 > LIMIT ){
					index = 0;
					vertLength = 0;
					vertices = new Vector.<Number>();
					indices = new Vector.<uint>();
					vuv = new Vector.<Number>();
					subGeomsData.push(vertices,indices,vuv);
				}
				
				uv0 = _uvs[i+1];
				uv1 = _uvs[i+3];
				uv2 = _uvs[i+5];
				
				v0 = _vertices[_uvs[i]];
				v1 = _vertices[_uvs[i+2]];
				v2 = _vertices[_uvs[i+4]];
				
				vertices.push(v1.x, v1.y, v1.z, v0.x, v0.y, v0.z, v2.x, v2.y, v2.z);
				
				for(j=0; j<3;++j){
					indices[index] = index;
					index++;
				}
				
				vuv.push(uv1.u, uv1.v, uv0.u, uv0.v, uv2.u, uv2.v);
				vertLength+=9;
			}
			
			var sub_geom:SubGeometry;
			var geom:Geometry = mesh.geometry;
			
			for(i=0;i<subGeomsData.length;i+=3){
				sub_geom = new SubGeometry();
				geom.addSubGeometry(sub_geom);
				sub_geom.updateVertexData(subGeomsData[i]);
				sub_geom.updateIndexData(subGeomsData[i+1]);
				sub_geom.updateUVData(subGeomsData[i+2]);
			}
			
			_activeContainer.addChild(mesh);
			
			mesh.x = -_tmpos.x;
			mesh.y = _tmpos.y;
			mesh.z = _tmpos.z;
			
			finalizeAsset(mesh);
		}
		
		private function retrieveMeshFromID(id:String):Mesh
		{
			if(_meshList[parseInt(id)]) return _meshList[parseInt(id)];
			
			return null;
		}
		 
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

		private function generateMaterial(materialString:String):void
		{	
			_materialList.push(parseMaterialLine(materialString));
		}
		
		private function parseMaterialLine(materialString:String):ColorMaterial
		{
			var trunk:Array = materialString.split(" ");
			var colorMaterial:ColorMaterial = new ColorMaterial(0xFFFFFF);

			for(var i:uint = 0;i<trunk.length;++i){
				
				if(trunk[i] == "") continue;
				
				if(trunk[i].indexOf("\"") != -1 || trunk[i].indexOf("\'") != -1){
					colorMaterial.name = trunk[i].substring(1, trunk[i].length-1);
					continue;
				}
				
				switch(trunk[i]){
					case "rgb":
						var r:uint = (parseFloat(trunk[i+1])*255);
						var g:uint = (parseFloat(trunk[i+2])*255);
						var b:uint = (parseFloat(trunk[i+3])*255);
						i+=3;
						colorMaterial.color = r << 16| g << 8 | b;
					break;
					
					case "amb":
						colorMaterial.ambient = parseFloat(trunk[i+1]);
						i+=2;
					break;
					
					case "spec":
						colorMaterial.specular = parseFloat(trunk[i+1]);
						i+=2;
					break;
					
					case "shi":
						colorMaterial.gloss = parseFloat(trunk[i+1])/255;
						i+=2;
					break;
					
					case "trans":
						colorMaterial.alpha = (1-parseFloat(trunk[i+1]));
					break;
				}
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
			for(var i:uint = 0;i<_vertices.length;++i)
				_vertices[i] = null;
			
			for(i = 0;i<_uvs.length;++i)
				_uvs[i] = null;
			
			_vertices = null;
			_uvs = null;
		}
						
	}
}
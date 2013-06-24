package away3d.loaders.parsers
{
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import away3d.arcane;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.Geometry;
	import away3d.entities.Mesh;
	import away3d.entities.SegmentSet;
	import away3d.loaders.parsers.utils.ParserUtil;
	import away3d.materials.ColorMaterial;
	import away3d.materials.ColorMultiPassMaterial;
	import away3d.materials.MaterialBase;
	import away3d.primitives.LineSegment;
	
	use namespace arcane;
	
	/**
	 * DXFParser provides a parser for the dxf 3D renderable data.
	 * supported blocks type: FACEDATA, LINE. Color from dxf color table is set where index is encountered
	 * POLYLINE(64 polyface mesh) and VERTEX.
	 */
	
	public class DXFParser extends ParserBase
	{
		private const LIMIT:uint = 65535;
		private const SETLIMIT:uint = 17872;
		private const CR:String = String.fromCharCode(10);
		
		private const FACE:String = "3DFACE";
		private const LINE:String = "LINE";
		private const VERTEX:String = "VERTEX";
		private const POLYLINE:String = "POLYLINE";
		
		private var _textData:String;
		private var _startedParsing:Boolean;
		private var _trim:RegExp = new RegExp("^[ \t]", "g");
		
		private var _v0:Vector3D;
		private var _v1:Vector3D;
		private var _v2:Vector3D;
		private var _v3:Vector3D;
		
		private var _meshesDic:Dictionary;
		
		private var _vertices:Vector.<Number>;
		private var _uvs:Vector.<Number>;
		private var _indices:Vector.<uint>;
		private var _subGeometry:CompactSubGeometry;
		
		private var _polyLines:Vector.<Vector3D>;
		private var _polyLinesIndices:Vector.<int>;
		
		//private var _charIndex:uint;
		private var _oldIndex:uint;
		private var _stringLen:uint;
		
		private var _meshName:String;
		private var _itemColor:uint;
		private var _lastMeshName:String = "";
		private var _activeMesh:Mesh;
		private var _blockType:String;
		private var _segmentSet:SegmentSet;
		private var _segCount:uint;
		
		private var _colorTable:Array = [0x000000, 0xFF0000, 0xFFFF00, 0x00FF00, 0x00FFFF, 0x0000FF, 0xFF00FF, 0xFFFFFF, 0x414141, 0x808080, 0xFF0000, 0xFFAAAA, 0xBD0000, 0xBD7E7E, 0x810000, 0x815656, 0x680000, 0x684545, 0x4F0000, 0x4F3535, 0xFF3F00, 0xFFBFAA, 0xBD2E00, 0xBD8D7E, 0x811F00, 0x816056, 0x681900, 0x684E45, 0x4F1300, 0x4F3B35, 0xFF7F00, 0xFFD4AA, 0xBD5E00, 0xBD9D7E, 0x814000, 0x816B56, 0x683400, 0x685645, 0x4F2700, 0x4F4235, 0xFFBF00, 0xFFEAAA, 0xBD8D00, 0xBDAD7E, 0x816000, 0x817656, 0x684E00, 0x685F45, 0x4F3B00, 0x4F4935, 0xFFFF00, 0xFFFFAA, 0xBDBD00, 0xBDBD7E, 0x818100, 0x818156, 0x686800, 0x686845, 0x4F4F00, 0x4F4F35, 0xBFFF00, 0xEAFFAA, 0x8DBD00, 0xADBD7E, 0x608100, 0x768156, 0x4E6800, 0x5F6845, 0x3B4F00, 0x494F35, 0x7FFF00, 0xD4FFAA, 0x5EBD00, 0x9DBD7E, 0x408100, 0x6B8156, 0x346800, 0x566845, 0x274F00, 0x424F35, 0x3FFF00, 0xBFFFAA, 0x2EBD00, 0x8DBD7E, 0x1F8100, 0x608156, 0x196800, 0x4E6845, 0x134F00, 0x3B4F35, 0x00FF00, 0xAAFFAA, 0x00BD00, 0x7EBD7E, 0x008100, 0x568156, 0x006800, 0x456845, 0x004F00, 0x354F35, 0x00FF3F, 0xAAFFBF, 0x00BD2E, 0x7EBD8D, 0x00811F, 0x568160, 0x006819, 0x45684E, 0x004F13, 0x354F3B, 0x00FF7F, 0xAAFFD4, 0x00BD5E, 0x7EBD9D, 0x008140, 0x56816B, 0x006834, 0x456856, 0x004F27, 0x354F42, 0x00FFBF, 0xAAFFEA, 0x00BD8D, 0x7EBDAD, 0x008160, 0x568176, 0x00684E, 0x45685F, 0x004F3B, 0x354F49, 0x00FFFF, 0xAAFFFF, 0x00BDBD, 0x7EBDBD, 0x008181, 0x568181, 0x006868, 0x456868, 0x004F4F, 0x354F4F, 0x00BFFF, 0xAAEAFF, 0x008DBD, 0x7EADBD, 0x006081, 0x567681, 004E68, 0x455F68, 0x003B4F, 0x35494F, 0x007FFF, 0xAAD4FF, 0x005EBD, 0x7E9DBD, 0x004081, 0x566B81, 0x003468, 0x455668, 0x00274F, 0x35424F, 0x003FFF, 0xAABFFF, 0x002EBD, 0x7E8DBD, 0x001F81, 0x566081, 0x001968, 0x454E68, 0x00134F, 0x353B4F, 0x0000FF, 0xAAAAFF, 0x0000BD, 0x7E7EBD, 0x000081, 0x565681, 0x000068, 0x454568, 0x00004F, 0x35354F, 0x3F00FF, 0xBFAAFF, 0x2E00BD, 0x8D7EBD, 0x1F0081, 0x605681, 0x190068, 0x4E4568, 0x13004F, 0x3B354F, 0x7F00FF, 0xD4AAFF, 0x5E00BD, 0x9D7EBD, 0x400081, 0x6B5681, 0x340068, 0x564568, 0x27004F, 0x42354F, 0xBF00FF, 0xEEAAFF, 0x8D00BD, 0xAD7EBD, 0x600081, 0x765681, 0x4E0068, 0x5F4568, 0x3B004F, 0x49354F, 0xFF00FF, 0xFFAAFF, 0xBD00BD, 0xBD7EBD, 0x810081, 0x815681, 0x680068, 0x684568, 0x4F004F, 0x4F354F, 0xFF00BF, 0xFFAAEA, 0xBD008D, 0xBD7EAD, 0x810060, 0x815676, 0x68004E, 0x68455F, 0x4F003B, 0x4F3549, 0xFF007F, 0xFFAAD4, 0xBD005E, 0xBD7E9D, 0x810040, 0x81566B, 0x680034, 0x684556, 0x4F0027, 0x4F3542, 0xFF003F, 0xFFAABF, 0xBD002E, 0xBD7E8D, 0x81001F, 0x815660, 0x680019, 0x68454E, 0x4F0013, 0x4F353B, 0x333333, 0x505050, 0x696969, 0x828282, 0xBEBEBE, 0xFFFFFF];
		
		/**
		 * Creates a new DXFParser object.
		 * @param uri The url or id of the data or file to be parsed.
		 * @param extra The holder for extra contextual data that the parser might need.
		 */
		public function DXFParser()
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
			return extension == "dxf";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data:*):Boolean
		{
			var str:String = ParserUtil.toString(data);
			if (!str)
				return false;
			
			if (str.indexOf("ENDSEC") != -1 && str.indexOf("EOF") != -1)
				return true;
			
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function proceedParsing():Boolean
		{
			var line:String;
			var _vSet:uint;
			
			if (!_startedParsing) {
				_textData = getTextData();
				
				if (_textData.indexOf(FACE) == -1 && _textData.indexOf(LINE) == -1 && _textData.indexOf(POLYLINE) == -1 && _textData.indexOf(VERTEX) == -1) {
					//we're done, nothing we do support in there
					return PARSING_DONE;
				}
				
				_meshesDic = new Dictionary();
				
				_v0 = new Vector3D();
				_v1 = new Vector3D();
				_v2 = new Vector3D();
				_v3 = new Vector3D();
				
				_startedParsing = true;
				
				var re:RegExp = new RegExp(String.fromCharCode(13), "g");
				_textData = _textData.replace(re, "");
				_textData = _textData.replace(/\\[\r\n]+\s*/gm, '');
				
				var _charIndex:uint = 0;
				_stringLen = _textData.length;
				_oldIndex = 0;
				_segCount = 0;
				_vSet = 0;
				
				if (_textData.indexOf(CR) == -1)
					return PARSING_DONE;
			}
			
			var tag:String;
			var isBlock:Boolean;
			var isTag:Boolean;
			
			var lineVal:Number;
			
			while (_charIndex < _stringLen && (hasTime() || isBlock)) {
				
				_charIndex = _textData.indexOf(CR, _oldIndex);
				
				line = _textData.substring(_oldIndex, _charIndex);
				line = line.replace(_trim, "");
				
				if (line == "") {
					_oldIndex = _charIndex + 1;
					continue;
				}
				
				if (line == FACE || line == LINE || line == POLYLINE || (line == VERTEX && _polyLines)) {
					if (_blockType == FACE && _vSet == 11)
						finalizeFace();
					if (line != VERTEX && _blockType == VERTEX && _polyLines.length >= 3)
						constructPolyfaceMesh();
					
					_vSet = 0;
					isBlock = true;
					_blockType = line;
					isTag = false;
					_meshName = "";
					_oldIndex = _charIndex + 1;
					continue;
				}
				
				if (isBlock) {
					
					if (isTag) {
						
						lineVal = parseFloat(line);
						
						if (_blockType == FACE) {
							
							switch (tag) {
								case "10":
									_v0.x = lineVal;
									_vSet++;
									break;
								case "20":
									_v0.y = lineVal;
									_vSet++;
									break;
								case "30":
									_v0.z = lineVal;
									_vSet++;
									break;
								case "11":
									_v1.x = lineVal;
									_vSet++;
									break;
								case "21":
									_v1.y = lineVal;
									_vSet++;
									break;
								case "31":
									_v1.z = lineVal;
									_vSet++;
									break;
								case "12":
									_v2.x = lineVal;
									_vSet++;
									break;
								case "22":
									_v2.y = lineVal;
									_vSet++;
									break;
								case "32":
									_v2.z = lineVal;
									_vSet++;
									break;
								case "13":
									_v3.x = lineVal;
									_vSet++;
									break;
								case "23":
									_v3.y = lineVal;
									_vSet++;
									break;
								case "33":
									_v3.z = lineVal;
									if (_vSet == 11) {
										if (_meshName == "")
											_meshName = "mesh";
										finalizeFace();
										isBlock = false;
									}
									break;
								
								case "62":
									_itemColor = getDXFColor(lineVal);
									break;
								
								//ignoring visibility tag
								default:
									if (isNaN(lineVal) && tag == "8" && _vSet == 0)
										_meshName = line;
								
							}
							
						} else if (_blockType == LINE) {
							
							switch (tag) {
								case "10":
									_v0.x = lineVal;
									_vSet++;
									break;
								case "20":
									_v0.y = lineVal;
									_vSet++;
									break;
								case "30":
									_v0.z = lineVal;
									_vSet++;
									break;
								
								case "11":
									_v1.x = lineVal;
									_vSet++;
									break;
								case "21":
									_v1.y = lineVal;
									_vSet++;
									break;
								case "31":
									_v1.z = lineVal;
									if (_vSet == 5) {
										finalizeLine();
										isBlock = false;
									}
									break;
								
								case "62":
									_itemColor = getDXFColor(lineVal);
								
							}
							
						} else if (_blockType == VERTEX) {
							
							switch (tag) {
								
								case "8":
									if (isNaN(lineVal))
										_meshName = line;
									break;
								case "10":
									_v0.x = lineVal;
									_vSet++;
									break;
								case "20":
									_v0.y = lineVal;
									_vSet++;
									break;
								case "30":
									_v0.z = lineVal;
									_vSet++;
									break;
								
								case "70":
									// 128, is the closing tag for a face.
									if (lineVal != 128 && _vSet == 3)
										_polyLines.push(_v0.clone());
									
									_vSet = 0;
									break;
								
								case "71":
								case "72":
									_polyLinesIndices.push(int(Math.abs(lineVal)) - 1);
									break;
								case "73":
									//in case of negative, invisible edges (line draw for faces not supported anyway)
									_polyLinesIndices.push(int(Math.abs(lineVal)) - 1, -1); //pushing already 4th component to make sure all is quad
									break;
								
								case "74":
									_polyLinesIndices[_polyLinesIndices.length - 1] = int(Math.abs(lineVal)) - 1;
									break;
								
							}
							
						} else if (_blockType == POLYLINE) {
							if (tag == "70") {
								//The polyline is a polyface mesh.
								if (lineVal == 64) {
									_polyLines = new Vector.<Vector3D>();
									_polyLinesIndices = new Vector.<int>();
									_meshName = "polyline";
								} else {
									trace("Skip: unsupported POLYLINE structure");
									_polyLines = null;
									_polyLinesIndices = null;
								}
								isBlock = false;
							}
							/*unused if(tag == "71") --> lineVal == vertexcount*/
						}
						
					} else
						tag = line;
					
					isTag = !isTag;
				}
				
				_oldIndex = _charIndex + 1;
				
			}
			
			if (_charIndex >= _stringLen) {
				if (_blockType == VERTEX && _polyLines.length >= 3)
					constructPolyfaceMesh();
				if (_activeMesh)
					finalizeMesh();
				cleanUP();
				return PARSING_DONE;
			}
			
			return MORE_TO_PARSE;
		}
		
		private function constructPolyfaceMesh():void
		{
			if (_polyLinesIndices.length == 0 && (_polyLines.length == 3 || _polyLines.length == 4)) {
				// we try display some data from this pourly defined dxf file. Purely to give some visual clues. Chances for holes very high.
				_v0 = _polyLines[0];
				_v1 = _polyLines[1];
				_v2 = _polyLines[2];
				
				if (_polyLines.length >= 4)
					_v3 = _polyLines[3];
				else
					_v3 = _v2;
				
				finalizeFace();
				
			} else {
				
				//indices were set in the vertex tags so we expect 4 indices per face (we forced push a negative index to make sure there are 4)
				if (_polyLinesIndices.length%4 == 0) {
					
					for (var i:uint = 0; i < _polyLinesIndices.length; i += 4) {
						_v0 = _polyLines[_polyLinesIndices[i]];
						_v1 = _polyLines[_polyLinesIndices[i + 1]];
						_v2 = _polyLines[_polyLinesIndices[i + 2]];
						
						if (_polyLinesIndices[i + 3] > -1)
							_v3 = _polyLines[_polyLinesIndices[i + 3]];
						else
							_v3 = _v2;
						
						finalizeFace();
					}
				}
				
			}
			
			_polyLines = null;
			_polyLinesIndices = null;
		}
		
		private function finalizeFace():void
		{
			
			if (_lastMeshName == "" || _meshName != _lastMeshName) {
				
				if (_activeMesh)
					finalizeMesh();
				
				if (!_meshesDic[_meshName]) {
					_activeMesh = buildMesh();
					//in case the data would not comes one full mesh description at a time. 
					// cannot find any info on this, and do no see why some package could not do this.
					//Lets keep track of this mesh
					_meshesDic[_meshName] = _activeMesh;
					
				} else {
					// glad we keeped track. Lets reuse this mesh.
					_activeMesh = _meshesDic[_meshName];
					_subGeometry = CompactSubGeometry(_activeMesh.geometry.subGeometries[_activeMesh.geometry.subGeometries.length - 1]);
					_vertices = _subGeometry.vertexData;
					_uvs = _subGeometry.UVData;
					_indices = _subGeometry.indexData;
				}
				
			}
			
			if (_indices.length + 3 > LIMIT) {
				_subGeometry.fromVectors(_vertices, _uvs, null, null);
				_subGeometry.updateIndexData(_indices);
				
				addSubGeometry(_activeMesh.geometry);
			}
			
			var ind:uint = _vertices.length/3;
			_vertices.push(_v0.x, _v0.y, _v0.z, _v1.x, _v1.y, _v1.z, _v2.x, _v2.y, _v2.z);
			_uvs.push(0, 1, .5, 0, 1, 1);
			_indices.push(ind, ind + 1, ind + 2);
			
			//This format writes twice v2 as v3 even if its not a quad face. 
			// if v3 values are not equal to v2, it's a quad.
			if (_v2.x != _v3.x || _v2.y != _v3.y || _v2.z != _v3.z) {
				
				if (_indices.length + 3 > LIMIT) {
					_subGeometry.fromVectors(_vertices, _uvs, null, null);
					_subGeometry.updateIndexData(_indices);
					
					addSubGeometry(_activeMesh.geometry);
					
					ind = 0;
					
				} else
					ind += 3;
				_vertices.push(_v0.x, _v0.y, _v0.z, _v2.x, _v2.y, _v2.z, _v3.x, _v3.y, _v3.z);
				_uvs.push(0, 1, .5, 0, 1, 1);
				_indices.push(ind, ind + 1, ind + 2);
				
			}
			
			_lastMeshName = _meshName;
		}
		
		private function buildMesh():Mesh
		{
			var geom:Geometry = new Geometry();
			addSubGeometry(geom);
			
			var material:MaterialBase;
			var color:uint = 0xffffff;
			if (!_itemColor || isNaN(_itemColor)) {
				
				var r:int = Math.random()*255;
				var g:int = Math.random()*255;
				var b:int = Math.random()*255;
				
				color = r << 16 | g << 8 | b;
			} else
				color = _itemColor;
			if (materialMode < 2)
				material = new ColorMaterial(color);
			else
				material = new ColorMultiPassMaterial(color);
			var mesh:Mesh = new Mesh(geom, material);
			mesh.name = _meshName;
			
			return mesh;
		}
		
		private function addSubGeometry(geom:Geometry):void
		{
			_subGeometry = new CompactSubGeometry();
			_subGeometry.autoDeriveVertexNormals = true;
			_subGeometry.autoDeriveVertexTangents = true;
			geom.addSubGeometry(_subGeometry);
			
			_vertices = new Vector.<Number>();
			_uvs = new Vector.<Number>();
			_indices = new Vector.<uint>;
		}
		
		private function finalizeLine():void
		{
			_segCount += 11;
			
			if (!_segmentSet || _segCount > SETLIMIT) {
				_segmentSet = new SegmentSet();
				finalizeAsset(_segmentSet);
				_segCount = 11;
			}
			
			var lineColor:uint = (!_itemColor || isNaN(_itemColor))? 0xCCCCCC : _itemColor;
			var line:LineSegment = new LineSegment(_v0.clone(), _v1.clone());
			line.startColor = lineColor;
			line.endColor = lineColor;
			
			_itemColor = NaN;
			
			_segmentSet.addSegment(line);
		}
		
		private function finalizeMesh():void
		{
			_subGeometry.fromVectors(_vertices, _uvs, null, null);
			_subGeometry.updateIndexData(_indices);
			
			finalizeAsset(_activeMesh);
			
			_itemColor = NaN;
			_activeMesh = null;
		}
		
		private function cleanUP():void
		{
			_meshesDic = null;
			_activeMesh = null;
			_subGeometry = null;
			_segmentSet = null;
			_vertices = null;
			_uvs = null;
			_indices = null;
		}
		
		private function getDXFColor(index:uint):uint
		{
			if (index > _colorTable.length - 1)
				return 0xCCCCCC;
			
			return _colorTable[index];
		}
	
	}
}

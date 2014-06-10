package away3d.materials.passes {
	import away3d.arcane;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.pool.RenderableBase;
	import away3d.entities.Camera3D;
	import away3d.materials.compilation.ShaderState;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.geom.Matrix3D;

	use namespace arcane;

	/**
	 * Pass for deferred lighting which stores world normal and specularIntensity in alpha channel
	 */
	public class WorldNormalPass extends MaterialPassBase {
		//varyings
		public static const UV_VARYING:String = "vUV";
		public static const PROJECTED_POSITION_VARYING:String = "vProjPos";
		public static const NORMAL_VARYING:String = "vNormal";
		public static const TANGENT_VARYING:String = "vTangent";
		public static const BINORMAL_VARYING:String = "vBinormal";
		//attributes
		public static const POSITION_ATTRIBUTE:String = "aPos";
		public static const NORMAL_ATTRIBUTE:String = "aNormal";
		public static const TANGENT_ATTRIBUTE:String = "aTangent";
		public static const UV_ATTRIBUTE:String = "aUV";
		//vertex constants
		public static const PROJ_MATRIX_VERTEX_CONSTANT:String = "cvProj";
		public static const WORLD_MATRIX_VERTEX_CONSTANT:String = "cvWorldMatrix";
		//fragment constants
		public static const PROPERTIES_FRAGMENT_CONSTANT:String = "cfPropertiesData";
		//textures
		public static const OPACITY_MAP:String = "tOpacity";
		public static const NORMAL_TEXTURE:String = "tNormal";

		private var _alphaThreshold:Number = 0;
		private var _opacityMap:Texture2DBase;
		private var _opacityChannel:String;
		private var _normalMap:Texture2DBase;
		private var _propertiesData:Vector.<Number>;
		private var _shader:ShaderState = new ShaderState();
		private var _specularIntensity:int = 1;

		public function WorldNormalPass() {
		}

		override arcane function getVertexCode():String {
			var code:String = "";
			var projectedPosTemp:int = _shader.getFreeVertexTemp();
			code += "m44 vt" + projectedPosTemp + ", va" + _shader.getAttribute(POSITION_ATTRIBUTE) + ", vc" + _shader.getVertexConstant(PROJ_MATRIX_VERTEX_CONSTANT, 4) + "\n";
			code += "mov op, vt" + projectedPosTemp + "\n";
			code += "mov v" + _shader.getVarying(PROJECTED_POSITION_VARYING) + ", vt" + projectedPosTemp + "\n";//projected position
			_shader.removeVertexTempUsage(projectedPosTemp);
			code += "mov v" + _shader.getVarying(UV_VARYING) + ", va" + _shader.getAttribute(UV_ATTRIBUTE) + "\n";//uv channel
			//normals
			var normalTemp:int = _shader.getFreeVertexTemp();
			code += "m33 vt" + normalTemp + ".xyz, va" + _shader.getAttribute(NORMAL_ATTRIBUTE) + ", vc" + _shader.getVertexConstant(WORLD_MATRIX_VERTEX_CONSTANT, 3) + "\n";
			code += "nrm vt" + normalTemp + ".xyz, vt" + normalTemp + ".xyz\n";
			code += "mov vt" + normalTemp + ".w, va" + _shader.getAttribute(NORMAL_ATTRIBUTE) + ".w\n";
			if (normalMap) {
				var tangentTemp:int = _shader.getFreeVertexTemp();
				code += "m33 vt" + tangentTemp + ".xyz, va" + _shader.getAttribute(TANGENT_ATTRIBUTE) + ", vc" + _shader.getVertexConstant(WORLD_MATRIX_VERTEX_CONSTANT, 3) + "\n";
				code += "nrm vt" + tangentTemp + ".xyz, vt" + tangentTemp + ".xyz\n";
				var binormal:int = _shader.getFreeVertexTemp();
				code += "crs vt" + binormal + ".xyz, vt" + normalTemp + ".xyz, vt" + tangentTemp + ".xyz\n";
				code += "nrm vt" + binormal + ".xyz, vt" + binormal + ".xyz\n";
				//transpose tbn
				code += "mov v" + _shader.getVarying(TANGENT_VARYING) + ".xyzw, vt" + normalTemp + ".xyxw\n";
				code += "mov v" + _shader.getVarying(TANGENT_VARYING) + ".x, vt" + tangentTemp + ".x\n";
				code += "mov v" + _shader.getVarying(TANGENT_VARYING) + ".y, vt" + binormal + ".x\n";
				code += "mov v" + _shader.getVarying(BINORMAL_VARYING) + ".xyzw, vt" + normalTemp + ".xyyw\n";
				code += "mov v" + _shader.getVarying(BINORMAL_VARYING) + ".x, vt" + tangentTemp + ".y\n";
				code += "mov v" + _shader.getVarying(BINORMAL_VARYING) + ".y, vt" + binormal + ".y\n";
				code += "mov v" + _shader.getVarying(NORMAL_VARYING) + ".xyzw, vt" + normalTemp + ".xyzw\n";
				code += "mov v" + _shader.getVarying(NORMAL_VARYING) + ".x, vt" + tangentTemp + ".z\n";
				code += "mov v" + _shader.getVarying(NORMAL_VARYING) + ".y, vt" + binormal + ".z\n";
				_shader.removeVertexTempUsage(binormal);
				_shader.removeVertexTempUsage(tangentTemp);
			} else {
				code += "mov v" + _shader.getVarying(NORMAL_VARYING) + ", vt" + normalTemp + "\n";
			}
			_shader.removeVertexTempUsage(normalTemp);

			_numUsedVaryings = _shader.numVaryings;
			_numUsedVertexConstants = _shader.numVertexConstants;
			_numUsedStreams = _shader.numAttributes;
			return code;
		}

		override arcane function getFragmentCode(fragmentAnimatorCode:String):String {
			var code:String = "";
			if (_opacityMap) {
				code += sampleTexture(_opacityMap, 0, _shader.getTexture(OPACITY_MAP));
				code += "sub ft0." + _opacityChannel + ", ft0." + _opacityChannel + ", fc" + _shader.getFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT) + ".x\n";
				code += "kil ft0." + _opacityChannel + "\n";
			}

			//we have filled the depth, lets fill world normal
			if (!_normalMap) {
				code += "nrm ft0.xyz, v" + _shader.getVarying(NORMAL_VARYING) + ".xyz\n";
				code += "mov ft0.w, fc" + _shader.getFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT) + ".w\n";
				code += "mov oc0, ft0\n";
			} else {
				//normal tangent space
				var normalTS:int = _shader.getFreeFragmentTemp();
				code += sampleTexture(normalMap, normalTS, _shader.getTexture(NORMAL_TEXTURE));
				//if normal map used as DXT5 it means that normal map encoded in green and alpha channels for better compression quality, we need to restore it
				if (normalMap.format == "compressedAlpha") {
					code += "add ft" + normalTS + ".xy, ft" + normalTS + ".yw, ft" + normalTS + ".yw\n"
					code += "sub ft" + normalTS + ".xy, ft" + normalTS + ".xy, fc" + _shader.getFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT) + ".yy\n"
					code += "mul ft" + normalTS + ".zw, ft" + normalTS + ".xy, ft" + normalTS + ".xy\n"
					code += "add ft" + normalTS + ".w, ft" + normalTS + ".w, ft" + normalTS + ".z\n"
					code += "sub ft" + normalTS + ".z, fc" + _shader.getFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT) + ".y, ft" + normalTS + ".w\n"
					code += "sqt ft" + normalTS + ".z, ft" + normalTS + ".z\n"
				} else {
					code += "add ft" + normalTS + ".xyz, ft" + normalTS + ", ft" + normalTS + "\n";
					code += "sub ft" + normalTS + ".xyz, ft" + normalTS + ", fc" + _shader.getFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT) + ".y\n";
				}
				code += "nrm ft" + normalTS + ".xyz, ft" + normalTS + "\n";
				var temp:int = _shader.getFreeFragmentTemp();
				var normalOutput:int = _shader.getFreeFragmentTemp();
				//TBN
				code += "nrm ft" + temp + ".xyz, v" + _shader.getVarying(TANGENT_VARYING) + ".xyz\n";
				code += "dp3 ft" + normalOutput + ".x, ft" + normalTS + ".xyz, ft" + temp + ".xyz\n";
				code += "nrm ft" + temp + ".xyz, v" + _shader.getVarying(BINORMAL_VARYING) + ".xyz\n";
				code += "dp3 ft" + normalOutput + ".y, ft" + normalTS + ".xyz, ft" + temp + ".xyz\n";
				code += "nrm ft" + temp + ".xyz, v" + _shader.getVarying(NORMAL_VARYING) + ".xyz\n";
				code += "dp3 ft" + normalOutput + ".z, ft" + normalTS + ".xyz, ft" + temp + ".xyz\n";
				code += "nrm ft" + normalOutput + ".xyz, ft" + normalOutput + ".xyz\n";
				//specular power
				code += "mov ft" + normalOutput + ".w, fc" + _shader.getFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT) + ".w\n";
				code += "mov oc, ft" + normalOutput + "\n";
				_shader.removeFragmentTempUsage(normalOutput);
				_shader.removeFragmentTempUsage(temp);
				_shader.removeFragmentTempUsage(normalTS);
			}

			_numUsedTextures = _shader.numTextureRegisters;
			_numUsedFragmentConstants = _shader.numFragmentConstants;
			return code;
		}

		override arcane function render(renderable:RenderableBase, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void {
			var context3D:Context3D = stage3DProxy.context3D;
			if (renderable.materialOwner.animator) {
				updateAnimationState(renderable, stage3DProxy, camera);
			}
			//projection matrix
			var matrix3D:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
			matrix3D.copyFrom(renderable.sourceEntity.getRenderSceneTransform(camera));
			matrix3D.append(viewProjection);
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _shader.getVertexConstant(PROJ_MATRIX_VERTEX_CONSTANT), matrix3D, true);

			if (_shader.hasVertexConstant(WORLD_MATRIX_VERTEX_CONSTANT)) {
				context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _shader.getVertexConstant(WORLD_MATRIX_VERTEX_CONSTANT), renderable.sourceEntity.inverseSceneTransform);
			}

			stage3DProxy.activateBuffer(_shader.getAttribute(POSITION_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.POSITION_DATA), renderable.getVertexOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);
			if (_shader.hasAttribute(UV_ATTRIBUTE)) {
				stage3DProxy.activateBuffer(_shader.getAttribute(UV_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.UV_DATA), renderable.getVertexOffset(TriangleSubGeometry.UV_DATA), TriangleSubGeometry.UV_FORMAT);
			}
			if (_shader.hasAttribute(NORMAL_ATTRIBUTE)) {
				stage3DProxy.activateBuffer(_shader.getAttribute(NORMAL_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.NORMAL_DATA), renderable.getVertexOffset(TriangleSubGeometry.NORMAL_DATA), TriangleSubGeometry.NORMAL_FORMAT);
			}
			if (_shader.hasAttribute(TANGENT_ATTRIBUTE)) {
				stage3DProxy.activateBuffer(_shader.getAttribute(TANGENT_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.TANGENT_DATA), renderable.getVertexOffset(TriangleSubGeometry.TANGENT_DATA), TriangleSubGeometry.TANGENT_FORMAT);
			}

			context3D.drawTriangles(stage3DProxy.getIndexBuffer(renderable.getIndexData()), 0, renderable.numTriangles);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void {
			var context:Context3D = stage3DProxy._context3D;
			super.activate(stage3DProxy, camera);
			_numUsedTextures = 0;

			if (_shader.hasTexture(OPACITY_MAP)) {
				_numUsedTextures++;
				context.setTextureAt(_shader.getTexture(OPACITY_MAP), _opacityMap.getTextureForStage3D(stage3DProxy));
			}

			if (_shader.hasTexture(NORMAL_TEXTURE)) {
				_numUsedTextures++;
				context.setTextureAt(_shader.getTexture(NORMAL_TEXTURE), _normalMap.getTextureForStage3D(stage3DProxy));
			}

			if (_shader.hasFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT)) {
				if(!_propertiesData) _propertiesData = new Vector.<Number>();
				_propertiesData[0] = alphaThreshold;//used for opacity map
				_propertiesData[1] = 1;//used for normal output and normal restoring and diffuse output
				_propertiesData[2] = _specularIntensity;
				_propertiesData[3] = 0;
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT), _propertiesData, 1);
			}
		}

		public function get alphaThreshold():Number {
			return _alphaThreshold;
		}

		public function set alphaThreshold(value:Number):void {
			if (value < 0)
				value = 0;
			else if (value > 1)
				value = 1;
			if (value == _alphaThreshold)
				return;

			_alphaThreshold = value;
			invalidateShaderProgram();
		}

		public function get opacityMap():Texture2DBase {
			return _opacityMap;
		}

		public function set opacityMap(value:Texture2DBase):void {
			if (_opacityMap == value) return;
			_opacityMap = value;
			invalidateShaderProgram();
		}

		public function get opacityChannel():String {
			return _opacityChannel;
		}

		public function set opacityChannel(value:String):void {
			if (_opacityChannel == value) return;
			_opacityChannel = value;
			invalidateShaderProgram();
		}

		public function get normalMap():Texture2DBase {
			return _normalMap;
		}

		public function set normalMap(value:Texture2DBase):void {
			if (_normalMap == value) return;
			_normalMap = value;
			invalidateShaderProgram();
		}

		override arcane function invalidateShaderProgram(updateMaterial:Boolean = true):void {
			_shader.clear();
			super.invalidateShaderProgram(updateMaterial);
		}

		private function sampleTexture(texture:Texture2DBase, targetTemp:int, textureRegister:int):String {
			var wrap:String = _repeat ? "wrap" : "clamp";
			var filter:String;
			var format:String;
			var uvVarying:int
			var enableMipMaps:Boolean;
			enableMipMaps = _mipmap && texture.hasMipMaps;
			if (_smooth) {
				filter = enableMipMaps ? "linear,miplinear" : "linear";
			} else {
				filter = enableMipMaps ? "nearest,mipnearest" : "nearest";
			}
			format = "";
			if (texture.format == Context3DTextureFormat.COMPRESSED) {
				format = "dxt1,";
			} else if (texture.format == "compressedAlpha") {
				format = "dxt5,";
			}
			uvVarying = _shader.getVarying(UV_VARYING);
			return "tex ft" + targetTemp + ", v" + uvVarying + ", fs" + textureRegister + " <2d," + filter + "," + format + wrap + ">\n";
		}

		public function get specularIntensity():int {
			return _specularIntensity;
		}

		public function set specularIntensity(value:int):void {
			_specularIntensity = value;
		}


		override public function dispose():void {
			_shader.clear();
			normalMap = null;
			opacityMap = null;
			_shader.clear();
			_shader = null;
			_propertiesData = null;
			super.dispose();
		}
	}
}

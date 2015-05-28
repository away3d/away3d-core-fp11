package away3d.materials.passes {
	import away3d.arcane;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.pool.MaterialPassData;
	import away3d.managers.Stage3DProxy;
	import away3d.core.geom.Matrix3DUtils;
	import away3d.core.pool.RenderableBase;
	import away3d.debug.Debug;
	import away3d.entities.Camera3D;
	import away3d.materials.compilation.ShaderObjectBase;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterData;
	import away3d.materials.compilation.ShaderState;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class GBufferPass extends MaterialPassBase {
		//varyings
		public static const UV_VARYING:String = "vUV";
		public static const SECONDARY_UV_VARYING:String = "vSecondaryUV"
		public static const PROJECTED_POSITION_VARYING:String = "vProjPos";
		public static const WORLD_POSITION_VARYING:String = "vWorldPos";
		public static const NORMAL_VARYING:String = "vNormal";
		public static const TANGENT_VARYING:String = "vTangent";
		public static const BINORMAL_VARYING:String = "vBinormal";
		//attributes
		public static const POSITION_ATTRIBUTE:String = "aPos";
		public static const NORMAL_ATTRIBUTE:String = "aNormal";
		public static const TANGENT_ATTRIBUTE:String = "aTangent";
		public static const UV_ATTRIBUTE:String = "aUV";
		public static const SECONDARY_UV_ATTRIBUTE:String = "aSecondaryUV";
		//vertex constants
		public static const PROJ_MATRIX_VC:String = "cvProj";
		public static const WORLD_MATRIX_VC:String = "cvWorldMatrix";
		//fragment constants
		public static const DEPTH_FC:String = "cfDepthData";
		public static const PROPERTIES_FC:String = "cfPropertiesData";
		public static const DIFFUSE_COLOR_FC:String = "cfDiffuseColor";
		public static const SPECULAR_COLOR_FC:String = "cfSpecularColor";
		//textures
		public static const OPACITY_TEXTURE:String = "tOpacity";
		public static const NORMAL_TEXTURE:String = "tNormal";
		public static const DIFFUSE_TEXTURE:String = "tDiffuse";
		public static const SPECULAR_TEXTURE:String = "tSpecular";

		public var colorR:Number = 0.8;
		public var colorG:Number = 0.8;
		public var colorB:Number = 0.8;

		public var specularColorR:uint = 0;
		public var specularColorG:uint = 0;
		public var specularColorB:uint = 0;
		public var gloss:int = 50;
		public var specularIntensity:Number = 1;

		public var diffuseMap:Texture2DBase;
		public var diffuseMapUVChannel:String = TriangleSubGeometry.UV_DATA;

		public var normalMap:Texture2DBase;
		public var normalMapUVChannel:String = TriangleSubGeometry.UV_DATA;

		public var specularMap:Texture2DBase;
		public var specularMapUVChannel:String = TriangleSubGeometry.UV_DATA;

		public var opacityMap:Texture2DBase;
		public var opacityChannel:String = "x";
		public var opacityUVChannel:String = TriangleSubGeometry.UV_DATA;
		public var alphaThreshold:Number = 0;

		private var _depthData:Vector.<Number>;
		private var _propertiesData:Vector.<Number>;
		private var _diffuseColorData:Vector.<Number>;
		private var _specularColorData:Vector.<Number>;
		private var _shader:ShaderState = new ShaderState();

		private var _drawDepth:Boolean;
		private var _drawWorldNormal:Boolean;
		//TODO: restore worldposition from depthbuffer
		private var _drawWorldPosition:Boolean;
		private var _drawAlbedo:Boolean;
		private var _drawSpecular:Boolean;

		public function GBufferPass(drawDepth:Boolean = true, drawWorldNormal:Boolean = true, drawWorldPosition:Boolean = false, drawAlbedo:Boolean = false, drawSpecular:Boolean = false) {
			_drawDepth = drawDepth;
			_drawWorldNormal = drawWorldNormal;
			_drawWorldPosition = drawWorldPosition;
			_drawAlbedo = drawAlbedo;
			_drawSpecular = drawSpecular;
		}

		override public function getVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String {
			var code:String = "";
			var projectedPosTemp:int = _shader.getFreeVertexTemp();
			code += "m44 vt" + projectedPosTemp + ", va" + _shader.getAttribute(POSITION_ATTRIBUTE) + ", vc" + _shader.getVertexConstant(PROJ_MATRIX_VC, 4) + "\n";
			code += "mov op, vt" + projectedPosTemp + "\n";
			code += "mov v" + _shader.getVarying(PROJECTED_POSITION_VARYING) + ", vt" + projectedPosTemp + "\n";//projected position
			_shader.removeFragmentTempUsage(projectedPosTemp);

			if (useUV) {
				code += "mov v" + _shader.getVarying(UV_VARYING) + ", va" + _shader.getAttribute(UV_ATTRIBUTE) + "\n";//uv channel
			}

			if (useSecondaryUV) {
				code += "mov v" + _shader.getVarying(SECONDARY_UV_VARYING) + ", va" + _shader.getAttribute(SECONDARY_UV_ATTRIBUTE) + "\n";//secondary uv channel
			}

			if (_drawWorldNormal) {
				//normals
				var normalTemp:int = _shader.getFreeVertexTemp();
				code += "m33 vt" + normalTemp + ".xyz, va" + _shader.getAttribute(NORMAL_ATTRIBUTE) + ", vc" + _shader.getVertexConstant(WORLD_MATRIX_VC, 4) + "\n";
				code += "nrm vt" + normalTemp + ".xyz, vt" + normalTemp + ".xyz\n";
				code += "mov vt" + normalTemp + ".w, va" + _shader.getAttribute(NORMAL_ATTRIBUTE) + ".w\n";
				if (normalMap) {
					var tangentTemp:int = _shader.getFreeVertexTemp();
					code += "m33 vt" + tangentTemp + ".xyz, va" + _shader.getAttribute(TANGENT_ATTRIBUTE) + ", vc" + _shader.getVertexConstant(WORLD_MATRIX_VC, 4) + "\n";
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
					_shader.removeFragmentTempUsage(binormal);
					_shader.removeFragmentTempUsage(tangentTemp);
				} else {
					code += "mov v" + _shader.getVarying(NORMAL_VARYING) + ", vt" + normalTemp + "\n";
				}
				_shader.removeFragmentTempUsage(normalTemp);
			}

			if(_drawWorldPosition) {
				code += "m44 v"+_shader.getVarying(WORLD_POSITION_VARYING)+", va"+_shader.getAttribute(POSITION_ATTRIBUTE)+", vc"+_shader.getVertexConstant(WORLD_MATRIX_VC,4);
			}


			shaderObject.numUsedVaryings = _shader.numVaryings;
			shaderObject.numUsedVertexConstants = _shader.numVertexConstants;
			shaderObject.numUsedStreams = _shader.numAttributes;
			return code;
		}

		override public function getFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String {
			var outputRegister:int = 0;
			var code:String = "";

			if (opacityMap) {
				code += sampleTexture(opacityMap, opacityUVChannel, 3, _shader.getTexture(OPACITY_TEXTURE), shaderObject.repeatTextures, shaderObject.useMipmapping, shaderObject.useSmoothTextures);
				code += "sub ft3." + opacityChannel + ", ft3." + opacityChannel + ", fc" + _shader.getFragmentConstant(PROPERTIES_FC) + ".x\n";
				code += "kil ft3." + opacityChannel + "\n";
			}

			if (_drawDepth) {
				var depthDataRegister:int = _shader.getFragmentConstant(DEPTH_FC, 2);
				var screenPosVarying:int = _shader.getVarying(PROJECTED_POSITION_VARYING);
				code += "div ft2, v" + screenPosVarying + ", v" + screenPosVarying + ".w\n";
				code += "mul ft0, fc" + depthDataRegister + ", ft2.z\n";
				code += "frc ft0, ft0\n";
				code += "mul ft1, ft0.yzww, fc" + (depthDataRegister + 1) + "\n";
				code += "sub oc" + outputRegister + ", ft0, ft1\n";
				outputRegister++;
			}

			if (_drawWorldNormal) {
				//we have filled the depth, lets fill world normal
				if (!normalMap) {
					code += "nrm ft0.xyz, v" + _shader.getVarying(NORMAL_VARYING) + ".xyz\n";
				} else {
					//normal tangent space
					var normalTS:int = _shader.getFreeFragmentTemp();
					code += sampleTexture(normalMap, normalMapUVChannel, normalTS, _shader.getTexture(NORMAL_TEXTURE), shaderObject.repeatTextures, shaderObject.useMipmapping, shaderObject.useSmoothTextures);
					//if normal map used as DXT5 it means that normal map encoded in green and alpha channels for better compression quality, we need to restore it
					if (normalMap.format == "compressedAlpha") {
						code += "add ft" + normalTS + ".xy, ft" + normalTS + ".yw, ft" + normalTS + ".yw\n"
						code += "sub ft" + normalTS + ".xy, ft" + normalTS + ".xy, fc" + _shader.getFragmentConstant(PROPERTIES_FC) + ".yy\n"
						code += "mul ft" + normalTS + ".zw, ft" + normalTS + ".xy, ft" + normalTS + ".xy\n"
						code += "add ft" + normalTS + ".w, ft" + normalTS + ".w, ft" + normalTS + ".z\n"
						code += "sub ft" + normalTS + ".z, fc" + _shader.getFragmentConstant(PROPERTIES_FC) + ".y, ft" + normalTS + ".w\n"
						code += "sqt ft" + normalTS + ".z, ft" + normalTS + ".z\n"
					} else {
						code += "add ft" + normalTS + ".xyz, ft" + normalTS + ", ft" + normalTS + "\n";
						code += "sub ft" + normalTS + ".xyz, ft" + normalTS + ", fc" + _shader.getFragmentConstant(PROPERTIES_FC) + ".y\n";
					}
					code += "nrm ft" + normalTS + ".xyz, ft" + normalTS + ".xyz\n";
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
					_shader.removeFragmentTempUsage(normalOutput);
					_shader.removeFragmentTempUsage(temp);
					_shader.removeFragmentTempUsage(normalTS);
				}
				//if do not draw specular, draw specular intesity to normalmap for deferred lighting
				if (!_drawSpecular) {
					code += "mov ft" + normalOutput + ".w, fc" + _shader.getFragmentConstant(SPECULAR_COLOR_FC) + ".w\n";
				} else {
					code += "mov ft" + normalOutput + ".w, fc" + _shader.getFragmentConstant(PROPERTIES_FC) + ".y\n";
				}
				code += "mov oc" + outputRegister + ", ft" + normalOutput + "\n";
				outputRegister++;
			}

			if(_drawWorldPosition) {
				code += "mov oc" + outputRegister + ", v" + _shader.getVarying(WORLD_POSITION_VARYING) + "\n";
				outputRegister++;
			}

			if (_drawAlbedo) {
				var diffuseColor:int = _shader.getFreeFragmentTemp();
				if (diffuseMap) {
					code += sampleTexture(diffuseMap, diffuseMapUVChannel, diffuseColor, _shader.getTexture(DIFFUSE_TEXTURE),shaderObject.repeatTextures, shaderObject.useMipmapping, shaderObject.useSmoothTextures);
					code += "mov oc" + outputRegister + ", ft" + diffuseColor + "\n";
				} else {
					code += "mov oc" + outputRegister + ", fc" + _shader.getFragmentConstant(DIFFUSE_COLOR_FC) + "\n";
				}
				outputRegister++;
				_shader.removeFragmentTempUsage(diffuseColor);
			}

			if (_drawSpecular) {
				//specular
				var specularColor:int = _shader.getFreeFragmentTemp();
				if (specularMap) {
					code += sampleTexture(specularMap, specularMapUVChannel, specularColor, _shader.getTexture(SPECULAR_TEXTURE), shaderObject.repeatTextures, shaderObject.useMipmapping, shaderObject.useSmoothTextures);
					code += "mul ft" + specularColor + ".xyz, ft" + specularColor + ".xyz, fc" + _shader.getFragmentConstant(SPECULAR_COLOR_FC) + ".xxx\n";
					//gloss
					code += "mov ft" + specularColor + ".w, fc" + _shader.getFragmentConstant(SPECULAR_COLOR_FC) + ".w\n";
					code += "mov oc" + outputRegister + ", ft" + specularColor + "\n";
				} else {
					code += "mov oc" + outputRegister + ", fc" + _shader.getFragmentConstant(SPECULAR_COLOR_FC) + "\n";
				}
				outputRegister++;
				_shader.removeFragmentTempUsage(specularColor);
			}

			shaderObject.numUsedTextures = _shader.numTextureRegisters;
			shaderObject.numUsedFragmentConstants = _shader.numFragmentConstants;
			return code;
		}

		override public function invalidatePass():void {
			_shader.clear();
			super.invalidatePass();
		}

		override public function activate(pass:MaterialPassData, stage:Stage3DProxy, camera:Camera3D):void {
			var context3D:Context3D = stage._context3D;
			super.activate(pass, stage, camera);

			if (!_depthData) {
				_depthData = new Vector.<Number>();
				_depthData[0] = 1;
				_depthData[1] = 255;
				_depthData[2] = 65025;
				_depthData[3] = 16581375;
				_depthData[4] = 1 / 255;
				_depthData[5] = 1 / 255;
				_depthData[6] = 1 / 255;
				_depthData[7] = 0;
			}
			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(DEPTH_FC), _depthData, 2);

			if (_shader.hasFragmentConstant(PROPERTIES_FC)) {
				if (!_propertiesData) _propertiesData = new Vector.<Number>();
				_propertiesData[0] = alphaThreshold;//used for opacity map
				_propertiesData[1] = 1;//used for normal output and normal restoring and diffuse output
				_propertiesData[2] = 0;
				_propertiesData[3] = 0;
				context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(PROPERTIES_FC), _propertiesData, 1);
			}

			if (_shader.hasFragmentConstant(DIFFUSE_COLOR_FC)) {
				if (!_diffuseColorData) _diffuseColorData = new Vector.<Number>();
				_diffuseColorData[0] = colorR;
				_diffuseColorData[1] = colorG;
				_diffuseColorData[2] = colorB;
				_diffuseColorData[3] = 1;
				context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(DIFFUSE_COLOR_FC), _diffuseColorData, 1);
			}

			if (_shader.hasFragmentConstant(SPECULAR_COLOR_FC)) {
				if (!_specularColorData) _specularColorData = new Vector.<Number>();
				if (specularMap) {
					_specularColorData[0] = specularIntensity;
					_specularColorData[1] = 0;
					_specularColorData[2] = 0;
					_specularColorData[3] = gloss/100;
				} else {
					_specularColorData[0] = specularColorR * specularIntensity;
					_specularColorData[1] = specularColorG * specularIntensity;
					_specularColorData[2] = specularColorB * specularIntensity;
					_specularColorData[3] = gloss/100;
				}
				context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(SPECULAR_COLOR_FC), _specularColorData, 1);
			}

			pass.shaderObject.numUsedTextures = null;
			if (_shader.hasTexture(OPACITY_TEXTURE)) {
				pass.shaderObject.numUsedTextures++;
				stage.activateTexture(_shader.getTexture(OPACITY_TEXTURE), opacityMap);
//				context3D.setTextureAt(_shader.getTexture(OPACITY_TEXTURE), opacityMap.getTextureForStage3D(stage));
			}
			if (_shader.hasTexture(NORMAL_TEXTURE)) {
				pass.shaderObject.numUsedTextures++;
				stage.activateTexture(_shader.getTexture(NORMAL_TEXTURE), normalMap);
//				context3D.setTextureAt(_shader.getTexture(NORMAL_TEXTURE), normalMap.getTextureForStage3D(stage3DProxy));
			}
			if (_shader.hasTexture(DIFFUSE_TEXTURE)) {
				pass.shaderObject.numUsedTextures++;
				stage.activateTexture(_shader.getTexture(DIFFUSE_TEXTURE), diffuseMap);
//				context3D.setTextureAt(_shader.getTexture(DIFFUSE_TEXTURE), diffuseMap.getTextureForStage3D(stage3DProxy));
			}
			if (_shader.hasTexture(SPECULAR_TEXTURE)) {
				pass.shaderObject.numUsedTextures++;
				stage.activateTexture(_shader.getTexture(SPECULAR_TEXTURE), specularMap);
//				context3D.setTextureAt(_shader.getTexture(SPECULAR_TEXTURE), specularMap.getTextureForStage3D(stage3DProxy));
			}
		}

		override public function render(pass:MaterialPassData, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void{
			var context3D:Context3D = stage._context3D;
//			if (renderable.materialOwner.animator) {
//				updateAnimationState(renderable, stage, camera);
//			}
			//projection matrix
			var matrix3D:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
			matrix3D.copyFrom(renderable.sourceEntity.getRenderSceneTransform(camera));
			matrix3D.append(viewProjection);
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _shader.getVertexConstant(PROJ_MATRIX_VC), matrix3D, true);

			if (_shader.hasVertexConstant(WORLD_MATRIX_VC)) {
				matrix3D.copyFrom(renderable.sourceEntity.sceneTransform);
				context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _shader.getVertexConstant(WORLD_MATRIX_VC), renderable.sourceEntity.inverseSceneTransform);
			}

			stage.activateBuffer(_shader.getAttribute(POSITION_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.POSITION_DATA), renderable.getVertexOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);
			if (_shader.hasAttribute(UV_ATTRIBUTE)) {
				stage.activateBuffer(_shader.getAttribute(UV_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.UV_DATA), renderable.getVertexOffset(TriangleSubGeometry.UV_DATA), TriangleSubGeometry.UV_FORMAT);
			}
			if (_shader.hasAttribute(SECONDARY_UV_ATTRIBUTE)) {
				stage.activateBuffer(_shader.getAttribute(SECONDARY_UV_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.SECONDARY_UV_DATA), renderable.getVertexOffset(TriangleSubGeometry.SECONDARY_UV_DATA), TriangleSubGeometry.SECONDARY_UV_FORMAT);
			}
			if (_shader.hasAttribute(NORMAL_ATTRIBUTE)) {
				stage.activateBuffer(_shader.getAttribute(NORMAL_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.NORMAL_DATA), renderable.getVertexOffset(TriangleSubGeometry.NORMAL_DATA), TriangleSubGeometry.NORMAL_FORMAT);
			}
			if (_shader.hasAttribute(TANGENT_ATTRIBUTE)) {
				stage.activateBuffer(_shader.getAttribute(TANGENT_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.TANGENT_DATA), renderable.getVertexOffset(TriangleSubGeometry.TANGENT_DATA), TriangleSubGeometry.TANGENT_FORMAT);
			}

			context3D.drawTriangles(stage.getIndexBuffer(renderable.getIndexData()), 0, renderable.numTriangles);
		}

		public function get useSecondaryUV():Boolean {
			return (opacityMap && opacityUVChannel == TriangleSubGeometry.SECONDARY_UV_DATA) || (specularMap && specularMapUVChannel == TriangleSubGeometry.SECONDARY_UV_DATA) ||
					(normalMap && normalMapUVChannel == TriangleSubGeometry.SECONDARY_UV_DATA) || (diffuseMap && diffuseMapUVChannel == TriangleSubGeometry.SECONDARY_UV_DATA);
		}

		public function get useUV():Boolean {
			return (opacityMap && opacityUVChannel == TriangleSubGeometry.UV_DATA) || (specularMap && specularMapUVChannel == TriangleSubGeometry.UV_DATA) ||
					(normalMap && normalMapUVChannel == TriangleSubGeometry.UV_DATA) || (diffuseMap && diffuseMapUVChannel == TriangleSubGeometry.UV_DATA);
		}

		private function sampleTexture(texture:Texture2DBase, textureUVChannel:String, targetTemp:int, textureRegister:int, repeat:Boolean, mipmap:Boolean, smooth:Boolean):String {
			var wrap:String = repeat ? "wrap" : "clamp";
			var filter:String;
			var format:String;
			var uvVarying:int;
			var enableMipMaps:Boolean;
			enableMipMaps = mipmap && texture.hasMipMaps;
			if (smooth) {
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
			uvVarying = (textureUVChannel == TriangleSubGeometry.SECONDARY_UV_DATA) ? _shader.getVarying(SECONDARY_UV_VARYING) : _shader.getVarying(UV_VARYING);
			return "tex ft" + targetTemp + ", v" + uvVarying + ", fs" + textureRegister + " <2d," + filter + "," + format + wrap + ">\n";
		}

		public function get drawDepth():Boolean {
			return _drawDepth;
		}

		public function set drawDepth(value:Boolean):void {
			if (_drawDepth == value) return;
			_drawDepth = value;
			invalidatePass();
		}

		public function get drawWorldNormal():Boolean {
			return _drawWorldNormal;
		}

		public function set drawWorldNormal(value:Boolean):void {
			if (_drawWorldNormal == value) return;
			_drawWorldNormal = value;
			invalidatePass();
		}

		public function get drawAlbedo():Boolean {
			return _drawAlbedo;
		}

		public function set drawAlbedo(value:Boolean):void {
			if (_drawAlbedo == value) return;
			_drawAlbedo = value;
			invalidatePass();
		}

		public function get drawSpecular():Boolean {
			return _drawSpecular;
		}

		public function set drawSpecular(value:Boolean):void {
			if (_drawSpecular == value) return;
			_drawSpecular = value;
			invalidatePass();
		}

		public function get drawWorldPosition():Boolean {
			return _drawWorldPosition;
		}

		public function set drawWorldPosition(value:Boolean):void {
			if (_drawWorldPosition == value) return;
			_drawWorldPosition = value;
			invalidatePass();
		}

		override public function dispose():void {
			diffuseMap = null;
			normalMap = null;
			specularMap = null;
			opacityMap = null;

			_shader.clear();
			_shader = null;
			_depthData = null;
			_propertiesData = null;
			_diffuseColorData = null;
			_specularColorData = null;
			super.dispose();
		}

	}
}
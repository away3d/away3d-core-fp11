package away3d.materials.passes {
	import away3d.arcane;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.managers.AGALProgram3DCache;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.pool.RenderableBase;
	import away3d.debug.Debug;
	import away3d.entities.Camera3D;
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
		public static const PROJ_MATRIX_VERTEX_CONSTANT:String = "cvProj";
		public static const WORLD_MATRIX_VERTEX_CONSTANT:String = "cvWorldMatrix";
		//fragment constants
		public static const DEPTH_FRAGMENT_CONSTANT:String = "cfDepthData";
		public static const PROPERTIES_FRAGMENT_CONSTANT:String = "cfPropertiesData";
		public static const DIFFUSE_COLOR_CONSTANT:String = "cfDiffuseColor";
		public static const SPECULAR_COLOR_CONSTANT:String = "cfSpecularColor";
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
		private var _propertiesData:Vector.<Number> = new Vector.<Number>();
		private var _diffuseColorData:Vector.<Number> = new Vector.<Number>();
		private var _specularColorData:Vector.<Number> = new Vector.<Number>();
		private var _shader:ShaderState = new ShaderState();

		private var _drawDepth:Boolean;
		private var _drawWorldNormal:Boolean;
		private var _drawAlbedo:Boolean;
		private var _drawSpecular:Boolean;

		public function GBufferPass(drawDepth:Boolean = true, drawWorldNormal:Boolean = true, drawAlbedo:Boolean = false, drawSpecular:Boolean = false) {
			_drawDepth = drawDepth;
			_drawWorldNormal = drawWorldNormal;
			_drawAlbedo = drawAlbedo;
			_drawSpecular = drawSpecular;

			_depthData = Vector.<Number>([
				1, 255, 65025, 16581375,
				1 / 255, 1 / 255, 1 / 255, 0
			]);
		}

		override arcane function getVertexCode():String {
			var code:String = "";
			var projectedPosTemp:int = _shader.getFreeVertexTemp();
			code += "m44 vt" + projectedPosTemp + ", va" + _shader.getAttribute(POSITION_ATTRIBUTE) + ", vc" + _shader.getVertexConstant(PROJ_MATRIX_VERTEX_CONSTANT, 4) + "\n";
			code += "mov op, vt" + projectedPosTemp + "\n";
			code += "mov v" + _shader.getVarying(PROJECTED_POSITION_VARYING) + ", vt" + projectedPosTemp + "\n";//projected position
			_shader.freeLastVertexTemp();
			code += "mov v" + _shader.getVarying(UV_VARYING) + ", va" + _shader.getAttribute(UV_ATTRIBUTE) + "\n";//uv channel
			if (useSecondaryUV) {
				code += "mov v" + _shader.getVarying(SECONDARY_UV_VARYING) + ", va" + _shader.getAttribute(SECONDARY_UV_ATTRIBUTE) + "\n";//secondary uv channel
			}
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
				_shader.freeLastVertexTemp();
				_shader.freeLastVertexTemp();
			} else {
				code += "mov v" + _shader.getVarying(NORMAL_VARYING) + ", vt" + normalTemp + "\n";
			}
			_shader.freeLastVertexTemp();

			_numUsedVaryings = _shader.numVaryings;
			_numUsedVertexConstants = _shader.numVertexConstants;
			_numUsedStreams = _shader.numAttributes;
			return code;
		}

		override arcane function getFragmentCode(fragmentAnimatorCode:String):String {
			var code:String = "";
			var depthDataRegister:int = _shader.getFragmentConstant(DEPTH_FRAGMENT_CONSTANT, 2);
			var screenPosVarying:int = _shader.getVarying(PROJECTED_POSITION_VARYING);
			code += "div ft2, v" + screenPosVarying + ", v" + screenPosVarying + ".w\n";
			code += "mul ft0, fc" + depthDataRegister + ", ft2.z\n";
			code += "frc ft0, ft0\n";
			code += "mul ft1, ft0.yzww, fc" + (depthDataRegister + 1) + "\n";
			if (opacityMap) {
				code += sampleTexture(opacityMap, opacityUVChannel, 3, _shader.getTexture(OPACITY_TEXTURE));
				code += "sub ft3." + opacityChannel + ", ft3." + opacityChannel + ", fc" + _shader.getFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT) + ".x\n";
				code += "kil ft3." + opacityChannel + "\n";
			}
			code += "sub oc0, ft0, ft1\n";

			//we have filled the depth, lets fill world normal
			if (!normalMap) {
				code += "nrm ft0.xyz, v" + _shader.getVarying(NORMAL_VARYING) + ".xyz\n";
			} else {
				//normal tangent space
				var normalTS:int = _shader.getFreeFragmentTemp();
				code += sampleTexture(normalMap, normalMapUVChannel, normalTS, _shader.getTexture(NORMAL_TEXTURE));
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
				code += "nrm ft" + normalOutput + ".xyz, ft" + normalOutput + "\n";
				_shader.freeLastFragmentTemp();
				_shader.freeLastFragmentTemp();
				_shader.freeLastFragmentTemp();
			}
			//if do not draw specular, draw specular intesity to normalmap for deferred lighting
			if(!_drawSpecular) {
				code += "mov ft" + normalOutput + ".w, fc" + _shader.getFragmentConstant(SPECULAR_COLOR_CONSTANT) + ".xxx\n";
			}else{
				code += "mov ft" + normalOutput + ".w, fc" + _shader.getFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT) + ".y\n";
			}
			code += "mov oc1, ft" + normalOutput + "\n";

			//color
			var diffuseColor:int = _shader.getFreeFragmentTemp();
			if (diffuseMap) {
				code += sampleTexture(diffuseMap, diffuseMapUVChannel, diffuseColor, _shader.getTexture(DIFFUSE_TEXTURE));
				code += "mov oc2, ft" + diffuseColor + "\n";
			} else {
				code += "mov oc2, fc" + _shader.getFragmentConstant(DIFFUSE_COLOR_CONSTANT) + "\n";
			}
			_shader.freeLastFragmentTemp();

			//specular
			var specularColor:int = _shader.getFreeFragmentTemp();
			if (specularMap) {
				code += sampleTexture(specularMap, specularMapUVChannel, specularColor, _shader.getTexture(SPECULAR_TEXTURE));
				//specular intensity
				code += "mul ft" + specularColor + ".xyz, ft" + specularColor + ".xyz, fc" + _shader.getFragmentConstant(SPECULAR_COLOR_CONSTANT) + ".xxx\n";
				//gloss
				code += "mov ft" + specularColor + ".w, fc" + _shader.getFragmentConstant(SPECULAR_COLOR_CONSTANT) + ".w\n";
				code += "mov oc3, ft" + specularColor + "\n";
			} else {
				code += "mov oc3, fc" + _shader.getFragmentConstant(SPECULAR_COLOR_CONSTANT) + "\n";
			}
			_shader.freeLastFragmentTemp();

			_numUsedTextures = _shader.numTextureRegisters;
			_numUsedFragmentConstants = _shader.numFragmentConstants;
			return code;
		}

		override arcane function invalidateShaderProgram(updateMaterial:Boolean = true):void {
			_shader.clear();
			super.invalidateShaderProgram(updateMaterial);
		}

		override arcane function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void {
			var context3D:Context3D = stage3DProxy._context3D;
			super.activate(stage3DProxy, camera);

			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(DEPTH_FRAGMENT_CONSTANT), _depthData, 2);

			if (_shader.hasFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT)) {
				_propertiesData[0] = alphaThreshold;//used for opacity map
				_propertiesData[1] = 1;//used for normal output and normal restoring and diffuse output
				_propertiesData[2] = 0;
				_propertiesData[3] = 0;
				context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(PROPERTIES_FRAGMENT_CONSTANT), _propertiesData, 1);
			}

			if (_shader.hasFragmentConstant(DIFFUSE_COLOR_CONSTANT)) {
				_diffuseColorData[0] = colorR;
				_diffuseColorData[1] = colorG;
				_diffuseColorData[2] = colorB;
				_diffuseColorData[3] = 1;
				context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(DIFFUSE_COLOR_CONSTANT), _diffuseColorData, 1);
			}

			if (_shader.hasFragmentConstant(SPECULAR_COLOR_CONSTANT)) {
				if (specularMap) {
					_specularColorData[0] = specularIntensity;
					_specularColorData[1] = 0;
					_specularColorData[2] = 0;
					_specularColorData[3] = gloss;
				} else {
					_specularColorData[0] = specularColorR * specularIntensity;
					_specularColorData[1] = specularColorG * specularIntensity;
					_specularColorData[2] = specularColorB * specularIntensity;
					_specularColorData[3] = gloss;
				}
				context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(SPECULAR_COLOR_CONSTANT), _specularColorData, 1);
			}

			if (_shader.hasTexture(OPACITY_TEXTURE)) {
				context3D.setTextureAt(_shader.getTexture(OPACITY_TEXTURE), opacityMap.getTextureForStage3D(stage3DProxy));
			}
			if (_shader.hasTexture(NORMAL_TEXTURE)) {
				context3D.setTextureAt(_shader.getTexture(NORMAL_TEXTURE), normalMap.getTextureForStage3D(stage3DProxy));
			}
			if (_shader.hasTexture(DIFFUSE_TEXTURE)) {
				context3D.setTextureAt(_shader.getTexture(DIFFUSE_TEXTURE), diffuseMap.getTextureForStage3D(stage3DProxy));
			}
			if (_shader.hasTexture(SPECULAR_TEXTURE)) {
				context3D.setTextureAt(_shader.getTexture(SPECULAR_TEXTURE), specularMap.getTextureForStage3D(stage3DProxy));
			}
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
			if (_shader.hasAttribute(SECONDARY_UV_ATTRIBUTE)) {
				stage3DProxy.activateBuffer(_shader.getAttribute(SECONDARY_UV_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.SECONDARY_UV_DATA), renderable.getVertexOffset(TriangleSubGeometry.SECONDARY_UV_DATA), TriangleSubGeometry.SECONDARY_UV_FORMAT);
			}
			if (_shader.hasAttribute(NORMAL_ATTRIBUTE)) {
				stage3DProxy.activateBuffer(_shader.getAttribute(NORMAL_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.NORMAL_DATA), renderable.getVertexOffset(TriangleSubGeometry.NORMAL_DATA), TriangleSubGeometry.NORMAL_FORMAT);
			}
			if (_shader.hasAttribute(TANGENT_ATTRIBUTE)) {
				stage3DProxy.activateBuffer(_shader.getAttribute(TANGENT_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.TANGENT_DATA), renderable.getVertexOffset(TriangleSubGeometry.TANGENT_DATA), TriangleSubGeometry.TANGENT_FORMAT);
			}

			context3D.drawTriangles(stage3DProxy.getIndexBuffer(renderable.getIndexData()), 0, renderable.numTriangles);
		}

		public function get useSecondaryUV():Boolean {
			return (opacityMap && opacityUVChannel == TriangleSubGeometry.SECONDARY_UV_DATA) || (specularMap && specularMapUVChannel == TriangleSubGeometry.SECONDARY_UV_DATA) ||
					(normalMap && normalMapUVChannel == TriangleSubGeometry.SECONDARY_UV_DATA) || (diffuseMap && diffuseMapUVChannel == TriangleSubGeometry.SECONDARY_UV_DATA);
		}

		public function get useUV():Boolean {
			return (opacityMap && opacityUVChannel == TriangleSubGeometry.UV_DATA) || (specularMap && specularMapUVChannel == TriangleSubGeometry.UV_DATA) ||
					(normalMap && normalMapUVChannel == TriangleSubGeometry.UV_DATA) || (diffuseMap && diffuseMapUVChannel == TriangleSubGeometry.UV_DATA);
		}

		/**
		 * Overrided because of AGAL compilation version
		 * @param stage3DProxy
		 */
		override arcane function updateProgram(stage3DProxy:Stage3DProxy):void {
			var animatorCode:String = "";
			var UVAnimatorCode:String = "";
			var fragmentAnimatorCode:String = "";
			var vertexCode:String = getVertexCode();

			if (_animationSet && !_animationSet.usesCPU) {
				animatorCode = _animationSet.getAGALVertexCode(this, _animatableAttributes, _animationTargetRegisters, stage3DProxy.profile);
				if (_needFragmentAnimation)
					fragmentAnimatorCode = _animationSet.getAGALFragmentCode(this, _shadedTarget, stage3DProxy.profile);
				if (_needUVAnimation)
					UVAnimatorCode = _animationSet.getAGALUVCode(this, _UVSource, _UVTarget);
				_animationSet.doneAGALCode(this);
			} else {
				var len:uint = _animatableAttributes.length;

				// simply write attributes to targets, do not animate them
				// projection will pick up on targets[0] to do the projection
				for (var i:uint = 0; i < len; ++i)
					animatorCode += "mov " + _animationTargetRegisters[i] + ", " + _animatableAttributes[i] + "\n";
				if (_needUVAnimation)
					UVAnimatorCode = "mov " + _UVTarget + "," + _UVSource + "\n";
			}

			vertexCode = animatorCode + UVAnimatorCode + vertexCode;

			var fragmentCode:String = getFragmentCode(fragmentAnimatorCode);
			if (Debug.active) {
				trace("Compiling AGAL Code:");
				trace("--------------------");
				trace(vertexCode);
				trace("--------------------");
				trace(fragmentCode);
			}
			AGALProgram3DCache.getInstance(stage3DProxy).setProgram3D(this, vertexCode, fragmentCode, 2);
		}

		private function sampleTexture(texture:Texture2DBase, textureUVChannel:String, targetTemp:int, textureRegister:int):String {
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
			uvVarying = (textureUVChannel == TriangleSubGeometry.SECONDARY_UV_DATA) ? _shader.getVarying(SECONDARY_UV_VARYING) : _shader.getVarying(UV_VARYING);
			return "tex ft" + targetTemp + ", v" + uvVarying + ", fs" + textureRegister + " <2d," + filter + "," + format + wrap + ">\n";
		}
	}
}
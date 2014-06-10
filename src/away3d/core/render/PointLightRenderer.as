package away3d.core.render {
	import away3d.arcane;
	import away3d.core.managers.RTTBufferManager;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.traverse.EntityCollector;
	import away3d.entities.Camera3D;
	import away3d.lights.PointLight;
	import away3d.materials.compilation.ShaderState;
	import away3d.textures.Texture2DBase;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class PointLightRenderer {
		//attribute
		private static const POSITION_ATTRIBUTE:String = "aPos";
		private static const UV_ATTRIBUTE:String = "aUv";
		private static const INDEX_FRUSTUM_ATTRIBUTE:String = "aIndex";
		//varying
		private static const UV_VARYING:String = "vUv";
		private static const POSITION_VARYING:String = "vPos";
		//fragment const
		private static const DECODE_VALUES_FC:String = "cfDecodeValues";
		private static const AMBIENT_VALUES_FC:String = "cfAmbientValues";
		private static const LIGHT_FC:String = "cfLightData";
		//texture
		private static const WORLD_NORMAL_TEXTURE:String = "tWorldNormal";
		private static const SPECULAR_TEXTURE:String = "tSpecular";
		private static const DEPTH_TEXTURE:String = "tDepth";

		private static const _decodeValuesFC:Vector.<Number> = Vector.<Number>([
			1, 1 / 255, 0.5, 1,
			-0.04, 100, 0, 1]);//last 2 are not used
		private static const _ambientValuesFC:Vector.<Number> = new Vector.<Number>();
		private static const _scaleValuesVC:Vector.<Number> = Vector.<Number>([0, 0, 1, 1]);

		protected var programs:Vector.<Program3D>;
		protected var dirtyPrograms:Vector.<Boolean>;
		protected var shaderStates:Vector.<ShaderState>;

		private var _vertexCode:String;
		private var _fragmentCode:String;
		private var _shader:ShaderState;

		private var _pointLights:Vector.<PointLight>;
		private var _pointLightsLength:uint;

		private var _textureRatioX:Number = 1;
		private var _textureRatioY:Number = 1;
		private var _camera:Camera3D;
		private var _monochromeSpecular:Boolean = false;
		private var _lightData:Vector.<Number> = new Vector.<Number>();

		public function PointLightRenderer() {
			initInstance();
		}

		private function initInstance():void {
			programs = new Vector.<Program3D>(8, true);
			dirtyPrograms = new Vector.<Boolean>(8, true);
			shaderStates = new Vector.<ShaderState>(8, true);
		}

		public function render(stage3DProxy:Stage3DProxy, entityCollector:EntityCollector, hasMRTSupport:Boolean, frustumCorners:Vector.<Number>, normalTexture:Texture2DBase, depthTexture:Texture2DBase, specularTexture:Texture2DBase):void {
			var i:int;
			//store data from collector
			_camera = entityCollector.camera;

			var rttBuffer:RTTBufferManager = RTTBufferManager.getInstance(stage3DProxy);
			var index:int = stage3DProxy.stage3DIndex;
			var context3D:Context3D = stage3DProxy.context3D;
			var vertexBuffer:VertexBuffer3D = (hasMRTSupport) ? rttBuffer.renderRectToScreenVertexBuffer : rttBuffer.renderToTextureVertexBuffer;
			var indexBuffer:IndexBuffer3D = rttBuffer.indexBuffer;

			var program:Program3D = programs[index];
			if (!program) {
				program = programs[index] = context3D.createProgram();
				dirtyPrograms[index] = true;
			}

			_shader = shaderStates[index];
			if (!_shader) {
				_shader = shaderStates[index] = new ShaderState();
			}

			//set point lights
			if (entityCollector.pointLights.length != _pointLightsLength) {
				_pointLights = entityCollector.pointLights;
				_pointLightsLength = _pointLights.length;
				dirtyPrograms[index] = true;
			}
			if (_pointLightsLength == 0) return;

			if (dirtyPrograms[index]) {
				_shader.clear();
				compileVertexProgram();
				compileFragmentProgram();
				program.upload((new AGALMiniAssembler()).assemble(Context3DProgramType.VERTEX, _vertexCode, 2),
						(new AGALMiniAssembler()).assemble(Context3DProgramType.FRAGMENT, _fragmentCode, 2));
				dirtyPrograms[index] = false;
			}
			context3D.setProgram(program);

			//in future, enable stencil test optimization in FlashPlayer 15, when we don't need to clear it each time

			context3D.setVertexBufferAt(_shader.getAttribute(POSITION_ATTRIBUTE), vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context3D.setVertexBufferAt(_shader.getAttribute(UV_ATTRIBUTE), vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			context3D.setVertexBufferAt(_shader.getAttribute(INDEX_FRUSTUM_ATTRIBUTE), vertexBuffer, 4, Context3DVertexBufferFormat.FLOAT_1);

			context3D.setTextureAt(_shader.getTexture(WORLD_NORMAL_TEXTURE), normalTexture.getTextureForStage3D(stage3DProxy));
			if (_shader.hasTexture(SPECULAR_TEXTURE)) {
				context3D.setTextureAt(_shader.getTexture(SPECULAR_TEXTURE), specularTexture.getTextureForStage3D(stage3DProxy));
			}

			if (_shader.hasTexture(DEPTH_TEXTURE)) {
				context3D.setTextureAt(_shader.getTexture(DEPTH_TEXTURE), depthTexture.getTextureForStage3D(stage3DProxy));
			}

			//VERTEX DATA
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, frustumCorners, 4);
			_scaleValuesVC[0] = _textureRatioX;
			_scaleValuesVC[1] = _textureRatioY;
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _scaleValuesVC, 1);
			//FRAGMENT DATA
			if (_shader.hasFragmentConstant(DECODE_VALUES_FC)) {
				_decodeValuesFC[3] = _camera.projection.far;
				context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(DECODE_VALUES_FC), _decodeValuesFC, _shader.getFragmentConstantStride(DECODE_VALUES_FC));
			}

			var globalAmbientR:Number = 0;
			var globalAmbientG:Number = 0;
			var globalAmbientB:Number = 0;
			var k:int = 0;
			for (i = 0; i < _pointLightsLength; i++) {
				var light:PointLight = _pointLights[i];
				var pos:Vector3D = _camera.inverseSceneTransform.transformVector(light.scenePosition);
				_lightData[k++] = pos.x;
				_lightData[k++] = pos.y;
				_lightData[k++] = pos.z;
				_lightData[k++] = light._radius;
				_lightData[k++] = light._diffuseR;
				_lightData[k++] = light._diffuseG;
				_lightData[k++] = light._diffuseB;
				_lightData[k++] = light._fallOffFactor;
				_lightData[k++] = light._specularR;
				_lightData[k++] = light._specularG;
				_lightData[k++] = light._specularB;
				_lightData[k++] = 1;

				globalAmbientR += light._ambientR;
				globalAmbientG += light._ambientG;
				globalAmbientB += light._ambientB;
			}

			if (_shader.hasFragmentConstant(AMBIENT_VALUES_FC)) {
				_ambientValuesFC[0] = globalAmbientR;
				_ambientValuesFC[1] = globalAmbientG;
				_ambientValuesFC[2] = globalAmbientB;
				_ambientValuesFC[3] = 1;
				context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(AMBIENT_VALUES_FC), _ambientValuesFC, _shader.getFragmentConstantStride(AMBIENT_VALUES_FC));
			}

			if (_shader.hasFragmentConstant(LIGHT_FC)) {
				context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(LIGHT_FC), _lightData, _shader.getFragmentConstantStride(LIGHT_FC));
			}

			context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			context3D.drawTriangles(indexBuffer, 0, 2);

			context3D.setTextureAt(0, null);
			context3D.setTextureAt(1, null);
			context3D.setTextureAt(2, null);
		}

		private function compileFragmentProgram():void {
			_fragmentCode = "";
			var normalDepth:int = _shader.getFreeFragmentTemp();
			var normal:int = _shader.getFreeFragmentTemp();
			var decodeValues:int = _shader.getFragmentConstant(DECODE_VALUES_FC, 2);//1, 1 / 255.0, 0.5, far
			_fragmentCode += "tex ft" + normalDepth + ", v" + _shader.getVarying(UV_VARYING) + ", fs" + _shader.getTexture(WORLD_NORMAL_TEXTURE) + " <2d,nearst,nomip,clamp>\n";
			//decode sphere map
			//fragmentCode += "mul ft" + normal + ".xy, ft" + normalDepth + ".xy, fc" + decodeValues + ".z\n";
			//fragmentCode += "sub ft" + normal + ".xy, ft" + normal + ".xy, fc" + decodeValues + ".w\n";
			//fragmentCode += "mul ft" + normal + ".xy, ft" + normal + ".xy, ft" + normal + ".xy\n";
			//fragmentCode += "add ft" + normal + ".z, ft" + normal + ".x, ft" + normal + ".y\n";
			//fragmentCode += "div ft" + normal + ".z, ft" + normal + ".z, fc" + decodeValues + ".z\n";
			//fragmentCode += "sub ft" + normal + ".z, fc" + decodeValues + ".x, ft" + normal + ".z\n";
			//fragmentCode += "sqt ft" + normal + ".z, ft" + normal + ".z\n";
			//fragmentCode += "mul ft" + normal + ".xy, ft" + normal + ".xy, ft" + normal + ".zz\n";
			//fragmentCode += "div ft" + normal + ".z, ft" + normal + ".z, fc" + decodeValues + ".w\n";
			//fragmentCode += "sub ft" + normal + ".z, fc" + decodeValues + ".x, ft" + normal + ".z\n";
			//decode normal
			_fragmentCode += "sub ft" + normal + ".xy, ft" + normalDepth + ".xy, fc" + decodeValues + ".zz\n";
			_fragmentCode += "add ft" + normal + ".xy, ft" + normal + ".xy, ft" + normal + ".xy\n";
			_fragmentCode += "mov ft" + normal + ".z, fc" + (decodeValues + 1) + ".x\n";//-0.04
			_fragmentCode += "dp3 ft" + normal + ".z, ft" + normal + ".xyz, ft" + normal + ".xyz\n";
			_fragmentCode += "sub ft" + normal + ".z, fc" + decodeValues + ".x, ft" + normal + ".z\n";
			_fragmentCode += "sqt ft" + normal + ".z, ft" + normal + ".z\n";
			_fragmentCode += "neg ft" + normal + ".z, ft" + normal + ".z\n";

			//decode view position
			var viewPosition:int = _shader.getFreeFragmentTemp();
			_fragmentCode += "mul ft" + viewPosition + ", ft" + normalDepth + ".zw, fc" + decodeValues + ".xy\n";
			_fragmentCode += "add ft" + viewPosition + ".z, ft" + viewPosition + ".x, ft" + viewPosition + ".y\n";
			_fragmentCode += "mul ft" + viewPosition + ".z, ft" + viewPosition + ".z, fc" + decodeValues + ".w\n";
			_fragmentCode += "mul ft" + viewPosition + ".xyz, ft" + viewPosition + ".zzz, v" + _shader.getVarying(POSITION_VARYING) + ".xyz\n";
			_fragmentCode += "mov ft" + viewPosition + ".w, v" + _shader.getVarying(POSITION_VARYING) + ".w\n";

			var specularBuffer:int = _shader.getFreeFragmentTemp();
			_fragmentCode += "tex ft" + specularBuffer + ", v" + _shader.getVarying(UV_VARYING) + ", fs" + _shader.getTexture(SPECULAR_TEXTURE) + " <2d,nearst,nomip,clamp>\n";
			_fragmentCode += "mul ft" + specularBuffer + ".w, ft" + specularBuffer + ".w, fc" + (decodeValues + 1) + ".y\n";//*100

			var viewVector:int = _shader.getFreeFragmentTemp();
			_fragmentCode += "nrm ft" + viewVector + ".xyz, v" + _shader.getVarying(POSITION_VARYING) + ".xyz\n";
			_fragmentCode += "mov ft" + viewVector + ".w, v" + _shader.getVarying(POSITION_VARYING) + ".w\n";
			_fragmentCode += "neg ft" + viewVector + ".xyz, ft" + viewVector + ".xyz\n";

			var diffuseLight:int = _shader.getFreeFragmentTemp();
			var specularLight:int = _shader.getFreeFragmentTemp();
			var output:int = _shader.getFreeFragmentTemp();

			var lightDataStart:int = _shader.getFragmentConstant(LIGHT_FC, _pointLightsLength * 3);
			for (var i:uint = 0; i < _pointLightsLength; i++) {
				var lightData:int = lightDataStart + i * 3;
				var temp:int = _shader.getFreeFragmentTemp();
				var nDotL:int = _shader.getFreeFragmentTemp();

				var lightVector:int = _shader.getFreeFragmentTemp();//w is length of it
				_fragmentCode += "sub ft" + lightVector + ".xyz, fc" + lightData + ".xyz, ft" + viewPosition + ".xyz\n";
				_fragmentCode += "dp3 ft" + lightVector + ".w, ft" + lightVector + ".xyz, ft" + lightVector + ".xyz\n";
				_fragmentCode += "sqt ft" + lightVector + ".w, ft" + lightVector + ".w\n";
				_fragmentCode += "sub ft" + lightVector + ".w, ft" + lightVector + ", fc" + lightData + ".w\n";//radius
				_fragmentCode += "mul ft" + lightVector + ".w, ft" + lightVector + ", fc" + (lightData + 1) + ".w\n";//falloff
				_fragmentCode += "sat ft" + lightVector + ".w, ft" + lightVector + ".w\n";
				_fragmentCode += "sub ft" + lightVector + ".w, fc" + decodeValues + ".x, ft" + lightVector + ".w\n";//1-w
				_fragmentCode += "nrm ft" + lightVector + ".xyz, ft" + lightVector + ".xyz\n";

				//DIFFUSE
				_fragmentCode += "dp3 ft" + temp + ".x, ft" + normal + ".xyz, ft" + lightVector + ".xyz\n";
				_fragmentCode += "sat ft" + temp + ".x, ft" + temp + ".x\n";
				_fragmentCode += "mov ft" + nDotL + ".x, ft" + temp + ".x\n";//copy
				_fragmentCode += "mul ft" + temp + ".xyz, ft" + temp + ".xxx, fc" + (lightData + 1) + ".xyz\n";
				if (i == 0) {
					_fragmentCode += "mov ft" + temp + ".w, fc" + decodeValues + ".x\n";//1
					_fragmentCode += "mov ft" + diffuseLight + ", ft" + temp + "\n";
				} else {
					_fragmentCode += "add ft" + diffuseLight + ", ft" + diffuseLight + ".xyz, ft" + temp + ".xyz\n";
				}

				//SPECULAR
				_fragmentCode += "add ft" + temp + ".xyz, ft" + lightVector + ".xyz, ft" + viewVector + "\n";
				_fragmentCode += "nrm ft" + temp + ".xyz, ft" + temp + ".xyz\n";

				_fragmentCode += "dp3 ft" + temp + ".w, ft" + normal + ".xyz, ft" + temp + ".xyz\n";
				_fragmentCode += "sat ft" + temp + ".w, ft" + temp + ".w\n";
				_fragmentCode += "pow ft" + temp + ".w, ft" + temp + ".w, ft" + specularBuffer + ".w\n";
//				_fragmentCode += "mul ft" + temp + ".w, ft" + temp + ".w, ft" + nDotL + ".x\n";

				if (_monochromeSpecular) {
					_fragmentCode += "mul ft" + temp + ".xyz, ft" + temp + ".www, ft" + specularBuffer + ".xxx\n";//specInt*gloss
				} else {
					_fragmentCode += "mul ft" + temp + ".xyz, ft" + specularBuffer + ".xyz, ft" + temp + ".w\n";//albedo specular color
					_fragmentCode += "mul ft" + temp + ".xyz, ft" + temp + ".xyz, fc" + (lightData + 2) + ".xyz\n";//light specular color
				}

				if (i == 0) {
					_fragmentCode += "mov ft" + temp + ".w, fc" + decodeValues + ".x\n";
					_fragmentCode += "mov ft" + specularLight + ", ft" + temp + "\n";
				} else {
					_fragmentCode += "add ft" + specularLight + ".xyz, ft" + specularLight + ".xyz, ft" + temp + ".xyz\n";
				}

				_shader.removeFragmentTempUsage(temp);
				_shader.removeFragmentTempUsage(nDotL);
				_shader.removeFragmentTempUsage(lightVector);
			}
			_shader.removeFragmentTempUsage(viewVector);

			var ambientValues:int = _shader.getFragmentConstant(AMBIENT_VALUES_FC);
			_fragmentCode += "add ft" + diffuseLight + ".xyz, ft" + diffuseLight + ".xyz, fc" + ambientValues + ".xyz\n";

			if (!_monochromeSpecular) {
				_fragmentCode += "mov oc0, ft" + diffuseLight + "\n";
				_fragmentCode += "mov oc1, ft" + specularLight + "\n";
			} else {
				_fragmentCode += "mov ft" + diffuseLight + ".w, ft" + specularLight + ".x\n";
				_fragmentCode += "mov oc, ft" + diffuseLight + "\n";
			}

			_shader.removeFragmentTempUsage(specularLight);
			_shader.removeFragmentTempUsage(diffuseLight);
			_shader.removeFragmentTempUsage(normal);
		}

		private function compileVertexProgram():void {
			_vertexCode = "";
			_vertexCode += "mov op, va" + _shader.getAttribute(POSITION_ATTRIBUTE) + "\n";

			_vertexCode += "mov vt0, va" + _shader.getAttribute(UV_ATTRIBUTE) + "\n";
			_vertexCode += "mul vt0.xy, vt0.xy, vc4.xy\n";
			_vertexCode += "mov v" + _shader.getVarying(UV_VARYING) + ", vt0\n";

			_vertexCode += "mov vt0, vc[va" + _shader.getAttribute(INDEX_FRUSTUM_ATTRIBUTE) + ".x]\n";
			_vertexCode += "div vt0.xyz, vt0.xyz, vt0.z\n";
			_vertexCode += "mov v" + _shader.getVarying(POSITION_VARYING) + ", vt0\n";
		}

		public function get textureRatioX():Number {
			return _textureRatioX;
		}

		public function set textureRatioX(value:Number):void {
			_textureRatioX = value;
		}

		public function get textureRatioY():Number {
			return _textureRatioY;
		}

		public function set textureRatioY(value:Number):void {
			_textureRatioY = value;
		}

		public function get monochromeSpecular():Boolean {
			return _monochromeSpecular;
		}

		public function set monochromeSpecular(value:Boolean):void {
			_monochromeSpecular = value;
		}
	}
}
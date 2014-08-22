package away3d.core.render {
    import away3d.arcane;
    import away3d.core.managers.RTTBufferManager;
    import away3d.core.managers.Stage3DProxy;
    import away3d.core.math.Matrix3DUtils;
    import away3d.core.traverse.EntityCollector;
    import away3d.entities.Camera3D;
    import away3d.lights.DirectionalLight;
    import away3d.lights.LightBase;
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
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;

    use namespace arcane;

    public class LightBufferRenderer implements ILightRenderer {
        private static const compiler:AGALMiniAssembler = new AGALMiniAssembler();

        //attribute
        private static const POSITION_ATTRIBUTE:String = "aPos";
        private static const UV_ATTRIBUTE:String = "aUv";
        private static const INDEX_FRUSTUM_ATTRIBUTE:String = "aIndex";
        //varying
        private static const UV_VARYING:String = "vUv";
        private static const POSITION_VARYING:String = "vPos";

        private static const AMBIENT_VALUES_FC:String = "cfAmbientValues";
        private static const LIGHT_FC:String = "cfLightData";
        private static const CAMERA_FC:String = "cfCameraData";
        private static const DECODE_FC:String = "cfDecodeDepth";
        private static const VIEW_TO_WORLD_FC:String = "cfWorld";
        //texture
        private static const WORLD_NORMAL_TEXTURE:String = "tWorldNormal";
        private static const DEPTH_TEXTURE:String = "tDepth";

        private static const _ambientValuesFC:Vector.<Number> = new Vector.<Number>();
        private static const _cameraFC:Vector.<Number> = new Vector.<Number>();
        private static const _decodeValuesFC:Vector.<Number> = Vector.<Number>([1, 1 / 255, 1 / 65025, 1 / 16581375]);
        private static const _scaleValuesVC:Vector.<Number> = Vector.<Number>([0, 0, 1, 1]);

        protected var programsCache:Vector.<Vector.<Program3D>>;
        protected var context3Ds:Vector.<Context3D>;
        protected var dirtyPrograms:Vector.<Boolean>;
        protected var programHash:Vector.<String>;
        protected var shaderStates:Vector.<Vector.<ShaderState>>;

        private var _vertexCode:String;
        private var _fragmentCode:String;

        private var _textureRatioX:Number = 1;
        private var _textureRatioY:Number = 1;

        private var _lightData:Vector.<Number> = new Vector.<Number>();

        private var _directionalLights:Vector.<DirectionalLight>;
        private var _pointLights:Vector.<PointLight>;
        private var _numDirLights:uint = 0;
        private var _numPointLights:uint = 0;

        private var _specularEnabled:Boolean = true;
        private var _coloredSpecularOutput:Boolean = false;
        private var _diffuseEnabled:Boolean = true;

        private var _profile:String;

        public function LightBufferRenderer() {
            initInstance();
        }

        private function initInstance():void {
            programsCache = new Vector.<Vector.<Program3D>>(8, true);
            dirtyPrograms = new Vector.<Boolean>(8, true);
            shaderStates = new Vector.<Vector.<ShaderState>>(8, true);
            context3Ds = new Vector.<Context3D>(8, true);
        }

        public function render(stage3DProxy:Stage3DProxy, entityCollector:EntityCollector, hasMRTSupport:Boolean, frustumCorners:Vector.<Number>, normalTexture:Texture2DBase, depthTexture:Texture2DBase = null):void {
            var i:int;
            var len:int;
            //store data from collector
            var camera:Camera3D = entityCollector.camera;

            //set point lights
            if (entityCollector.numDeferredDirectionalLights != _numDirLights || entityCollector.numDeferredPointLights != _numPointLights) {
                _directionalLights = entityCollector.deferredDirectionalLights;
                _pointLights = entityCollector.deferredPointLights;
                _numDirLights = entityCollector.numDeferredDirectionalLights;
                _numPointLights = entityCollector.numDeferredPointLights;
                dirtyPrograms[index] = true;
            }

            if (_numDirLights == 0 && _numPointLights == 0) return;

            var maxLightCountPerBatch:int = (hasMRTSupport) ? 18 : 7;
            var numDirectionalPrograms:int = Math.ceil(_numDirLights / maxLightCountPerBatch);
            var numPointPrograms:int = Math.ceil(_numPointLights / maxLightCountPerBatch);

            var rttBuffer:RTTBufferManager = RTTBufferManager.getInstance(stage3DProxy);
            var index:int = stage3DProxy.stage3DIndex;
            var context3D:Context3D = stage3DProxy.context3D;

            var programs:Vector.<Program3D> = programsCache[index];
            if (!programs) {
                programs = programsCache[index] = new Vector.<Program3D>(numDirectionalPrograms + numPointPrograms, true);
                programHash = new Vector.<String>();
                dirtyPrograms[index] = true;
            }

            if (context3Ds[index] != context3D) {
                context3Ds[index] = context3D;
                len = programs.length;
                for (i = 0; i < len; i++) {
                    if (!programs[i]) continue;
                    programs[i].dispose();
                    programs[i] = null;
                }
            }

            var shaders:Vector.<ShaderState> = shaderStates[index];
            if (!shaderStates[index]) {
                shaders = shaderStates[index] = new Vector.<ShaderState>(numDirectionalPrograms + numPointPrograms, true);
            }

            var shader:ShaderState;
            var lightCountToDraw:int;
            if (dirtyPrograms[index]) {
                var batchIndex:int = 0;
                var program:Program3D;
                lightCountToDraw = _numDirLights;
                for (i = 0; i < numDirectionalPrograms; i++) {
                    program = programs[batchIndex];
                    if (!program) {
                        program = programs[batchIndex] = context3D.createProgram();
                    }
                    shader = shaders[batchIndex];
                    if (!shader) {
                        shader = shaders[batchIndex] = new ShaderState();
                    }

                    shader.clear();
                    compileVertexProgram(shader);
                    compileDirectionalFragmentProgram(Math.min(maxLightCountPerBatch, lightCountToDraw), shader);
                    lightCountToDraw -= maxLightCountPerBatch;
                    program.upload(compiler.assemble(Context3DProgramType.VERTEX, _vertexCode, 2), compiler.assemble(Context3DProgramType.FRAGMENT, _fragmentCode, 2));
                    programs[batchIndex] = program;
                    shaders[batchIndex] = shader;
                    batchIndex++;
                }

                lightCountToDraw = _numPointLights;
                for (i = 0; i < numPointPrograms; i++) {
                    program = programs[batchIndex];
                    if (!program) {
                        program = programs[batchIndex] = context3D.createProgram();
                    }
                    shader = shaders[batchIndex];
                    if (!shader) {
                        shader = shaders[batchIndex] = new ShaderState();
                    }
                    shader.clear();
                    compileVertexProgram(shader);
                    compilePointFragmentProgram(Math.min(maxLightCountPerBatch, lightCountToDraw), shader);
                    lightCountToDraw -= maxLightCountPerBatch;
                    program.upload(compiler.assemble(Context3DProgramType.VERTEX, _vertexCode, 2), compiler.assemble(Context3DProgramType.FRAGMENT, _fragmentCode, 2));
                    programs[batchIndex] = program;
                    shaders[batchIndex] = shader;
                    batchIndex++;
                }
                shader = null;
                program = null;
                dirtyPrograms[index] = false;
            }

            shader = shaders[0];

            var vertexBuffer:VertexBuffer3D = (hasMRTSupport) ? rttBuffer.renderRectToScreenVertexBuffer : rttBuffer.renderToTextureVertexBuffer;
            var indexBuffer:IndexBuffer3D = rttBuffer.indexBuffer;
            //in future, enable stencil test optimization in FlashPlayer 15, when we don't need to clear it each time
            context3D.setVertexBufferAt(shader.getAttribute(POSITION_ATTRIBUTE), vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
            context3D.setVertexBufferAt(shader.getAttribute(UV_ATTRIBUTE), vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
            context3D.setVertexBufferAt(shader.getAttribute(INDEX_FRUSTUM_ATTRIBUTE), vertexBuffer, 4, Context3DVertexBufferFormat.FLOAT_1);

            //VERTEX DATA
            context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, frustumCorners, 4);
            _scaleValuesVC[0] = _textureRatioX;
            _scaleValuesVC[1] = _textureRatioY;
            context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _scaleValuesVC, 1);

            var offsetLight:int = 0;
            var drawCalls:int = 0;
            context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
            for (i = 0; i < numDirectionalPrograms; i++) {
                activatePass(shaders[i], camera, stage3DProxy, normalTexture, depthTexture);
                activateDirectionalLightData(shaders[i], context3D, offsetLight, Math.min(maxLightCountPerBatch, _numDirLights - offsetLight));
                context3D.setProgram(programs[i]);
                context3D.drawTriangles(indexBuffer, 0, 2);
                drawCalls++;
                if (drawCalls == 1) {
                    context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
                }
                offsetLight += maxLightCountPerBatch;
            }

            offsetLight = 0;
            for (i = numDirectionalPrograms; i < numDirectionalPrograms+numPointPrograms; i++) {
                activatePass(shaders[i], camera, stage3DProxy, normalTexture, depthTexture);
                activatePointLightData(shaders[i], context3D, offsetLight, Math.min(maxLightCountPerBatch, _numPointLights - offsetLight));
                context3D.setProgram(programs[i]);
                context3D.drawTriangles(indexBuffer, 0, 2);
                drawCalls++;
                if (drawCalls == 1) {
                    context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
                }
                offsetLight += maxLightCountPerBatch;
            }

            context3D.setVertexBufferAt(0, null);
            context3D.setVertexBufferAt(1, null);
            context3D.setVertexBufferAt(2, null);
            context3D.setTextureAt(0, null);
            context3D.setTextureAt(1, null);
            context3D.setTextureAt(2, null);
        }

        private function activatePointLightData(shader:ShaderState, context3D:Context3D, from:int, count:int):void {
            var globalAmbientR:Number = 0;
            var globalAmbientG:Number = 0;
            var globalAmbientB:Number = 0;

            var k:int = 0;
            var i:int;
            for (i = from; i < from+count; i++) {
                var light:PointLight = _pointLights[i];
                var radius:Number = light._radius;
                var falloff:Number = light._fallOffFactor;
                var posDir:Vector3D = light.scenePosition;
                _lightData[k++] = posDir.x;
                _lightData[k++] = posDir.y;
                _lightData[k++] = posDir.z;

                _lightData[k++] = 1;
                _lightData[k++] = light._diffuseR;
                _lightData[k++] = light._diffuseG;
                _lightData[k++] = light._diffuseB;
                _lightData[k++] = radius * radius;
                _lightData[k++] = light._specularR;
                _lightData[k++] = light._specularG;
                _lightData[k++] = light._specularB;
                _lightData[k++] = falloff;

                globalAmbientR += light._ambientR;
                globalAmbientG += light._ambientG;
                globalAmbientB += light._ambientB;
            }

            if (shader.hasFragmentConstant(LIGHT_FC)) {
                context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, shader.getFragmentConstant(LIGHT_FC), _lightData, shader.getFragmentConstantStride(LIGHT_FC));
            }

            if (shader.hasFragmentConstant(AMBIENT_VALUES_FC)) {
                _ambientValuesFC[0] = globalAmbientR;
                _ambientValuesFC[1] = globalAmbientG;
                _ambientValuesFC[2] = globalAmbientB;
                _ambientValuesFC[3] = 100;//decode gloss
                context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, shader.getFragmentConstant(AMBIENT_VALUES_FC), _ambientValuesFC, shader.getFragmentConstantStride(AMBIENT_VALUES_FC));
            }
        }

        private function activateDirectionalLightData(shader:ShaderState, context3D:Context3D, from:int, count:int):void {
            var globalAmbientR:Number = 0;
            var globalAmbientG:Number = 0;
            var globalAmbientB:Number = 0;

            var k:int = 0;
            for (var i:int = from; i < from+count; i++) {
                var light:LightBase = _directionalLights[i];
                var posDir:Vector3D = (light as DirectionalLight).sceneDirection;
                var dx:Number = posDir.x;
                var dy:Number = posDir.y;
                var dz:Number = posDir.z;
                var nrm:Number = 1 / Math.sqrt(dx * dx + dy * dy + dz * dz);
                _lightData[k++] = -posDir.x * nrm;
                _lightData[k++] = -posDir.y * nrm;
                _lightData[k++] = -posDir.z * nrm;
                _lightData[k++] = 1;
                _lightData[k++] = light._diffuseR;
                _lightData[k++] = light._diffuseG;
                _lightData[k++] = light._diffuseB;
                _lightData[k++] = 0;
                _lightData[k++] = light._specularR;
                _lightData[k++] = light._specularG;
                _lightData[k++] = light._specularB;
                _lightData[k++] = 0;

                globalAmbientR += light._ambientR;
                globalAmbientG += light._ambientG;
                globalAmbientB += light._ambientB;
            }

            if (shader.hasFragmentConstant(LIGHT_FC)) {
                context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, shader.getFragmentConstant(LIGHT_FC), _lightData, shader.getFragmentConstantStride(LIGHT_FC));
            }

            if (shader.hasFragmentConstant(AMBIENT_VALUES_FC)) {
                _ambientValuesFC[0] = globalAmbientR;
                _ambientValuesFC[1] = globalAmbientG;
                _ambientValuesFC[2] = globalAmbientB;
                _ambientValuesFC[3] = 100;//decode gloss
                context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, shader.getFragmentConstant(AMBIENT_VALUES_FC), _ambientValuesFC, shader.getFragmentConstantStride(AMBIENT_VALUES_FC));
            }
        }

        private function activatePass(shader:ShaderState, camera:Camera3D, stage3DProxy:Stage3DProxy, normalTexture:Texture2DBase, depthTexture:Texture2DBase):void {
            var context3D:Context3D = stage3DProxy.context3D;
            context3D.setTextureAt(shader.getTexture(WORLD_NORMAL_TEXTURE), normalTexture.getTextureForStage3D(stage3DProxy));
            if (shader.hasTexture(DEPTH_TEXTURE)) {
                context3D.setTextureAt(shader.getTexture(DEPTH_TEXTURE), depthTexture.getTextureForStage3D(stage3DProxy));
            }
            //FRAGMENT GLOBAL VALUES
            if (shader.hasFragmentConstant(CAMERA_FC)) {
                _cameraFC[0] = camera.scenePosition.x;
                _cameraFC[1] = camera.scenePosition.y;
                _cameraFC[2] = camera.scenePosition.z;
                _cameraFC[3] = 1;
                context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, shader.getFragmentConstant(CAMERA_FC), _cameraFC, shader.getFragmentConstantStride(CAMERA_FC));
            }

            if (shader.hasFragmentConstant(DECODE_FC)) {
                var raw:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
                camera.projection.matrix.copyRawDataTo(raw);
                _decodeValuesFC[4] = 0;
                _decodeValuesFC[5] = 0;
                _decodeValuesFC[6] = raw[14];
                _decodeValuesFC[7] = -raw[10];
                context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, shader.getFragmentConstant(DECODE_FC), _decodeValuesFC, shader.getFragmentConstantStride(DECODE_FC));
            }

            if (shader.hasFragmentConstant(VIEW_TO_WORLD_FC)) {
                var mat:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
                mat.copyFrom(camera.sceneTransform);
                context3D.setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT, shader.getFragmentConstant(VIEW_TO_WORLD_FC), mat, true);
            }
        }

        private function compilePointFragmentProgram(numLights:int, shader:ShaderState):void {
            _fragmentCode = "";

            var normal:int = shader.getFreeFragmentTemp();
            _fragmentCode += "tex ft" + normal + ", v" + shader.getVarying(UV_VARYING) + ", fs" + shader.getTexture(WORLD_NORMAL_TEXTURE) + " <2d,nearst,nomip,clamp>\n";

            if (_specularEnabled) {
                _fragmentCode += "mul ft" + normal + ".w, ft" + normal + ".w, fc" + shader.getFragmentConstant(AMBIENT_VALUES_FC) + ".w\n";//100
            }

            var depth:int = shader.getFreeFragmentTemp();
            var decode:int = shader.getFragmentConstant(DECODE_FC, 2);
            _fragmentCode += "tex ft" + depth + ", v" + shader.getVarying(UV_VARYING) + ", fs" + shader.getTexture(DEPTH_TEXTURE) + " <2d,nearst,nomip,clamp>\n";
            _fragmentCode += "dp4 ft" + depth + ".z, ft" + depth + ", fc" + decode + "\n";
            _fragmentCode += "add ft" + depth + ".z, ft" + depth + ".z, fc" + (decode + 1) + ".w\n";
            _fragmentCode += "div ft" + depth + ".z, fc" + (decode + 1) + ".z, ft" + depth + ".z\n";
            _fragmentCode += "mul ft" + depth + ".xyz, ft" + depth + ".z, v" + shader.getVarying(POSITION_VARYING) + ".xyz\n";
            _fragmentCode += "mov ft" + depth + ".w, v" + shader.getVarying(POSITION_VARYING) + ".w\n";
            //TODO: can be done without matrix, just project on the camera view direction
            _fragmentCode += "m44 ft" + depth + ", ft" + depth + ", fc" + shader.getFragmentConstant(VIEW_TO_WORLD_FC, 4) + "\n";

            if (_diffuseEnabled) {
                var accumulationDiffuse:int = shader.getFreeFragmentTemp();
                _fragmentCode += "mov ft" + accumulationDiffuse + ".xyz, fc" + shader.getFragmentConstant(AMBIENT_VALUES_FC) + ".xyz\n";
                _fragmentCode += "mov ft" + accumulationDiffuse + ".w, fc" + (decode + 1) + ".x\n";
            }

            if (_specularEnabled && _coloredSpecularOutput) {
                var accumulationSpecular:int = shader.getFreeFragmentTemp();
                _fragmentCode += "mov ft" + accumulationSpecular + ", fc" + (decode + 1) + ".xxxx\n";
            }

            var lightConstants:int = shader.getFragmentConstant(LIGHT_FC, numLights * 3);
            for (var i:uint = 0; i < numLights; i++) {
                var lightValues:int = lightConstants + i * 3;
                var lightDir:int = shader.getFreeFragmentTemp();
                _fragmentCode += "sub ft" + lightDir + ", fc" + lightValues + ", ft" + depth + "\n";
                _fragmentCode += "dp3 ft" + lightDir + ".w, ft" + lightDir + ", ft" + lightDir + "\n";
                _fragmentCode += "sub ft" + lightDir + ".w, ft" + lightDir + ".w, fc" + (lightValues + 1) + ".w\n";
                _fragmentCode += "mul ft" + lightDir + ".w, ft" + lightDir + ".w, fc" + (lightValues + 2) + ".w\n";
                _fragmentCode += "sat ft" + lightDir + ".w, ft" + lightDir + ".w\n";
                _fragmentCode += "sub ft" + lightDir + ".w, fc" + lightValues + ".w, ft" + lightDir + ".w\n";
                _fragmentCode += "nrm ft" + lightDir + ".xyz, ft" + lightDir + ".xyz\n";

                if (_diffuseEnabled) {
                    var tempDiffuseCalculation:int = shader.getFreeFragmentTemp();
                    _fragmentCode += "dp3 ft" + tempDiffuseCalculation + ".x, ft" + lightDir + ", ft" + normal + ".xyz\n";
                    _fragmentCode += "sat ft" + tempDiffuseCalculation + ".x, ft" + tempDiffuseCalculation + ".x\n";
                    _fragmentCode += "mul ft" + tempDiffuseCalculation + ".x, ft" + tempDiffuseCalculation + ".x, ft" + lightDir + ".w\n";
                    _fragmentCode += "mul ft" + tempDiffuseCalculation + ".xyz, ft" + tempDiffuseCalculation + ".xxx, fc" + (lightValues + 1) + ".xyz\n";
                    _fragmentCode += "add ft" + accumulationDiffuse + ".xyz, ft" + accumulationDiffuse + ".xyz, ft" + tempDiffuseCalculation + ".xyz\n";
                    shader.removeFragmentTempUsage(tempDiffuseCalculation);
                }

                if (_specularEnabled) {
                    var tempSpecularCalculation:int = shader.getFreeFragmentTemp();
                    _fragmentCode += "sub ft" + tempSpecularCalculation + ", fc" + shader.getFragmentConstant(CAMERA_FC) + ", ft" + depth + "\n";
                    _fragmentCode += "nrm ft" + tempSpecularCalculation + ".xyz, ft" + tempSpecularCalculation + ".xyz\n";
                    _fragmentCode += "add ft" + tempSpecularCalculation + ".xyz, ft" + tempSpecularCalculation + ".xyz, ft" + lightDir + ".xyz\n";
                    _fragmentCode += "nrm ft" + tempSpecularCalculation + ".xyz, ft" + tempSpecularCalculation + ".xyz\n";
                    _fragmentCode += "dp3 ft" + tempSpecularCalculation + ".x, ft" + normal + ", ft" + tempSpecularCalculation + "\n";
                    _fragmentCode += "sat ft" + tempSpecularCalculation + ".x, ft" + tempSpecularCalculation + ".x\n";
                    _fragmentCode += "pow ft" + tempSpecularCalculation + ".x, ft" + tempSpecularCalculation + ".x, ft" + normal + ".w\n";//gloss
                    if (_coloredSpecularOutput) {
                        _fragmentCode += "mul ft" + tempSpecularCalculation + ".xyz, ft" + tempSpecularCalculation + ".xxx, fc" + (lightValues + 2) + ".xyz\n";
                        _fragmentCode += "add ft" + accumulationSpecular + ".xyz, ft" + accumulationSpecular + ".xyz, ft" + tempSpecularCalculation + ".xyz\n";
                    } else {
                        _fragmentCode += "add ft" + accumulationDiffuse + ".w, ft" + accumulationDiffuse + ".w, ft" + tempSpecularCalculation + ".x\n";
                    }
                    shader.removeFragmentTempUsage(tempSpecularCalculation);
                }

                shader.removeFragmentTempUsage(lightDir);
            }

            if (_coloredSpecularOutput && _diffuseEnabled) {
                _fragmentCode += "mov oc0, ft" + accumulationDiffuse + "\n";
                _fragmentCode += "mov oc1, ft" + accumulationSpecular + "\n";
            } else if (_coloredSpecularOutput && !_diffuseEnabled) {
                _fragmentCode += "mov oc0, ft" + accumulationSpecular + "\n";
            } else {
                _fragmentCode += "mov oc0, ft" + accumulationDiffuse + "\n";
            }
        }

        private function compileDirectionalFragmentProgram(numDirectionals:uint, shader:ShaderState):void {
            _fragmentCode = "";

            var normal:int = shader.getFreeFragmentTemp();
            _fragmentCode += "tex ft" + normal + ", v" + shader.getVarying(UV_VARYING) + ", fs" + shader.getTexture(WORLD_NORMAL_TEXTURE) + " <2d,nearst,nomip,clamp>\n";
            var decode:int = shader.getFragmentConstant(DECODE_FC, 2);

            if (_specularEnabled) {
                //restore gloss value
                _fragmentCode += "mul ft" + normal + ".w, ft" + normal + ".w, fc" + shader.getFragmentConstant(AMBIENT_VALUES_FC) + ".w\n";//100

                var depth:int = shader.getFreeFragmentTemp();
                _fragmentCode += "tex ft" + depth + ", v" + shader.getVarying(UV_VARYING) + ", fs" + shader.getTexture(DEPTH_TEXTURE) + " <2d,nearst,nomip,clamp>\n";
                _fragmentCode += "dp4 ft" + depth + ".z, ft" + depth + ", fc" + decode + "\n";
                _fragmentCode += "add ft" + depth + ".z, ft" + depth + ".z, fc" + (decode + 1) + ".w\n";
                _fragmentCode += "div ft" + depth + ".z, fc" + (decode + 1) + ".z, ft" + depth + ".z\n";
                _fragmentCode += "mul ft" + depth + ".xyz, ft" + depth + ".z, v" + shader.getVarying(POSITION_VARYING) + ".xyz\n";
                _fragmentCode += "mov ft" + depth + ".w, v" + shader.getVarying(POSITION_VARYING) + ".w\n";
                //TODO: can be done without matrix, just project on the camera view direction
                _fragmentCode += "m44 ft" + depth + ", ft" + depth + ", fc" + shader.getFragmentConstant(VIEW_TO_WORLD_FC, 4) + "\n";
            }

            if (_diffuseEnabled) {
                var accumulationDiffuse:int = shader.getFreeFragmentTemp();
                _fragmentCode += "mov ft" + accumulationDiffuse + ".xyz, fc" + shader.getFragmentConstant(AMBIENT_VALUES_FC) + ".xyz\n";
                _fragmentCode += "mov ft" + accumulationDiffuse + ".w, fc" + (decode + 1) + ".x\n";
            }

            if (_specularEnabled && _coloredSpecularOutput) {
                var accumulationSpecular:int = shader.getFreeFragmentTemp();
                _fragmentCode += "mov ft" + accumulationSpecular + ", fc" + (decode + 1) + ".xxxx\n";
            }

            var lightValues:int = shader.getFragmentConstant(LIGHT_FC, numDirectionals * 3);
            for (var i:uint = 0; i < numDirectionals; i++) {
                var lightOffset:int = lightValues + i * 3;
                if (_diffuseEnabled) {
                    var tempDiffuseCalculation:int = shader.getFreeFragmentTemp();
                    _fragmentCode += "dp3 ft" + tempDiffuseCalculation + ".x, fc" + lightOffset + ", ft" + normal + ".xyz\n";
                    _fragmentCode += "sat ft" + tempDiffuseCalculation + ".x, ft" + tempDiffuseCalculation + ".x\n";
                    _fragmentCode += "mul ft" + tempDiffuseCalculation + ".xyz, ft" + tempDiffuseCalculation + ".xxx, fc" + (lightOffset + 1) + ".xyz\n";
                    _fragmentCode += "add ft" + accumulationDiffuse + ".xyz, ft" + accumulationDiffuse + ".xyz, ft" + tempDiffuseCalculation + ".xyz\n";
                    shader.removeFragmentTempUsage(tempDiffuseCalculation);
                }

                if (_specularEnabled) {
                    var tempSpecularCalculation:int = shader.getFreeFragmentTemp();
                    _fragmentCode += "sub ft" + tempSpecularCalculation + ", fc" + shader.getFragmentConstant(CAMERA_FC) + ", ft" + depth + "\n";
                    _fragmentCode += "nrm ft" + tempSpecularCalculation + ".xyz, ft" + tempSpecularCalculation + ".xyz\n";
                    _fragmentCode += "add ft" + tempSpecularCalculation + ".xyz, ft" + tempSpecularCalculation + ".xyz, fc" + lightOffset + ".xyz\n";
                    _fragmentCode += "nrm ft" + tempSpecularCalculation + ".xyz, ft" + tempSpecularCalculation + ".xyz\n";
                    _fragmentCode += "dp3 ft" + tempSpecularCalculation + ".x, ft" + normal + ", ft" + tempSpecularCalculation + "\n";
                    _fragmentCode += "sat ft" + tempSpecularCalculation + ".x, ft" + tempSpecularCalculation + ".x\n";
                    _fragmentCode += "pow ft" + tempSpecularCalculation + ".x, ft" + tempSpecularCalculation + ".x, ft" + normal + ".w\n";//gloss
                    if (_coloredSpecularOutput) {
                        _fragmentCode += "mul ft" + tempSpecularCalculation + ".xyz, ft" + tempSpecularCalculation + ".xxx, fc" + (lightOffset + 2) + ".xyz\n";
                        _fragmentCode += "add ft" + accumulationSpecular + ".xyz, ft" + accumulationSpecular + ".xyz, ft" + tempSpecularCalculation + ".xyz\n";
                    } else {
                        _fragmentCode += "add ft" + accumulationDiffuse + ".w, ft" + accumulationDiffuse + ".w, ft" + tempSpecularCalculation + ".x\n";
                    }
                    shader.removeFragmentTempUsage(tempSpecularCalculation);
                }
            }

            if (_coloredSpecularOutput && _diffuseEnabled) {
                _fragmentCode += "mov oc0, ft" + accumulationDiffuse + "\n";
                _fragmentCode += "mov oc1, ft" + accumulationSpecular + "\n";
            } else if (_coloredSpecularOutput && !_diffuseEnabled) {
                _fragmentCode += "mov oc0, ft" + accumulationSpecular + "\n";
            } else {
                _fragmentCode += "mov oc0, ft" + accumulationDiffuse + ".wwww\n";
            }
        }

        private function compileVertexProgram(shader:ShaderState):void {
            _vertexCode = "";
            _vertexCode += "mov op, va" + shader.getAttribute(POSITION_ATTRIBUTE) + "\n";

            _vertexCode += "mov vt0, va" + shader.getAttribute(UV_ATTRIBUTE) + "\n";
            _vertexCode += "mul vt0.xy, vt0.xy, vc4.xy\n";
            _vertexCode += "mov v" + shader.getVarying(UV_VARYING) + ", vt0\n";

            _vertexCode += "mov vt0, vc[va" + shader.getAttribute(INDEX_FRUSTUM_ATTRIBUTE) + ".x]\n";
            _vertexCode += "div vt0.xyz, vt0.xyz, vt0.z\n";
            _vertexCode += "mov v" + shader.getVarying(POSITION_VARYING) + ", vt0\n";
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

        public function get specularEnabled():Boolean {
            return _specularEnabled;
        }

        public function set specularEnabled(value:Boolean):void {
            if (_specularEnabled == value) return;
            _specularEnabled = value;
            invalidatePrograms();
        }

        public function get diffuseEnabled():Boolean {
            return _diffuseEnabled;
        }

        public function set diffuseEnabled(value:Boolean):void {
            if (_diffuseEnabled == value) return;
            _diffuseEnabled = value;
            invalidatePrograms();
        }

        public function get profile():String {
            return _profile;
        }

        public function set profile(value:String):void {
            if (_profile == value) return;
            _profile = value;
            invalidatePrograms();
        }

        public function get coloredSpecularOutput():Boolean {
            return _coloredSpecularOutput;
        }

        public function set coloredSpecularOutput(value:Boolean):void {
            if (_coloredSpecularOutput == value) return;
            _coloredSpecularOutput = value;
            invalidatePrograms();
        }

        private function invalidatePrograms():void {
            for (var i:uint = 0; i < 8; i++) {
                dirtyPrograms[i] = true;
            }
        }
    }
}
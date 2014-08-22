package away3d.core.render {
    import away3d.arcane;
    import away3d.core.managers.RTTBufferManager;
    import away3d.core.managers.Stage3DProxy;
    import away3d.core.math.Matrix3DUtils;
    import away3d.core.render.DeferredStencilSphere;
    import away3d.core.traverse.EntityCollector;
    import away3d.entities.Camera3D;
    import away3d.lights.DirectionalLight;
    import away3d.lights.PointLight;
    import away3d.materials.compilation.ShaderState;
    import away3d.textures.Texture2DBase;

    import com.adobe.utils.AGALMiniAssembler;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DBlendFactor;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DStencilAction;
    import flash.display3D.Context3DTriangleFace;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.Program3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;

    use namespace arcane;

    public class PointLightRenderer implements ILightRenderer {
        private static const NUM_BATCHED_LIGHTS_STANDARD:int = 18;
        private static const NUM_BATCHED_LIGHTS_BASELINE:int = 7;

        private static const compiler:AGALMiniAssembler = new AGALMiniAssembler();

        //attribute
        private static const POSITION_ATTRIBUTE:String = "aPos";
        private static const UV_ATTRIBUTE:String = "aUv";
        private static const INDEX_FRUSTUM_ATTRIBUTE:String = "aIndex";
        //varying
        private static const UV_VARYING:String = "vUv";
        private static const POSITION_VARYING:String = "vPos";

        private static const LIGHT_FC:String = "cfLightData";
        private static const CAMERA_FC:String = "cfCameraData";
        private static const DECODE_FC:String = "cfDecodeDepth";
        private static const VIEW_TO_WORLD_FC:String = "cfWorld";
        //texture
        private static const WORLD_NORMAL_TEXTURE:String = "tWorldNormal";
        private static const DEPTH_TEXTURE:String = "tDepth";

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
        private var _lightStencilData:Vector.<Number> = new Vector.<Number>();
        private var _stencilFragmentData:Vector.<Number> = Vector.<Number>([0, 0, 0, 0]);

        private var _pointLights:Vector.<PointLight>;
        private var _numPointLights:uint = 0;

        private var _specularEnabled:Boolean = true;
        private var _coloredSpecularOutput:Boolean = false;
        private var _diffuseEnabled:Boolean = true;

        private var _sphereVertexBuffer:VertexBuffer3D;
        private var _sphereIndex:IndexBuffer3D;
        private var _batchedSphereProgram:Program3D;
        private var _profile:String;
        private var _previousNumDrawCalls:int = 0;
        private var _numBatchedLights:int = 0;
        private var deferredStateHash:uint = 0;

        public function PointLightRenderer() {
            initInstance();
        }

        private function initInstance():void {
            programsCache = new Vector.<Vector.<Program3D>>(8, true);
            dirtyPrograms = new Vector.<Boolean>(8, true);
            shaderStates = new Vector.<Vector.<ShaderState>>(8, true);
            context3Ds = new Vector.<Context3D>(8, true);
        }

        public function render(stage3DProxy:Stage3DProxy, deferredData:DeferredData, entityCollector:EntityCollector, frustumCorners:Vector.<Number>):void {
            var i:int;
            var len:int;
            var camera:Camera3D = entityCollector.camera;
            var index:int = stage3DProxy.stage3DIndex;

            //set point lights
            if (entityCollector.numDeferredPointLights != _numPointLights) {
                _pointLights = entityCollector.deferredPointLights;
                _numPointLights = entityCollector.numDeferredPointLights;
                dirtyPrograms[index] = true;
            }

            if (_numPointLights == 0) return;

            if (_numBatchedLights == 0) {
                _numBatchedLights = (deferredData.useMRT) ? NUM_BATCHED_LIGHTS_STANDARD : NUM_BATCHED_LIGHTS_BASELINE;
            }

            var hash:uint = deferredData.getHashForDeferredLighting();
            var numDrawCalls:int = Math.ceil(_numPointLights / _numBatchedLights);
            if (_previousNumDrawCalls != numDrawCalls || deferredStateHash != hash) {
                programsCache[index] = null;
                shaderStates[index] = null;
                dirtyPrograms[index] = true;
                _previousNumDrawCalls = numDrawCalls;
                deferredStateHash = hash;
            }

            var context3D:Context3D = stage3DProxy.context3D;

            var programs:Vector.<Program3D> = programsCache[index];
            if (!programs) {
                programs = programsCache[index] = new Vector.<Program3D>(2, true);
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
                shaders = shaderStates[index] = new Vector.<ShaderState>(2, true);
            }

            var shader:ShaderState;
            var program:Program3D;

            if (dirtyPrograms[index]) {
                program = programs[0] = context3D.createProgram();
                shader = shaders[0] = new ShaderState();
                shader.clear();
                compileVertexProgram(shader);
                compilePointFragmentProgram(Math.min(_numBatchedLights, _numPointLights), shader);
                program.upload(compiler.assemble(Context3DProgramType.VERTEX, _vertexCode, 2), compiler.assemble(Context3DProgramType.FRAGMENT, _fragmentCode, 2));

                if (_numPointLights > _numBatchedLights && _numPointLights % _numBatchedLights > 0) {
                    program = programs[1] = context3D.createProgram();
                    shader = shaders[1] = new ShaderState();
                    shader.clear();
                    compileVertexProgram(shader);
                    compilePointFragmentProgram(_numPointLights % _numBatchedLights, shader);
                    program.upload(compiler.assemble(Context3DProgramType.VERTEX, _vertexCode, 2), compiler.assemble(Context3DProgramType.FRAGMENT, _fragmentCode, 2));
                }
                dirtyPrograms[index] = false;
            }

            var offsetLight:int = 0;

            context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);

            context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, frustumCorners, 4);
            _scaleValuesVC[0] = _textureRatioX;
            _scaleValuesVC[1] = _textureRatioY;
            context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _scaleValuesVC, 1);
            context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 5, camera.viewProjection, true);

            program = programs[0];
            shader = shaders[0];
            for (i = 0; i < numDrawCalls; i++) {
                shader = shaders[0];
                activatePointLightData(offsetLight, Math.min(_numBatchedLights, _numPointLights - offsetLight));
                context3D.setStencilReferenceValue(i + 1);
                context3D.setStencilActions(Context3DTriangleFace.FRONT, Context3DCompareMode.ALWAYS, Context3DStencilAction.SET, Context3DStencilAction.SET, Context3DStencilAction.SET);
                context3D.setColorMask(false, false, false, false);
                renderStencil(context3D, Math.min(_numBatchedLights, _numPointLights - offsetLight));
                context3D.setStencilActions(Context3DTriangleFace.FRONT, Context3DCompareMode.EQUAL);
                context3D.setColorMask(true, true, true, true);

                if (_numPointLights > _numBatchedLights && _numPointLights % _numBatchedLights > 0 && i == numDrawCalls - 1 && numDrawCalls != 1) {
                    program = programs[1];
                    shader = shaders[1];
                }

                renderLightBatch(shader, deferredData.useMRT, camera, stage3DProxy, deferredData.sceneNormalTexture, deferredData.sceneDepthTexture, program);

                offsetLight += _numBatchedLights;
            }
            context3D.setStencilActions();
        }

        private function renderStencil(context3D:Context3D, numSpheres:int):void {
            if (!_sphereVertexBuffer) {
                _sphereVertexBuffer = context3D.createVertexBuffer(DeferredStencilSphere.numVertices * NUM_BATCHED_LIGHTS_STANDARD, 4);
                _sphereVertexBuffer.uploadFromVector(DeferredStencilSphere.data, 0, DeferredStencilSphere.numVertices * NUM_BATCHED_LIGHTS_STANDARD);
            }

            if (!_sphereIndex) {
                _sphereIndex = context3D.createIndexBuffer(DeferredStencilSphere.numIndices * 18);
                _sphereIndex.uploadFromVector(DeferredStencilSphere.indices, 0, DeferredStencilSphere.numIndices * 18);
            }

            if (!_batchedSphereProgram) {
                _batchedSphereProgram = context3D.createProgram();
                _batchedSphereProgram.upload(compiler.assemble(Context3DProgramType.VERTEX, getStencilVertex(), 2), compiler.assemble(Context3DProgramType.FRAGMENT, getSphereFragment(), 2));
            }

            context3D.setVertexBufferAt(0, _sphereVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
            context3D.setVertexBufferAt(1, _sphereVertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_1);
            context3D.setProgram(_batchedSphereProgram);

            context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 9, _lightStencilData, numSpheres);
            context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _stencilFragmentData);

            context3D.drawTriangles(_sphereIndex, 0, DeferredStencilSphere.numIndices / 3 * numSpheres);
        }

        private function getStencilVertex():String {
            var code:String = "";
            code += "mov vt0.w, va0.w\n" +
                    "mov vt1, vc[va1.x]\n" +
                    "mul vt0.xyz, va0.xyz, vt1.w\n" +
                // add position
                    "add vt0.xyz, vt0.xyz, vt1.xyz\n" +
                // project
                    "m44 op, vt0, vc5\n";
            return code;
        }

        private function getSphereFragment():String {
            return "mov oc0, fc0\n" +
                    "mov oc1, fc0";
        }

        private function activatePointLightData(from:int, count:int):void {
            var k:int = 0;
            var stencilIndex:int = 0;
            var i:int;
            for (i = from; i < from + count; i++) {
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

                _lightStencilData[stencilIndex++] = posDir.x;
                _lightStencilData[stencilIndex++] = posDir.y;
                _lightStencilData[stencilIndex++] = posDir.z;
                _lightStencilData[stencilIndex++] = light.fallOff;
            }
        }

        private function renderLightBatch(shader:ShaderState, hasMRTSupport:Boolean, camera:Camera3D, stage3DProxy:Stage3DProxy, normalTexture:Texture2DBase, depthTexture:Texture2DBase, program:Program3D):void {
            //VERTEX DATA
            var context3D:Context3D = stage3DProxy.context3D;

            context3D.setTextureAt(shader.getTexture(WORLD_NORMAL_TEXTURE), normalTexture.getTextureForStage3D(stage3DProxy));
            if (shader.hasTexture(DEPTH_TEXTURE)) {
                context3D.setTextureAt(shader.getTexture(DEPTH_TEXTURE), depthTexture.getTextureForStage3D(stage3DProxy));
            }

            if (shader.hasFragmentConstant(LIGHT_FC)) {
                context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, shader.getFragmentConstant(LIGHT_FC), _lightData, shader.getFragmentConstantStride(LIGHT_FC));
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
                _decodeValuesFC[5] = 100;//decode gloss
                _decodeValuesFC[6] = raw[14];
                _decodeValuesFC[7] = -raw[10];
                context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, shader.getFragmentConstant(DECODE_FC), _decodeValuesFC, shader.getFragmentConstantStride(DECODE_FC));
            }

            if (shader.hasFragmentConstant(VIEW_TO_WORLD_FC)) {
                var mat:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
                mat.copyFrom(camera.sceneTransform);
                context3D.setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT, shader.getFragmentConstant(VIEW_TO_WORLD_FC), mat, true);
            }

            context3D.setProgram(program);
            var rttBuffer:RTTBufferManager = RTTBufferManager.getInstance(stage3DProxy);
            var vertexBuffer:VertexBuffer3D = (hasMRTSupport) ? rttBuffer.renderRectToScreenVertexBuffer : rttBuffer.renderToTextureVertexBuffer;
            var indexBuffer:IndexBuffer3D = rttBuffer.indexBuffer;

            context3D.setVertexBufferAt(shader.getAttribute(POSITION_ATTRIBUTE), vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
            context3D.setVertexBufferAt(shader.getAttribute(UV_ATTRIBUTE), vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
            context3D.setVertexBufferAt(shader.getAttribute(INDEX_FRUSTUM_ATTRIBUTE), vertexBuffer, 4, Context3DVertexBufferFormat.FLOAT_1);

            context3D.drawTriangles(indexBuffer, 0, 2);

            context3D.setVertexBufferAt(0, null);
            context3D.setVertexBufferAt(1, null);
            context3D.setVertexBufferAt(2, null);
            context3D.setTextureAt(0, null);
            context3D.setTextureAt(1, null);
            context3D.setTextureAt(2, null);
        }

        private function compilePointFragmentProgram(numLights:int, shader:ShaderState):void {
            _fragmentCode = "";

            var normal:int = shader.getFreeFragmentTemp();
            _fragmentCode += "tex ft" + normal + ", v" + shader.getVarying(UV_VARYING) + ", fs" + shader.getTexture(WORLD_NORMAL_TEXTURE) + " <2d,nearst,nomip,clamp>\n";

            var depth:int = shader.getFreeFragmentTemp();
            var decode:int = shader.getFragmentConstant(DECODE_FC, 2);

            if (_specularEnabled) {
                _fragmentCode += "mul ft" + normal + ".w, ft" + normal + ".w, fc" + (decode + 1) + ".y\n";//100
            }

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
                _fragmentCode += "mov ft" + accumulationDiffuse + ".xyzw, fc" + (decode + 1) + ".x\n";
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
                    _fragmentCode += "mul ft" + tempSpecularCalculation + ".x, ft" + tempSpecularCalculation + ".x, ft" + lightDir + ".w\n";
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

        private function getStencilVertexCode():String {
            return  "mov vt0.w, va0.w\n" +
                    "mul vt0.xyz, va0.xyz, vc8.w\n" +
                    "add vt0.xyz, vt0.xyz, vc8.xyz\n" +
                    "m44 vt0, vt0, vc4\n" +
                    "mul op, vt0, vc9\n";
        }

        private function getStencilFragmentCode():String {
            return "mov oc, fc0";
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

        public function get numBatchedLights():int {
            return _numBatchedLights;
        }

        public function set numBatchedLights(value:int):void {
            _numBatchedLights = value;
        }
    }
}
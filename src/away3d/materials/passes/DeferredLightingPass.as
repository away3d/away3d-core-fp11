package away3d.materials.passes {
    import away3d.arcane;
    import away3d.core.base.TriangleSubGeometry;
    import away3d.core.managers.AGALProgram3DCache;
    import away3d.core.managers.Stage3DProxy;
    import away3d.core.math.Matrix3DUtils;
    import away3d.core.pool.RenderableBase;
    import away3d.debug.Debug;
    import away3d.entities.Camera3D;
    import away3d.materials.MaterialBase;
    import away3d.materials.compilation.ShaderState;
    import away3d.textures.Texture2DBase;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DTextureFormat;
    import flash.geom.Matrix3D;

    use namespace arcane;

    public class DeferredLightingPass extends MaterialPassBase {
        //varyings
        public static const UV_VARYING:String = "vUV";
        public static const SECONDARY_UV_VARYING:String = "vSecondaryUV";
        public static const PROJ_POS_VARYING:String = "vProjPos";
        //attributes
        public static const POSITION_ATTRIBUTE:String = "aPos";
        public static const UV_ATTRIBUTE:String = "aUV";
        public static const SECONDARY_UV_ATTRIBUTE:String = "aSecondaryUV";
        //vertex constants
        public static const PROJ_MATRIX_VC:String = "cvProj";
        //fragment constants
        public static const PROPERTIES_FC:String = "cfPropertiesData";
        public static const DIFFUSE_COLOR_FC:String = "cfDiffuseColor";
        public static const SPECULAR_COLOR_FC:String = "cfSpecularColor";
        //textures
        public static const OPACITY_TEXTURE:String = "tOpacity";
        public static const DIFFUSE_TEXTURE:String = "tDiffuse";
        public static const SPECULAR_TEXTURE:String = "tSpecular";
        public static const ACCUMULATION_TEXTURE:String = "tAccumulation";
        public static const ACCUMULATION_SPECULAR_TEXTURE:String = "tAccumulationSpecular";

        public var colorR:Number = 0.8;
        public var colorG:Number = 0.8;
        public var colorB:Number = 0.8;

        public var specularColorR:uint = 0;
        public var specularColorG:uint = 0;
        public var specularColorB:uint = 0;
        public var gloss:int = 50;
        public var specularIntensity:Number = 1;

        private var hash:int;//TODO:

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

        private var _propertiesData:Vector.<Number>;
        private var _diffuseColorData:Vector.<Number>;
        private var _specularColorData:Vector.<Number>;
        private var _shader:ShaderState = new ShaderState();

        public function DeferredLightingPass(material:MaterialBase) {
            _material = material;
        }

        override arcane function getVertexCode():String {
            var code:String = "";
            var projectedPosTemp:int = _shader.getFreeVertexTemp();
            code += "m44 vt" + projectedPosTemp + ", va" + _shader.getAttribute(POSITION_ATTRIBUTE) + ", vc" + _shader.getVertexConstant(PROJ_MATRIX_VC, 4) + "\n";
            code += "mov op, vt" + projectedPosTemp + "\n";
            code += "mov v" + _shader.getVarying(PROJ_POS_VARYING) + ", vt" + projectedPosTemp + "\n";
            _shader.removeFragmentTempUsage(projectedPosTemp);

            if (useUV) {
                code += "mov v" + _shader.getVarying(UV_VARYING) + ", va" + _shader.getAttribute(UV_ATTRIBUTE) + "\n";//uv channel
            }

            if (useSecondaryUV) {
                code += "mov v" + _shader.getVarying(SECONDARY_UV_VARYING) + ", va" + _shader.getAttribute(SECONDARY_UV_ATTRIBUTE) + "\n";//secondary uv channel
            }

            _numUsedVaryings = _shader.numVaryings;
            _numUsedVertexConstants = _shader.numVertexConstants;
            _numUsedStreams = _shader.numAttributes;
            return code;
        }

        override arcane function getFragmentCode(fragmentAnimatorCode:String):String {
            var code:String = "";

            if (opacityMap) {
                code += sampleTexture(opacityMap, opacityUVChannel, 3, _shader.getTexture(OPACITY_TEXTURE));
                code += "sub ft3." + opacityChannel + ", ft3." + opacityChannel + ", fc" + _shader.getFragmentConstant(PROPERTIES_FC) + ".x\n";
                code += "kil ft3." + opacityChannel + "\n";
            }

            var renderTargetUv:int = _shader.getFreeFragmentTemp();
            code += "mov ft" + renderTargetUv + ", v" + _shader.getVarying(PROJ_POS_VARYING) + "\n";
            code += "div ft" + renderTargetUv + ", ft" + renderTargetUv + ", ft" + renderTargetUv + ".w\n";

            code += "neg ft" + renderTargetUv + ".y, ft" + renderTargetUv + ".y\n";
            code += "add ft" + renderTargetUv + ".xy, ft" + renderTargetUv + ".xy, fc" + _shader.getFragmentConstant(PROPERTIES_FC) + ".yy\n";
            code += "mul ft" + renderTargetUv + ".xy, ft" + renderTargetUv + ".xy, fc" + _shader.getFragmentConstant(PROPERTIES_FC) + ".zz\n";


            var diffuseColor:int = _shader.getFreeFragmentTemp();
            var specularColor:int = _shader.getFreeFragmentTemp();

            code += "mov ft" + diffuseColor + ", fc" + _shader.getFragmentConstant(PROPERTIES_FC) + ".wwwy\n";//0,0,0,1
            code += "mov ft" + specularColor + ", fc" + _shader.getFragmentConstant(PROPERTIES_FC) + ".wwww\n";//0,0,0,0
            var accumulationSampleRegister:int;

            if (_material.deferredData.useDiffuseLighting) {
                if (diffuseMap) {
                    code += sampleTexture(diffuseMap, diffuseMapUVChannel, diffuseColor, _shader.getTexture(DIFFUSE_TEXTURE));
                } else {
                    code += "mov ft" + diffuseColor + ", fc" + _shader.getFragmentConstant(DIFFUSE_COLOR_FC) + "\n";
                }

                accumulationSampleRegister = _shader.getFreeFragmentTemp();

                code += "tex ft" + accumulationSampleRegister + ", ft" + renderTargetUv + ".xy, fs" + _shader.getTexture(ACCUMULATION_TEXTURE) + " <2d,linear, nearest>\n";
                code += "mul ft" + diffuseColor + ".xyz, ft" + accumulationSampleRegister + ".xyz, ft" + diffuseColor + ".xyz\n";
                _shader.removeFragmentTempUsage(accumulationSampleRegister);
            }

            if (_material.deferredData.useSpecularLighting) {
                if (specularMap) {
                    code += sampleTexture(specularMap, specularMapUVChannel, specularColor, _shader.getTexture(SPECULAR_TEXTURE));
                    code += "mul ft" + specularColor + ".xyz, ft" + specularColor + ".xyz, fc" + _shader.getFragmentConstant(SPECULAR_COLOR_FC) + ".xxx\n";
                } else {
                    code += "mov ft" + specularColor + ", fc" + _shader.getFragmentConstant(SPECULAR_COLOR_FC) + "\n";
                }

                accumulationSampleRegister = _shader.getFreeFragmentTemp();

                if (_material.deferredData.useDiffuseLighting) {
                    code += "tex ft" + accumulationSampleRegister + ", ft" + renderTargetUv + ".xy, fs" + _shader.getTexture(ACCUMULATION_SPECULAR_TEXTURE) + " <2d,linear, nearest>\n";
                    code += "mul ft" + specularColor + ".xyz, ft" + accumulationSampleRegister + ".xyz, ft" + specularColor + ".xyz\n";
                } else {
                    code += "tex ft" + accumulationSampleRegister + ", ft" + renderTargetUv + ".xy, fs" + _shader.getTexture(ACCUMULATION_TEXTURE) + " <2d,linear, nearest>\n";
                    code += "mul ft" + specularColor + ".xyz, ft" + accumulationSampleRegister + ".www, ft" + specularColor + ".xyz\n";
                }

                _shader.removeFragmentTempUsage(accumulationSampleRegister);
            }

            code += "add oc, ft" + diffuseColor + ", ft" + specularColor + "\n";
//            code += "mov oc, ft" + diffuseColor + "\n";

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

            if (_shader.hasFragmentConstant(PROPERTIES_FC)) {
                if (!_propertiesData) _propertiesData = new Vector.<Number>();
                _propertiesData[0] = alphaThreshold;//used for opacity map
                _propertiesData[1] = 1;//used for normal output and normal restoring and diffuse output
                //todo support
                _propertiesData[2] = 1 / 2;//z
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
                    _specularColorData[3] = gloss / 100;
                } else {
                    _specularColorData[0] = specularColorR * specularIntensity;
                    _specularColorData[1] = specularColorG * specularIntensity;
                    _specularColorData[2] = specularColorB * specularIntensity;
                    _specularColorData[3] = gloss / 100;
                }
                context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _shader.getFragmentConstant(SPECULAR_COLOR_FC), _specularColorData, 1);
            }

            if (_shader.hasTexture(OPACITY_TEXTURE)) {
                context3D.setTextureAt(_shader.getTexture(OPACITY_TEXTURE), opacityMap.getTextureForStage3D(stage3DProxy));
            }

            if (_shader.hasTexture(DIFFUSE_TEXTURE)) {
                context3D.setTextureAt(_shader.getTexture(DIFFUSE_TEXTURE), diffuseMap.getTextureForStage3D(stage3DProxy));
            }

            if (_shader.hasTexture(SPECULAR_TEXTURE)) {
                context3D.setTextureAt(_shader.getTexture(SPECULAR_TEXTURE), specularMap.getTextureForStage3D(stage3DProxy));
            }

            if (_shader.hasTexture(ACCUMULATION_TEXTURE) && _material.deferredData.lightAccumulation) {
                context3D.setTextureAt(_shader.getTexture(ACCUMULATION_TEXTURE), _material.deferredData.lightAccumulation.getTextureForStage3D(stage3DProxy));
            }

            if (_shader.hasTexture(ACCUMULATION_SPECULAR_TEXTURE) && _material.deferredData.lightAccumulationSpecular) {
                context3D.setTextureAt(_shader.getTexture(ACCUMULATION_SPECULAR_TEXTURE), _material.deferredData.lightAccumulationSpecular.getTextureForStage3D(stage3DProxy));
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
            context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _shader.getVertexConstant(PROJ_MATRIX_VC), matrix3D, true);

            stage3DProxy.activateBuffer(_shader.getAttribute(POSITION_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.POSITION_DATA), renderable.getVertexOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);
            if (_shader.hasAttribute(UV_ATTRIBUTE)) {
                stage3DProxy.activateBuffer(_shader.getAttribute(UV_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.UV_DATA), renderable.getVertexOffset(TriangleSubGeometry.UV_DATA), TriangleSubGeometry.UV_FORMAT);
            }
            if (_shader.hasAttribute(SECONDARY_UV_ATTRIBUTE)) {
                stage3DProxy.activateBuffer(_shader.getAttribute(SECONDARY_UV_ATTRIBUTE), renderable.getVertexData(TriangleSubGeometry.SECONDARY_UV_DATA), renderable.getVertexOffset(TriangleSubGeometry.SECONDARY_UV_DATA), TriangleSubGeometry.SECONDARY_UV_FORMAT);
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

        private function sampleTexture(texture:Texture2DBase, textureUVChannel:String, targetTemp:int, textureRegister:int):String {
            var wrap:String = _repeat ? "wrap" : "clamp";
            var filter:String;
            var format:String;
            var uvVarying:int;
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

        override public function dispose():void {
            diffuseMap = null;
            normalMap = null;
            specularMap = null;
            opacityMap = null;

            _shader.clear();
            _shader = null;
            _propertiesData = null;
            _diffuseColorData = null;
            _specularColorData = null;
            super.dispose();
        }
    }
}
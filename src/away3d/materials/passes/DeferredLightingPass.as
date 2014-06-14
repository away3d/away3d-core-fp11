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

    public class DeferredLightingPass extends MaterialPassBase {
        //varyings
        public static const UV_VARYING:String = "vUV";
        public static const SECONDARY_UV_VARYING:String = "vSecondaryUV";
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

        private var _propertiesData:Vector.<Number>;
        private var _diffuseColorData:Vector.<Number>;
        private var _specularColorData:Vector.<Number>;
        private var _shader:ShaderState = new ShaderState();

        public function DeferredLightingPass() {
        }

        override arcane function getVertexCode():String {
            var code:String = "";
            var projectedPosTemp:int = _shader.getFreeVertexTemp();
            code += "m44 vt" + projectedPosTemp + ", va" + _shader.getAttribute(POSITION_ATTRIBUTE) + ", vc" + _shader.getVertexConstant(PROJ_MATRIX_VC, 4) + "\n";
            code += "mov op, vt" + projectedPosTemp + "\n";
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

            var diffuseLighting:int = _shader.getFreeFragmentTemp();

            if (diffuseMap) {
                code += sampleTexture(diffuseMap, diffuseMapUVChannel, diffuseLighting, _shader.getTexture(DIFFUSE_TEXTURE));
            } else {
                code += "mov ft" + diffuseLighting + ", fc" + _shader.getFragmentConstant(DIFFUSE_COLOR_FC) + "\n";
            }

            //specular
            var specularColor:int = _shader.getFreeFragmentTemp();
            if (specularMap) {
                code += sampleTexture(specularMap, specularMapUVChannel, specularColor, _shader.getTexture(SPECULAR_TEXTURE));
                code += "mul ft" + specularColor + ".xyz, ft" + specularColor + ".xyz, fc" + _shader.getFragmentConstant(SPECULAR_COLOR_FC) + ".xxx\n";
            } else {
                code += "mov oc" + specularColor + ", fc" + _shader.getFragmentConstant(SPECULAR_COLOR_FC) + "\n";
            }

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

            if (_shader.hasTexture(OPACITY_TEXTURE)) {
                context3D.setTextureAt(_shader.getTexture(OPACITY_TEXTURE), opacityMap.getTextureForStage3D(stage3DProxy));
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
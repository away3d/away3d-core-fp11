package away3d.materials.methods {
    import away3d.arcane;
    import away3d.core.base.LightBase;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
    import away3d.entities.PointLight;
    import away3d.errors.AbstractMethodError;
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderLightingObject;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
    import away3d.materials.compilation.ShaderRegisterData;
    import away3d.materials.compilation.ShaderRegisterElement;
    import away3d.materials.shadowmappers.DirectionalShadowMapper;
    import away3d.textures.RenderTexture;

    import flash.geom.Vector3D;

    use namespace arcane;

    /**
     * SimpleShadowMapMethodBase provides an abstract method for simple (non-wrapping) shadow map methods.
     */
    public class ShadowMethodBase extends ShadowMapMethodBase {
        protected var _depthMapCoordReg:ShaderRegisterElement;
        protected var _usePoint:Boolean;

        /**
         * Creates a new SimpleShadowMapMethodBase object.
         * @param castingLight The light used to cast shadows.
         */
        public function ShadowMethodBase(castingLight:LightBase)
        {
            _usePoint = castingLight is PointLight;
            super(castingLight);
        }

        /**
         * @inheritDoc
         */
        override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
        {
            methodVO.needsView = true;
            methodVO.needsGlobalVertexPos = true;
            methodVO.needsGlobalFragmentPos = _usePoint;
            methodVO.needsNormals = (methodVO as ShaderLightingObject).numLights > 0;
        }

        /**
         * @inheritDoc
         */
        override arcane function initConstants(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
        {
            var fragmentData:Vector.<Number> = shaderObject.fragmentConstantData;
            var vertexData:Vector.<Number> = shaderObject.vertexConstantData;
            var index:int = methodVO.fragmentConstantsIndex;
            fragmentData[index] = 1.0;
            fragmentData[index + 1] = 1 / 255.0;
            fragmentData[index + 2] = 1 / 65025.0;
            fragmentData[index + 3] = 1 / 16581375.0;

            fragmentData[index + 6] = 0;
            fragmentData[index + 7] = 1;

            if (_usePoint) {
                fragmentData[index + 8] = 0;
                fragmentData[index + 9] = 0;
                fragmentData[index + 10] = 0;
                fragmentData[index + 11] = 1;
            }

            index = methodVO.vertexConstantsIndex;
            if (index != -1) {
                vertexData[index] = .5;
                vertexData[index + 1] = -.5;
                vertexData[index + 2] = 0.0;
                vertexData[index + 3] = 1.0;
            }
        }

        /**
         * Wrappers that override the vertex shader need to set this explicitly
         */
        arcane function get depthMapCoordReg():ShaderRegisterElement
        {
            return _depthMapCoordReg;
        }

        arcane function set depthMapCoordReg(value:ShaderRegisterElement):void
        {
            _depthMapCoordReg = value;
        }

        /**
         * @inheritDoc
         */
        arcane override function cleanCompilationData():void
        {
            super.cleanCompilationData();

            _depthMapCoordReg = null;
        }

        /**
         * @inheritDoc
         */
        arcane override function getVertexCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            return _usePoint ? getPointVertexCode(methodVO, regCache, sharedRegisters) : getPlanarVertexCode(methodVO, regCache, sharedRegisters);
        }

        /**
         * Gets the vertex code for shadow mapping with a point light.
         *
         * @param methodVO The MethodVO object linking this method with the pass currently being compiled.
         * @param regCache The register cache used during the compilation.
         */
        protected function getPointVertexCode(methodVO:MethodVO, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            methodVO.vertexConstantsIndex = -1;
            return "";
        }

        /**
         * Gets the vertex code for shadow mapping with a planar shadow map (fe: directional lights).
         *
         * @param methodVO The MethodVO object linking this method with the pass currently being compiled.
         * @param regCache The register cache used during the compilation.
         */
        protected function getPlanarVertexCode(methodVO:MethodVO, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = "";
            var temp:ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
            var dataReg:ShaderRegisterElement = regCache.getFreeVertexConstant();
            var depthMapProj:ShaderRegisterElement = regCache.getFreeVertexConstant();
            regCache.getFreeVertexConstant();
            regCache.getFreeVertexConstant();
            regCache.getFreeVertexConstant();
            _depthMapCoordReg = regCache.getFreeVarying();
            methodVO.vertexConstantsIndex = dataReg.index * 4;

            // todo: can epsilon be applied here instead of fragment shader?

            code += "m44 " + temp + ", " + sharedRegisters.globalPositionVertex + ", " + depthMapProj + "\n" +
                    "div " + temp + ", " + temp + ", " + temp + ".w\n" +
                    "mul " + temp + ".xy, " + temp + ".xy, " + dataReg + ".xy\n" +
                    "add " + _depthMapCoordReg + ", " + temp + ", " + dataReg + ".xxwz\n";

            return code;
        }

        /**
         * @inheritDoc
         */
        override arcane function getFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            var code:String = _usePoint ? getPointFragmentCode(methodVO, targetReg, registerCache, sharedRegisters) : getPlanarFragmentCode(methodVO, targetReg, registerCache, sharedRegisters);
            code += "add " + targetReg + ".w, " + targetReg + ".w, fc" + (methodVO.fragmentConstantsIndex / 4 + 1) + ".y\n" + "sat " + targetReg + ".w, " + targetReg + ".w\n";
            return code;
        }

        /**
         * Gets the fragment code for shadow mapping with a planar shadow map.
         * @param methodVO The MethodVO object linking this method with the pass currently being compiled.
         * @param regCache The register cache used during the compilation.
         * @param targetReg The register to contain the shadow coverage
         * @return
         */
        protected function getPlanarFragmentCode(methodVO:MethodVO, targetReg:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            throw new AbstractMethodError();
            return "";
        }

        /**
         * Gets the fragment code for shadow mapping with a point light.
         * @param methodVO The MethodVO object linking this method with the pass currently being compiled.
         * @param regCache The register cache used during the compilation.
         * @param targetReg The register to contain the shadow coverage
         * @return
         */
        protected function getPointFragmentCode(methodVO:MethodVO, targetReg:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            throw new AbstractMethodError();
            return "";
        }

        /**
         * @inheritDoc
         */
        arcane function setRenderState(shaderObject:ShaderObjectBase, methodVO:MethodVO, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D):void
        {
            if (!_usePoint)
                DirectionalShadowMapper(_shadowMapper).depthProjection.copyRawDataTo(shaderObject.vertexConstantData, methodVO.vertexConstantsIndex + 4, true);
        }

        /**
         * Gets the fragment code for combining this method with a cascaded shadow map method.
         * @param methodVO The MethodVO object linking this method with the pass currently being compiled.
         * @param regCache The register cache used during the compilation.
         * @param decodeRegister The register containing the data to decode the shadow map depth value.
         * @param depthTexture The texture containing the shadow map.
         * @param depthProjection The projection of the fragment relative to the light.
         * @param targetRegister The register to contain the shadow coverage
         * @return
         */
        arcane function getCascadeFragmentCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, decodeRegister:ShaderRegisterElement, depthTexture:ShaderRegisterElement, depthProjection:ShaderRegisterElement, targetRegister:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
        {
            throw new Error("This shadow method is incompatible with cascade shadows");
        }

        /**
         * @inheritDoc
         */
        override arcane function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage3DProxy:Stage3DProxy):void
        {
            var fragmentData:Vector.<Number> = shaderObject.fragmentConstantData;
            var index:int = methodVO.fragmentConstantsIndex;

            if (_usePoint)
                fragmentData[index + 4] = -Math.pow(1 / ((_castingLight as PointLight).fallOff * _epsilon), 2);
            else
                shaderObject.vertexConstantData[methodVO.vertexConstantsIndex + 3] = -1 / (DirectionalShadowMapper(_shadowMapper).depth * _epsilon);

            fragmentData[index + 5] = 1 - _alpha;
            if (_usePoint) {
                var pos:Vector3D = _castingLight.scenePosition;
                fragmentData[index + 8] = pos.x;
                fragmentData[index + 9] = pos.y;
                fragmentData[index + 10] = pos.z;
                // used to decompress distance
                var f:Number = PointLight(_castingLight)._fallOff;
                fragmentData[index + 11] = 1 / (2 * f * f);
            }
            stage3DProxy.activateRenderTexture(methodVO.texturesIndex, _castingLight.shadowMapper.depthMap as RenderTexture);
        }

        /**
         * Sets the method state for cascade shadow mapping.
         */
        arcane function activateForCascade(vo:MethodVO, stage3DProxy:Stage3DProxy):void
        {
            throw new Error("This shadow method is incompatible with cascade shadows");
        }
    }
}

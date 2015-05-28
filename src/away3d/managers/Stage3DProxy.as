package away3d.managers {
    import away3d.animators.AnimationSetBase;
    import away3d.animators.AnimatorBase;
    import away3d.arcane;
    import away3d.core.base.IMaterialOwner;
    import away3d.core.pool.IndexData;
    import away3d.core.pool.MaterialData;
    import away3d.core.pool.MaterialDataPool;
    import away3d.core.pool.MaterialPassData;
    import away3d.core.pool.ProgramData;
    import away3d.core.pool.ProgramDataPool;
    import away3d.core.pool.TextureData;
    import away3d.core.pool.TextureDataPool;
    import away3d.core.pool.VertexData;
    import away3d.debug.Debug;
    import away3d.entities.Camera3D;
    import away3d.events.Stage3DEvent;
    import away3d.materials.MaterialBase;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.textures.CubeTextureBase;
    import away3d.textures.RectangleRenderTexture;
    import away3d.textures.RenderCubeTexture;
    import away3d.textures.RenderTexture;
    import away3d.textures.Texture2DBase;
    import away3d.textures.TextureProxyBase;

    import com.adobe.utils.AGALMiniAssembler;

    import flash.display.BitmapData;

    import flash.display.Shape;
    import flash.display.Stage3D;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DClearMask;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DRenderMode;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.Program3D;
    import flash.display3D.textures.CubeTexture;
    import flash.display3D.textures.Texture;
    import flash.display3D.textures.TextureBase;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;

    use namespace arcane;

    [Event(name="enterFrame", type="flash.events.Event")]
    [Event(name="exitFrame", type="flash.events.Event")]

    /**
     * Stage3DProxy provides a proxy class to manage a single Stage3D instance as well as handling the creation and
     * attachment of the Context3D (and in turn the back buffer) is uses. Stage3DProxy should never be created directly,
     * but requested through Stage3DManager.
     *
     * @see away3d.managers.Stage3DProxy
     *
     * todo: consider moving all creation methods (createVertexBuffer etc) in here, so that disposal can occur here
     * along with the context, instead of scattered throughout the framework
     */ public class Stage3DProxy extends EventDispatcher {
        private static var _frameEventDriver:Shape = new Shape();

        arcane var _context3D:Context3D;
        arcane var _stage3DIndex:int = -1;

        private var _usesSoftwareRendering:Boolean;
        private var _profile:String;
        private var _stage3D:Stage3D;
        private var _activeProgram3D:Program3D;
        private var _stage3DManager:Stage3DManager;
        private var _width:int;
        private var _height:int;
        private var _antiAlias:int;
        private var _enableDepthAndStencil:Boolean = true;
        private var _contextRequested:Boolean;
        private var _renderTarget:TextureProxyBase;
        private var _renderSurfaceSelector:int;
        private var _scissorRect:Rectangle;
        private var _color:uint;
        private var _backBufferDirty:Boolean;
        private var _viewPort:Rectangle;
        private var _enterFrame:Event;
        private var _exitFrame:Event;
        private var _viewportUpdated:Stage3DEvent;
        private var _viewportDirty:Boolean;
        private var _bufferClear:Boolean;

        private var _programData:Vector.<ProgramData> = new Vector.<ProgramData>();
        private var _numUsedStreams:Number = 0;
        private var _numUsedTextures:Number = 0;
        private var _texturePool:TextureDataPool;
        private var _materialDataPool:MaterialDataPool;
        private var _programDataPool:ProgramDataPool;

        /**
         * Creates a Stage3DProxy object. This method should not be called directly. Creation of Stage3DProxy objects should
         * be handled by Stage3DManager.
         * @param stage3DIndex The index of the Stage3D to be proxied.
         * @param stage3D The Stage3D to be proxied.
         * @param stage3DManager
         * @param forceSoftware Whether to force software mode even if hardware acceleration is available.
         */
        public function Stage3DProxy(stage3DIndex:int, stage3D:Stage3D, stage3DManager:Stage3DManager, forceSoftware:Boolean = false, profile:String = "baseline")
        {
            _stage3DIndex = stage3DIndex;
            _stage3D = stage3D;
            _stage3D.x = 0;
            _stage3D.y = 0;
            _stage3D.visible = true;
            _stage3DManager = stage3DManager;
            _viewPort = new Rectangle();
            _enableDepthAndStencil = true;

            _texturePool = new TextureDataPool(this);
            _materialDataPool = new MaterialDataPool(this);
            _programDataPool = new ProgramDataPool(this);

            // whatever happens, be sure this has highest priority
            _stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate, false, 1000, false);
            requestContext(forceSoftware, profile);
        }

        /**
         * Configures the back buffer associated with the Stage3D object.
         * @param backBufferWidth The width of the backbuffer.
         * @param backBufferHeight The height of the backbuffer.
         * @param antiAlias The amount of anti-aliasing to use.
         * @param enableDepthAndStencil Indicates whether the back buffer contains a depth and stencil buffer.
         */
        public function configureBackBuffer(backBufferWidth:int, backBufferHeight:int, antiAlias:int, enableDepthAndStencil:Boolean):void
        {
            if (backBufferWidth < 50) backBufferWidth = 50;
            if (backBufferHeight < 50) backBufferHeight = 50;
            var oldWidth:uint = _width;
            var oldHeight:uint = _height;

            _width = _viewPort.width = backBufferWidth;
            _height = _viewPort.height = backBufferHeight;

            if (oldWidth != _width || oldHeight != _height)
                notifyViewportUpdated();

            _antiAlias = antiAlias;

            if (_context3D)
                _context3D.configureBackBuffer(backBufferWidth, backBufferHeight, antiAlias, enableDepthAndStencil);
        }

        private function notifyViewportUpdated():void
        {
            if (_viewportDirty)
                return;

            _viewportDirty = true;

            if (!hasEventListener(Stage3DEvent.VIEWPORT_UPDATED))
                return;

            //TODO: investigate bug causing coercion error
            //if (!_viewportUpdated)
            _viewportUpdated = new Stage3DEvent(Stage3DEvent.VIEWPORT_UPDATED);

            dispatchEvent(_viewportUpdated);
        }

        private function notifyEnterFrame():void
        {
            if (!hasEventListener(Event.ENTER_FRAME))
                return;

            if (!_enterFrame)
                _enterFrame = new Event(Event.ENTER_FRAME);

            dispatchEvent(_enterFrame);
        }

        private function notifyExitFrame():void
        {
            if (!hasEventListener(Event.EXIT_FRAME))
                return;

            if (!_exitFrame)
                _exitFrame = new Event(Event.EXIT_FRAME);

            dispatchEvent(_exitFrame);
        }


        /**
         * Disposes the Stage3DProxy object, freeing the Context3D attached to the Stage3D.
         */
        public function dispose():void
        {
            _stage3DManager.removeStage3DProxy(this);
            _stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate);
            freeContext3D();
            _stage3D = null;
            _stage3DManager = null;
            _stage3DIndex = -1;
        }


        /*
         * Indicates whether the depth and stencil buffer is used
         */
        public function get enableDepthAndStencil():Boolean
        {
            return _enableDepthAndStencil;
        }

        public function set enableDepthAndStencil(enableDepthAndStencil:Boolean):void
        {
            _enableDepthAndStencil = enableDepthAndStencil;
            _backBufferDirty = true;
        }

        public function get renderTarget():TextureProxyBase
        {
            return _renderTarget;
        }

        public function get renderSurfaceSelector():int
        {
            return _renderSurfaceSelector;
        }

        public function setRenderTarget(target:TextureProxyBase, enableDepthAndStencil:Boolean = false, surfaceSelector:int = 0):void
        {
            if (_renderTarget == target && surfaceSelector == _renderSurfaceSelector && _enableDepthAndStencil == enableDepthAndStencil)
                return;
            _renderTarget = target;
            _renderSurfaceSelector = surfaceSelector;
            _enableDepthAndStencil = enableDepthAndStencil;

            if (target) {
                _context3D.setRenderToTexture(getRenderTexture(target as RenderTexture), enableDepthAndStencil, _antiAlias, surfaceSelector);
            } else {
                _context3D.setRenderToBackBuffer();
                configureBackBuffer(_width, _height, _antiAlias, _enableDepthAndStencil);
            }
        }

        public function getRenderTexture(textureProxy:RenderTexture):TextureBase
        {
            var textureData:TextureData = _texturePool.getItem(textureProxy);
            if (!textureData.texture) {
                if (textureProxy is RectangleRenderTexture) {
                    textureData.texture = _context3D.createRectangleTexture(textureProxy.width, textureProxy.height, Context3DTextureFormat.BGRA, true);
                } else {
                    textureData.texture = _context3D.createTexture(textureProxy.width, textureProxy.height, Context3DTextureFormat.BGRA, true);
                }
            }
            return textureData.texture;
        }

        public function getProgram(materialPassData:MaterialPassData):ProgramData
        {
            //check key doesn't need re-concatenating
            if (!materialPassData.key.length) {
                materialPassData.key = materialPassData.animationVertexCode + materialPassData.vertexCode + "---" + materialPassData.fragmentCode + materialPassData.animationFragmentCode + materialPassData.postAnimationFragmentCode;
            } else {
                return materialPassData.programData;
            }

            var programData:ProgramData = _programDataPool.getItem(materialPassData.key);

            //check program data hasn't changed, keep count of program usages
            if (materialPassData.programData != programData) {
                if (materialPassData.programData)
                    materialPassData.programData.dispose();

                materialPassData.programData = programData;

                programData.usages++;
            }

            return programData;
        }

        public function registerProgram(programData:ProgramData):void
        {
            var i:int = 0;
            while (_programData[i] != null)
                i++;

            _programData[i] = programData;
            programData.id = i;
        }

        public function unregisterProgram(programData:ProgramData):void
        {
            _programData[programData.id] = null;
            programData.id = -1;
        }

        public function getMaterial(material:MaterialBase, profile:String):MaterialData
        {
            var materialData:MaterialData = _materialDataPool.getItem(material);

            if (materialData.invalidAnimation) {
                materialData.invalidAnimation = false;

                var materialDataPasses:Vector.<MaterialPassData> = materialData.getMaterialPasses(profile);

                var enabledGPUAnimation:Boolean = getEnabledGPUAnimation(material, materialDataPasses);

                var renderOrderId:int = 0;
                var mult:Number = 1;
                var materialPassData:MaterialPassData;
                var len:Number = materialDataPasses.length;
                for (var i:Number = 0; i < len; i++) {
                    materialPassData = materialDataPasses[i];

                    if (materialPassData.usesAnimation != enabledGPUAnimation) {
                        materialPassData.usesAnimation = enabledGPUAnimation;
                        materialPassData.key = "";
                    }

                    if (materialPassData.key == "")
                        calcAnimationCode(material, materialPassData);

                    renderOrderId += getProgram(materialPassData).id * mult;
                    mult *= 1000;
                }

                materialData.renderOrderId = renderOrderId;
            }

            return materialData;
        }

        /**
         * test if animation will be able to run on gpu BEFORE compiling materials
         * test if the shader objects supports animating the animation set in the vertex shader
         * if any object using this material fails to support accelerated animations for any of the shader objects,
         * we should do everything on cpu (otherwise we have the cost of both gpu + cpu animations)
         */
        private function getEnabledGPUAnimation(material:MaterialBase, materialDataPasses:Vector.<MaterialPassData>):Boolean
        {
            if (material.animationSet) {
                material.animationSet.resetGPUCompatibility();

                var owners:Vector.<IMaterialOwner> = material.owners;
                var numOwners:int = owners.length;

                var len:int = materialDataPasses.length;
                for (var i:int = 0; i < len; i++)
                    for (var j:int = 0; j < numOwners; j++)
                        if (owners[j].animator)
                            (owners[j].animator as AnimatorBase).testGPUCompatibility(materialDataPasses[i].shaderObject);

                return !material.animationSet.usesCPU;
            }

            return false;
        }

        public function calcAnimationCode(material:MaterialBase, materialPassData:MaterialPassData):void
        {
            //reset key so that the program is re-calculated
            materialPassData.key = "";
            materialPassData.animationVertexCode = "";
            materialPassData.animationFragmentCode = "";

            var shaderObject:ShaderObjectBase = materialPassData.shaderObject;

            //check to see if GPU animation is used
            if (materialPassData.usesAnimation) {

                var animationSet:AnimationSetBase = material.animationSet as AnimationSetBase;

                materialPassData.animationVertexCode += animationSet.getAGALVertexCode(shaderObject);

                if (shaderObject.uvDependencies > 0 && !shaderObject.usesUVTransform)
                    materialPassData.animationVertexCode += animationSet.getAGALUVCode(shaderObject);

                if (shaderObject.usesFragmentAnimation)
                    materialPassData.animationFragmentCode += animationSet.getAGALFragmentCode(shaderObject, materialPassData.shadedTarget);

                animationSet.doneAGALCode(shaderObject);

            } else {
                // simply write attributes to targets, do not animate them
                // projection will pick up on targets[0] to do the projection
                var len:int = shaderObject.animatableAttributes.length;
                for (var i:int = 0; i < len; ++i)
                    materialPassData.animationVertexCode += "mov " + shaderObject.animationTargetRegisters[i] + ", " + shaderObject.animatableAttributes[i] + "\n";

                if (shaderObject.uvDependencies > 0 && !shaderObject.usesUVTransform)
                    materialPassData.animationVertexCode += "mov " + shaderObject.uvTarget + "," + shaderObject.uvSource + "\n";
            }
        }


        /*
         * Clear and reset the back buffer when using a shared context
         */
        public function clear():void
        {
            if (!_context3D)
                return;

            if (_backBufferDirty) {
                configureBackBuffer(_width, _height, _antiAlias, _enableDepthAndStencil);
                _backBufferDirty = false;
            }

            _context3D.clear(((_color >> 16) & 0xff) / 255.0, ((_color >> 8) & 0xff) / 255.0, (_color & 0xff) / 255.0, ((_color >> 24) & 0xff) / 255.0);

            _bufferClear = true;
        }

        /**
         * Clear buffers state
         */
        public function clearBuffers():void
        {
            var i:uint = 0;
            for (i = 0; i < 8; ++i) {
                _context3D.setVertexBufferAt(i, null);
                _context3D.setTextureAt(i, null);
            }
        }

        /*
         * Display the back rendering buffer
         */
        public function present():void
        {
            if (!_context3D)
                return;

            _context3D.present();

            _activeProgram3D = null;

            //			if (_mouse3DManager)
            //				_mouse3DManager.fireMouseEvents();
        }

        /**
         * Registers an event listener object with an EventDispatcher object so that the listener receives notification of an event. Special case for enterframe and exitframe events - will switch Stage3DProxy into automatic render mode.
         * You can register event listeners on all nodes in the display list for a specific type of event, phase, and priority.
         *
         * @param type The type of event.
         * @param listener The listener function that processes the event.
         * @param useCapture Determines whether the listener works in the capture phase or the target and bubbling phases. If useCapture is set to true, the listener processes the event only during the capture phase and not in the target or bubbling phase. If useCapture is false, the listener processes the event only during the target or bubbling phase. To listen for the event in all three phases, call addEventListener twice, once with useCapture set to true, then again with useCapture set to false.
         * @param priority The priority level of the event listener. The priority is designated by a signed 32-bit integer. The higher the Number, the higher the priority. All listeners with priority n are processed before listeners of priority n-1. If two or more listeners share the same priority, they are processed in the order in which they were added. The default priority is 0.
         * @param useWeakReference Determines whether the reference to the listener is strong or weak. A strong reference (the default) prevents your listener from being garbage-collected. A weak reference does not.
         */
        public override function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
        {
            super.addEventListener(type, listener, useCapture, priority, useWeakReference);

            if ((type == Event.ENTER_FRAME || type == Event.EXIT_FRAME) && !_frameEventDriver.hasEventListener(Event.ENTER_FRAME))
                _frameEventDriver.addEventListener(Event.ENTER_FRAME, onEnterFrame, useCapture, priority, useWeakReference);
        }

        /**
         * Removes a listener from the EventDispatcher object. Special case for enterframe and exitframe events - will switch Stage3DProxy out of automatic render mode.
         * If there is no matching listener registered with the EventDispatcher object, a call to this method has no effect.
         *
         * @param type The type of event.
         * @param listener The listener object to remove.
         * @param useCapture Specifies whether the listener was registered for the capture phase or the target and bubbling phases. If the listener was registered for both the capture phase and the target and bubbling phases, two calls to removeEventListener() are required to remove both, one call with useCapture() set to true, and another call with useCapture() set to false.
         */
        public override function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
        {
            super.removeEventListener(type, listener, useCapture);

            // Remove the main rendering listener if no EnterFrame listeners remain
            if (!hasEventListener(Event.ENTER_FRAME) && !hasEventListener(Event.EXIT_FRAME) && _frameEventDriver.hasEventListener(Event.ENTER_FRAME))
                _frameEventDriver.removeEventListener(Event.ENTER_FRAME, onEnterFrame, useCapture);
        }

        public function get scissorRect():Rectangle
        {
            return _scissorRect;
        }

        public function set scissorRect(value:Rectangle):void
        {
            _scissorRect = value;
            _context3D.setScissorRectangle(_scissorRect);
        }

        /**
         * The index of the Stage3D which is managed by this instance of Stage3DProxy.
         */
        public function get stage3DIndex():int
        {
            return _stage3DIndex;
        }

        /**
         * The base Stage3D object associated with this proxy.
         */
        public function get stage3D():Stage3D
        {
            return _stage3D;
        }

        /**
         * The Context3D object associated with the given Stage3D object.
         */
        public function get context3D():Context3D
        {
            return _context3D;
        }

        /**
         * The driver information as reported by the Context3D object (if any)
         */
        public function get driverInfo():String
        {
            return _context3D ? _context3D.driverInfo : null;
        }

        /**
         * Indicates whether the Stage3D managed by this proxy is running in software mode.
         * Remember to wait for the CONTEXT3D_CREATED event before checking this property,
         * as only then will it be guaranteed to be accurate.
         */
        public function get usesSoftwareRendering():Boolean
        {
            return _usesSoftwareRendering;
        }

        /**
         * The x position of the Stage3D.
         */
        public function get x():Number
        {
            return _stage3D.x;
        }

        public function set x(value:Number):void
        {
            if (_viewPort.x == value)
                return;

            _stage3D.x = _viewPort.x = value;

            notifyViewportUpdated();
        }

        /**
         * The y position of the Stage3D.
         */
        public function get y():Number
        {
            return _stage3D.y;
        }

        public function set y(value:Number):void
        {
            if (_viewPort.y == value)
                return;

            _stage3D.y = _viewPort.y = value;

            notifyViewportUpdated();
        }

        /**
         * The width of the Stage3D.
         */
        public function get width():int
        {
            return _width;
        }

        public function set width(width:int):void
        {
            if (_viewPort.width == width)
                return;

            if (width < 50) width = 50;
            _width = _viewPort.width = width;
            _backBufferDirty = true;

            notifyViewportUpdated();
        }

        /**
         * The height of the Stage3D.
         */
        public function get height():int
        {
            return _height;
        }

        public function set height(height:int):void
        {
            if (_viewPort.height == height)
                return;

            if (height < 50) height = 50;
            _height = _viewPort.height = height;
            _backBufferDirty = true;

            notifyViewportUpdated();
        }

        /**
         * The antiAliasing of the Stage3D.
         */
        public function get antiAlias():int
        {
            return _antiAlias;
        }

        public function set antiAlias(antiAlias:int):void
        {
            _antiAlias = antiAlias;
            _backBufferDirty = true;
        }

        /**
         * A viewPort rectangle equivalent of the Stage3D size and position.
         */
        public function get viewPort():Rectangle
        {
            _viewportDirty = false;

            return _viewPort;
        }

        /**
         * The background color of the Stage3D.
         */
        public function get color():uint
        {
            return _color;
        }

        public function set color(color:uint):void
        {
            _color = color;
        }

        /**
         * The visibility of the Stage3D.
         */
        public function get visible():Boolean
        {
            return _stage3D.visible;
        }

        public function set visible(value:Boolean):void
        {
            _stage3D.visible = value;
        }

        /**
         * The freshly cleared state of the backbuffer before any rendering
         */
        public function get bufferClear():Boolean
        {
            return _bufferClear;
        }

        public function set bufferClear(newBufferClear:Boolean):void
        {
            _bufferClear = newBufferClear;
        }

        /**
         * Assigns an attribute stream
         *
         * @param index The attribute stream index for the vertex shader
         * @param buffer
         * @param offset
         * @param stride
         * @param format
         */
        public function activateBuffer(index:int, buffer:VertexData, offset:Number, format:String):void
        {
            if (!buffer.stage3Ds[_stage3DIndex])
                buffer.stage3Ds[_stage3DIndex] = this;

            if (!buffer.buffers[_stage3DIndex]) {
                buffer.buffers[_stage3DIndex] = _context3D.createVertexBuffer(buffer.data.length / buffer.dataPerVertex, buffer.dataPerVertex);
                buffer.invalid[_stage3DIndex] = true;
            }

            if (buffer.invalid[_stage3DIndex]) {
                buffer.buffers[_stage3DIndex].uploadFromVector(buffer.data, 0, buffer.data.length / buffer.dataPerVertex);
                buffer.invalid[_stage3DIndex] = false;
            }

            _context3D.setVertexBufferAt(index, buffer.buffers[_stage3DIndex], offset, format);
        }

        public function disposeVertexData(buffer:VertexData):void
        {
            buffer.buffers[_stage3DIndex].dispose();
            buffer.buffers[_stage3DIndex] = null;
        }

        public function activateRenderTexture(index:int, textureProxy:RenderTexture):void
        {
            _context3D.setTextureAt(index, getRenderTexture(textureProxy));
        }

        public function activateMaterialPass(materialPassData:MaterialPassData, camera:Camera3D):void
        {
            var shaderObject:ShaderObjectBase = materialPassData.shaderObject;

            var i:int;

            //clear unused vertex streams
            for (i = shaderObject.numUsedStreams; i < _numUsedStreams; i++)
                _context3D.setVertexBufferAt(i, null);

            //clear unused texture streams
            for (i = shaderObject.numUsedTextures; i < _numUsedTextures; i++)
                _context3D.setTextureAt(i, null);

            if (materialPassData.usesAnimation)
                (materialPassData.material.animationSet as AnimationSetBase).activate(shaderObject, this);

            //activate shader object
            shaderObject.activate(this, camera);

            //check program data is uploaded
            var programData:ProgramData = getProgram(materialPassData);

            if (!programData.program) {
                programData.program = _context3D.createProgram();
                var vertexByteCode:ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, materialPassData.animationVertexCode + materialPassData.vertexCode);
                var fragmentByteCode:ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, materialPassData.fragmentCode + materialPassData.animationFragmentCode + materialPassData.postAnimationFragmentCode);
                programData.program.upload(vertexByteCode, fragmentByteCode);
            }

            //set program data
            _context3D.setProgram(programData.program);
        }

        public function deactivateMaterialPass(materialPassData:MaterialPassData):void
        {
            var shaderObject:ShaderObjectBase = materialPassData.shaderObject;

            if (materialPassData.usesAnimation)
                (materialPassData.material.animationSet as AnimationSetBase).deactivate(shaderObject, this);

            materialPassData.shaderObject.deactivate(this);

            _numUsedStreams = shaderObject.numUsedStreams;
            _numUsedTextures = shaderObject.numUsedTextures;
        }

        public function activateTexture(index:int, textureProxy:TextureProxyBase):void
        {
            var i:int;
            var len:int;
            var mipmapData:Vector.<BitmapData>;
            var textureData:TextureData = _texturePool.getItem(textureProxy);

            if (!textureData.texture) {
                if (textureProxy is Texture2DBase) {
                    var texture2D:Texture2DBase = textureProxy as Texture2DBase;
                    if (textureProxy is RenderTexture) {
                        textureData.texture = _context3D.createTexture(texture2D.width, texture2D.height, Context3DTextureFormat.BGRA, true);
                    } else if (textureProxy is Texture2DBase) {
                        textureData.texture = _context3D.createTexture(texture2D.width, texture2D.height, Context3DTextureFormat.BGRA, false);
                        textureData.invalid = true;
                    }

                    if (textureData.invalid) {
                        var texture:Texture = textureData.texture as Texture;

                        textureData.invalid = false;
                        if (texture2D.generateMipmaps) {
                            mipmapData = texture2D.getMipmapData();
                            len = mipmapData.length;
                            for (i = 0; i < len; i++)
                                texture.uploadFromBitmapData(mipmapData[i], i);
                        } else {
                            texture.uploadFromBitmapData(texture2D.getTextureData(), 0);
                        }
                    }

                } else if (textureProxy is CubeTextureBase) {
                    var textureCube:CubeTextureBase = textureProxy as CubeTextureBase;
                    if (textureProxy is RenderCubeTexture) {
                        textureData.texture = _context3D.createCubeTexture(textureCube.size, Context3DTextureFormat.BGRA, true);
                    } else {
                        textureData.texture = _context3D.createCubeTexture(textureCube.size, Context3DTextureFormat.BGRA, false);
                        textureData.invalid = true;
                    }

                    if (textureData.invalid) {
                        var cubeTexture:CubeTexture = textureData.texture as CubeTexture;
                        textureData.invalid = false;
                        for (i = 0; i < 6; ++i) {
                            if (textureCube.generateMipmaps) {
                                mipmapData = textureCube.getMipmapData(i);
                                len = mipmapData.length;
                                for (var j:int = 0; j < len; j++)
                                    cubeTexture.uploadFromBitmapData(mipmapData[j], i, j);
                            } else {
                                cubeTexture.uploadFromBitmapData(textureCube.getTextureData(i), i, 0);
                            }
                        }
                    }
                }
            }

            _context3D.setTextureAt(index, textureData.texture);
        }

        public function getIndexBuffer(buffer:IndexData):IndexBuffer3D
        {
            if (!buffer.stage3Ds[_stage3DIndex])
                buffer.stage3Ds[_stage3DIndex] = this;

            if (!buffer.buffers[_stage3DIndex]) {
                buffer.buffers[_stage3DIndex] = _context3D.createIndexBuffer(buffer.data.length);
                buffer.invalid[_stage3DIndex] = true;
            }

            if (buffer.invalid[_stage3DIndex]) {
                (buffer.buffers[_stage3DIndex] as IndexBuffer3D).uploadFromVector(buffer.data, 0, buffer.data.length);
                buffer.invalid[_stage3DIndex] = false;
            }

            return buffer.buffers[_stage3DIndex];
        }

        public function disposeIndexData(buffer:IndexData):void
        {
            buffer.buffers[_stage3DIndex].dispose();
            buffer.buffers[_stage3DIndex] = null;
        }

        /*
         * Access to fire mouseevents across multiple layered view3D instances
         */
        //		public function get mouse3DManager():Mouse3DManager
        //		{
        //			return _mouse3DManager;
        //		}
        //
        //		public function set mouse3DManager(value:Mouse3DManager):void
        //		{
        //			_mouse3DManager = value;
        //		}

        //		public function get touch3DManager():Touch3DManager
        //		{
        //			return _touch3DManager;
        //		}
        //
        //		public function set touch3DManager(value:Touch3DManager):void
        //		{
        //			_touch3DManager = value;
        //		}

        /**
         * Frees the Context3D associated with this Stage3DProxy.
         */
        private function freeContext3D():void
        {
            if (_context3D) {
                _context3D.dispose();
                dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_DISPOSED));
            }
            _context3D = null;
        }

        /*
         * Called whenever the Context3D is retrieved or lost.
         * @param event The event dispatched.
         */
        private function onContext3DUpdate(event:Event):void
        {
            if (_stage3D.context3D) {
                var hadContext:Boolean = (_context3D != null);
                _context3D = _stage3D.context3D;
                _context3D.enableErrorChecking = Debug.active;

                _usesSoftwareRendering = (_context3D.driverInfo.indexOf('Software') == 0);

                // Only configure back buffer if width and height have been set,
                // which they may not have been if View3D.render() has yet to be
                // invoked for the first time.
                if (_width && _height)
                    _context3D.configureBackBuffer(_width, _height, _antiAlias, _enableDepthAndStencil);

                // Dispatch the appropriate event depending on whether context was
                // created for the first time or recreated after a device loss.
                dispatchEvent(new Stage3DEvent(hadContext ? Stage3DEvent.CONTEXT3D_RECREATED : Stage3DEvent.CONTEXT3D_CREATED));

            } else
                throw new Error("Rendering context lost!");
        }

        /**
         * Requests a Context3D object to attach to the managed Stage3D.
         */
        private function requestContext(forceSoftware:Boolean = false, profile:String = "baseline"):void
        {
            // If forcing software, we can be certain that the
            // returned Context3D will be running software mode.
            // If not, we can't be sure and should stick to the
            // old value (will likely be same if re-requesting.)
            _usesSoftwareRendering ||= forceSoftware;
            _profile = profile;

            // ugly stuff for backward compatibility
            var renderMode:String = forceSoftware ? Context3DRenderMode.SOFTWARE : Context3DRenderMode.AUTO;
            if (profile == "baseline")
                _stage3D.requestContext3D(renderMode); else {
                try {
                    _stage3D["requestContext3D"](renderMode, profile);
                } catch (error:Error) {
                    throw "An error occurred creating a context using the given profile. Profiles are not supported for the SDK this was compiled with.";
                }
            }

            _contextRequested = true;
        }

        /**
         * The Enter_Frame handler for processing the proxy.ENTER_FRAME and proxy.EXIT_FRAME event handlers.
         * Typically the proxy.ENTER_FRAME listener would render the layers for this Stage3D instance.
         */
        private function onEnterFrame(event:Event):void
        {
            if (!_context3D)
                return;

            // Clear the stage3D instance
            clear();

            //notify the enterframe listeners
            notifyEnterFrame();

            // Call the present() to render the frame
            present();

            //notify the exitframe listeners
            notifyExitFrame();
        }

        public function recoverFromDisposal():Boolean
        {
            if (!_context3D)
                return false;
            if (_context3D.driverInfo == "Disposed") {
                _context3D = null;
                dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_DISPOSED));
                return false;
            }
            return true;
        }

        public function clearDepthBuffer():void
        {
            if (!_context3D) return;
            _context3D.clear(0, 0, 0, 1, 1, 0, Context3DClearMask.DEPTH);
        }

        public function get profile():String
        {
            return _profile;
        }
    }
}

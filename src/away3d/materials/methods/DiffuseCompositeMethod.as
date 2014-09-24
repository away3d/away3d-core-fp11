package away3d.materials.methods
{
	import away3d.arcane;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
    import away3d.managers.Stage3DProxy;
	import away3d.events.ShadingMethodEvent;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderLightingObject;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterData;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;
	
	/**
	 * CompositeDiffuseMethod provides a base class for diffuse methods that wrap a diffuse method to alter the
	 * calculated diffuse reflection strength.
	 */
	public class DiffuseCompositeMethod extends DiffuseBasicMethod
	{
		protected var _baseMethod:DiffuseBasicMethod;

		/**
		 * Creates a new WrapDiffuseMethod object.
		 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature clampDiffuse(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the diffuse strength.
		 * @param baseDiffuseMethod The base diffuse method on which this method's shading is based.
		 */
		public function DiffuseCompositeMethod(modulateMethod:Function = null, baseDiffuseMethod:DiffuseBasicMethod = null)
		{
			_baseMethod = baseDiffuseMethod || new DiffuseBasicMethod();
			_baseMethod._modulateMethod = modulateMethod;
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		/**
		 * The base diffuse method on which this method's shading is based.
		 */
		public function get baseMethod():DiffuseBasicMethod
		{
			return _baseMethod;
		}

		public function set baseMethod(value:DiffuseBasicMethod):void
		{
			if (_baseMethod == value)
				return;
			_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_baseMethod = value;
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
			invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			_baseMethod.initVO(shaderObject, methodVO);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initConstants(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			_baseMethod.initConstants(shaderObject, methodVO);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_baseMethod.dispose();
		}

        /**
         * @inheritDoc
         */
        override public function get texture():Texture2DBase
        {
            return _baseMethod.texture;
        }

        /**
         * @inheritDoc
         */
        override public function set texture(value:Texture2DBase):void
        {
            _baseMethod.texture = value;
        }

		/**
		 * @inheritDoc
		 */
		override public function get diffuseColor():uint
		{
			return _baseMethod.diffuseColor;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set diffuseColor(diffuseColor:uint):void
		{
			_baseMethod.diffuseColor = diffuseColor;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			return _baseMethod.getFragmentPreLightingCode(shaderObject, methodVO, registerCache, sharedRegisters);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCodePerLight(shaderObject:ShaderLightingObject, methodVO:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String = _baseMethod.getFragmentCodePerLight(shaderObject, methodVO, lightDirReg, lightColReg, registerCache, sharedRegisters);
			_totalLightColorReg = _baseMethod._totalLightColorReg;
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerProbe(shaderObject:ShaderLightingObject, methodVO:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String = _baseMethod.getFragmentCodePerProbe(shaderObject, methodVO, cubeMapReg, weightRegister, registerCache, sharedRegisters);
			_totalLightColorReg = _baseMethod._totalLightColorReg;
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
			_baseMethod.activate(shaderObject, methodVO, stage);
		}

        /**
         * @inheritDoc
         */
        override arcane function setRenderState(shaderObject:ShaderLightingObject, methodVO:MethodVO, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D):void
        {
            _baseMethod.setRenderState(shaderObject, methodVO, renderable, stage, camera);
        }

		/**
		 * @inheritDoc
		 */
		arcane override function deactivate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
			_baseMethod.deactivate(shaderObject, methodVO, stage);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getVertexCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			return _baseMethod.getVertexCode(shaderObject, methodVO, registerCache, sharedRegisters);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, targetReg:ShaderRegisterElement, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			return _baseMethod.getFragmentPostLightingCode(shaderObject, methodVO, targetReg, registerCache, sharedRegisters);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function reset():void
		{
			_baseMethod.reset();
		}

		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData():void
		{
			super.cleanCompilationData();
			_baseMethod.cleanCompilationData();
		}

		/**
		 * Called when the base method's shader code is invalidated.
		 */
		private function onShaderInvalidated(event:ShadingMethodEvent):void
		{
			invalidateShaderProgram();
		}
	}
}

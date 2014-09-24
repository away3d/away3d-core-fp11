package away3d.materials.methods
{
	import away3d.*;
    import away3d.core.pool.RenderableBase;
    import away3d.entities.Camera3D;
    import away3d.managers.*;
	import away3d.events.*;
	import away3d.materials.compilation.*;
	import away3d.materials.passes.*;
	import away3d.textures.*;
	
	use namespace arcane;
	
	/**
	 * CompositeSpecularMethod provides a base class for specular methods that wrap a specular method to alter the
	 * calculated specular reflection strength.
	 */
	public class SpecularCompositeMethod extends SpecularBasicMethod
	{
		private var _baseMethod:SpecularBasicMethod;
		
		/**
		 * Creates a new WrapSpecularMethod object.
		 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature modSpecular(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the specular strength and t.xyz will contain the half-vector or the reflection vector.
		 * @param baseSpecularMethod The base specular method on which this method's shading is based.
		 */
		public function SpecularCompositeMethod(modulateMethod:Function, baseSpecularMethod:SpecularBasicMethod = null)
		{
			super();
			_baseMethod = baseSpecularMethod || new SpecularBasicMethod();
			_baseMethod._modulateMethod = modulateMethod;
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		/**
		 * @inheritDoc
		 */
        override arcane function initVO(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			_baseMethod.initVO(shaderObject,methodVO);
		}

		/**
		 * @inheritDoc
		 */
        override arcane function initConstants(shaderObject:ShaderObjectBase, methodVO:MethodVO):void
		{
			_baseMethod.initConstants(shaderObject, methodVO);
		}
		
		/**
		 * The base specular method on which this method's shading is based.
		 */
		public function get baseMethod():SpecularBasicMethod
		{
			return _baseMethod;
		}
		
		public function set baseMethod(value:SpecularBasicMethod):void
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
		override public function get gloss():Number
		{
			return _baseMethod.gloss;
		}
		
		override public function set gloss(value:Number):void
		{
			_baseMethod.gloss = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get specular():Number
		{
			return _baseMethod.specular;
		}
		
		override public function set specular(value:Number):void
		{
			_baseMethod.specular = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get passes():Vector.<MaterialPassBase>
		{
			return _baseMethod.passes;
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
		
		override public function set texture(value:Texture2DBase):void
		{
			_baseMethod.texture = value;
		}
		
		/**
		 * @inheritDoc
		 */
        arcane override function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
            _baseMethod.activate(shaderObject, methodVO, stage);
		}


        override public function setRenderState(shaderObject:ShaderObjectBase, methodVO:MethodVO, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D):void
        {
            _baseMethod.setRenderState(shaderObject, methodVO, renderable, stage, camera);
        }

        /**
		 * @inheritDoc
		 */
        override arcane function deactivate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
        {
            _baseMethod.deactivate(shaderObject, methodVO, stage);
        }

		
		/**
		 * @inheritDoc
		 */

        override arcane function getVertexCode(shaderObject:ShaderObjectBase, methodVO:MethodVO, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			return _baseMethod.getVertexCode(shaderObject, methodVO,registerCache,sharedRegisters);
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
			return _baseMethod.getFragmentCodePerLight(shaderObject, methodVO, lightDirReg, lightColReg, registerCache, sharedRegisters);
		}
		
		/**
		 * @inheritDoc
		 * @return
		 */
		arcane override function getFragmentCodePerProbe(shaderObject:ShaderLightingObject, methodVO:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			return _baseMethod.getFragmentCodePerProbe(shaderObject, methodVO, cubeMapReg, weightRegister, registerCache, sharedRegisters);
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
		arcane override function reset():void
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

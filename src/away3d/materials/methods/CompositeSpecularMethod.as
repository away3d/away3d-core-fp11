package away3d.materials.methods
{
	import away3d.*;
	import away3d.core.managers.*;
	import away3d.events.*;
	import away3d.materials.compilation.*;
	import away3d.materials.passes.*;
	import away3d.textures.*;
	
	use namespace arcane;
	
	/**
	 * CompositeSpecularMethod provides a base class for specular methods that wrap a specular method to alter the
	 * calculated specular reflection strength.
	 */
	public class CompositeSpecularMethod extends BasicSpecularMethod
	{
		private var _baseMethod:BasicSpecularMethod;
		
		/**
		 * Creates a new WrapSpecularMethod object.
		 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature modSpecular(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the specular strength and t.xyz will contain the half-vector or the reflection vector.
		 * @param baseSpecularMethod The base specular method on which this method's shading is based.
		 */
		public function CompositeSpecularMethod(modulateMethod:Function, baseSpecularMethod:BasicSpecularMethod = null)
		{
			super();
			_baseMethod = baseSpecularMethod || new BasicSpecularMethod();
			_baseMethod._modulateMethod = modulateMethod;
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			_baseMethod.initVO(vo);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initConstants(vo:MethodVO):void
		{
			_baseMethod.initConstants(vo);
		}
		
		/**
		 * The base specular method on which this method's shading is based.
		 */
		public function get baseMethod():BasicSpecularMethod
		{
			return _baseMethod;
		}
		
		public function set baseMethod(value:BasicSpecularMethod):void
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
		override arcane function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			_baseMethod.activate(vo, stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function deactivate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			_baseMethod.deactivate(vo, stage3DProxy);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function set sharedRegisters(value:ShaderRegisterData):void
		{
			super.sharedRegisters = _baseMethod.sharedRegisters = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			return _baseMethod.getVertexCode(vo, regCache);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			return _baseMethod.getFragmentPreLightingCode(vo, regCache);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
		{
			return _baseMethod.getFragmentCodePerLight(vo, lightDirReg, lightColReg, regCache);
		}
		
		/**
		 * @inheritDoc
		 * @return
		 */
		arcane override function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
		{
			return _baseMethod.getFragmentCodePerProbe(vo, cubeMapReg, weightRegister, regCache);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			return _baseMethod.getFragmentPostLightingCode(vo, regCache, targetReg);
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
		 * @inheritDoc
		 */
		override arcane function set shadowRegister(value:ShaderRegisterElement):void
		{
			super.shadowRegister = value;
			_baseMethod.shadowRegister = value;
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

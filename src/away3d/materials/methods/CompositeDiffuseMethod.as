package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
	import away3d.events.ShadingMethodEvent;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterData;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	use namespace arcane;
	
	/**
	 * CompositeDiffuseMethod provides a base class for diffuse methods that wrap a diffuse method to alter the
	 * calculated diffuse reflection strength.
	 */
	public class CompositeDiffuseMethod extends DiffuseBasicMethod
	{
		protected var _baseMethod:DiffuseBasicMethod;

		/**
		 * Creates a new WrapDiffuseMethod object.
		 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature clampDiffuse(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the diffuse strength.
		 * @param baseDiffuseMethod The base diffuse method on which this method's shading is based.
		 */
		public function CompositeDiffuseMethod(modulateMethod:Function = null, baseDiffuseMethod:DiffuseBasicMethod = null)
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
		override public function get alphaThreshold():Number
		{
			return _baseMethod.alphaThreshold;
		}
		
		override public function set alphaThreshold(value:Number):void
		{
			_baseMethod.alphaThreshold = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get diffuseTexture():Texture2DBase
		{
			return _baseMethod.diffuseTexture;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set diffuseTexture(value:Texture2DBase):void
		{
			_baseMethod.diffuseTexture = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get diffuseAlpha():Number
		{
			return _baseMethod.diffuseAlpha;
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
		override public function set diffuseAlpha(value:Number):void
		{
			_baseMethod.diffuseAlpha = value;
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
			var code:String = _baseMethod.getFragmentCodePerLight(vo, lightDirReg, lightColReg, regCache);
			_totalLightColorReg = _baseMethod._totalLightColorReg;
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
		{
			var code:String = _baseMethod.getFragmentCodePerProbe(vo, cubeMapReg, weightRegister, regCache);
			_totalLightColorReg = _baseMethod._totalLightColorReg;
			return code;
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
		override arcane function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			return _baseMethod.getVertexCode(vo, regCache);
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
		 * @inheritDoc
		 */
		override arcane function set sharedRegisters(value:ShaderRegisterData):void
		{
			super.sharedRegisters = _baseMethod.sharedRegisters = value;
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

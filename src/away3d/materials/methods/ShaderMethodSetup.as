package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.events.ShadingMethodEvent;
	
	import flash.events.EventDispatcher;
	
	use namespace arcane;

	/**
	 * ShaderMethodSetup contains the method configuration for an entire material.
	 */
	public class ShaderMethodSetup extends EventDispatcher
	{
		arcane var _colorTransformMethod:ColorTransformMethod;
		arcane var _colorTransformMethodVO:MethodVO;
		arcane var _normalMethod:BasicNormalMethod;
		arcane var _normalMethodVO:MethodVO;
		arcane var _ambientMethod:BasicAmbientMethod;
		arcane var _ambientMethodVO:MethodVO;
		arcane var _shadowMethod:ShadowMapMethodBase;
		arcane var _shadowMethodVO:MethodVO;
		arcane var _diffuseMethod:BasicDiffuseMethod;
		arcane var _diffuseMethodVO:MethodVO;
		arcane var _specularMethod:BasicSpecularMethod;
		arcane var _specularMethodVO:MethodVO;
		arcane var _methods:Vector.<MethodVOSet>;

		/**
		 * Creates a new ShaderMethodSetup object.
		 */
		public function ShaderMethodSetup()
		{
			_methods = new Vector.<MethodVOSet>();
			_normalMethod = new BasicNormalMethod();
			_ambientMethod = new BasicAmbientMethod();
			_diffuseMethod = new BasicDiffuseMethod();
			_specularMethod = new BasicSpecularMethod();
			_normalMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_diffuseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_specularMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_ambientMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_normalMethodVO = _normalMethod.createMethodVO();
			_ambientMethodVO = _ambientMethod.createMethodVO();
			_diffuseMethodVO = _diffuseMethod.createMethodVO();
			_specularMethodVO = _specularMethod.createMethodVO();
		}

		/**
		 * Called when any method's code is invalidated.
		 */
		private function onShaderInvalidated(event:ShadingMethodEvent):void
		{
			invalidateShaderProgram();
		}

		/**
		 * Invalidates the material's shader code.
		 */
		private function invalidateShaderProgram():void
		{
			dispatchEvent(new ShadingMethodEvent(ShadingMethodEvent.SHADER_INVALIDATED));
		}

		/**
		 *  The method used to generate the per-pixel normals.
		 */
		public function get normalMethod():BasicNormalMethod
		{
			return _normalMethod;
		}
		
		public function set normalMethod(value:BasicNormalMethod):void
		{
			if (_normalMethod)
				_normalMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			
			if (value) {
				if (_normalMethod)
					value.copyFrom(_normalMethod);
				_normalMethodVO = value.createMethodVO();
				value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			}
			
			_normalMethod = value;
			
			if (value)
				invalidateShaderProgram();
		}

		/**
		 * The method that provides the ambient lighting contribution.
		 */
		public function get ambientMethod():BasicAmbientMethod
		{
			return _ambientMethod;
		}
		
		public function set ambientMethod(value:BasicAmbientMethod):void
		{
			if (_ambientMethod)
				_ambientMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			if (value) {
				if (_ambientMethod)
					value.copyFrom(_ambientMethod);
				value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_ambientMethodVO = value.createMethodVO();
			}
			_ambientMethod = value;
			
			if (value)
				invalidateShaderProgram();
		}

		/**
		 * The method used to render shadows cast on this surface, or null if no shadows are to be rendered.
		 */
		public function get shadowMethod():ShadowMapMethodBase
		{
			return _shadowMethod;
		}
		
		public function set shadowMethod(value:ShadowMapMethodBase):void
		{
			if (_shadowMethod)
				_shadowMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_shadowMethod = value;
			if (_shadowMethod) {
				_shadowMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_shadowMethodVO = _shadowMethod.createMethodVO();
			} else
				_shadowMethodVO = null;
			invalidateShaderProgram();
		}

		/**
		 * The method that provides the diffuse lighting contribution.
		 */
		 public function get diffuseMethod():BasicDiffuseMethod
		{
			return _diffuseMethod;
		}
		
		public function set diffuseMethod(value:BasicDiffuseMethod):void
		{
			if (_diffuseMethod)
				_diffuseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			
			if (value) {
				if (_diffuseMethod)
					value.copyFrom(_diffuseMethod);
				value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_diffuseMethodVO = value.createMethodVO();
			}
			
			_diffuseMethod = value;
			
			if (value)
				invalidateShaderProgram();
		}
		
		/**
		 * The method to perform specular shading.
		 */
		public function get specularMethod():BasicSpecularMethod
		{
			return _specularMethod;
		}
		
		public function set specularMethod(value:BasicSpecularMethod):void
		{
			if (_specularMethod) {
				_specularMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				if (value)
					value.copyFrom(_specularMethod);
			}
			
			_specularMethod = value;
			if (_specularMethod) {
				_specularMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_specularMethodVO = _specularMethod.createMethodVO();
			} else
				_specularMethodVO = null;
			
			invalidateShaderProgram();
		}
		
		/**
		 * @private
		 */
		arcane function get colorTransformMethod():ColorTransformMethod
		{
			return _colorTransformMethod;
		}
		
		arcane function set colorTransformMethod(value:ColorTransformMethod):void
		{
			if (_colorTransformMethod == value)
				return;
			if (_colorTransformMethod)
				_colorTransformMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			if (!_colorTransformMethod || !value)
				invalidateShaderProgram();
			
			_colorTransformMethod = value;
			if (_colorTransformMethod) {
				_colorTransformMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_colorTransformMethodVO = _colorTransformMethod.createMethodVO();
			} else
				_colorTransformMethodVO = null;
		}

		/**
		 * Disposes the object.
		 */
		public function dispose():void
		{
			clearListeners(_normalMethod);
			clearListeners(_diffuseMethod);
			clearListeners(_shadowMethod);
			clearListeners(_ambientMethod);
			clearListeners(_specularMethod);
			
			for (var i:int = 0; i < _methods.length; ++i)
				clearListeners(_methods[i].method);
			
			_methods = null;
		}

		/**
		 * Removes all listeners from a method.
		 */
		private function clearListeners(method:ShadingMethodBase):void
		{
			if (method)
				method.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}
		
		/**
		 * Adds a method to change the material after all lighting is performed.
		 * @param method The method to be added.
		 */
		public function addMethod(method:EffectMethodBase):void
		{
			_methods.push(new MethodVOSet(method));
			method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			invalidateShaderProgram();
		}

		/**
		 * Queries whether a given effect method was added to the material.
		 *
		 * @param method The method to be queried.
		 * @return true if the method was added to the material, false otherwise.
		 */
		public function hasMethod(method:EffectMethodBase):Boolean
		{
			return getMethodSetForMethod(method) != null;
		}
		
		/**
		 * Inserts a method to change the material after all lighting is performed at the given index.
		 * @param method The method to be added.
		 * @param index The index of the method's occurrence
		 */
		public function addMethodAt(method:EffectMethodBase, index:int):void
		{
			_methods.splice(index, 0, new MethodVOSet(method));
			method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			invalidateShaderProgram();
		}

		/**
		 * Returns the method added at the given index.
		 * @param index The index of the method to retrieve.
		 * @return The method at the given index.
		 */
		public function getMethodAt(index:int):EffectMethodBase
		{
			if (index > _methods.length - 1)
				return null;
			
			return _methods[index].method;
		}

		/**
		 * The number of "effect" methods added to the material.
		 */
		public function get numMethods():int
		{
			return _methods.length;
		}
		
		/**
		 * Removes a method from the pass.
		 * @param method The method to be removed.
		 */
		public function removeMethod(method:EffectMethodBase):void
		{
			var methodSet:MethodVOSet = getMethodSetForMethod(method);
			if (methodSet != null) {
				var index:int = _methods.indexOf(methodSet);
				_methods.splice(index, 1);
				method.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				invalidateShaderProgram();
			}
		}
		
		private function getMethodSetForMethod(method:EffectMethodBase):MethodVOSet
		{
			var len:int = _methods.length;
			for (var i:int = 0; i < len; ++i) {
				if (_methods[i].method == method)
					return _methods[i];
			}
			
			return null;
		}
	}
}

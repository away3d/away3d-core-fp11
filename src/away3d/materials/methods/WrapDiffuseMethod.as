package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	use namespace arcane;
	
	/**
	 * WrapDiffuseMethod is an alternative to BasicDiffuseMethod in which the light is allowed to be "wrapped around" the normally dark area, to some extent.
	 * It can be used as a crude approximation to Oren-Nayar or simple subsurface scattering.
	 */
	public class WrapDiffuseMethod extends BasicDiffuseMethod
	{
		private var _wrapDataRegister:ShaderRegisterElement;
		private var _wrapFactor:Number;
		
		/**
		 * Creates a new WrapDiffuseMethod object.
		 * @param wrapFactor A factor to indicate the amount by which the light is allowed to wrap
		 */
		public function WrapDiffuseMethod(wrapFactor:Number = .5)
		{
			super();
			this.wrapFactor = wrapFactor;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData():void
		{
			super.cleanCompilationData();
			_wrapDataRegister = null;
		}

		/**
		 * A factor to indicate the amount by which the light is allowed to wrap.
		 */
		public function get wrapFactor():Number
		{
			return _wrapFactor;
		}
		
		public function set wrapFactor(value:Number):void
		{
			_wrapFactor = value;
			_wrapFactor = 1/(value + 1);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			var code:String = super.getFragmentPreLightingCode(vo, regCache);
			_isFirstLight = true;
			_wrapDataRegister = regCache.getFreeFragmentConstant();
			vo.secondaryFragmentConstantsIndex = _wrapDataRegister.index*4;
			
			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
		{
			var code:String = "";
			var t:ShaderRegisterElement;
			
			// write in temporary if not first light, so we can add to total diffuse colour
			if (_isFirstLight)
				t = _totalLightColorReg;
			else {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			
			code += "dp3 " + t + ".x, " + lightDirReg + ".xyz, " + _sharedRegisters.normalFragment + ".xyz\n" +
				"add " + t + ".y, " + t + ".x, " + _wrapDataRegister + ".x\n" +
				"mul " + t + ".y, " + t + ".y, " + _wrapDataRegister + ".y\n" +
				"sat " + t + ".w, " + t + ".y\n" +
				"mul " + t + ".xz, " + t + ".w, " + lightDirReg + ".wz\n";
			
			if (_modulateMethod != null)
				code += _modulateMethod(vo, t, regCache, _sharedRegisters);
			
			code += "mul " + t + ", " + t + ".x, " + lightColReg + "\n";
			
			if (!_isFirstLight) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + t + ".xyz\n";
				regCache.removeFragmentTempUsage(t);
			}
			
			_isFirstLight = false;
			
			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			super.activate(vo, stage3DProxy);
			var index:int = vo.secondaryFragmentConstantsIndex;
			var data:Vector.<Number> = vo.fragmentData;
			data[index] = _wrapFactor;
			data[index + 1] = 1/(_wrapFactor + 1);
		}
	}
}

package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	use namespace arcane;

	/**
	 * RimLightMethod provides a method to add rim lighting to a material. This adds a glow-like effect to edges of objects.
	 */
	public class RimLightMethod extends EffectMethodBase
	{
		public static const ADD:String = "add";
		public static const MULTIPLY:String = "multiply";
		public static const MIX:String = "mix";
		
		private var _color:uint;
		private var _blendMode:String;
		private var _colorR:Number;
		private var _colorG:Number;
		private var _colorB:Number;
		private var _strength:Number;
		private var _power:Number;

		/**
		 * Creates a new RimLightMethod.
		 * @param color The colour of the rim light.
		 * @param strength The strength of the rim light.
		 * @param power The power of the rim light. Higher values will result in a higher edge fall-off.
		 * @param blend The blend mode with which to add the light to the object.
		 */
		public function RimLightMethod(color:uint = 0xffffff, strength:Number = .4, power:Number = 2, blend:String = "mix")
		{
			super();
			_blendMode = blend;
			_strength = strength;
			_power = power;
			this.color = color;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initConstants(vo:MethodVO):void
		{
			vo.fragmentData[vo.fragmentConstantsIndex + 3] = 1;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			vo.needsNormals = true;
			vo.needsView = true;
		}


		/**
		 * The blend mode with which to add the light to the object.
		 *
		 * RimLightMethod.MULTIPLY multiplies the rim light with the material's colour.
		 * RimLightMethod.ADD adds the rim light with the material's colour.
		 * RimLightMethod.MIX provides normal alpha blending.
		 */
		public function get blendMode() : String
		{
			return _blendMode;
		}

		public function set blendMode(value : String) : void
		{
			if (_blendMode == value) return;
			_blendMode = value;
			invalidateShaderProgram();
		}

		/**
		 * The color of the rim light.
		 */
		public function get color():uint
		{
			return _color;
		}
		
		public function set color(value:uint):void
		{
			_color = value;
			_colorR = ((value >> 16) & 0xff)/0xff;
			_colorG = ((value >> 8) & 0xff)/0xff;
			_colorB = (value & 0xff)/0xff;
		}

		/**
		 * The strength of the rim light.
		 */
		public function get strength():Number
		{
			return _strength;
		}
		
		public function set strength(value:Number):void
		{
			_strength = value;
		}

		/**
		 * The power of the rim light. Higher values will result in a higher edge fall-off.
		 */
		public function get power():Number
		{
			return _power;
		}
		
		public function set power(value:Number):void
		{
			_power = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			var index:int = vo.fragmentConstantsIndex;
			var data:Vector.<Number> = vo.fragmentData;
			data[index] = _colorR;
			data[index + 1] = _colorG;
			data[index + 2] = _colorB;
			data[index + 4] = _strength;
			data[index + 5] = _power;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var dataRegister:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataRegister2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code:String = "";
			
			vo.fragmentConstantsIndex = dataRegister.index*4;
			
			code += "dp3 " + temp + ".x, " + _sharedRegisters.viewDirFragment + ".xyz, " + _sharedRegisters.normalFragment + ".xyz	\n" +
				"sat " + temp + ".x, " + temp + ".x														\n" +
				"sub " + temp + ".x, " + dataRegister + ".w, " + temp + ".x								\n" +
				"pow " + temp + ".x, " + temp + ".x, " + dataRegister2 + ".y							\n" +
				"mul " + temp + ".x, " + temp + ".x, " + dataRegister2 + ".x							\n" +
				"sub " + temp + ".x, " + dataRegister + ".w, " + temp + ".x								\n" +
				"mul " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".x						\n" +
				"sub " + temp + ".w, " + dataRegister + ".w, " + temp + ".x								\n";
			
			if (_blendMode == ADD) {
				code += "mul " + temp + ".xyz, " + temp + ".w, " + dataRegister + ".xyz							\n" +
					"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz						\n";
			} else if (_blendMode == MULTIPLY) {
				code += "mul " + temp + ".xyz, " + temp + ".w, " + dataRegister + ".xyz							\n" +
					"mul " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz						\n";
			} else {
				code += "sub " + temp + ".xyz, " + dataRegister + ".xyz, " + targetReg + ".xyz				\n" +
					"mul " + temp + ".xyz, " + temp + ".xyz, " + temp + ".w								\n" +
					"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz					\n";
			}
			
			return code;
		}
	}
}

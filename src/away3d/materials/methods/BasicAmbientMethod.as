package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * BasicAmbientMethod provides the default shading method for uniform ambient lighting.
	 */


	public class BasicAmbientMethod extends ShadingMethodBase
	{
		private var _ambientColor : uint = 0xffffff;
		private var _ambientData : Vector.<Number>;
		private var _ambientR : Number = 0, _ambientG : Number = 0, _ambientB : Number = 0;
		private var _ambient : Number = 1;
		arcane var _lightAmbientR : Number = 0;
		arcane var _lightAmbientG : Number = 0;
		arcane var _lightAmbientB : Number = 0;

		protected var _ambientInputRegister : ShaderRegisterElement;
		protected var _ambientInputIndex : int;


		/**
		 * Creates a new BasicAmbientMethod object.
		 */
		public function BasicAmbientMethod()
		{
			super(false, false, false);
			_ambientData = Vector.<Number>([0, 0, 0, 1]);
		}

		/**
		 * The strength of the ambient reflection of the surface.
		 */
		public function get ambient() : Number
		{
			return _ambient;
		}

		public function set ambient(value : Number) : void
		{
			_ambient = value;
		}

		/**
		 * The colour of the ambient reflection of the surface.
		 */
		public function get ambientColor() : uint
		{
			return _ambientColor;
		}

		public function set ambientColor(value : uint) : void
		{
			_ambientColor = value;
		}

		/**
		 * Copies the state from a BasicAmbientMethod object into the current object.
		 */
		override public function copyFrom(method : ShadingMethodBase) : void
		{
			var diff : BasicAmbientMethod = BasicAmbientMethod(method);
			ambient = diff.ambient;
			ambientColor = diff.ambientColor;
			smooth = diff.smooth;
			repeat = diff.repeat;
			mipmap = diff.mipmap;
			numLights = diff.numLights;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function set numLights(value : int) : void
		{
			super.numLights = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			_ambientInputRegister = regCache.getFreeFragmentConstant();
			_ambientInputIndex = _ambientInputRegister.index;

			return "mov " + targetReg.toString() + ", " + _ambientInputRegister.toString() + "	\n";
		}

		arcane override function reset() : void
		{
			super.reset();
			_ambientInputIndex = -1;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_ambientInputRegister = null;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy) : void
		{
			updateAmbient();
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _ambientInputIndex, _ambientData, 1);
		}

		/**
		 * Updates the ambient color data used by the render state.
		 */
		private function updateAmbient() : void
		{
			_ambientData[uint(0)] = _ambientR = ((_ambientColor >> 16) & 0xff) / 0xff * _ambient * _lightAmbientR;
			_ambientData[uint(1)] = _ambientG = ((_ambientColor >> 8) & 0xff) / 0xff * _ambient * _lightAmbientG;
			_ambientData[uint(2)] = _ambientB = (_ambientColor & 0xff) / 0xff * _ambient * _lightAmbientB;
		}


	}
}

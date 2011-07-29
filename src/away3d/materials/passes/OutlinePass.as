package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.CubeTexture3DProxy;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;

	use namespace arcane;

	public class OutlinePass extends MaterialPassBase
	{
		private var _outlineColor : uint;
		private var _colorData : Vector.<Number>;
		private var _offsetData : Vector.<Number>;
		private var _showInnerLines : Boolean;

		/**
		 *
		 * @param outlineColor
		 * @param outlineSize
		 * @param showInnerLines
		 */
		public function OutlinePass(outlineColor : uint = 0x000000,  outlineSize : Number = 20, showInnerLines : Boolean = true)
		{
			super();
			mipmap = false;
			_colorData = new Vector.<Number>(4, true);
			_colorData[3] = 1;
			_offsetData = new Vector.<Number>(4, true);
			this.outlineColor = outlineColor;
			this.outlineSize = outlineSize;
			_defaultCulling = Context3DTriangleFace.FRONT;
			_animatableAttributes = ["va0", "va1"];
			_targetRegisters = ["vt0", "vt1"];
			_numUsedStreams = 2;
			_numUsedVertexConstants = 5;
			_showInnerLines = showInnerLines;
		}

		public function get showInnerLines() : Boolean
		{
			return _showInnerLines;
		}

		public function set showInnerLines(value : Boolean) : void
		{
			_showInnerLines = value;
		}

		public function get outlineColor() : uint
		{
			return _outlineColor;
		}

		public function set outlineColor(value : uint) : void
		{
			_outlineColor = value;
			_colorData[0] = ((value >> 16) & 0xff) / 0xff;
			_colorData[1] = ((value >> 8) & 0xff) / 0xff;
			_colorData[2] = (value & 0xff) / 0xff;
		}

		public function get outlineSize() : Number
		{
			return _offsetData[0];
		}

		public function set outlineSize(value : Number) : void
		{
			_offsetData[0] = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode() : String
		{
			return "";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : String
		{
			return 	"mov oc, fc0\n";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			super.activate(stage3DProxy, camera);

			// do not write depth if not drawing inner lines (will cause the overdraw to hide inner lines)
			if (!_showInnerLines)
				context.setDepthTest(false, Context3DCompareMode.LESS);

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _colorData, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _offsetData, 1);
		}


		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			super.deactivate(stage3DProxy);
			if (!_showInnerLines)
				stage3DProxy._context3D.setDepthTest(true, Context3DCompareMode.LESS);
		}


		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			stage3DProxy.setSimpleVertexBuffer(1, renderable.getVertexNormalBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3);
			super.render(renderable, stage3DProxy, camera);
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateProgram(stage3DProxy : Stage3DProxy, polyOffsetReg : String = null) : void
		{
			super.updateProgram(stage3DProxy, "vc4.x");
		}
	}

}
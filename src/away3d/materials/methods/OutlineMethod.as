package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.passes.OutlinePass;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	use namespace arcane;

	/**
	 * OutlineMethod provides a shading method to add outlines to an object.
	 */
	public class OutlineMethod extends EffectMethodBase
	{
		private var _outlinePass:OutlinePass;
		
		/**
		 * Creates a new OutlineMethod object.
		 * @param outlineColor The colour of the outline stroke
		 * @param outlineSize The size of the outline stroke
		 * @param showInnerLines Indicates whether or not strokes should be potentially drawn over the existing model.
		 * @param dedicatedWaterProofMesh Used to stitch holes appearing due to mismatching normals for overlapping vertices. Warning: this will create a new mesh that is incompatible with animations!
		 */
		public function OutlineMethod(outlineColor:uint = 0x000000, outlineSize:Number = 1, showInnerLines:Boolean = true, dedicatedWaterProofMesh:Boolean = false)
		{
			super();
			_passes = new Vector.<MaterialPassBase>();
			_outlinePass = new OutlinePass(outlineColor, outlineSize, showInnerLines, dedicatedWaterProofMesh);
			_passes.push(_outlinePass);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function initVO(vo:MethodVO):void
		{
			vo.needsNormals = true;
		}
		
		/**
		 * Indicates whether or not strokes should be potentially drawn over the existing model.
		 * Set this to true to draw outlines for geometry overlapping in the view, useful to achieve a cel-shaded drawing outline.
		 * Setting this to false will only cause the outline to appear around the 2D projection of the geometry.
		 */
		public function get showInnerLines():Boolean
		{
			return _outlinePass.showInnerLines;
		}
		
		public function set showInnerLines(value:Boolean):void
		{
			_outlinePass.showInnerLines = value;
		}
		
		/**
		 * The colour of the outline.
		 */
		public function get outlineColor():uint
		{
			return _outlinePass.outlineColor;
		}
		
		public function set outlineColor(value:uint):void
		{
			_outlinePass.outlineColor = value;
		}
		
		/**
		 * The size of the outline.
		 */
		public function get outlineSize():Number
		{
			return _outlinePass.outlineSize;
		}
		
		public function set outlineSize(value:Number):void
		{
			_outlinePass.outlineSize = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function reset():void
		{
			super.reset();
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			return "";
		}
	}
}

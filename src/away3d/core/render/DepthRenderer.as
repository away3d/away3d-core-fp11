package away3d.core.render
{
	import away3d.core.base.IRenderable;
	import away3d.core.sort.DepthSorter;
	import away3d.core.traverse.EntityCollector;
	import away3d.materials.utils.AGAL;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;

	/**
	 * The DepthRenderer class renders 32-bit depth information encoded as RGBA
	 */
	public class DepthRenderer extends RendererBase
	{
		private var _program3D : Program3D;
		private var _enc : Vector.<Number>;
		private var _renderBlended : Boolean;

		/**
		 * Creates a new DepthRenderer object.
		 * @param renderBlended Indicates whether semi-transparent objects should be rendered.
		 * @param antiAlias The amount of anti-aliasing to be used.
		 * @param renderMode The render mode to be used.
		 */
		public function DepthRenderer(renderBlended : Boolean = false, antiAlias : uint = 0, renderMode : String = "auto")
		{
			super(antiAlias, true, renderMode);
			_renderBlended = renderBlended;
			_enc = Vector.<Number>([	1.0, 255.0, 65025.0, 160581375.0,
										1.0 / 255.0,1.0 / 255.0,1.0 / 255.0,0.0]);
			_backgroundR = 1;
			_backgroundG = 1;
			_backgroundB = 1;
			_renderableSorter = new DepthSorter();
		}

		/**
		 * @inheritDoc
		 */
		override protected function draw(entityCollector : EntityCollector) : void
		{
			var opaques : Vector.<IRenderable> = entityCollector.opaqueRenderables;
			var blendeds : Vector.<IRenderable> = entityCollector.blendedRenderables;
			var len : uint = opaques.length;
			var renderable : IRenderable;

			_context.setDepthTest(true, Context3DCompareMode.LESS);
			_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

			if (!_program3D) initProgram3D(_context);
			_context.setProgram(_program3D);
			_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _enc, 2);

			for (var i : uint = 0; i < len; ++i) {
				renderable = opaques[i];
				_context.setVertexBufferAt(0, renderable.getVertexBuffer(_context, _contextIndex), 0, Context3DVertexBufferFormat.FLOAT_3);
				_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, renderable.modelViewProjection, true);
				_context.drawTriangles(renderable.getIndexBuffer(_context, _contextIndex), 0, renderable.numTriangles);
			}

			if (!_renderBlended) return;

			len = blendeds.length;
			for (i = 0; i < len; ++i) {
				renderable = blendeds[i];
				_context.setVertexBufferAt(0, renderable.getVertexBuffer(_context, _contextIndex), 0, Context3DVertexBufferFormat.FLOAT_3);
				_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, renderable.modelViewProjection, true);
				_context.drawTriangles(renderable.getIndexBuffer(_context, _contextIndex), 0, renderable.numTriangles);
			}
		}

		/**
		 * Creates the depth rendering Program3D.
		 * @param context The Context3D object for which the Program3D needs to be created.
		 */
		private function initProgram3D(context : Context3D) : void
		{
			var vertexCode : String;
			var fragmentCode : String;

			_program3D = context.createProgram();

			vertexCode = 	"m44 vt0, va0, vc0	\n" +
							"mov op, vt0		\n" +
							"rcp vt1.x, vt0.w	\n" +
							"mul v0, vt0, vt1.x	\n";

			fragmentCode =  AGAL.mul("ft0", "fc0", "v0.z") +
							AGAL.fract("ft0", "ft0") +
							AGAL.mul("ft1", "ft0.yzww", "fc1") +
							AGAL.sub("ft0", "ft0", "ft1") +
							AGAL.mov("oc", "ft0");

			_program3D.upload(	new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX, vertexCode),
								new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT, fragmentCode));
		}
	}
}
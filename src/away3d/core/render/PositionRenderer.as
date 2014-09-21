package away3d.core.render
{
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.pool.RenderableBase;
	import away3d.core.geom.Matrix3DUtils;
	import away3d.core.traverse.ICollector;
	import away3d.debug.Debug;
	
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	
	/**
	 * The PositionRenderer renders normalized position coordinates.
	 */
	public class PositionRenderer extends RendererBase
	{
		private var _program3D:Program3D;
		private var _renderBlended:Boolean;
		
		/**
		 * Creates a PositionRenderer object.
		 * @param renderBlended Indicates whether semi-transparent objects should be rendered.
		 * @param antiAlias The amount of anti-aliasing to be used
		 * @param renderMode The render mode to be used.
		 */
		public function PositionRenderer(renderBlended:Boolean = false)
		{
			// todo: request context in here
			_renderBlended = renderBlended;
			super();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function draw(entityCollector:ICollector, target:TextureBase):void
		{
			var renderable:RenderableBase;
			var matrix:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
			var viewProjection:Matrix3D = entityCollector.camera.viewProjection;
			
			_context3D.setDepthTest(true, Context3DCompareMode.LESS);
			_context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			
			if (!_program3D)
				initProgram3D(_context3D);
			_context3D.setProgram(_program3D);
			
			renderable = opaqueRenderableHead;
			while (renderable) {
				_stage3DProxy.activateBuffer(0, renderable.getVertexData(TriangleSubGeometry.POSITION_DATA), renderable.getVertexOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);
				matrix.copyFrom(renderable.renderSceneTransform);
				matrix.append(viewProjection);
				_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, viewProjection, true);
				_context3D.drawTriangles(_stage3DProxy.getIndexBuffer(renderable.getIndexData()), 0, renderable.numTriangles);
				renderable = renderable.next as RenderableBase;
			}
			
			if (!_renderBlended)
				return;
			
			renderable = blendedRenderableHead;
			while (renderable) {
				_stage3DProxy.activateBuffer(0, renderable.getVertexData(TriangleSubGeometry.POSITION_DATA), renderable.getVertexOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);
				matrix.copyFrom(renderable.renderSceneTransform);
				matrix.append(viewProjection);
				_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
				_context3D.drawTriangles(_stage3DProxy.getIndexBuffer(renderable.getIndexData()), 0, renderable.numTriangles);
				renderable = renderable.next as RenderableBase;
			}
		}
		
		/**
		 * Creates the depth rendering Program3D.
		 * @param context The Context3D object for which the Program3D needs to be created.
		 */
		private function initProgram3D(context:Context3D):void
		{
			var vertexCode:String;
			var fragmentCode:String;
			
			_program3D = context.createProgram();
			
			vertexCode = "m44 vt0, va0, vc0	\n" +
				"mov op, vt0		\n" +
				"rcp vt1.x, vt0.w	\n" +
				"mul v0, vt0, vt1.x	\n";
			fragmentCode = "mov oc, v0\n";
			
			_program3D.upload(new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, vertexCode),
				new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, fragmentCode));
		}
	}
}

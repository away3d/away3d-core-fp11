package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.core.base.TriangleSubMesh;
	import away3d.core.base.Geometry;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.pool.MaterialPassData;
	import away3d.managers.Stage3DProxy;
	import away3d.core.geom.Matrix3DUtils;
	import away3d.core.pool.RenderableBase;
	import away3d.core.pool.TriangleSubMeshRenderable;
	import away3d.entities.Camera3D;
	import away3d.entities.Mesh;
	import away3d.materials.compilation.ShaderObjectBase;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterData;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;

	use namespace arcane;

	/**
	 * OutlinePass is a pass that offsets a mesh and draws it in a single colour. This is a pass provided by OutlineMethod.
	 *
	 * @see away3d.materials.methods.OutlineMethod
	 */
	public class OutlinePass extends MaterialPassBase
	{
		private var _outlineColor:uint;
		private var _colorData:Vector.<Number>;
		private var _offsetData:Vector.<Number>;
		private var _showInnerLines:Boolean;
		private var _outlineMeshes:Dictionary;
		private var _dedicatedMeshes:Boolean;
		private var _defaultCulling:String;

		/**
		 * Creates a new OutlinePass object.
		 * @param outlineColor The colour of the outline stroke
		 * @param outlineSize The size of the outline stroke
		 * @param showInnerLines Indicates whether or not strokes should be potentially drawn over the existing model.
		 * @param dedicatedWaterProofMesh Used to stitch holes appearing due to mismatching normals for overlapping vertices. Warning: this will create a new mesh that is incompatible with animations!
		 */
		public function OutlinePass(outlineColor:uint = 0x000000, outlineSize:Number = 20, showInnerLines:Boolean = true, dedicatedMeshes:Boolean = false)
		{
			super();
//			mipmap = false;
			_colorData = new Vector.<Number>(4, true);
			_colorData[3] = 1;
			_offsetData = new Vector.<Number>(4, true);
			this.outlineColor = outlineColor;
			this.outlineSize = outlineSize;
			_defaultCulling = Context3DTriangleFace.FRONT;
//			_numUsedStreams = 2;
//			_numUsedVertexConstants = 6;
			_showInnerLines = showInnerLines;
			_dedicatedMeshes = dedicatedMeshes;
			if (dedicatedMeshes)
				_outlineMeshes = new Dictionary();
			
//			_animatableAttributes = Vector.<String>(["va0", "va1"]);
//			_animationTargetRegisters = Vector.<String>(["vt0", "vt1"]);
		
		}
		
		/**
		 * Clears the dedicated mesh associated with a Mesh object to free up memory.
		 */
		public function clearDedicatedMesh(mesh:Mesh):void
		{
			if (_dedicatedMeshes) {
				for (var i:int = 0; i < mesh.subMeshes.length; ++i)
					disposeDedicated(mesh.subMeshes[i]);
			}
		}

		/**
		 * Disposes a single dedicated sub-mesh.
		 */
		private function disposeDedicated(keySubMesh:Object):void
		{
			var mesh:Mesh;
			mesh = Mesh(_dedicatedMeshes[keySubMesh]);
			mesh.geometry.dispose();
			mesh.dispose();
			delete _dedicatedMeshes[keySubMesh];
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			
			if (_dedicatedMeshes) {
				for (var key:Object in _outlineMeshes)
					disposeDedicated(key);
			}
		}

		/**
		 * Indicates whether or not strokes should be potentially drawn over the existing model.
		 * Set this to true to draw outlines for geometry overlapping in the view, useful to achieve a cel-shaded drawing outline.
		 * Setting this to false will only cause the outline to appear around the 2D projection of the geometry.
		 */
		public function get showInnerLines():Boolean
		{
			return _showInnerLines;
		}
		
		public function set showInnerLines(value:Boolean):void
		{
			_showInnerLines = value;
		}

		/**
		 * The colour of the outline.
		 */
		public function get outlineColor():uint
		{
			return _outlineColor;
		}
		
		public function set outlineColor(value:uint):void
		{
			_outlineColor = value;
			_colorData[0] = ((value >> 16) & 0xff)/0xff;
			_colorData[1] = ((value >> 8) & 0xff)/0xff;
			_colorData[2] = (value & 0xff)/0xff;
		}

		/**
		 * The size of the outline.
		 */
		public function get outlineSize():Number
		{
			return _offsetData[0];
		}
		
		public function set outlineSize(value:Number):void
		{
			_offsetData[0] = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function getVertexCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			var code:String;
			// offset
			code = "mul vt7, vt1, vc5.x\n" +
			"add vt7, vt7, vt0\n" +
			"mov vt7.w, vt0.w\n" +
				// project and scale to viewport
			"m44 op, vt7, vc0		\n";

			return code;
		}

		/**
		 * @inheritDoc
		 */
		override public function getFragmentCode(shaderObject:ShaderObjectBase, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			return "mov oc, fc0\n";
		}

		/**
		 * @inheritDoc
		 */
		override public function activate(pass:MaterialPassData, stage:Stage3DProxy, camera:Camera3D):void
		{
			var context:Context3D = stage._context3D;
			super.activate(pass, stage, camera);
			
			// do not write depth if not drawing inner lines (will cause the overdraw to hide inner lines)
			if (!_showInnerLines)
				context.setDepthTest(false, Context3DCompareMode.LESS);
			context.setCulling(_defaultCulling);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _colorData, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, _offsetData, 1);
		}

		/**
		 * @inheritDoc
		 */
		override public function deactivate(pass:MaterialPassData, stage:Stage3DProxy):void
		{
			super.deactivate(pass, stage);
			if (!_showInnerLines)
				stage._context3D.setDepthTest(true, Context3DCompareMode.LESS);
		}

		/**
		 * @inheritDoc
		 */
		override public function render(pass:MaterialPassData, renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
		{
			var mesh:Mesh;
			var dedicatedRenderable:RenderableBase;
			
			var context:Context3D = stage._context3D;
			var matrix3D:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
			matrix3D.copyFrom(renderable.sourceEntity.getRenderSceneTransform(camera));
			matrix3D.append(viewProjection);
			
			if (_dedicatedMeshes) {
				mesh = _outlineMeshes[renderable] ||= createDedicatedMesh(renderable);

				dedicatedRenderable = new TriangleSubMeshRenderable(null,mesh.subMeshes[0] as TriangleSubMesh);
				
				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix3D, true);
				stage.activateBuffer(0, dedicatedRenderable.getVertexData(TriangleSubGeometry.POSITION_DATA), dedicatedRenderable.getVertexOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);
				stage.activateBuffer(1, dedicatedRenderable.getVertexData(TriangleSubGeometry.NORMAL_DATA), dedicatedRenderable.getVertexOffset(TriangleSubGeometry.NORMAL_DATA), TriangleSubGeometry.NORMAL_FORMAT);
				context.drawTriangles(stage.getIndexBuffer(dedicatedRenderable.getIndexData()), 0, dedicatedRenderable.numTriangles);
			} else {
				stage.activateBuffer(1, renderable.getVertexData(TriangleSubGeometry.NORMAL_DATA), renderable.getVertexOffset(TriangleSubGeometry.NORMAL_DATA), TriangleSubGeometry.NORMAL_FORMAT);
				
				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix3D, true);
				stage.activateBuffer(0, renderable.getVertexData(TriangleSubGeometry.POSITION_DATA), renderable.getVertexOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);
				context.drawTriangles(stage.getIndexBuffer(renderable.getIndexData()), 0, renderable.numTriangles);
			}
		}

		/**
		 * Creates a new mesh in which vertices with the same position are collapsed into a single vertex. This
		 * will prevent gaps appearing where vertex normals are different for a seemingly single vertex.
		 *
		 * @param source The ISubGeometry object for which to generate a dedicated mesh.
		 */
		private function createDedicatedMesh(source:RenderableBase):Mesh
		{
			var mesh:Mesh = new Mesh(new Geometry(), null);
			var dest:TriangleSubGeometry = new TriangleSubGeometry(true);
			//TODO: test OutlinePass
			var indexLookUp:Array = [];
			var srcIndices:Vector.<uint> = source.getIndexData().data;
			var srcVertices:Vector.<Number> = source.getVertexData(TriangleSubGeometry.POSITION_DATA).data;
			var dstIndices:Vector.<uint> = new Vector.<uint>();
			var dstVertices:Vector.<Number> = new Vector.<Number>();
			var index:int;
			var x:Number, y:Number, z:Number;
			var key:String;
			var indexCount:int;
			var vertexCount:int;
			var len:int = srcIndices.length;
			var maxIndex:int;

			for (var i:int = 0; i < len; ++i) {
				index = srcIndices[i];
				x = srcVertices[index*3];
				y = srcVertices[index*3 + 1];
				z = srcVertices[index*3 + 2];
				key = x.toPrecision(5) + "/" + y.toPrecision(5) + "/" + z.toPrecision(5);
				
				if (indexLookUp[key])
					index = indexLookUp[key] - 1;
				else {
					index = vertexCount/3;
					indexLookUp[key] = index + 1;
					dstVertices[vertexCount++] = x;
					dstVertices[vertexCount++] = y;
					dstVertices[vertexCount++] = z;
				}
				
				if (index > maxIndex)
					maxIndex = index;
				dstIndices[indexCount++] = index;
			}
			
			dest.updatePositions(dstVertices);
			dest.updateIndices(dstIndices);
			mesh.geometry.addSubGeometry(dest);
			return mesh;
		}
	}
}

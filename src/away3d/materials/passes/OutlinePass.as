package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.IRenderable;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.SubMesh;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.Matrix3DUtils;
	import away3d.entities.Mesh;
	
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
			mipmap = false;
			_colorData = new Vector.<Number>(4, true);
			_colorData[3] = 1;
			_offsetData = new Vector.<Number>(4, true);
			this.outlineColor = outlineColor;
			this.outlineSize = outlineSize;
			_defaultCulling = Context3DTriangleFace.FRONT;
			_numUsedStreams = 2;
			_numUsedVertexConstants = 6;
			_showInnerLines = showInnerLines;
			_dedicatedMeshes = dedicatedMeshes;
			if (dedicatedMeshes)
				_outlineMeshes = new Dictionary();
			
			_animatableAttributes = Vector.<String>(["va0", "va1"]);
			_animationTargetRegisters = Vector.<String>(["vt0", "vt1"]);
		
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
		arcane override function getVertexCode():String
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
		arcane override function getFragmentCode(animationCode:String):String
		{
			return "mov oc, fc0\n";
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			var context:Context3D = stage3DProxy._context3D;
			super.activate(stage3DProxy, camera);
			
			// do not write depth if not drawing inner lines (will cause the overdraw to hide inner lines)
			if (!_showInnerLines)
				context.setDepthTest(false, Context3DCompareMode.LESS);
			
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _colorData, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, _offsetData, 1);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function deactivate(stage3DProxy:Stage3DProxy):void
		{
			super.deactivate(stage3DProxy);
			if (!_showInnerLines)
				stage3DProxy._context3D.setDepthTest(true, Context3DCompareMode.LESS);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
		{
			var mesh:Mesh, dedicatedRenderable:IRenderable;
			
			var context:Context3D = stage3DProxy._context3D;
			var matrix3D:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
			matrix3D.copyFrom(renderable.getRenderSceneTransform(camera));
			matrix3D.append(viewProjection);
			
			if (_dedicatedMeshes) {
				mesh = _outlineMeshes[renderable] ||= createDedicatedMesh(SubMesh(renderable).subGeometry);
				dedicatedRenderable = mesh.subMeshes[0];
				
				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix3D, true);
				dedicatedRenderable.activateVertexBuffer(0, stage3DProxy);
				dedicatedRenderable.activateVertexNormalBuffer(1, stage3DProxy);
				context.drawTriangles(dedicatedRenderable.getIndexBuffer(stage3DProxy), 0, dedicatedRenderable.numTriangles);
			} else {
				renderable.activateVertexNormalBuffer(1, stage3DProxy);
				
				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix3D, true);
				renderable.activateVertexBuffer(0, stage3DProxy);
				context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
			}
		}

		/**
		 * Creates a new mesh in which vertices with the same position are collapsed into a single vertex. This
		 * will prevent gaps appearing where vertex normals are different for a seemingly single vertex.
		 *
		 * @param source The ISubGeometry object for which to generate a dedicated mesh.
		 */
		private function createDedicatedMesh(source:ISubGeometry):Mesh
		{
			var mesh:Mesh = new Mesh(new Geometry(), null);
			var dest:SubGeometry = new SubGeometry();
			var indexLookUp:Array = [];
			var srcIndices:Vector.<uint> = source.indexData;
			var srcVertices:Vector.<Number> = source.vertexData;
			var dstIndices:Vector.<uint> = new Vector.<uint>();
			var dstVertices:Vector.<Number> = new Vector.<Number>();
			var index:int;
			var x:Number, y:Number, z:Number;
			var key:String;
			var indexCount:int;
			var vertexCount:int;
			var len:int = srcIndices.length;
			var maxIndex:int;
			var stride:int = source.vertexStride;
			var offset:int = source.vertexOffset;
			
			for (var i:int = 0; i < len; ++i) {
				index = offset + srcIndices[i]*stride;
				x = srcVertices[index];
				y = srcVertices[index + 1];
				z = srcVertices[index + 2];
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
			
			dest.autoDeriveVertexNormals = true;
			dest.updateVertexData(dstVertices);
			dest.updateIndexData(dstIndices);
			mesh.geometry.addSubGeometry(dest);
			return mesh;
		}
	}
}

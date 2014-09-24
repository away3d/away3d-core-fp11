package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.pool.RenderableBase;
	import away3d.entities.Camera3D;
	import away3d.core.pool.IRenderable;
	import away3d.managers.Stage3DProxy;
	import away3d.core.base.LightBase;
    import away3d.textures.RenderTexture;

    import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;
	
	use namespace arcane;
	
	/**
	 * The SingleObjectDepthPass provides a material pass that renders a single object to a depth map from the point
	 * of view from a light.
	 */
	public class SingleObjectDepthPass extends MaterialPassBase
	{
		private var _textures:Object;
		private var _projections:Object;
		private var _textureSize:uint;
		private var _polyOffset:Vector.<Number>;
		private var _enc:Vector.<Number>;
		private var _projectionTexturesInvalid:Boolean = true;
		
		/**
		 * Creates a new SingleObjectDepthPass object.
		 * @param textureSize The size of the depth map texture to render to.
		 * @param polyOffset The amount by which the rendered object will be inflated, to prevent depth map rounding errors.
		 *
		 * todo: provide custom vertex code to assembler
		 */
		public function SingleObjectDepthPass(textureSize:uint = 512, polyOffset:Number = 15)
		{
			super(true);
			_textureSize = textureSize;
			_numUsedStreams = 2;
			_numUsedVertexConstants = 7;
			_polyOffset = new <Number>[polyOffset, 0, 0, 0];
			_enc = Vector.<Number>([    1.0, 255.0, 65025.0, 16581375.0,
				1.0/255.0, 1.0/255.0, 1.0/255.0, 0.0
				]);
			
			_animatableAttributes = Vector.<String>(["va0", "va1"]);
			_animationTargetRegisters = Vector.<String>(["vt0", "vt1"]);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
            if (_textures) {
                for (var key:* in _textures) {
                    var texture:RenderTexture = _textures[key];
                    texture.dispose();
                }
                _textures = null;
            }
		}

		/**
		 * Updates the projection textures used to contain the depth renders.
		 */
		private function updateProjectionTextures():void
		{
            if (_textures) {
                for (var key:* in _textures) {
                    var texture:RenderTexture = _textures[key];
                    texture.dispose();
                }
            }

            _textures = {};
            _projections = {};
            _projectionTexturesInvalid = false;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode():String
		{
			var code:String;
			// offset
			code = "mul vt7, vt1, vc4.x	\n" +
				"add vt7, vt7, vt0		\n" +
				"mov vt7.w, vt0.w		\n";
			// project
			code += "m44 vt2, vt7, vc0		\n" +
				"mov op, vt2			\n";
			
			// perspective divide
			code += "div v0, vt2, vt2.w \n";
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(animationCode:String):String
		{
			var code:String = "";
			
			// encode float -> rgba
			code += "mul ft0, fc0, v0.z     \n" +
				"frc ft0, ft0           \n" +
				"mul ft1, ft0.yzww, fc1 \n" +
				"sub ft0, ft0, ft1      \n" +
				"mov oc, ft0            \n";
			
			return code;
		}

		/**
		 * Gets the depth maps rendered for this object from all lights.
		 * @param renderable The renderable for which to retrieve the depth maps.
		 * @param stage3DProxy The Stage3DProxy object currently used for rendering.
		 * @return A list of depth map textures for all supported lights.
		 */
		arcane function getDepthMap(renderable:IRenderable):RenderTexture
		{
			return _textures[renderable.materialOwner.id];
		}
		
		/**
		 * Retrieves the depth map projection maps for all lights.
		 * @param renderable The renderable for which to retrieve the projection maps.
		 * @return A list of projection maps for all supported lights.
		 */
		arcane function getProjection(renderable:IRenderable):Matrix3D
		{
            return _projections[renderable.materialOwner.id];
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function render(renderable:RenderableBase, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
		{
			var matrix:Matrix3D;
			var contextIndex:int = stage3DProxy._stage3DIndex;
			var context:Context3D = stage3DProxy._context3D;
			var len:uint;
			var light:LightBase;
			var lights:Vector.<LightBase> = _lightPicker.allPickedLights;
            var rId:uint = renderable.materialOwner.id;

            if (!_textures[rId])
                _textures[rId] = new RenderTexture(_textureSize, _textureSize);

            if (!_projections[rId])
                _projections[rId] = new Matrix3D();

            len = lights.length;

			// local position = enough
			light = lights[0];
			
			matrix = light.getObjectProjectionMatrix(renderable.sourceEntity, camera, _projections[renderable]);
			
			stage3DProxy.setRenderTarget(_textures[rId], true);
			context.clear(1, 1, 1);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _enc, 2);

			stage3DProxy.activateBuffer(0, renderable.getVertexData(TriangleSubGeometry.POSITION_DATA), renderable.getVertexOffset(TriangleSubGeometry.POSITION_DATA), TriangleSubGeometry.POSITION_FORMAT);
			stage3DProxy.activateBuffer(1, renderable.getVertexData(TriangleSubGeometry.NORMAL_DATA), renderable.getVertexOffset(TriangleSubGeometry.NORMAL_DATA), TriangleSubGeometry.NORMAL_FORMAT);
			context.drawTriangles(stage3DProxy.getIndexBuffer(renderable.getIndexData()), 0, renderable.numTriangles);
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			if (_projectionTexturesInvalid)
				updateProjectionTextures();
			// never scale
			super.activate(stage3DProxy, camera);
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _polyOffset, 1);
		}
	}
}

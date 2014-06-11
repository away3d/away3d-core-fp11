package away3d.core.render {
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.pool.RenderableBase;
	import away3d.entities.Camera3D;
	import away3d.materials.MaterialBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class GBufferRenderer {
		private var _drawDepth:Boolean = true;
		private var _drawWorldNormal:Boolean = true;
		private var _drawPosition:Boolean = true;
		private var _drawAlbedo:Boolean = false;
		private var _drawSpecular:Boolean = false;

		public function GBufferRenderer() {
		}

		public function render(stage3DProxy:Stage3DProxy, opaqueHead:RenderableBase, camera:Camera3D, projectionMatrix:Matrix3D):void {
			var context3D:Context3D = stage3DProxy.context3D;
			var renderable:RenderableBase = opaqueHead;
			var renderable2:RenderableBase;
			var activeMaterial:MaterialBase;

			context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			context3D.setDepthTest(true, Context3DCompareMode.LESS);

			while (renderable) {
				activeMaterial = renderable.material;
				// otherwise this would result in depth rendered anyway because fragment shader kil is ignored
				activeMaterial.activateForGBuffer(stage3DProxy, camera, _drawDepth, _drawWorldNormal, _drawPosition, _drawAlbedo, _drawSpecular);
				renderable2 = renderable;
				do {
					activeMaterial.renderGBuffer(renderable2, stage3DProxy, camera, projectionMatrix);
					renderable2 = renderable2.next as RenderableBase;
				} while (renderable2 && renderable2.material == activeMaterial);
				activeMaterial.deactivateGBuffer(stage3DProxy);
				renderable = renderable2;
			}

			if (activeMaterial) {
				activeMaterial.deactivateGBuffer(stage3DProxy);
				activeMaterial = null;
			}
		}

		public function get drawSpecular():Boolean {
			return _drawSpecular;
		}

		public function set drawSpecular(value:Boolean):void {
			_drawSpecular = value;
		}

		public function get drawAlbedo():Boolean {
			return _drawAlbedo;
		}

		public function set drawAlbedo(value:Boolean):void {
			_drawAlbedo = value;
		}

		public function get drawWorldNormal():Boolean {
			return _drawWorldNormal;
		}

		public function set drawWorldNormal(value:Boolean):void {
			_drawWorldNormal = value;
		}

		public function get drawDepth():Boolean {
			return _drawDepth;
		}

		public function set drawDepth(value:Boolean):void {
			_drawDepth = value;
		}

		public function get drawPosition():Boolean {
			return _drawPosition;
		}

		public function set drawPosition(value:Boolean):void {
			_drawPosition = value;
		}
	}
}

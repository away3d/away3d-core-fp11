package away3d.core.render {
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
	import away3d.core.pool.RenderableBase;
	import away3d.entities.Camera3D;
	import away3d.materials.MaterialBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class WorldNormalRenderer {

		public function WorldNormalRenderer() {
		}

		public function render(stage3DProxy:Stage3DProxy, opaqueHead:RenderableBase, camera:Camera3D, projectionMatrix:Matrix3D):void {
			var context3D:Context3D = stage3DProxy.context3D;
			context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			context3D.setDepthTest(true, Context3DCompareMode.LESS);

			var renderable:RenderableBase = opaqueHead;
			var renderable2:RenderableBase;
			var activeMaterial:MaterialBase;

			while (renderable) {
				activeMaterial = renderable.material;
//				activeMaterial.activateForWorldNormal(stage3DProxy, camera);
				renderable2 = renderable;
				do {
//					activeMaterial.renderWorldNormal(renderable2, stage3DProxy, camera, projectionMatrix);
					renderable2 = renderable2.next as RenderableBase;
				} while (renderable2 && renderable2.material == activeMaterial);
//				activeMaterial.deactivateForWorldNormal(stage3DProxy);
				renderable = renderable2;
			}

			if (activeMaterial) {
//				activeMaterial.deactivateForWorldNormal(stage3DProxy);
				activeMaterial = null;
			}
		}
	}
}

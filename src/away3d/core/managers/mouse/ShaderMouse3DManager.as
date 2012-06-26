package away3d.core.managers.mouse
{

	import away3d.arcane;
	import away3d.containers.View3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Mouse3DManager;
	import away3d.core.render.HitTestRenderer;
	import away3d.core.traverse.EntityCollector;

	use namespace arcane;

	public class ShaderMouse3DManager extends Mouse3DManager
	{
		private var _hitTestRenderer:HitTestRenderer;

		public function ShaderMouse3DManager() {
			super();
		}

		override public function set view( view:View3D ):void {
			super.view = view;
			_hitTestRenderer = new HitTestRenderer( view );
			_hitTestRenderer.stage3DProxy = _view.stage3DProxy;
		}

		override protected function updatePicker():void {
			var collector:EntityCollector = _view.entityCollector;
			_hitTestRenderer.update(_view.mouseX / _view.width, _view.mouseY / _view.height, collector);
			var activeRenderable:IRenderable = _hitTestRenderer.hitRenderable;
			_collidingObject = activeRenderable ? activeRenderable.sourceEntity : null;
			if( _collidingObject ) {
				_collisionPosition = _hitTestRenderer.localHitPosition;
				_collisionNormal = _hitTestRenderer.localHitNormal;
				_collisionUV = _hitTestRenderer.hitUV;
			}
		}
	}
}

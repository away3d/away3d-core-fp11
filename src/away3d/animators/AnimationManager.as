/**
 * Author: David Lenaerts
 */
package away3d.animators
{
	import away3d.arcane;

	use namespace arcane;

	public class AnimationManager
	{
		private static var _instance : AnimationManager;

		private var _controllers : Vector.<AnimatorBase>;

		public function AnimationManager(se : SingletonEnforcer)
		{
			_controllers = new Vector.<AnimatorBase>();
		}

		public static function getInstance() : AnimationManager
		{
			return _instance ||= new AnimationManager(new SingletonEnforcer());
		}

		public function updateAnimations(deltaTime : int) : void
		{
			var len : uint = _controllers.length;

			for (var i : int = 0; i < len; ++i)
				_controllers[i].updateAnimation(deltaTime);
		}

		arcane function registerController(controller : AnimatorBase) : void
		{
			_controllers.push(controller);
		}

		arcane function unregisterController(controller : AnimatorBase) : void
		{
			_controllers.splice(_controllers.indexOf(controller), 1);
		}
	}
}

class SingletonEnforcer {}
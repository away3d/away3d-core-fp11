package away3d.core.traverse
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;

	use namespace arcane;

	public class SceneIterator
	{
		private static const PRE : int = 0;
		private static const IN : int = 1;
		private static const POST : int = 2;

		private var _childIndex : int;
		private var _scene : Scene3D;
		private var _node : ObjectContainer3D;
		private var _traverseState : int;
		private var _childIndexStack : Vector.<int>;
		private var _stackPos : int;

		public function SceneIterator(scene : Scene3D)
		{
			_scene = scene;
			reset();
		}

		public function reset() : void
		{
			_childIndexStack = new Vector.<int>();
			_node = _scene._sceneGraphRoot;
			_childIndex = 0;
			_stackPos = 0;
			_traverseState = PRE;
		}

		public function next() : ObjectContainer3D
		{
			do {
				switch (_traverseState) {
					case PRE:
					// just entered a node
						_childIndexStack[_stackPos++] = _childIndex;
						_childIndex = 0;
						_traverseState = IN;
						return _node;
					case IN:
						if (_childIndex == _node.numChildren)
							_traverseState = POST;
						else {
							_node = _node.getChildAt(_childIndex);
							_traverseState = PRE;
						}
						break;
					case POST:
						_node = _node.parent;
						_childIndex = _childIndexStack[--_stackPos] + 1;
						_traverseState = IN;
						break;
				}
			} while (!(_node == _scene._sceneGraphRoot && _traverseState == POST));

			return null;
		}
	}
}

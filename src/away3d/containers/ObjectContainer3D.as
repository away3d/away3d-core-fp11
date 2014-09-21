package away3d.containers
{
	import away3d.arcane;
	import away3d.core.base.Object3D;
	import away3d.core.partition.Partition3D;
	import away3d.core.library.AssetType;
	import away3d.core.library.IAsset;

	use namespace arcane;

	/**
	 * Dispatched when the scene transform matrix of the 3d object changes.
	 *
	 * @eventType away3d.events.Object3DEvent
	 * @see    #sceneTransform
	 */
	[Event(name="scenetransformChanged", type="away3d.events.Object3DEvent")]

	/**
	 * Dispatched when the parent scene of the 3d object changes.
	 *
	 * @eventType away3d.events.Object3DEvent
	 * @see    #scene
	 */
	[Event(name="sceneChanged", type="away3d.events.Object3DEvent")]

	/**
	 * Dispatched when a user moves the cursor while it is over the 3d object.
	 *
	 * @eventType away3d.events.MouseEvent3D
	 */
	[Event(name="mouseMove3d", type="away3d.events.MouseEvent3D")]

	/**
	 * Dispatched when a user presses the left hand mouse button while the cursor is over the 3d object.
	 *
	 * @eventType away3d.events.MouseEvent3D
	 */
	[Event(name="mouseDown3d", type="away3d.events.MouseEvent3D")]

	/**
	 * Dispatched when a user releases the left hand mouse button while the cursor is over the 3d object.
	 *
	 * @eventType away3d.events.MouseEvent3D
	 */
	[Event(name="mouseUp3d", type="away3d.events.MouseEvent3D")]

	/**
	 * Dispatched when a user moves the cursor over the 3d object.
	 *
	 * @eventType away3d.events.MouseEvent3D
	 */
	[Event(name="mouseOver3d", type="away3d.events.MouseEvent3D")]

	/**
	 * Dispatched when a user moves the cursor away from the 3d object.
	 *
	 * @eventType away3d.events.MouseEvent3D
	 */
	[Event(name="mouseOut3d", type="away3d.events.MouseEvent3D")]

	/**
	 * ObjectContainer3D is the most basic scene graph node. It can contain other ObjectContainer3Ds.
	 *
	 * ObjectContainer3D can have its own scene partition assigned. However, when assigned to a different scene,
	 * it will loose any partition information, since partitions are tied to a scene.
	 */ public class ObjectContainer3D extends Object3D implements IAsset
	{
		private var _mouseChildren:Boolean = true;
		private var _children:Vector.<Object3D> = new Vector.<Object3D>();
		arcane var isRoot:Boolean;

		override public function get assetType():String
		{
			return AssetType.CONTAINER;
		}


		/**
		 * Determines whether or not the children of the object are mouse, or user
		 * input device, enabled. If an object is enabled, a user can interact with
		 * it by using a mouse or user input device. The default is
		 * <code>true</code>.
		 *
		 * <p>This property is useful when you create a button with an instance of
		 * the Sprite class(instead of using the SimpleButton class). When you use a
		 * Sprite instance to create a button, you can choose to decorate the button
		 * by using the <code>addChild()</code> method to add additional Sprite
		 * instances. This process can cause unexpected behavior with mouse events
		 * because the Sprite instances you add as children can become the target
		 * object of a mouse event when you expect the parent instance to be the
		 * target object. To ensure that the parent instance serves as the target
		 * objects for mouse events, you can set the <code>mouseChildren</code>
		 * property of the parent instance to <code>false</code>.</p>
		 *
		 * <p> No event is dispatched by setting this property. You must use the
		 * <code>addEventListener()</code> method to create interactive
		 * functionality.</p>
		 */
		public function get mouseChildren():Boolean
		{
			return _mouseChildren;
		}

		public function set mouseChildren(value:Boolean):void
		{
			if (_mouseChildren == value) return;

			_mouseChildren = value;

			updateImplicitMouseEnabled(_parent ? _parent.mouseChildren : true);
		}

		function ObjectContainer3D()
		{

		}

		/**
		 * Adds a child ObjectContainer3D to the current object. The child's transformation will become relative to the
		 * current object's transformation.
		 * @param child The object to be added as a child.
		 * @return A reference to the added child object.
		 */
		public function addChild(child:Object3D):Object3D
		{
			if (child == null)
				throw new Error("Parameter child cannot be null.");

			if (child.parent)
				child.parent.removeChild(child);

			child.setParent(this);

			_children.push(child);

			return child;
		}

		/**
		 * Adds an array of 3d objects to the scene as children of the container
		 *
		 * @param    ...childarray        An array of 3d objects to be added
		 */
		public function addChildren(...childarray):void
		{
			for each (var child:ObjectContainer3D in childarray)
				addChild(child);
		}

		/**
		 *
		 */
		override public function clone():Object3D
		{
			var clone:ObjectContainer3D = new ObjectContainer3D();
			clone.pivot = pivot;
			clone.transform = transform;
			clone.partition = partition;
			clone.name = name;

			var len:int = _children.length;
			for (var i:int = 0; i < len; ++i)
				clone.addChild(_children[i].clone());

			// todo: implement for all subtypes
			return clone;
		}

		/**
		 * Determines whether the specified display object is a child of the
		 * DisplayObjectContainer instance or the instance itself. The search
		 * includes the entire display list including this DisplayObjectContainer
		 * instance. Grandchildren, great-grandchildren, and so on each return
		 * <code>true</code>.
		 *
		 * @param child The child object to test.
		 * @return <code>true</code> if the <code>child</code> object is a child of
		 *         the DisplayObjectContainer or the container itself; otherwise
		 *         <code>false</code>.
		 */
		public function contains(child:Object3D):Boolean
		{
			return _children.indexOf(child) >= 0;
		}

		public function disposeWithChildren():void
		{
			dispose();

			while (numChildren > 0)
				getChildAt(0).dispose();
		}

		/**
		 * Returns the child display object that exists with the specified name. If
		 * more that one child display object has the specified name, the method
		 * returns the first object in the child list.
		 *
		 * <p>The <code>getChildAt()</code> method is faster than the
		 * <code>getChildByName()</code> method. The <code>getChildAt()</code> method
		 * accesses a child from a cached array, whereas the
		 * <code>getChildByName()</code> method has to traverse a linked list to
		 * access a child.</p>
		 *
		 * @param name The name of the child to return.
		 * @return The child display object with the specified name.
		 */
		public function getChildByName(name:String):Object3D
		{
			var len:int = _children.length;
			for (var i:int = 0; i < len; ++i)
				if (_children[i].name == name)
					return _children[i];

			return null;
		}

		/**
		 * Returns the index position of a <code>child</code> DisplayObject instance.
		 *
		 * @param child The DisplayObject instance to identify.
		 * @return The index position of the child display object to identify.
		 * @throws ArgumentError Throws if the child parameter is not a child of this
		 *                       object.
		 */
		public function getChildIndex(child:Object3D):Number /*int*/
		{
			var childIndex:Number = _children.indexOf(child);

			if (childIndex == -1)
				throw new ArgumentError("Child parameter is not a child of the caller");

			return childIndex;
		}

		/**
		 * Retrieves the child object at the given index.
		 * @param index The index of the object to be retrieved.
		 * @return The child object at the given index.
		 */
		public function getChildAt(index:uint):Object3D
		{
			return _children[index];
		}

		/**
		 * The amount of child objects of the ObjectContainer3D.
		 */
		public function get numChildren():uint
		{
			return _children.length;
		}

		/**
		 * Removes a 3d object from the child array of the container
		 *
		 * @param    child    The 3d object to be removed
		 * @throws    Error    ObjectContainer3D.removeChild(null)
		 */
		public function removeChild(child:Object3D):Object3D
		{
			if (child == null)
				throw new Error("Parameter child cannot be null");

			removeChildInternal(child);
			child.setParent(null);
			return child;
		}

		/**
		 * Removes a 3d object from the child array of the container
		 *
		 * @param    index    Index of 3d object to be removed
		 */
		public function removeChildAt(index:uint):Object3D
		{
			return removeChild(_children[index]);
		}

		/**
		 * Removes all <code>child</code> DisplayObject instances from the child list
		 * of the DisplayObjectContainer instance. The <code>parent</code> property
		 * of the removed children is set to <code>null</code>, and the objects are
		 * garbage collected if no other references to the children exist.
		 *
		 * The garbage collector reallocates unused memory space. When a variable or
		 * object is no longer actively referenced or stored somewhere, the garbage
		 * collector sweeps through and wipes out the memory space it used to occupy
		 * if no other references to it exist.
		 *
		 * @param beginIndex The beginning position. A value smaller than 0 throws a RangeError.
		 * @param endIndex The ending position. A value smaller than 0 throws a RangeError.
		 * @throws RangeError    Throws if the beginIndex or endIndex positions do
		 *                       not exist in the child list.
		 */
		public function removeChildren(beginIndex:int = 0, endIndex:int = 2147483647):void
		{
			if (beginIndex < 0)
				throw new RangeError("beginIndex is out of range of the child list");

			if (endIndex > _children.length)
				throw new RangeError("endIndex is out of range of the child list");

			for (var i:int = beginIndex; i < endIndex; i++)
				removeChild(_children[i]);
		}

		/**
		 * @protected
		 */
		override public function invalidateSceneTransform():void
		{
			super.invalidateSceneTransform();

			var len:int = _children.length;
			for (var i:int = 0; i < len; ++i)
				_children[i].invalidateSceneTransform();
		}

		/**
		 * @protected
		 */
		override protected function updateScene(value:Scene3D):void
		{
			super.updateScene(value);

			var len:int = _children.length;
			for (var i:int = 0; i < len; ++i)
				_children[i].updateScene(value);
		}

		/**
		 * @protected
		 */
		override protected function updateImplicitMouseEnabled(value:Boolean):void
		{
			super.updateImplicitMouseEnabled(value);

			var len:int = _children.length;
			for (var i:int = 0; i < len; ++i)
				_children[i].updateImplicitMouseEnabled(_mouseChildren);
		}

		/**
		 * @protected
		 */
		override protected function updateImplicitVisibility(value:Boolean):void
		{
			super.updateImplicitVisibility(value);

			var len:int = _children.length;
			for (var i:int = 0; i < len; ++i)
				_children[i].updateImplicitVisibility(_implicitVisibility);
		}

		/**
		 * @protected
		 */
		override protected function updateImplicitPartition(value:Partition3D):void
		{
			super.updateImplicitPartition(value);

			var len:int = _children.length;
			for (var i:int = 0; i < len; ++i)
				_children[i].updateImplicitPartition(_implicitPartition);
		}

		/**
		 * @private
		 *
		 * @param child
		 */
		private function removeChildInternal(child:Object3D):Object3D
		{
			_children.splice(getChildIndex(child), 1);
			return child;
		}
	}
}

package away3d.core.data
{

	public class LinkedListUtil
	{
		public static function filterLinkedList( listHead:ListItem, filterFunction:Function ):ListItem {

			var listItem:ListItem;
			var lastValidListItem:ListItem;

			listItem = listHead;
			while( listItem ) {

				if( filterFunction( listItem ) ) {

					if( lastValidListItem ) {
						lastValidListItem.next = listItem;
					}
					else {
						listHead = listItem;
					}

					lastValidListItem = listItem;
				}

				listItem = RenderableListItem( listItem.next );
			}

			return listHead;

		}

		/*
		* compareFunction should return -1 if a.value < b.value, 1 if else
		* */
		public static function sortLinkedList( listHead:ListItem, listLength:uint, compareFunction:Function ):ListItem {

			var i:uint, j:uint;

			var item1:ListItem;
			var item2:ListItem;
			var item3:ListItem;

			var subListLength:uint = listLength - 1;

			for( i = 1; i < listLength; ++i ) {

				item1 = listHead;
				item2 = listHead.next;
				item3 = item2.next;

				for( j = 1; j <= subListLength; ++j ) {

					if( compareFunction( item2, item3 ) ) {

						item2.next = item3.next;
						item3.next = item2;
						item1.next = item3;

						item1 = item3;
						item3 = item2.next;

					}
					else {

						item1 = item2;
						item2 = item3;
						item3 = item3.next;

					}

				}

			}

			return listHead;

		}
	}
}

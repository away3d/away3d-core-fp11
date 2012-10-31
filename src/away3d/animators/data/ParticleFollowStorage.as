package away3d.animators.data
{
	import away3d.core.managers.Stage3DProxy;
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	/**
	 * ...
	 */
	public class ParticleFollowStorage
	{
		protected var _itemList:Vector.<ParticleFollowingItem> = new Vector.<ParticleFollowingItem>;
		protected var _numVertices:uint;
		protected var _dataLength:int;
		
		public function ParticleFollowStorage()
		{
		}
		
		public function initData(numVertices:uint,dataLength:int):void
		{
			_numVertices = numVertices;
			_dataLength = dataLength;
		}
		
		public function get numVertices():uint
		{
			return _numVertices;
		}
		
		public function get itemList():Vector.<ParticleFollowingItem>
		{
			return _itemList;
		}
		
		public function get dataLength():int
		{
			return _dataLength;
		}
	}

}
package away3d.animators.data
{
	/**
	 * ...
	 */
	public class ParticleFollowStorage
	{
		protected var _itemList:Vector.<ParticleAnimationData> = new Vector.<ParticleAnimationData>;
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
		
		public function get itemList():Vector.<ParticleAnimationData>
		{
			return _itemList;
		}
		
		public function get dataLength():int
		{
			return _dataLength;
		}
	}

}
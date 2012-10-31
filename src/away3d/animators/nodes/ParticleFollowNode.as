package away3d.animators.nodes
{

	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleFollowingItem;
	import away3d.animators.data.ParticleFollowStorage;
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleFollowingItem;
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.states.ParticleFollowState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	
	/**
	 * ...
	 */
	public class ParticleFollowNode extends LocalParticleNodeBase
	{
		public static const NAME:String = "ParticleFollowNode";
		public static const FOLLOW_OFFSET_STREAM_REGISTER:int = 0;
		public static const FOLLOW_ROTATION_STREAM_REGISTER:int = 1;
		
		private var _offset:Boolean;
		private var _rotation:Boolean;
		
		/**
		 *
		 * If you this node, make sure you have set the ParticleAnimationSet::hasSleepTime to true
		 */
		public function ParticleFollowNode(offset:Boolean, rotation:Boolean)
		{
			super(NAME, ParticleAnimationSet.POST_PRIORITY);
			_stateClass = ParticleFollowState;
			_dataLenght = 0;
			initOneData();
			
			this._offset = offset;
			this._rotation = rotation;
		}
		
		override public function procressExtraData(param:ParticleParameter, animationSubGeometry:AnimationSubGeometry, numVertex:int):void
		{
			
			var storage:ParticleFollowStorage = animationSubGeometry.extraStorage[this];
			if (!storage)
			{
				storage = animationSubGeometry.extraStorage[this] = new ParticleFollowStorage;
				if (needOffset && needRotate)
					storage.initData(animationSubGeometry.numVertices, 6);
				else
					storage.initData(animationSubGeometry.numVertices, 3);
			}
			var item:ParticleFollowingItem = new ParticleFollowingItem();
			item.startTime = param.startTime;
			item.lifeTime = param.sleepTime + param.duringTime;
			item.numVertex = numVertex;
			var len:uint = storage.itemList.length;
			if (len > 0)
			{
				var lastItem:ParticleFollowingItem = storage.itemList[len - 1];
				item.startIndex = lastItem.startIndex + lastItem.numVertex;
			}
			storage.itemList.push(item);
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, animationRegisterCache:AnimationRegisterCache):String
		{
			var code:String = "";
			if (_rotation)
				code += getRotationCode(animationRegisterCache);
			if (_offset)
				code += getOffsetCode(animationRegisterCache);
			
			return code;
		}
		
		private function getOffsetCode(animationRegisterCache:AnimationRegisterCache):String
		{
			var offsetAttribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, FOLLOW_OFFSET_STREAM_REGISTER, offsetAttribute.index);
			return "add " + animationRegisterCache.scaleAndRotateTarget.toString() + "," + offsetAttribute.toString() + "," + animationRegisterCache.scaleAndRotateTarget.toString() + "\n";
		}
		
		private function getRotationCode(animationRegisterCache:AnimationRegisterCache):String
		{
			var rotationAttribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, FOLLOW_ROTATION_STREAM_REGISTER, rotationAttribute.index);
			
			var temp1:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(temp1, 1);
			var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(temp2, 1);
			var temp3:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			
			animationRegisterCache.removeVertexTempUsage(temp1);
			animationRegisterCache.removeVertexTempUsage(temp2);
			
			var code:String = "";
			
			code += "mov " + temp1.toString() + "," + animationRegisterCache.vertexZeroConst.toString() + "\n";
			code += "cos " + temp1.toString() + ".x," + rotationAttribute.toString() + ".x\n";
			code += "sin " + temp1.toString() + ".y," + rotationAttribute.toString() + ".x\n";
			code += "mov " + temp2.toString() + "," + animationRegisterCache.vertexZeroConst.toString() + "\n";
			code += "neg " + temp2.toString() + ".x," + temp1.toString() + ".y\n";
			code += "mov " + temp2.toString() + ".y," + temp1.toString() + ".x\n";
			code += "mov " + temp3.toString() + "," + animationRegisterCache.vertexZeroConst.toString() + "\n";
			code += "mov " + temp3.toString() + ".z," + animationRegisterCache.vertexOneConst.toString() + "\n";
			code += "m33 " + animationRegisterCache.scaleAndRotateTarget.toString() + "," + animationRegisterCache.scaleAndRotateTarget.toString() + "," + temp1.toString() + "\n";
			
			code += "mov " + temp1.toString() + "," + animationRegisterCache.vertexZeroConst.toString() + "\n";
			code += "mov " + temp1.toString() + ".x," + animationRegisterCache.vertexOneConst.toString() + "\n";
			code += "mov " + temp2.toString() + ".x," + animationRegisterCache.vertexZeroConst.toString() + "\n";
			code += "cos " + temp2.toString() + ".y," + rotationAttribute.toString() + ".y\n";
			code += "sin " + temp2.toString() + ".z," + rotationAttribute.toString() + ".y\n";
			code += "mov " + temp3.toString() + "," + animationRegisterCache.vertexZeroConst.toString() + "\n";
			code += "neg " + temp3.toString() + ".y," + temp2.toString() + ".z\n";
			code += "mov " + temp3.toString() + ".z," + temp2.toString() + ".y\n";
			code += "m33 " + animationRegisterCache.scaleAndRotateTarget.toString() + "," + animationRegisterCache.scaleAndRotateTarget.toString() + "," + temp1.toString() + "\n";
			
			code += "cos " + temp1.toString() + ".x," + rotationAttribute.toString() + ".z\n";
			code += "sin " + temp1.toString() + ".y," + rotationAttribute.toString() + ".z\n";
			code += "mov " + temp1.toString() + ".z," + animationRegisterCache.vertexZeroConst.toString() + "\n";
			code += "neg " + temp2.toString() + ".x," + temp1.toString() + ".y\n";
			code += "mov " + temp2.toString() + ".y," + temp1.toString() + ".x\n";
			code += "mov " + temp2.toString() + ".z," + animationRegisterCache.vertexZeroConst.toString() + "\n";
			code += "mov " + temp3.toString() + "," + animationRegisterCache.vertexZeroConst.toString() + "\n";
			code += "mov " + temp3.toString() + ".z," + animationRegisterCache.vertexOneConst.toString() + "\n";
			code += "m33 " + animationRegisterCache.scaleAndRotateTarget.toString() + "," + animationRegisterCache.scaleAndRotateTarget.toString() + "," + temp1.toString() + "\n";
			
			return code;
		}
		
		public function get needOffset():Boolean
		{
			return _offset;
		}
		
		public function get needRotate():Boolean
		{
			return _rotation;
		}
	}

}

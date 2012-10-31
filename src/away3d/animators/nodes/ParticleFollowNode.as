package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleFollowingItem;
	import away3d.animators.data.ParticleFollowStorage;
	import away3d.animators.data.ParticleParamter;
	import away3d.animators.data.ParticleStreamManager;
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.states.ParticleFollowState;
	import away3d.animators.utils.ParticleAnimationCompiler;
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
		
		override public function procressExtraData(param:ParticleParamter, streamManager:ParticleStreamManager, numVertex:int):void
		{
			
			var stroage:ParticleFollowStorage = streamManager.extraStorage[this];
			if (!stroage)
			{
				stroage = streamManager.extraStorage[this] = new ParticleFollowStorage;
				if (needOffset && needRotate)
					stroage.initData(streamManager.numVertices, 6);
				else
					stroage.initData(streamManager.numVertices, 3);
			}
			var item:ParticleFollowingItem = new ParticleFollowingItem();
			item.startTime = param.startTime;
			item.lifeTime = param.sleepTime + param.duringTime;
			item.numVertex = numVertex;
			var len:uint = stroage.itemList.length;
			if (len > 0)
			{
				var lastItem:ParticleFollowingItem = stroage.itemList[len - 1];
				item.startIndex = lastItem.startIndex + lastItem.numVertex;
			}
			stroage.itemList.push(item);
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler):String
		{
			var code:String = "";
			if (_rotation)
				code += getRotationCode(activatedCompiler);
			if (_offset)
				code += getOffsetCode(activatedCompiler);
			
			return code;
		}
		
		private function getOffsetCode(activatedCompiler:ParticleAnimationCompiler):String
		{
			var offsetAttribute:ShaderRegisterElement = activatedCompiler.getFreeVertexAttribute();
			activatedCompiler.setRegisterIndex(this, FOLLOW_OFFSET_STREAM_REGISTER, offsetAttribute.index);
			return "add " + activatedCompiler.scaleAndRotateTarget.toString() + "," + offsetAttribute.toString() + "," + activatedCompiler.scaleAndRotateTarget.toString() + "\n";
		}
		
		private function getRotationCode(activatedCompiler:ParticleAnimationCompiler):String
		{
			var rotationAttribute:ShaderRegisterElement = activatedCompiler.getFreeVertexAttribute();
			activatedCompiler.setRegisterIndex(this, FOLLOW_ROTATION_STREAM_REGISTER, rotationAttribute.index);
			
			var temp1:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			activatedCompiler.addVertexTempUsages(temp1, 1);
			var temp2:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			activatedCompiler.addVertexTempUsages(temp2, 1);
			var temp3:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			
			activatedCompiler.removeVertexTempUsage(temp1);
			activatedCompiler.removeVertexTempUsage(temp2);
			
			var code:String = "";
			
			code += "mov " + temp1.toString() + "," + activatedCompiler.vertexZeroConst.toString() + "\n";
			code += "cos " + temp1.toString() + ".x," + rotationAttribute.toString() + ".x\n";
			code += "sin " + temp1.toString() + ".y," + rotationAttribute.toString() + ".x\n";
			code += "mov " + temp2.toString() + "," + activatedCompiler.vertexZeroConst.toString() + "\n";
			code += "neg " + temp2.toString() + ".x," + temp1.toString() + ".y\n";
			code += "mov " + temp2.toString() + ".y," + temp1.toString() + ".x\n";
			code += "mov " + temp3.toString() + "," + activatedCompiler.vertexZeroConst.toString() + "\n";
			code += "mov " + temp3.toString() + ".z," + activatedCompiler.vertexOneConst.toString() + "\n";
			code += "m33 " + activatedCompiler.scaleAndRotateTarget.toString() + "," + activatedCompiler.scaleAndRotateTarget.toString() + "," + temp1.toString() + "\n";
			
			code += "mov " + temp1.toString() + "," + activatedCompiler.vertexZeroConst.toString() + "\n";
			code += "mov " + temp1.toString() + ".x," + activatedCompiler.vertexOneConst.toString() + "\n";
			code += "mov " + temp2.toString() + ".x," + activatedCompiler.vertexZeroConst.toString() + "\n";
			code += "cos " + temp2.toString() + ".y," + rotationAttribute.toString() + ".y\n";
			code += "sin " + temp2.toString() + ".z," + rotationAttribute.toString() + ".y\n";
			code += "mov " + temp3.toString() + "," + activatedCompiler.vertexZeroConst.toString() + "\n";
			code += "neg " + temp3.toString() + ".y," + temp2.toString() + ".z\n";
			code += "mov " + temp3.toString() + ".z," + temp2.toString() + ".y\n";
			code += "m33 " + activatedCompiler.scaleAndRotateTarget.toString() + "," + activatedCompiler.scaleAndRotateTarget.toString() + "," + temp1.toString() + "\n";
			
			code += "cos " + temp1.toString() + ".x," + rotationAttribute.toString() + ".z\n";
			code += "sin " + temp1.toString() + ".y," + rotationAttribute.toString() + ".z\n";
			code += "mov " + temp1.toString() + ".z," + activatedCompiler.vertexZeroConst.toString() + "\n";
			code += "neg " + temp2.toString() + ".x," + temp1.toString() + ".y\n";
			code += "mov " + temp2.toString() + ".y," + temp1.toString() + ".x\n";
			code += "mov " + temp2.toString() + ".z," + activatedCompiler.vertexZeroConst.toString() + "\n";
			code += "mov " + temp3.toString() + "," + activatedCompiler.vertexZeroConst.toString() + "\n";
			code += "mov " + temp3.toString() + ".z," + activatedCompiler.vertexOneConst.toString() + "\n";
			code += "m33 " + activatedCompiler.scaleAndRotateTarget.toString() + "," + activatedCompiler.scaleAndRotateTarget.toString() + "," + temp1.toString() + "\n";
			
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

package a3dparticle.animators.actions 
{
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import away3d.arcane;
	use namespace arcane;
	
	/**
	 * ...
	 * @author liaocheng
	 */
	public class TransformFollowAction extends PerParticleAction
	{
		public var offsetAttribute:ShaderRegisterElement;
		public var rotationAttribute:ShaderRegisterElement;
		
		private var _offset:Boolean;
		private var _rotation:Boolean;
		private var temp:Vector3D;
		
		public var particlesData:Dictionary = new Dictionary();
		
		public function TransformFollowAction(offset:Boolean, rotation:Boolean)
		{
			this._offset = offset;
			this._rotation = rotation;
			priority = 9;
		}
		
		override public function genOne(param:ParticleParam):void
		{
			temp = new Vector3D(param.startTime, param.duringTime + param.sleepTime);
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			if (!particlesData[subContainer.shareAtt])
			{
				particlesData[subContainer.shareAtt] = new Vector.<Object>();
			}
			var vector:Vector.<Object> = particlesData[subContainer.shareAtt];
			if (temp)
			{
				var obj:Object = new Object;
				obj.startTime = temp.x;
				obj.lifeTime = temp.y;
				obj.num = 0;
				if (vector.length == 0)
				{
					obj.start = 0;
				}
				else
				{
					obj.start = vector[vector.length - 1].start + vector[vector.length - 1].num;
				}
				vector.push(obj);
				temp = null;
			}
			vector[vector.length - 1].num++;
			
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var code:String = "";
			if (_rotation) code += getRotationCode();
			if (_offset) code += getOffsetCode();
			
			return code;
		}
		
		private function getOffsetCode():String
		{
			offsetAttribute = shaderRegisterCache.getFreeVertexAttribute();
			var code:String = "";
			code += "add " + _animation.scaleAndRotateTarget.toString() +"," + offsetAttribute.toString() + ".xyz," + _animation.scaleAndRotateTarget.toString() + "\n";
			return code;
		}
		
		private function getRotationCode():String
		{
			rotationAttribute = shaderRegisterCache.getFreeVertexAttribute();
			
			var temp1:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp1, 1);
			var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp2, 1);
			var temp3:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			
			shaderRegisterCache.removeVertexTempUsage(temp1);
			shaderRegisterCache.removeVertexTempUsage(temp2);			
			
			var code:String = "";
			
			code += "mov " + temp1.toString() + "," + _animation.zeroConst.toString() + "\n";
			code += "cos " + temp1.toString() + ".x," + rotationAttribute.toString() + ".x\n";
			code += "sin " + temp1.toString() + ".y," + rotationAttribute.toString() + ".x\n";
			code += "mov " + temp2.toString() + "," + _animation.zeroConst.toString() + "\n";
			code += "neg " + temp2.toString() + ".x," + temp1.toString() + ".y\n";
			code += "mov " + temp2.toString() + ".y," + temp1.toString() + ".x\n";
			code += "mov " + temp3.toString() + "," + _animation.zeroConst.toString() + "\n";
			code += "mov " + temp3.toString() + ".z," + _animation.OneConst.toString() + "\n";
			code += "m33 " + _animation.scaleAndRotateTarget.toString() +"," + _animation.scaleAndRotateTarget.toString() + "," + temp1.toString() + "\n";
			
			code += "mov " + temp1.toString() + "," + _animation.zeroConst.toString() + "\n";
			code += "mov " + temp1.toString() + ".x," + _animation.OneConst.toString() + "\n";
			code += "mov " + temp2.toString() + ".x," + _animation.zeroConst.toString() + "\n";
			code += "cos " + temp2.toString() + ".y," + rotationAttribute.toString() + ".y\n";
			code += "sin " + temp2.toString() + ".z," + rotationAttribute.toString() + ".y\n";
			code += "mov " + temp3.toString() + "," + _animation.zeroConst.toString() + "\n";
			code += "neg " + temp3.toString() + ".y," + temp2.toString() + ".z\n";
			code += "mov " + temp3.toString() + ".z," + temp2.toString() + ".y\n";
			code += "m33 " + _animation.scaleAndRotateTarget.toString() +"," + _animation.scaleAndRotateTarget.toString() + "," + temp1.toString() + "\n";
			
			code += "cos " + temp1.toString() + ".x," + rotationAttribute.toString() + ".z\n";
			code += "sin " + temp1.toString() + ".y," + rotationAttribute.toString() + ".z\n";
			code += "mov " + temp1.toString() + ".z," + _animation.zeroConst.toString() + "\n";
			code += "neg " + temp2.toString() + ".x," + temp1.toString() + ".y\n";
			code += "mov " + temp2.toString() + ".y," + temp1.toString() + ".x\n";
			code += "mov " + temp2.toString() + ".z," + _animation.zeroConst.toString() + "\n";
			code += "mov " + temp3.toString() + "," + _animation.zeroConst.toString() + "\n";
			code += "mov " + temp3.toString() + ".z," + _animation.OneConst.toString() + "\n";
			code += "m33 " + _animation.scaleAndRotateTarget.toString() +"," + _animation.scaleAndRotateTarget.toString() + "," + temp1.toString() + "\n";
			
			return code;
		}
	}

}

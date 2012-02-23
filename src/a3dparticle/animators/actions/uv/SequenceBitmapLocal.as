package a3dparticle.animators.actions.uv
{
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.animators.ParticleAnimation;
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	import flash.display3D.Context3DProgramType;
	
	import away3d.arcane;
	use namespace arcane;
	
	/**
	 * ...
	 * @author ...
	 */
	public class SequenceBitmapLocal extends PerParticleAction
	{
		private var _genFun:Function;
		
		private var _temp:Vector3D;
		
		private var uvParamAttribute:ShaderRegisterElement;
		private var uvParamConst:ShaderRegisterElement;
		
		private var _smooth:Boolean;
		private var _hasStartTime:Boolean;
		
		private var _data:Vector.<Number>;
		
		private var _fullUse:Boolean;
		
		private var _cuttingNum:int;
		private var _usingNum:int;
		
		/**
		 *
		 * @param	fun Function.The fun should return a Vector3D which x is the uv offest,y is the cycle,z is start time.
		 */
		public function SequenceBitmapLocal(cuttingNum:int, smooth:Boolean = true, usingNum:int = int.MAX_VALUE, hasStartTime:Boolean = false, fun:Function = null)
		{
			priority = ParticleAnimation.POST_PRIORITY + 5;
			
			_name = "SequenceBitmapLocal";
			_cuttingNum = cuttingNum;
			_usingNum = usingNum;
			_smooth = smooth;
			_genFun = fun;
			_hasStartTime = hasStartTime;
			
			if (_hasStartTime)
				dataLenght = 3;
			else
				dataLenght = 2;
			
			_data = Vector.<Number>([_cuttingNum, 1 / _cuttingNum, _usingNum / _cuttingNum, _cuttingNum / _usingNum]);
			if (_usingNum >= cuttingNum)
				_fullUse = true;
		}
		
		override public function set animation(value:ParticleAnimation):void
		{
			super.animation = value;
			value.hasUVAction = true;
		}
		
		override public function genOne(param:ParticleParam):void
		{
			if (!_animation.needUV)
				return;
			if (_genFun != null)
			{
				_temp = _genFun(param);
			}
			else
			{
				if (!param[_name])
					throw new Error("there is no " + _name + " in param!");
				_temp = param[_name];
			}
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			if (!_animation.needUV)
				return;
			getExtraData(subContainer).push(_temp.x);
			if (_fullUse)
			{
				getExtraData(subContainer).push(1 / _temp.y);
			}
			else
			{
				getExtraData(subContainer).push(_usingNum / _temp.y / _cuttingNum);
			}
			if (_hasStartTime)
			{
				getExtraData(subContainer).push(_temp.z);
			}
		
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase):String
		{
			if (_animation.needUV)
			{
				uvParamConst = shaderRegisterCache.getFreeVertexConstant();
				uvParamAttribute = shaderRegisterCache.getFreeVertexAttribute();
				var u:ShaderRegisterElement = new ShaderRegisterElement(_animation.uvTarget.regName, _animation.uvTarget.index, "x");
				var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
				temp = new ShaderRegisterElement(temp.regName, temp.index, "x");
				var temp2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
				
				
				var code:String = "";
				code += "mul " + u.toString() + "," + u.toString() + "," + uvParamConst.toString() + ".y\n";
				if (_hasStartTime)
				{
					var temp3:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
					code += "sub " + temp3.toString() + "," + _animation.vertexTime.toString() + "," + uvParamAttribute.toString() + ".z\n";
					code += "max " + temp3.toString() + "," + temp3.toString() + "," + _animation.zeroConst.toString() + "\n";
					code += "mul " + temp.toString() + "," + temp3.toString() + "," + uvParamAttribute.toString() + ".y\n";
				}
				else
					code += "mul " + temp.toString() + "," + _animation.vertexTime.toString() + "," + uvParamAttribute.toString() + ".y\n";
					
				if (!_fullUse)
				{
					code += "mul " + temp.toString() + "," + temp.toString() + "," + uvParamConst.toString() + ".w\n";
					code += "frc " + temp.toString() + "," + temp.toString() + "\n";
					code += "mul " + temp.toString() + "," + temp.toString() + "," + uvParamConst.toString() + ".z\n";
				}
				if (!_smooth)
				{
					code += "mul " + temp.toString() + "," + temp.toString() + "," + uvParamConst.toString() + ".x\n";
					code += "frc " + temp2.toString() + "," + temp.toString() + "\n";
					code += "sub " + temp.toString() + "," + temp.toString() + "," + temp2.toString() + "\n";
					code += "mul " + temp.toString() + "," + temp.toString() + "," + uvParamConst.toString() + ".y\n";
				}
				code += "add " + u.toString() + "," + u.toString() + "," + uvParamAttribute.toString() + ".x\n";
				code += "add " + u.toString() + "," + u.toString() + "," + temp.toString() + "\n";
				return code;
			}
			else
			{
				return "";
			}
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable):void
		{
			if (_animation.needUV)
			{
				if (_hasStartTime)
					stage3DProxy.setSimpleVertexBuffer(uvParamAttribute.index, getExtraBuffer(stage3DProxy, SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_3, 0);
				else
					stage3DProxy.setSimpleVertexBuffer(uvParamAttribute.index, getExtraBuffer(stage3DProxy, SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_2, 0);
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, uvParamConst.index, _data);
			}
		}
	
	}

}
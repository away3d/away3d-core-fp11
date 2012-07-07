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
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class UVSeqPicByTimeLocal extends PerParticleAction
	{
		//return a Vector3D that x is cycle,y is start time
		private var _genFun:Function;
		private var temp:Vector3D;
		
		private var uvParamConst:ShaderRegisterElement;
		private var uvParamAttrubite:ShaderRegisterElement;
		
		private var _hasStartTime:Boolean;
		private var _loop:Boolean;
		private var _needV:Boolean;
		
		private var _data:Vector.<Number>;
		
		private var _total:int;

		public function UVSeqPicByTimeLocal(columns:int, rows:int , usingNum:int = int.MAX_VALUE, hasStartTime:Boolean = false, loop:Boolean = true, fun:Function = null)
		{
			priority = ParticleAnimation.POST_PRIORITY + 5;
			dataLenght = 3;
			_name = "UVSeqPicByTimeLocal";
			_genFun = fun;
			
			_total = Math.min(usingNum, columns * rows);
			_hasStartTime = hasStartTime;
			_loop = loop;
			if (rows > 1)_needV = true;
			var uTotal:Number = _total / columns;
			var uStep:Number = 1 / columns;
			var vStep:Number = 1 / rows;
			_data = Vector.<Number>([uTotal, uStep, vStep, 0]);
		}
		
		override public function set animation(value:ParticleAnimation):void
		{
			super.animation = value;
			value.hasUVAction = true;
		}
		
		override public function genOne(param:ParticleParam):void
		{
			if (_genFun != null)
			{
				temp = _genFun(param);
			}
			else
			{
				if (!param[_name]) throw("there is no ", _name, " in param!");
				temp = param[_name];
			}
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(temp.x);
			getExtraData(subContainer).push(temp.y);
			getExtraData(subContainer).push(temp.x - temp.x / _total / 2);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			if (_animation.needUV)
			{
				uvParamConst = shaderRegisterCache.getFreeVertexConstant();
				uvParamAttrubite = shaderRegisterCache.getFreeVertexAttribute();
				
				var uTotal:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst.regName, uvParamConst.index, "x");
				var uStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst.regName, uvParamConst.index, "y");
				var vStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst.regName, uvParamConst.index, "z");
				
				var cycle:ShaderRegisterElement = new ShaderRegisterElement(uvParamAttrubite.regName, uvParamAttrubite.index, "x");
				var startTime:ShaderRegisterElement = new ShaderRegisterElement(uvParamAttrubite.regName, uvParamAttrubite.index, "y");
				var endThreshold:ShaderRegisterElement = new ShaderRegisterElement(uvParamAttrubite.regName, uvParamAttrubite.index, "z");
				
				
				var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
				var time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
				var vOffset:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
				temp = new ShaderRegisterElement(temp.regName, temp.index, "z");
				var temp2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "w");
				
				
				var u:ShaderRegisterElement = new ShaderRegisterElement(_animation.uvTarget.regName, _animation.uvTarget.index, "x");
				var v:ShaderRegisterElement = new ShaderRegisterElement(_animation.uvTarget.regName, _animation.uvTarget.index, "y");
				
				var code:String = "";
				//scale uv
				code += "mul " + u.toString() + "," + u.toString() + "," + uStep.toString() + "\n";
				if (_needV) code += "mul " + v.toString() + "," + v.toString() + "," + vStep.toString() + "\n";
				
				if (_hasStartTime)
				{
					code += "sub " + time.toString() + "," + _animation.vertexTime.toString() + "," + startTime.toString() + "\n";
					code += "max " + time.toString() + "," + time.toString() + "," + _animation.zeroConst.toString() + "\n";
				}
				else
				{
					code += "mov " + time.toString() +"," + _animation.vertexTime.toString() + "\n";
				}
				if (!_loop)
				{
					code += "min " + time.toString() + "," + time.toString() + "," + endThreshold.toString() + "\n";
				}
				else
				{
					code += "div " + time.toString() + "," + time.toString() + "," + cycle.toString() + "\n";
					code += "frc " + time.toString() + "," + time.toString() + "\n";
					code += "mul " + time.toString() + "," + time.toString() + "," + cycle.toString() + "\n";
				}
				
				code += "div " + temp.toString() + "," + uTotal.toString() + "," + cycle.toString() + "\n";
				code += "mul " + temp.toString() + "," + time.toString() + "," + temp.toString() + "\n";
				if (_needV)
				{
					code += "frc " + temp2.toString() + "," + temp.toString() + "\n";
					code += "sub " + vOffset.toString() + "," + temp.toString() + "," + temp2.toString() + "\n";
					code += "mul " + vOffset.toString() + "," + vOffset.toString() + "," + vStep.toString() + "\n";
					code += "add " + v.toString() + "," + v.toString() + "," + vOffset.toString() + "\n";
				}
				code += stepDiv(temp, temp, uStep, temp2);
				code += "add " + u.toString() + "," + u.toString() + "," + temp.toString() + "\n";
				
				return code;
			}
			else
			{
				return "";
			}
		}
		
		private function stepDiv(destination:ShaderRegisterElement, source1:ShaderRegisterElement, source2:ShaderRegisterElement, temp:ShaderRegisterElement):String
		{
			return "div " + temp.toString() + "," + source1.toString() + "," + source2.toString() + "\n" +
					"frc " + destination.toString() + "," + temp.toString() + "\n"+
					"sub " + temp.toString() + "," + temp.toString() + "," + destination.toString() + "\n" +
					"mul " + destination.toString() + "," + temp.toString() + "," + source2.toString() + "\n";
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable):void
		{
			if (_animation.needUV)
			{
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, uvParamConst.index, _data, 1);
				stage3DProxy.setSimpleVertexBuffer(uvParamAttrubite.index, getExtraBuffer(stage3DProxy, SubContainer(renderable)), Context3DVertexBufferFormat.FLOAT_3, 0);
			}
		}
		
	}

}
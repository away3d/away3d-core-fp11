package a3dparticle.animators.actions.brokenline 
{
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	import flash.display3D.VertexBuffer3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class BrokenLineLocal extends PerParticleAction
	{
		private var _brokenRegisters:Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>();
		
		private var _brokenData:Vector.<Vector3D> = new Vector.<Vector3D>();
		
		private var _brokenCount:uint;
		
		private var _genFun:Function;
		
		private var vertices_vec:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
		private var vertices_buffer:Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>();
		
		/**
		 * 
		 * @param	brokenCount uint.Becasue the number of attribute registers is only 8,the broken should be less 4.
		 * @param	fun Function.It should return a [Vector3D],(Vector3D.x,Vector3D.y,Vector3D.z) is the velocity,Vector3D.w is the during time.
		 */
		public function BrokenLineLocal(brokenCount:uint,fun:Function=null) 
		{
			_brokenCount = brokenCount;
			_genFun = fun;
			dataLenght = 4;
			_name = "BrokenLineLocal";
			for (var i:int; i < _brokenCount; i++)
			{
				vertices_vec[i] = new Vector.<Number>();
				vertices_buffer.push(null);
			}
		}
		
		override public function genOne(param:ParticleParam):void
		{
			if (_genFun != null)
			{
				_brokenData = Vector.<Vector3D>(_genFun(param));
			}
			else
			{
				if (!param[_name]) throw new Error("there is no " + _name + " in param!");
				_brokenData = Vector.<Vector3D>(param[_name]);
			}
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			for(var i:int = 0; i < _brokenCount; i++)
			{
				getExtraDataByIndex(subContainer,i).push(_brokenData[i].x)
				getExtraDataByIndex(subContainer,i).push(_brokenData[i].y)
				getExtraDataByIndex(subContainer,i).push(_brokenData[i].z)
				getExtraDataByIndex(subContainer,i).push(_brokenData[i].w)
			}
		}
		
		public function getExtraDataByIndex(subContainer:SubContainer,index:uint):Vector.<Number>
		{
			if (!subContainer.extraDatas[_name+index])
			{
				subContainer.extraDatas[_name+index] = new Vector.<Number>;
			}
			return subContainer.extraDatas[_name+index];
		}
		
		public function getExtraBufferByIndex(stage3DProxy : Stage3DProxy,subContainer:SubContainer,index:uint) : VertexBuffer3D
		{
			if (!subContainer.extraBuffers[_name+index])
			{
				subContainer.extraBuffers[_name+index] = stage3DProxy._context3D.createVertexBuffer(subContainer.extraDatas[_name+index].length / dataLenght, dataLenght);
				subContainer.extraBuffers[_name+index].uploadFromVector(subContainer.extraDatas[_name+index], 0, subContainer.extraDatas[_name+index].length / dataLenght);
			}
			return subContainer.extraBuffers[_name+index];
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			for (var j:int = 0; j < _brokenCount; j++)
			{
				_brokenRegisters.push(shaderRegisterCache.getFreeVertexAttribute());
			}
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp, 1);
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "xyz");
			var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			shaderRegisterCache.addVertexTempUsages(temp2, 1);
			var time:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "x");
			var max:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "y");
			var sge:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "z");
			var slt:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "w");
			
			
			shaderRegisterCache.removeVertexTempUsage(temp);
			shaderRegisterCache.removeVertexTempUsage(temp2);
			

			var code:String = "";
			code += "mov " + time.toString() + "," + _animation.vertexTime.toString() + "\n";
			for (var i:int = 0; i < _brokenRegisters.length; i++)
			{
				code += "min " + max.toString() + "," + time.toString() + "," + _brokenRegisters[i].toString() + ".w\n";
				code += "max " + max.toString() + "," + max.toString() + "," + _animation.zeroConst.toString() + "\n";
				code += "mul " + distance.toString() + "," + _brokenRegisters[i].toString() + ".xyz," + max.toString() + "\n";
				code += "add " + _animation.offsetTarget.toString() + "," + distance.toString() + "," + _animation.offsetTarget.toString() + "\n";
				if (_animation.needVelocity)
				{
					code += "slt " + slt.toString() + "," + _animation.zeroConst.toString() + "," + time.toString() + "\n";
				}
				code += "sub " + time.toString() + "," + time.toString() + "," + _brokenRegisters[i].toString() + ".w\n";
				if (_animation.needVelocity)
				{
					code += "sge " + sge.toString() + "," + _animation.zeroConst.toString() + "," + time.toString() + "\n";
					code += "mul " + sge.toString() + "," + sge.toString() + "," + slt.toString() + "\n";
					code += "mul " + distance.toString() + "," + sge.toString() + "," + _brokenRegisters[i].toString() + ".xyz\n";
					code += "add " + _animation.velocityTarget.toString() + "," + _animation.velocityTarget.toString() + "," + distance.toString() + "\n";
				}
			}

			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			for (var i:int = 0; i < _brokenCount; i++)
			{
				stage3DProxy.setSimpleVertexBuffer(_brokenRegisters[i].index, getExtraBufferByIndex(stage3DProxy, SubContainer(renderable), i), Context3DVertexBufferFormat.FLOAT_4, 0);
			}
		}
		
	}

}
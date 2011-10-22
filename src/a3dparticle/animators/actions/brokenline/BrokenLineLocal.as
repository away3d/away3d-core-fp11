package a3dparticle.animators.actions.brokenline 
{
	import a3dparticle.animators.actions.PerParticleAction;
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
		public function BrokenLineLocal(brokenCount:uint,fun:Function) 
		{
			_brokenCount = brokenCount;
			_genFun = fun;
			for (var i:int; i < _brokenCount; i++)
			{
				vertices_vec[i] = new Vector.<Number>();
				vertices_buffer.push(null);
			}
		}
		
		override public function genOne(index:uint):void
		{
			_brokenData = Vector.<Vector3D>(_genFun(index));
		}
		
		override public function distributeOne(index:int, verticeIndex:uint):void
		{
			for(var i:int = 0; i < _brokenCount; i++)
			{
				vertices_vec[i].push(_brokenData[i].x)
				vertices_vec[i].push(_brokenData[i].y)
				vertices_vec[i].push(_brokenData[i].z)
				vertices_vec[i].push(_brokenData[i].w)
			}
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
				code += "add " + _animation.offestTarget.toString() + "," + distance.toString() + "," + _animation.offestTarget.toString() + "\n";
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
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			for (var i:int = 0; i < _brokenCount; i++)
			{
				if (!vertices_buffer[i])
				{
					vertices_buffer[i]= stage3DProxy._context3D.createVertexBuffer(vertices_vec[i].length/4,4);
					vertices_buffer[i].uploadFromVector(vertices_vec[i], 0, vertices_vec[i].length/4);
				}
				stage3DProxy.setSimpleVertexBuffer(_brokenRegisters[i].index, vertices_buffer[i], Context3DVertexBufferFormat.FLOAT_4);
			}
		}
		
	}

}
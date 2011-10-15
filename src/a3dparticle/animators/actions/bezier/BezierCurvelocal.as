package a3dparticle.animators.actions.bezier 
{
	import a3dparticle.animators.actions.PerParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * Bezier formula : P(t)=2t*(1-t)*P1+t*t*P2
	 * @author ...
	 */
	public class BezierCurvelocal extends PerParticleAction
	{
		private var p1Attribute:ShaderRegisterElement;
		private var p2Attribute:ShaderRegisterElement;
		
		private var _fun:Function;
		
		private var _p1:Vector3D;
		private var _p2:Vector3D;
		
		private var _vertices2:Vector.<Number> = new Vector.<Number>();
		private var _vertexBuffer2:VertexBuffer3D;
		/**
		 * 
		 * @param	fun Function.The function return a [p1:Vector3D,p2:Vector3D].
		 */
		public function BezierCurvelocal(fun:Function) 
		{
			dataLenght = 3;
			_fun = fun;
		}
		
		override public function genOne(index:uint):void
		{
			var temp:Array = _fun(index);
			_p1 = temp[0];
			_p2 = temp[1];
		}
		
		override public function distributeOne(index:int, verticeIndex:uint):void
		{
			_vertices.push(_p1.x);
			_vertices.push(_p1.y);
			_vertices.push(_p1.z);
			_vertices2.push(_p2.x);
			_vertices2.push(_p2.y);
			_vertices2.push(_p2.z);
		}
		
		private function getVertexBuffer2(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			if (!_vertexBuffer2) {
				_vertexBuffer2 = stage3DProxy._context3D.createVertexBuffer(_vertices2.length/dataLenght,dataLenght);
				_vertexBuffer2.uploadFromVector(_vertices2, 0, _vertices2.length/dataLenght);
			}
			return _vertexBuffer2;
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			p1Attribute = shaderRegisterCache.getFreeVertexAttribute();
			p2Attribute = shaderRegisterCache.getFreeVertexAttribute();
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var rev_time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var time_2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var time_temp:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			shaderRegisterCache.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "xyz");
			shaderRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "sub " + rev_time.toString() + "," + _animation.OneConst.toString() + "," + _animation.vertexLife.toString() + "\n";
			code += "mul " + time_2.toString() + "," + _animation.vertexLife.toString() + "," + _animation.vertexLife.toString() + "\n";
			
			code += "mul " + time_temp.toString() + "," + _animation.vertexLife.toString() +"," + rev_time.toString() + "\n";
			code += "mul " + time_temp.toString() + "," + time_temp.toString() +"," + _animation.TwoConst.toString() + "\n";
			code += "mul " + distance.toString() + "," + time_temp.toString() +"," + p1Attribute.toString() + "\n";
			code += "add " + _animation.offestTarget.toString() +".xyz," + distance.toString() + "," + _animation.offestTarget.toString() + ".xyz\n";
			code += "mul " + distance.toString() + "," + time_2.toString() +"," + p2Attribute.toString() + "\n";
			code += "add " + _animation.offestTarget.toString() +".xyz," + distance.toString() + "," + _animation.offestTarget.toString() + ".xyz\n";
			
			if (_animation.needVelocity)
			{	
				code += "mul " + time_2.toString() + "," + _animation.vertexLife.toString() + "," + _animation.TwoConst.toString() + "\n";
				code += "sub " + time_temp.toString() + "," + _animation.OneConst.toString() + "," + time_2.toString() + "\n";
				code += "mul " + time_temp.toString() + "," + _animation.TwoConst.toString() + "," + time_temp.toString() + "\n";
				code += "mul " + distance.toString() + "," + p1Attribute.toString() + "," + time_temp.toString() + "\n";
				code += "add " + _animation.velocityTarget.toString() + ".xyz," + distance.toString() + "," + _animation.velocityTarget.toString() + ".xyz\n";
				code += "mul " + distance.toString() + "," + p2Attribute.toString() + "," + time_2.toString() + "\n";
				code += "add " + _animation.velocityTarget.toString() + ".xyz," + distance.toString() + "," + _animation.velocityTarget.toString() + ".xyz\n";
			}
			
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			stage3DProxy.setSimpleVertexBuffer(p1Attribute.index, getVertexBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3);
			stage3DProxy.setSimpleVertexBuffer(p2Attribute.index, getVertexBuffer2(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3);
		}
	}

}
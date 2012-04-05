package a3dparticle.animators.actions.uv
{
	import a3dparticle.animators.actions.AllParticleAction;
	import a3dparticle.animators.ParticleAnimation;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3DProgramType;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author liaocheng
	 */
	public class UVLinearEaseGlobal extends AllParticleAction
	{
		public static const U_AXIS:int = 0;
		public static const V_AXIS:int = 1;
		
		private var uvParamConst:ShaderRegisterElement;		
		private var _data:Vector.<Number>;
		
		private var _isScale:Boolean;
		private var _axis:int;

		public function UVLinearEaseGlobal(cycle:Number,scale:Number=1, axis:int=U_AXIS)
		{
			priority = ParticleAnimation.POST_PRIORITY + 5;
			
			if (scale != 1)_isScale = true;
			_axis = axis;
			_data = Vector.<Number>([1 / cycle, scale, 0, 0]);
		}
		
		override public function set animation(value:ParticleAnimation):void
		{
			super.animation = value;
			value.hasUVAction = true;
		}
		
		
		override public function getAGALVertexCode(pass:MaterialPassBase):String
		{
			if (_animation.needUV)
			{
				uvParamConst = shaderRegisterCache.getFreeVertexConstant();
				
				var target:ShaderRegisterElement;
				if (_axis == U_AXIS) target = new ShaderRegisterElement(_animation.uvTarget.regName, _animation.uvTarget.index, "x");
				else target = new ShaderRegisterElement(_animation.uvTarget.regName, _animation.uvTarget.index, "y");
				
				var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexSingleTemp();
				
				var code:String = "";
				
				if (_isScale) code += "mul " + target.toString() + "," + target.toString() + "," + uvParamConst.toString() + ".y\n";
				code += "mul " + temp.toString() + "," + _animation.vertexTime.toString() + "," + uvParamConst.toString() + ".x\n";
				code += "add " + target.toString() + "," + target.toString() + "," + temp.toString() + "\n";
				
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
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, uvParamConst.index, _data);
			}
		}
	
	}

}
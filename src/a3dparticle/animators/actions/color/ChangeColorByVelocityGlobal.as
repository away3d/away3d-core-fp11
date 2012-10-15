package a3dparticle.animators.actions.color 
{
	import a3dparticle.animators.actions.AllParticleAction;
	import a3dparticle.animators.ParticleAnimation;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.ColorTransform;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class ChangeColorByVelocityGlobal extends AllParticleAction
	{
		private var _deltaColor:ColorTransform;
		
		private var velFactor:ShaderRegisterElement;
		private var deltaMultiplierConst:ShaderRegisterElement;
		private var deltaOffsetConst:ShaderRegisterElement;
		
		private var _hasMult:Boolean;
		private var _hasOffset:Boolean;
		
		private var deltaMultiplier:Vector.<Number>;
		private var deltaOffset:Vector.<Number>;
		
		private var _multFactor:Number;
		private var _offsetFactor:Number;
		
		public function ChangeColorByVelocityGlobal(deltaColor:ColorTransform,multFactor:Number=0,offsetFactor:Number=0) 
		{
			priority = 2;
			_deltaColor = deltaColor;
			this._multFactor = multFactor;
			this._offsetFactor = offsetFactor;
			if (deltaColor.alphaMultiplier != 0 || deltaColor.blueMultiplier != 0 || deltaColor.greenMultiplier != 0 || deltaColor.redMultiplier != 0)
				if (multFactor != 0)_hasMult = true;
			if (deltaColor.alphaOffset != 0 || deltaColor.blueOffset != 0 || deltaColor.greenOffset != 0 || deltaColor.redOffset != 0 )
				if (offsetFactor != 0)_hasOffset = true;
			
			deltaMultiplier = Vector.<Number>([_deltaColor.redMultiplier , _deltaColor.greenMultiplier , _deltaColor.blueMultiplier , _deltaColor.alphaMultiplier]);
			deltaOffset = Vector.<Number>([_deltaColor.redOffset / 256, _deltaColor.greenOffset / 256, _deltaColor.blueOffset / 256, _deltaColor.alphaOffset / 256]);
		}
		
		override public function set animation(value:ParticleAnimation):void
		{
			value.needVelocity = true;
			value.needVelocityInFragment = true;
			super.animation = value;
		}
		
		override public function getAGALFragmentCode(pass : MaterialPassBase) : String
		{
			velFactor = shaderRegisterCache.getFreeFragmentConstant();
			var multFactor:ShaderRegisterElement = new ShaderRegisterElement(velFactor.regName, velFactor.index, "x");
			var offsetFactor:ShaderRegisterElement = new ShaderRegisterElement(velFactor.regName, velFactor.index, "y");
			
			if (_hasMult)
			{
				deltaMultiplierConst = shaderRegisterCache.getFreeFragmentConstant();
			}
			if (_hasOffset)
			{
				deltaOffsetConst = shaderRegisterCache.getFreeFragmentConstant();
			}
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeFragmentVectorTemp();
			
			var code:String = "";
			
			if (_hasMult)
			{
				code += "mul " + temp.toString() + "," + deltaMultiplierConst.toString() + "," +  _animation.fragmentVelocity.toString() + "\n";
				code += "mul " + temp.toString() + "," + temp.toString() + "," +  multFactor.toString() + "\n";
				code += "add " + temp.toString() + "," + temp.toString() + "," + _animation.fragmentOneConst.toString() + "\n";
				code += "mul " + _animation.colorTarget.toString() +"," + temp.toString() + "," + _animation.colorTarget.toString() + "\n";
			}
			if (_hasOffset)
			{
				code += "mul " + temp.toString() + "," + deltaOffsetConst.toString() +"," + _animation.fragmentVelocity.toString() + "\n";
				code += "mul " + temp.toString() + "," + temp.toString() +"," + offsetFactor.toString() + "\n";
				code += "add " + _animation.colorTarget.toString() +"," +temp.toString() + "," + _animation.colorTarget.toString() + "\n";
			}
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			
			var context : Context3D = stage3DProxy._context3D;
			if (_hasMult)
			{
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, deltaMultiplierConst.index, deltaMultiplier);
			}
			if (_hasOffset)
			{
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, deltaOffsetConst.index, deltaOffset);
			}
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, velFactor.index,  Vector.<Number>([_multFactor, _offsetFactor, 0, 0]));
		}
		
	}

}
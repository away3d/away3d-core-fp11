package a3dparticle.animators.actions.color 
{
	import a3dparticle.animators.actions.AllParticleAction;
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
	public class ChangeColorByLifeGlobal extends AllParticleAction
	{
		private var _startColor:ColorTransform;
		private var _endColor:ColorTransform;
		
		private var startMultiplierConst:ShaderRegisterElement;
		private var deltaMultiplierConst:ShaderRegisterElement;
		private var startOffsetConst:ShaderRegisterElement;
		private var deltaOffsetConst:ShaderRegisterElement;
		
		private var _hasMult:Boolean;
		private var _hasOffset:Boolean;
		
		private var startMultiplier:Vector.<Number>;
		private var deltaMultiplier:Vector.<Number>;
		private var startOffset:Vector.<Number>;
		private var deltaOffset:Vector.<Number>;
		
		public function ChangeColorByLifeGlobal(startColor:ColorTransform,endColor:ColorTransform) 
		{
			_startColor = startColor;
			_endColor = endColor;
			if (_startColor.alphaMultiplier != 1 || _startColor.blueMultiplier != 1 || _startColor.greenMultiplier != 1 || _startColor.redMultiplier != 1 ||
				_endColor.alphaMultiplier != 1 || _endColor.blueMultiplier != 1 || _endColor.greenMultiplier != 1 || _endColor.redMultiplier != 1)
				_hasMult = true;
			if (_startColor.alphaOffset != 0 || _startColor.blueOffset != 0 || _startColor.greenOffset != 0 || _startColor.redOffset != 0 ||
				_endColor.alphaOffset != 0 || _endColor.blueOffset != 0 || _endColor.greenOffset != 0 || _endColor.redOffset != 0)
				_hasOffset = true;
			
			startMultiplier = Vector.<Number>([_startColor.redMultiplier , _startColor.greenMultiplier , _startColor.blueMultiplier , _startColor.alphaMultiplier ]);
			deltaMultiplier = Vector.<Number>([(_endColor.redMultiplier - _startColor.redMultiplier) , (_endColor.greenMultiplier - _startColor.greenMultiplier) , (_endColor.blueMultiplier - _startColor.blueMultiplier) , (_endColor.alphaMultiplier - _startColor.alphaMultiplier)]);
			startOffset = Vector.<Number>([_startColor.redOffset / 256, _startColor.greenOffset / 256, _startColor.blueOffset / 256, _startColor.alphaOffset / 256]);
			deltaOffset = Vector.<Number>([(_endColor.greenOffset - _startColor.redOffset) / 256, (_endColor.greenOffset - _startColor.greenOffset) / 256, (_endColor.blueOffset - _startColor.blueOffset ) / 256, (_endColor.alphaOffset - _startColor.alphaOffset) / 256]);
			
		}
		
		override public function getAGALFragmentCode(pass : MaterialPassBase) : String
		{
			if (_hasMult)
			{
				startMultiplierConst = shaderRegisterCache.getFreeFragmentConstant();
				deltaMultiplierConst = shaderRegisterCache.getFreeFragmentConstant();
			}
			if (_hasOffset)
			{
				startOffsetConst = shaderRegisterCache.getFreeFragmentConstant();
				deltaOffsetConst = shaderRegisterCache.getFreeFragmentConstant();
			}
			
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeFragmentVectorTemp();
			
			var code:String = "";
			
			if (_hasMult)
			{
				code += "mul " + temp.toString() + "," + deltaMultiplierConst.toString() + "," +  _animation.fragmentLife.toString()+ "\n";
				code += "add " + temp.toString() + "," + temp.toString() + "," + startMultiplierConst.toString() + "\n";
				code += "mul " + _animation.colorTarget.toString() +"," + temp.toString() + "," + _animation.colorTarget.toString() + "\n";
			}
			if (_hasOffset)
			{
				code += "mul " + temp.toString() + "," + _animation.fragmentLife.toString() +"," + deltaOffsetConst.toString() + "\n";
				code += "add " + temp.toString() + "," + temp.toString() +"," + startOffsetConst.toString() + "\n";
				code += "add " + _animation.colorTarget.toString() +"," +temp.toString() + "," + _animation.colorTarget.toString() + "\n";
			}
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			
			var context : Context3D = stage3DProxy._context3D;
			if (_hasMult)
			{
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, startMultiplierConst.index, startMultiplier);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, deltaMultiplierConst.index, deltaMultiplier);
			}
			if (_hasOffset)
			{
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, startOffsetConst.index, startOffset);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, deltaOffsetConst.index, deltaOffset);
			}
			
		}
		
	}

}
package a3dparticle.animators.actions.color 
{
	import a3dparticle.animators.actions.PerParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.ColorTransform;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class RandomColorLocal extends PerParticleAction
	{
		private var _colorFun:Function;
		
		private var _tempColor:ColorTransform;
		
		private var _hasMult:Boolean;
		private var _hasOffest:Boolean;
		
		private var multiplierAtt:ShaderRegisterElement;
		private var multiplierVary:ShaderRegisterElement;
		private var offsetAtt:ShaderRegisterElement;
		private var offsetVary:ShaderRegisterElement;
		
		
		public function RandomColorLocal(fun:Function,hasMult:Boolean=true,hasOffest:Boolean=true) 
		{
			_colorFun = fun;
			_hasMult = hasMult;
			_hasOffest = hasOffest;
			
			if (_hasMult && _hasOffest) dataLenght = 8;
			if (_hasMult && !_hasOffest) dataLenght = 4;
			if (!_hasMult && _hasOffest) dataLenght = 4;
			if (!_hasMult && !_hasOffest) throw(new Error("no change!"));
		}
		
		override public function genOne(index:uint):void
		{
			_tempColor = _colorFun(index);
		}
		
		override public function distributeOne(index:int, verticeIndex:uint):void
		{
			if (_hasMult)
			{
				_vertices.push(_tempColor.redMultiplier);
				_vertices.push(_tempColor.greenMultiplier);
				_vertices.push(_tempColor.blueMultiplier);
				_vertices.push(_tempColor.alphaMultiplier);
			}
			if (_hasOffest)
			{
				_vertices.push(_tempColor.redOffset);
				_vertices.push(_tempColor.greenOffset);
				_vertices.push(_tempColor.blueOffset);
				_vertices.push(_tempColor.alphaOffset);
			}
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var code:String = "";
			
			if (_hasMult)
			{
				multiplierAtt = shaderRegisterCache.getFreeVertexAttribute();
				multiplierVary = shaderRegisterCache.getFreeVarying();
				code += "mov " + multiplierVary.toString() + "," + multiplierAtt.toString() + "\n";
			}
			if (_hasOffest)
			{
				offsetAtt = shaderRegisterCache.getFreeVertexAttribute();
				offsetVary = shaderRegisterCache.getFreeVarying();
				code += "mov " + offsetVary.toString() + "," + offsetAtt.toString() + "\n";
			}
			return code;
		}
		
		override public function getAGALFragmentCode(pass : MaterialPassBase) : String
		{
			
			var code:String = "";
			
			if (_hasMult)
			{
				code += "mul " + _animation.colorTarget.toString() +"," + multiplierVary.toString() + "," + _animation.colorTarget.toString() + "\n";
			}
			if (_hasOffest)
			{
				code += "add " + _animation.colorTarget.toString() +"," +offsetVary.toString() + "," + _animation.colorTarget.toString() + "\n";
			}
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			if (_hasMult)
			{
				context.setVertexBufferAt(multiplierAtt.index, getVertexBuffer(stage3DProxy), 0, Context3DVertexBufferFormat.FLOAT_4);
				if (_hasOffest)
					context.setVertexBufferAt(offsetAtt.index, getVertexBuffer(stage3DProxy), 4, Context3DVertexBufferFormat.FLOAT_4);
			}
			else
			{
				context.setVertexBufferAt(offsetAtt.index, getVertexBuffer(stage3DProxy), 0, Context3DVertexBufferFormat.FLOAT_4);
			}
		}
		
	}

}
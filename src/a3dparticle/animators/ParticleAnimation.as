package a3dparticle.animators 
{
	import a3dparticle.animators.actions.ActionBase;
	import a3dparticle.animators.actions.AllParticleAction;
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.animators.actions.TimeAction;
	import a3dparticle.materials.SimpleParticlePass;
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.arcane;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleAnimation extends AnimationBase
	{
		
		public var hasGen:Boolean;
		
		private var _AGALVertexCode:String;
		private var _AGALFragmentCode:String;
		
		public var shaderRegisterCache:ShaderRegisterCache;
		
		
		private var _perParticleActions:Vector.<ActionBase>=new Vector.<ActionBase>();
		private var _allParticleActions:Vector.<ActionBase>=new Vector.<ActionBase>();
		
		//dependent action
		private var timeAction:TimeAction;
		
		
		
		//vertex
		public var timeConst:ShaderRegisterElement;
		public var positionAttribute:ShaderRegisterElement;
		public var uvAttribute:ShaderRegisterElement;
		public var postionTarget:ShaderRegisterElement;
		public var vertexTime:ShaderRegisterElement;
		public var vertexLife:ShaderRegisterElement;
		public var zeroConst:ShaderRegisterElement;
		public var piConst:ShaderRegisterElement;
		//vary
		public var fragmentTime:ShaderRegisterElement;
		public var fragmentLife:ShaderRegisterElement;
		//fragment
		public var colorTarget : ShaderRegisterElement;
		public var colorDefalut : ShaderRegisterElement;
		public var textSample : ShaderRegisterElement;
		public var uvVar:ShaderRegisterElement;
		public var fragmentZeroConst:ShaderRegisterElement;
		public var fragmentPiConst:ShaderRegisterElement;
		
		
		public function ParticleAnimation()
		{
			super();
			
			timeAction = new TimeAction();
			timeAction.animation = this;
			addPerParticleAction(timeAction);
			
			
			
			
		}
		
		public function set startTimeFun(fun:Function):void
		{
			timeAction.startTimeFun = fun;
		}
		
		public function set endTimeFun(fun:Function):void
		{
			timeAction.endTimeFun = fun;
		}
		
		public function set loop(value:Boolean):void
		{
			timeAction.loop = value;
		}
		
		public function addPerParticleAction(action:PerParticleAction):void
		{
			_perParticleActions.push(action);
			action.animation = this;
		}
		public function addAllParticleAction(action:AllParticleAction):void
		{
			_allParticleActions.push(action);
			action.animation = this;
		}
		
		public function genOne(index:uint):void
		{
			for each (var action:PerParticleAction in _perParticleActions)
			{
				action.genOne(index);
			}
		}
		
		public function distributeOne(index:uint, verticeIndex:uint):void
		{
			for each (var action:PerParticleAction in _perParticleActions)
			{
				action.distributeOne(index,verticeIndex);
			}
		}
		
		public function get zeroConstIndex():int
		{
			return zeroConst.index;
		}
		public function get piConstIndex():int
		{
			return piConst.index;
		}
		
		public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			var action:ActionBase;
			for each(action in _perParticleActions)
			{
				action.setRenderState(stage3DProxy,pass,renderable);
			}
			for each(action in _allParticleActions)
			{
				action.setRenderState(stage3DProxy,pass,renderable);
			}
		}
		
		private function resrt(simpleParticlePass:SimpleParticlePass):void
		{
			shaderRegisterCache = new ShaderRegisterCache();
			shaderRegisterCache.vertexConstantOffset = 4;
			shaderRegisterCache.vertexAttributesOffset = 1;
			shaderRegisterCache.reset();
			
			//because of projectionVertexCode,I set these value directly
			postionTarget = new ShaderRegisterElement("vt", 0);
			shaderRegisterCache.addVertexTempUsages(postionTarget, 1);
			positionAttribute = new ShaderRegisterElement("va", 0);
			uvAttribute = shaderRegisterCache.getFreeVertexAttribute();
			
			zeroConst = shaderRegisterCache.getFreeVertexConstant();
			piConst = shaderRegisterCache.getFreeVertexConstant();
			
			
			colorTarget = shaderRegisterCache.getFreeFragmentVectorTemp();
			shaderRegisterCache.addFragmentTempUsages(postionTarget, 1);
			uvVar = shaderRegisterCache.getFreeVarying();
			textSample = shaderRegisterCache.getFreeTextureReg();
			colorDefalut = shaderRegisterCache.getFreeFragmentConstant();
			fragmentZeroConst = shaderRegisterCache.getFreeFragmentConstant();
			fragmentPiConst = shaderRegisterCache.getFreeFragmentConstant();

		}
		/**
		 * @inheritDoc
		 */
		override arcane function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var simpleParticlePass:SimpleParticlePass = SimpleParticlePass(pass);
			resrt(simpleParticlePass);
			
			_AGALVertexCode = "";
			if (simpleParticlePass._texture)
			{
				_AGALVertexCode += "mov " + uvVar.toString() + "," + uvAttribute.toString() + "\n";
			}
			
			_AGALVertexCode += "mov " + postionTarget.toString() + "," + positionAttribute.toString() + "\n";
			var action:ActionBase;
			for each(action in _perParticleActions)
			{
				_AGALVertexCode += action.getAGALVertexCode(pass);
			}
			for each(action in _allParticleActions)
			{
				_AGALVertexCode += action.getAGALVertexCode(pass);
			}

			return _AGALVertexCode;
		}		
		
		arcane function getAGALFragmentCode(pass : MaterialPassBase) : String
		{
			_AGALFragmentCode = ""; 
			var action:ActionBase;
			for each(action in _perParticleActions)
			{
				_AGALFragmentCode += action.getAGALFragmentCode(pass);
			}
			for each(action in _allParticleActions)
			{
				_AGALFragmentCode += action.getAGALFragmentCode(pass);
			}
			return _AGALFragmentCode;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function deactivate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			//
			var i:int;0
			for (i = pass.numUsedStreams; i < shaderRegisterCache.numUsedStreams; i++)
			{
				stage3DProxy.setSimpleVertexBuffer(i, null);
			}
			super.deactivate(stage3DProxy , pass );
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function createAnimationState() : AnimationStateBase
		{
			return null;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function equals(animation : AnimationBase) : Boolean
		{
			return animation == this;
		}
		
	}

}
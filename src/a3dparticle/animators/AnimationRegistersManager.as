package a3dparticle.animators
{
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Cheng Liao
	 */
	public class AnimationRegistersManager
	{
		//vertex
		public var timeConst:ShaderRegisterElement;
		public var positionAttribute:ShaderRegisterElement;
		public var uvAttribute:ShaderRegisterElement;
		public var offsetTarget:ShaderRegisterElement;
		public var scaleAndRotateTarget:ShaderRegisterElement
		public var velocityTarget:ShaderRegisterElement;
		public var vertexTime:ShaderRegisterElement;
		public var vertexLife:ShaderRegisterElement;
		public var vertexZeroConst:ShaderRegisterElement;
		public var vertexOneConst:ShaderRegisterElement;
		public var vertexTwoConst:ShaderRegisterElement;
		public var cameraPosConst:ShaderRegisterElement;
		public var uvTarget:ShaderRegisterElement;
		//vary
		public var varyTime:ShaderRegisterElement;
		public var fragmentTime:ShaderRegisterElement;
		public var fragmentLife:ShaderRegisterElement;
		public var fragmentVelocity:ShaderRegisterElement;
		//fragment
		public var colorTarget:ShaderRegisterElement;
		public var textSample:ShaderRegisterElement;
		public var uvVar:ShaderRegisterElement;
		public var fragmentZeroConst:ShaderRegisterElement;
		public var fragmentOneConst:ShaderRegisterElement;
		public var fragmentMinConst:ShaderRegisterElement;
		public var fadeFactorConst:ShaderRegisterElement;
		
		public var shaderRegisterCache:ShaderRegisterCache = new ShaderRegisterCache();
		
		
		
		public var needCameraPosition:Boolean;
		public var needUV:Boolean;
		public var needVelocity:Boolean;
		public var needFragmentAnimation:Boolean;
		
		private var indexDictionary:Dictionary = new Dictionary(true);
		
		
		public function AnimationRegistersManager()
		{
			
		}
		
		public function reset():void
		{
			//because of projectionVertexCode,I set these value directly
			scaleAndRotateTarget = new ShaderRegisterElement("vt", 0);
			shaderRegisterCache.addVertexTempUsages(scaleAndRotateTarget, 1);
			scaleAndRotateTarget = new ShaderRegisterElement(scaleAndRotateTarget.regName, scaleAndRotateTarget.index, "xyz");//only use xyz, w is used as vertexLife
			positionAttribute = new ShaderRegisterElement("va", 0);
			//allot const register
			timeConst = shaderRegisterCache.getFreeVertexConstant();
			vertexZeroConst = shaderRegisterCache.getFreeVertexConstant();
			vertexZeroConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, "x");
			vertexOneConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, "y");
			vertexTwoConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, "z");
			if (needCameraPosition)
				cameraPosConst = shaderRegisterCache.getFreeVertexConstant();
			
			fragmentZeroConst = shaderRegisterCache.getFreeFragmentConstant();
			fragmentZeroConst = new ShaderRegisterElement(fragmentZeroConst.regName, fragmentZeroConst.index, "x");
			fragmentOneConst = new ShaderRegisterElement(fragmentZeroConst.regName, fragmentZeroConst.index, "y");
			fragmentMinConst = new ShaderRegisterElement(fragmentZeroConst.regName, fragmentZeroConst.index, "z");
			//allot attribute register
			if (needUV)
			{
				uvAttribute = shaderRegisterCache.getFreeVertexAttribute();
			}
			//allot temp register
			var tempTime:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			offsetTarget = new ShaderRegisterElement(tempTime.regName, tempTime.index, "xyz");
			//uv action is processed after normal actions,so use offsetTarget as uvTarget
			uvTarget = new ShaderRegisterElement(offsetTarget.regName, offsetTarget.index, "xy");
			
			shaderRegisterCache.addVertexTempUsages(tempTime, 1);
			vertexTime = new ShaderRegisterElement(tempTime.regName, tempTime.index, "w");
			vertexLife = new ShaderRegisterElement(scaleAndRotateTarget.regName, scaleAndRotateTarget.index, "w");
			if (needVelocity)
			{
				velocityTarget = shaderRegisterCache.getFreeVertexVectorTemp();
				shaderRegisterCache.addVertexTempUsages(velocityTarget, 1);
			}
			
			//TOdo:
			colorTarget = shaderRegisterCache.getFreeFragmentVectorTemp();
			shaderRegisterCache.addFragmentTempUsages(colorTarget,1);
			
			//allot vary register
			varyTime = shaderRegisterCache.getFreeVarying();
			fragmentTime = new ShaderRegisterElement(varyTime.regName, varyTime.index, "x");
			fragmentLife = new ShaderRegisterElement(varyTime.regName, varyTime.index, "y");
			fragmentVelocity = new ShaderRegisterElement(varyTime.regName, varyTime.index, "z");
			if (needUV)
			{
				uvVar = shaderRegisterCache.getFreeVarying();
			}
		}
		
		public function setRegisterIndex(action:Object, name:String, index:int):void
		{
			var t:Object = indexDictionary[action] ||= new Object;
			t[name] = index;
		}
		
		public function getRegisterIndex(action:Object, name:String):int
		{
			return indexDictionary[action][name];
		}
		
		public  function getRegisterFromString(code:String):ShaderRegisterElement
		{
			var temp:Array = code.split(/(\d+)/);
			return new ShaderRegisterElement(temp[0], temp[1]);
		}
		
	}

}
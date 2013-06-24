package away3d.stereo.methods
{
	import away3d.arcane;
	import away3d.core.managers.RTTBufferManager;
	import away3d.core.managers.Stage3DProxy;
	
	import flash.display3D.Context3DProgramType;
	
	use namespace arcane;
	
	public class InterleavedStereoRenderMethod extends StereoRenderMethodBase
	{
		private var _shaderData:Vector.<Number>;
		
		public function InterleavedStereoRenderMethod()
		{
			super();
			
			_shaderData = new <Number>[1, 1, 1, 1];
		}
		
		override public function activate(stage3DProxy:Stage3DProxy):void
		{
			if (_textureSizeInvalid) {
				var minV:Number;
				var rttManager:RTTBufferManager;
				
				rttManager = RTTBufferManager.getInstance(stage3DProxy);
				_textureSizeInvalid = false;
				
				minV = rttManager.renderToTextureRect.bottom/rttManager.textureHeight;
				
				_shaderData[0] = 2;
				_shaderData[1] = rttManager.renderToTextureRect.height;
				_shaderData[2] = 1;
				_shaderData[3] = .5;
			}
			
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _shaderData);
		}
		
		override public function deactivate(stage3DProxy:Stage3DProxy):void
		{
			stage3DProxy._context3D.setTextureAt(2, null);
		}
		
		override public function getFragmentCode():String
		{
			return "tex ft0, v1, fs0 <2d,linear,nomip>\n" +
				"tex ft1, v1, fs1 <2d,linear,nomip>\n" +
				"add ft2, v0.y, fc0.z\n" +
				"div ft2, ft2, fc0.x\n" +
				"mul ft2, ft2, fc0.y\n" +
				"div ft3, ft2, fc0.x\n" +
				"frc ft3, ft3\n" +
				"slt ft4, ft3, fc0.w\n" +
				"sge ft5, ft3, fc0.w\n" +
				"mul ft6, ft0, ft4\n" +
				"mul ft7, ft1, ft5\n" +
				"add oc, ft7, ft6";
		}
	}
}

package away3d.stereo.methods
{
	import away3d.core.managers.Stage3DProxy;
	
	import flash.display3D.Context3DProgramType;

	public class AnaglyphStereoRenderMethod extends StereoRenderMethodBase
	{
		private var _filterData : Vector.<Number>;
		
		public function AnaglyphStereoRenderMethod()
		{
			super();
			
			_filterData = new <Number>[ 
				1.0, 0.0, 0.0, 1.0,
				0.0, 1.0, 1.0, 1.0,	
				1.0, 1.0, 1.0, 1.0];
		}
		
		
		override public function activate(stage3DProxy:Stage3DProxy):void
		{
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _filterData, 3);
		}
		
		
		override public function getFragmentCode():String
		{
			return 	"tex ft0, v1, fs0 <2d,linear,nomip>\n"+
					"tex ft1, v1, fs1 <2d,linear,nomip>\n"+
					"mul ft0, ft0, fc0\n"+
					"sub ft0, fc2, ft0\n"+
					"mul ft1, ft1, fc1\n"+
					"sub ft1, fc2, ft1\n"+
					"mul ft2, ft0, ft1\n"+
					"div ft2, ft2, fc2\n"+
					"sub oc, fc2, ft2";
		}
	}
}
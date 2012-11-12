package away3d.materials.compilation
{
	import away3d.materials.LightSources;
	import away3d.materials.methods.MethodVO;

	public class MethodDependencyCounter
	{
		private var _projectionDependencies : uint;
		private var _normalDependencies : uint;
		private var _viewDirDependencies : uint;
		private var _uvDependencies : uint;
		private var _secondaryUVDependencies : uint;
		private var _globalPosDependencies : uint;
		private var _tangentDependencies : uint;
		private var _usesGlobalPosFragment : Boolean = false;
		private var _numPointLights : uint;
		private var _lightSourceMask : uint;
		// why always true?

		public function MethodDependencyCounter()
		{
		}

		public function reset() : void
		{
			_projectionDependencies = 0;
			_normalDependencies = 0;
			_viewDirDependencies = 0;
			_uvDependencies = 0;
			_secondaryUVDependencies = 0;
			_globalPosDependencies = 0;
			_tangentDependencies = 0;
			_usesGlobalPosFragment = false;
		}

		public function setPositionedLights(numPointLights : uint, lightSourceMask : uint) : void
		{
			_numPointLights = numPointLights;
			_lightSourceMask = lightSourceMask;
		}

		public function includeMethodVO(methodVO : MethodVO) : void
		{
			if (methodVO.needsProjection) ++_projectionDependencies;
			if (methodVO.needsGlobalVertexPos) {
				++_globalPosDependencies;
				if (methodVO.needsGlobalFragmentPos) _usesGlobalPosFragment = true;
			}
			else if (methodVO.needsGlobalFragmentPos) {
				++_globalPosDependencies;
				_usesGlobalPosFragment = true;
			}
			if (methodVO.needsNormals) ++_normalDependencies;
			if (methodVO.needsTangents) ++_tangentDependencies;
			if (methodVO.needsView) ++_viewDirDependencies;
			if (methodVO.needsUV) ++_uvDependencies;
			if (methodVO.needsSecondaryUV) ++_secondaryUVDependencies;
		}

		public function get tangentDependencies() : uint
		{
			return _tangentDependencies;
		}

		public function get usesGlobalPosFragment() : Boolean
		{
			return _usesGlobalPosFragment;
		}

		public function get projectionDependencies() : uint
		{
			return _projectionDependencies;
		}

		public function get normalDependencies() : uint
		{
			return _normalDependencies;
		}

		public function get viewDirDependencies() : uint
		{
			return _viewDirDependencies;
		}

		public function get uvDependencies() : uint
		{
			return _uvDependencies;
		}

		public function get secondaryUVDependencies() : uint
		{
			return _secondaryUVDependencies;
		}

		public function get globalPosDependencies() : uint
		{
			return _globalPosDependencies;
		}

		public function addWorldSpaceDependencies(fragmentLights : Boolean) : void
		{
			if (_viewDirDependencies > 0) ++_globalPosDependencies;

			if (_numPointLights > 0 && (_lightSourceMask & LightSources.LIGHTS)) {
				++_globalPosDependencies;
				if (fragmentLights) _usesGlobalPosFragment = true;
			}
		}
	}
}

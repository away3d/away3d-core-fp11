package away3d.lights
{
	import away3d.arcane;
	import away3d.bounds.BoundingSphere;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.core.base.IRenderable;
	import away3d.core.math.Matrix3DUtils;

	import away3d.materials.ColorMaterial;
	import away3d.materials.MaterialBase;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.AGAL;
	import away3d.materials.utils.ShaderRegisterCache;

	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace arcane;

	/**
	 * PointLight represents an omni-directional light. The light is emitted from a given position in the scene.
	 */
	public class PointLight extends LightBase
	{
		//private static var _pos : Vector3D = new Vector3D();
		protected var _radius : Number = Number.MAX_VALUE;
		protected var _fallOff : Number = Number.MAX_VALUE;
		private var _positionData : Vector.<Number> = Vector.<Number>([0, 0, 0, 1]);
		private var _attenuationData : Vector.<Number>;
		private var _vertexPosReg : ShaderRegisterElement;
		private var _varyingReg : ShaderRegisterElement;
		private var _attenuationIndices : Dictionary;
		private var _attenuationRegister : ShaderRegisterElement;

		/**
		 * Creates a new PointLight object.
		 */
		public function PointLight()
		{
			super();
			_attenuationData = Vector.<Number>([_radius, 1/(_fallOff-_radius), 0, 1]);
			_attenuationIndices = new Dictionary(true);
		}

		/**
		 * The maximum distance of the light's reach.
		 */
		public function get radius() : Number
		{
			return _radius;
		}

		public function set radius(value : Number) : void
		{
			_radius = value;
			if (_radius < 0) _radius = 0;
			else if (_radius > _fallOff) {
				_fallOff = _radius;
				invalidateBounds();
			}

			_attenuationData[0] = _radius;
			_attenuationData[1] = 1/(_fallOff-_radius);
		}

		/**
		 * The fallOff component of the light.
		 */
		public function get fallOff() : Number
		{
			return _fallOff;
		}

		public function set fallOff(value : Number) : void
		{
			_fallOff = value;
			if (_fallOff < 0) _fallOff = 0;
			if (_fallOff < _radius) _radius = _fallOff;
			invalidateBounds();
			_attenuationData[0] = _radius;
			_attenuationData[1] = 1/(_fallOff-_radius);
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateBounds() : void
		{
//			super.updateBounds();
			_bounds.fromExtremes(-_fallOff, -_fallOff, -_fallOff, _fallOff, _fallOff, _fallOff);
			_boundsInvalid = false;
		}


		override protected function updateSceneTransform() : void
		{
			super.updateSceneTransform();
			var pos : Vector3D = scenePosition;

			_positionData[0] = pos.x;
			_positionData[1] = pos.y;
			_positionData[2] = pos.z;
		}

		/**
		 * @inheritDoc
		 */
		override protected function getDefaultBoundingVolume() : BoundingVolumeBase
		{
			return new BoundingSphere();
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getObjectProjectionMatrix(renderable : IRenderable, target : Matrix3D = null) : Matrix3D
		{
			var raw : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var bounds : BoundingVolumeBase = renderable.sourceEntity.bounds;
			var m : Matrix3D = new Matrix3D();

			m.copyFrom(renderable.sceneTransform);
			m.append(_parent.inverseSceneTransform);
// todo: why doesn't this work?
//			m.copyRowTo(3, _pos);
			lookAt(m.position);

			m.copyFrom(renderable.sceneTransform);
			m.append(inverseSceneTransform);
			m.copyRowTo(3, _pos);

			var v1 : Vector3D = m.deltaTransformVector(bounds.min);
			var v2 : Vector3D = m.deltaTransformVector(bounds.max);
			var z : Number = _pos.z;
			var d1 : Number = v1.x*v1.x + v1.y*v1.y + v1.z*v1.z;
			var d2 : Number = v2.x*v2.x + v2.y*v2.y + v2.z*v2.z;
			var d : Number = Math.sqrt(d1 > d2? d1 : d2);
			var zMin : Number, zMax : Number;

			zMin = z - d;
			zMax = z + d;

            raw[uint(5)] = raw[uint(0)] = zMin/d;
			raw[uint(10)] = zMax/(zMax-zMin);
			raw[uint(11)] = 1;
			raw[uint(1)] = raw[uint(2)] = raw[uint(3)] = raw[uint(4)] =
			raw[uint(6)] = raw[uint(7)] = raw[uint(8)] = raw[uint(9)] =
			raw[uint(12)] = raw[uint(13)] = raw[uint(15)] = 0;
			raw[uint(14)] = -zMin*raw[uint(10)];

			target ||= new Matrix3D();
			target.copyRawDataFrom(raw);
			target.prepend(m);

			return target;
		}

		override arcane function get positionBased() : Boolean
		{
			return true;
		}


		arcane override function getVertexCode(regCache : ShaderRegisterCache, globalPositionRegister : ShaderRegisterElement, pass : MaterialPassBase) : String
		{
			_vertexPosReg = regCache.getFreeVertexConstant();
			_varyingReg = regCache.getFreeVarying();
			_shaderConstantIndex = _vertexPosReg.index;

			return "sub "+_varyingReg.toString()+", "+_vertexPosReg.toString()+", "+  globalPositionRegister.toString()+"\n";
		}

		arcane override function getFragmentCode(regCache : ShaderRegisterCache, pass : MaterialPassBase) : String
		{
			_attenuationRegister = regCache.getFreeFragmentConstant();
			// setting this causes the material bug
			_attenuationIndices[pass] = _attenuationRegister.index;
			_fragmentDirReg = _varyingReg;
			return 	"";
		}


		arcane override function getAttenuationCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement, pass : MaterialPassBase) : String
		{
			var code : String = "";

			// w = sqrt(dir . dir) = len(dir)
			code += AGAL.dp3(targetReg+".w", _varyingReg+".xyz", _varyingReg+".xyz");
			code += AGAL.sqrt(targetReg+".w", targetReg+".w");
			// w = d - min
			code += AGAL.sub(targetReg+".w", targetReg+".w", _attenuationRegister+".x");
			// w = (d - min)/(max-min)
			code += AGAL.mul(targetReg+".w", targetReg+".w", _attenuationRegister+".y");
			// w = clamp(w, 0, 1)
			code += AGAL.sat(targetReg+".w", targetReg+".w");
			code += AGAL.sub(targetReg+".w", _attenuationRegister+".w", targetReg+".w");

			return code;
		}

		arcane override function setRenderState(context : Context3D, inputIndex : int, pass : MaterialPassBase) : void
		{
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, inputIndex, _positionData, 1);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _attenuationIndices[pass], _attenuationData, 1);
		}
	}
}
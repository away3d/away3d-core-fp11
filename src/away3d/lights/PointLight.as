package away3d.lights
{
	import away3d.arcane;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.core.math.Box;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.PointLightNode;
	import away3d.core.render.IRenderer;
	import away3d.entities.Camera3D;
	import away3d.entities.IEntity;
	import away3d.lights.shadowmaps.CubeMapShadowMapper;
	import away3d.lights.shadowmaps.ShadowMapperBase;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * PointLight represents an omni-directional light. The light is emitted from a given position in the scene.
	 */
	public class PointLight extends LightBase implements IEntity
	{
		//private static var _pos : Vector3D = new Vector3D();
		arcane var _radius:Number = 90000;
		arcane var _fallOff:Number = 100000;
		arcane var _fallOffFactor:Number;
		
		/**
		 * Creates a new PointLight object.
		 */
		public function PointLight()
		{
			super();

			_isEntity = true;
			_fallOffFactor = 1/(_fallOff*_fallOff - _radius*_radius);
		}
		
		override protected function createShadowMapper():ShadowMapperBase
		{
			return new CubeMapShadowMapper();
		}
		
		override protected function createEntityPartitionNode():EntityNode
		{
			return new PointLightNode(this);
		}
		
		/**
		 * The minimum distance of the light's reach.
		 */
		public function get radius():Number
		{
			return _radius;
		}
		
		public function set radius(value:Number):void
		{
			_radius = value;
			if (_radius < 0)
				_radius = 0;
			else if (_radius > _fallOff) {
				_fallOff = _radius;
				invalidateBounds();
			}
			
			_fallOffFactor = 1/(_fallOff*_fallOff - _radius*_radius);
		}
		
		arcane function fallOffFactor():Number
		{
			return _fallOffFactor;
		}
		
		/**
		 * The maximum distance of the light's reach
		 */
		public function get fallOff():Number
		{
			return _fallOff;
		}
		
		public function set fallOff(value:Number):void
		{
			_fallOff = value;
			if (_fallOff < 0)
				_fallOff = 0;
			if (_fallOff < _radius)
				_radius = _fallOff;
			_fallOffFactor = 1/(_fallOff*_fallOff - _radius*_radius);
			invalidateBounds();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateBounds():void
		{
			//			super.updateBounds();
			//			_bounds.fromExtremes(-_fallOff, -_fallOff, -_fallOff, _fallOff, _fallOff, _fallOff);
			_bounds.fromSphere(new Vector3D(), _fallOff);
			_boundsInvalid = false;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getObjectProjectionMatrix(entity:IEntity, camera:Camera3D, target:Matrix3D = null):Matrix3D
		{
			var raw:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var bounds:BoundingVolumeBase = entity.bounds;
			var m:Matrix3D = new Matrix3D();
			
			// todo: do not use lookAt on Light
			m.copyFrom(entity.getRenderSceneTransform(camera));
			m.append(_parent.inverseSceneTransform);
			lookAt(m.position);
			
			m.copyFrom(entity.getRenderSceneTransform(camera));
			m.append(inverseSceneTransform);

			var box:Box = bounds.aabb;
			var v1:Vector3D = m.deltaTransformVector(new Vector3D(box.left, box.bottom, box.front));
			var v2:Vector3D = m.deltaTransformVector(new Vector3D(box.right, box.top, box.back));

			var d1:Number = v1.x*v1.x + v1.y*v1.y + v1.z*v1.z;
			var d2:Number = v2.x*v2.x + v2.y*v2.y + v2.z*v2.z;
			var d:Number = Math.sqrt(d1 > d2? d1 : d2);
			var zMin:Number;
			var zMax:Number;

			var z:Number = m.rawData[14];
			zMin = z - d;
			zMax = z + d;
			
			raw[uint(5)] = raw[uint(0)] = zMin/d;
			raw[uint(10)] = zMax/(zMax - zMin);
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

		public function collectRenderables(renderer:IRenderer):void
		{
			//nothing to do here
		}
	}
}

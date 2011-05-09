package away3d.primitives
{
	import away3d.primitives.data.Segment;

	import flash.geom.Vector3D;

	/**
	* Class WireFrameGrid generates a grid of lines on a given plane<code>WireFrameGrid</code>
	* @param	subDivision		[optional] uint . Default is 10;
	* @param	gridSize				[optional] uint . Default is 100;
	* @param	color					[optional] uint . Default is 0xFFFFFF;
	* @param	thickness			[optional] Number . Default is 1;
	* @param	plane					[optional] String . Default is PLANE_XZ;
	* @param	worldPlanes		[optional] Boolean . Default is false.
	* If true, class displays the 3 world planes, at 0,0,0. with subDivision, thickness and and gridSize. Overrides color and plane settings.
	*/
		
	public class WireframeSphere extends WireframePrimitiveBase
	{
		private var _segmentsW : uint;
		private var _segmentsH : uint;
		private var _radius : Number;

		public function WireframeSphere(radius : Number = 50, segmentsW : uint = 16, segmentsH : uint = 12, color:uint = 0xFFFFFF, thickness:Number = 1) {
			super(color, thickness);

			_radius = radius;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
		}

		override protected function buildGeometry() : void
		{
			var vertices : Vector.<Number> = new Vector.<Number>();
			var v0 : Vector3D = new Vector3D();
			var v1 : Vector3D = new Vector3D();
			var i : uint, j : uint;
			var numVerts : uint = 0;
			var index : int;

			for (j = 0; j <= _segmentsH; ++j) {
				var horangle : Number = Math.PI * j / _segmentsH;
				var z : Number = -_radius * Math.cos(horangle);
				var ringradius : Number = _radius * Math.sin(horangle);

				for (i = 0; i <= _segmentsW; ++i) {
					var verangle : Number = 2 * Math.PI * i / _segmentsW;
					var x : Number = ringradius * Math.cos(verangle);
					var y : Number = ringradius * Math.sin(verangle);
					vertices[numVerts++] = x;
					vertices[numVerts++] = -z;
					vertices[numVerts++] = y;
				}
			}

			for (j = 1; j <= _segmentsH; ++j) {
				for (i = 1; i <= _segmentsW; ++i) {
					var a : int = ((_segmentsW + 1) * j + i)*3;
					var b : int = ((_segmentsW + 1) * j + i - 1)*3;
					var c : int = ((_segmentsW + 1) * (j - 1) + i - 1)*3;
					var d : int = ((_segmentsW + 1) * (j - 1) + i)*3;

					if (j == _segmentsH) {
						v0.x = vertices[c];
						v0.y = vertices[c+1];
						v0.z = vertices[c+2];
						v1.x = vertices[d];
						v1.y = vertices[d+1];
						v1.z = vertices[d+2];
						updateOrAddSegment(index++, v0, v1);
						v0.x = vertices[a];
						v0.y = vertices[a+1];
						v0.z = vertices[a+2];
						updateOrAddSegment(index++, v0, v1);
					}
					else if (j == 1) {
						v1.x = vertices[b];
						v1.y = vertices[b+1];
						v1.z = vertices[b+2];
						v0.x = vertices[c];
						v0.y = vertices[c+1];
						v0.z = vertices[c+2];
						updateOrAddSegment(index++, v0, v1);
					}
					else {
						v1.x = vertices[b];
						v1.y = vertices[b+1];
						v1.z = vertices[b+2];
						v0.x = vertices[c];
						v0.y = vertices[c+1];
						v0.z = vertices[c+2];
						updateOrAddSegment(index++, v0, v1);
						v1.x = vertices[d];
						v1.y = vertices[d+1];
						v1.z = vertices[d+2];
						updateOrAddSegment(index++, v0, v1);
					}
				}
			}
		}

	}
}

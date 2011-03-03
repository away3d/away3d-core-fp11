package away3d.primitives
{
    import away3d.core.base.SubGeometry;
    import away3d.materials.MaterialBase;

    import flash.display.BitmapData;

    public class HeightMapTerrain extends PrimitiveBase
    {
        private var _segmentsW : uint;
        private var _segmentsH : uint;
        private var _width : Number;
		private var _height : Number;
		private var _depth : Number;
        private var _heightMap : BitmapData;

        public function HeightMapTerrain(material : MaterialBase, heightMap : BitmapData, width : Number = 5000, height : Number = 500, depth : Number = 5000, segmentsW : uint = 50, segmentsH : uint = 50)
        {
            super(material);
            _heightMap = heightMap;
            _segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_width = depth;
            _height = height;
			_depth = depth;
        }

        /**
         * The number of segments that make up the plane along the Y or Z-axis, depending on whether yUp is true or
         * false, respectively. Defaults to 1.
         */
        public function get segmentsH() : uint
        {
            return _segmentsH;
        }

        public function set segmentsH(value : uint) : void
        {
            _segmentsH = value;
            invalidateGeometry();
            invalidateUVs();
        }

        /**
		 * The width of the terrain plane.
		 */
		public function get width() : Number
		{
			return _width;
		}

		public function set width(value : Number) : void
		{
			_width = value;
			invalidateGeometry();
		}


        public function get height() : Number
        {
            return _height;
        }

        public function set height(value : Number) : void
        {
            _height = value;
        }

        /**
		 * The depth of the terrain plane.
		 */
		public function get depth() : Number
		{
			return _depth;
		}

		public function set depth(value : Number) : void
		{
			_depth = value;
			invalidateGeometry();
		}

		public function getHeightAt(x : Number, z : Number) : Number
		{
			var col : Number = _heightMap.getPixel((x/_width+.5)*_heightMap.width, (-z/_depth+.5)*_heightMap.height);
			return (col & 0xff) / 0xff * _height;
		}

		/**
		 * @inheritDoc
		 */
		protected override function buildGeometry(target : SubGeometry) : void
		{
			var vertices : Vector.<Number>;
			var indices : Vector.<uint>;
			var x : Number, z : Number;
			var numInds : uint;
			var base : uint;
			var tw : uint = _segmentsW + 1;
			var numVerts : uint = (_segmentsH + 1) * tw;
            var uDiv : Number = (_heightMap.width-1)/_segmentsW;
            var vDiv : Number = (_heightMap.height-1)/_segmentsH;
            var u : Number, v : Number;
            var y : Number;

			if (numVerts == target.numVertices) {
				vertices = target.vertexData;
				indices = target.indexData;
			}
			else {
				vertices = new Vector.<Number>(numVerts * 3, true);
				indices = new Vector.<uint>(_segmentsH * _segmentsW * 6, true);
			}

			numVerts = 0;
			for (var zi : uint = 0; zi <= _segmentsH; ++zi) {
				for (var xi : uint = 0; xi <= _segmentsW; ++xi) {
					x = (xi/_segmentsW-.5)*_width;
					z = (zi/_segmentsH-.5)*_depth;
                    u = xi*uDiv;
                    v = (_segmentsH-zi)*vDiv;
                    y = (_heightMap.getPixel(u, v) & 0xff) / 0xff * _height;
					vertices[numVerts++] = x;
					vertices[numVerts++] = y;
					vertices[numVerts++] = z;

					if (xi != _segmentsW && zi != _segmentsH) {
						base = xi + zi*tw;
						indices[numInds++] = base;
						indices[numInds++] = base + tw;
						indices[numInds++] = base + tw + 1;
						indices[numInds++] = base;
						indices[numInds++] = base + tw + 1;
						indices[numInds++] = base + 1;
					}
				}
			}

            target.autoDeriveVertexNormals = true;
            target.autoDeriveVertexTangents = true;
			target.updateVertexData(vertices);
			target.updateIndexData(indices);
		}

		/**
		 * @inheritDoc
		 */
		override protected function buildUVs(target : SubGeometry) : void
		{
			var uvs : Vector.<Number> = new Vector.<Number>();
			var numUvs : uint = (_segmentsH + 1) * (_segmentsW + 1) * 2;

			if (target.UVData && numUvs == target.UVData.length)
				uvs = target.UVData;
			else
				uvs = new Vector.<Number>(numUvs, true);

			numUvs = 0;
			for (var yi : uint = 0; yi <= _segmentsH; ++yi) {
				for (var xi : uint = 0; xi <= _segmentsW; ++xi) {
					uvs[numUvs++] = xi/_segmentsW;
					uvs[numUvs++] = 1 - yi/_segmentsH;
				}
			}

			target.updateUVData(uvs);
		}
    }
}

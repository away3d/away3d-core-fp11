package away3d.materials.utils
{
	/**
	 * The AGAL class provides static helper methods to improve readability when writing AGAL code.
	 */
	public class AGAL
	{

		/**
		 * Dot product for a 3-component vector
		 */
		public static function dp3(tgt : String, src1 : String, src2 : String) : String
		{
			return "dp3 "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Dot product for a 4-component vector
		 */
		public static function dp4(tgt : String, src1 : String, src2 : String) : String
		{
			return "dp4 "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Saturate; Clamp a value between 0 and 1
		 */
		public static function sat(tgt : String, src : String) : String
		{
			return "sat "+tgt+", "+src+"\n";
		}

		/**
		 * Normalize a 3-component vector
		 */
		public static function normalize(tgt : String, src : String) : String
		{
			return "nrm "+tgt+", "+src+"\n";
		}

		/**
		 * Multiply
		 */
		public static function mul(tgt : String, src1 : String, src2 : String) : String
		{
			return "mul "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Divide
		 */
		public static function div(tgt : String, src1 : String, src2 : String) : String
		{
			return "div "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Add
		 */
		public static function add(tgt : String, src1 : String, src2 : String) : String
		{
			return "add "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Subtract
		 */
		public static function sub(tgt : String, src1 : String, src2 : String) : String
		{
			return "sub "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Cross product for 3-component vectors
		 */
		public static function cross(tgt : String, src1 : String, src2 : String) : String
		{
			return "crs "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Copy value
		 */
		public static function mov(tgt : String, src : String) : String
		{
			return "mov "+tgt+", " + src + "\n";
		}

		/**
		 * Power
		 */
		public static function pow(tgt : String, src1 : String, src2 : String) : String
		{
			return "pow "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Sample texture
		 */
		public static function sample(tgt : String, coord : String, type : String, fs : String, filter : String, wrap : String) : String
		{
			var filtering : String;

			switch (filter) {
				case "trilinear":
					filtering = "linear,miplinear";
					break;
				case "bilinear":
					filtering = "linear";
					break;
				case "nearestMip":
					filtering = "nearest,mipnearest";
					break;
				case "nearestNoMip":
					filtering = "nearest";
					break;
				case "centroid":
					filtering = "centroid";
					break;
			}
			return 	"tex "+tgt+", "+coord+", "+fs+" <"+type+","+filtering+","+wrap+">\n";
		}

		/**
		 * Vector * Matrix3x4 multiplication
		 */
		public static function m34(tgt : String, src1 : String, src2 : String) : String
		{
			return "m34 "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Vector * Matrix3x3 multiplication
		 */
		public static function m33(tgt : String, src1 : String, src2 : String) : String
		{
			return "m33 "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Vector * Matrix4x4 multiplication
		 */
		public static function m44(tgt : String, src1 : String, src2 : String) : String
		{
			return "m44 "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Step: tgt = src1 > src2? 1 : 0
		 */
		public static function step(tgt : String, src1 : String, src2 : String) : String
		{
			return "sge "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Less than: tgt = src1 < src2? 1 : 0
		 */
		public static function lessThan(tgt : String, src1 : String, src2 : String) : String
		{
			return "slt "+tgt+", " + src1 + ", "+src2 +"\n";
		}

		/**
		 * Get the fractional part
		 */
		public static function fract(tgt : String, src : String) : String
		{
			return "frc "+tgt+", " + src + "\n";
		}

		/**
		 * Reciprocal, tgt = 1/src
		 */
		public static function rcp(tgt : String, src : String) : String
		{
			return "rcp "+tgt+", " + src + "\n";
		}

		/**
		 * Negate, tgt = -src
		 */
		public static function neg(tgt : String, src : String) : String
		{
			return "neg "+tgt+", " + src + "\n";
		}

		/**
		 * Square root
		 */
		public static function sqrt(tgt : String, src : String) : String
		{
			return "sqt "+tgt+", " + src + "\n";
		}

		/**
		 * Exponential
		 */
		public static function exp(tgt : String, src : String) : String
		{
			return "exp "+tgt+", " + src +"\n";
		}

		/**
		 * Greater or equal (identical to step)
		 */
        public static function greaterOrEqualTo(tgt : String, src1 : String, src2 : String) : String
		{
			return "sge "+tgt+", " + src1 + ", "+src2 +"\n";
		}

        public static function kill(src : String) : String
        {
            return "kil "+src+"\n";
        }

		public static function sin(tgt : String, src : String) : String
		{
			return "sin "+tgt+", " + src +"\n";
		}

		public static function cos(tgt : String, src : String) : String
		{
			return "cos "+tgt+", " + src +"\n";
		}
	}
}
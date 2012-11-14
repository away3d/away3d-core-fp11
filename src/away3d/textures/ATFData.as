package away3d.textures {
	import flash.display3D.Context3DTextureFormat;
	import flash.utils.ByteArray;
	/**
	 * @author simo
	 */
	public class ATFData {
		
		public static const TYPE_NORMAL	:int = 0x0;
		public static const TYPE_CUBE	:int = 0x1;
		
		public var type:		int;
		public var format		:String;
        public var width		:int;
        public var height		:int;
        public var numTextures	:int;
        public var data			:ByteArray;
		public var totalBytes	:int;
        
        /** Create a new instance by parsing the given byte array. */
        public function ATFData(data:ByteArray)
        {
            
			var sign : String = data.readUTFBytes( 3 );
			if( sign != "ATF" )
				throw new Error( "ATF parsing error, unknown format " + sign );
			
			this.totalBytes = (data.readUnsignedByte( ) << 16) + (data.readUnsignedByte( ) << 8) + data.readUnsignedByte( );

			var tdata : uint = data.readUnsignedByte( );
			var _type:int = tdata >> 7; 		// UB[1]
			var _format:int = tdata & 0x7f;		// UB[7]
			
			switch (_format)
            {
               	case 0:
                case 1: format = Context3DTextureFormat.BGRA; break;
                case 2:
                case 3: format = Context3DTextureFormat.COMPRESSED; break;
                case 4:
                case 5: format = "compressedAlpha"; break; 	// explicit string to stay compatible 
                                                            // with older versions
               default: throw new Error("Invalid ATF format");
            }
			
			switch (_type)
            {
                case 0: type = ATFData.TYPE_NORMAL; break;
                case 1: type = ATFData.TYPE_CUBE; break; 
				
                default: throw new Error("Invalid ATF type");
            }
			
			this.width = Math.pow( 2, data.readUnsignedByte( ) );
			this.height = Math.pow( 2, data.readUnsignedByte( ) );
			this.numTextures = data.readUnsignedByte( );
			this.data = data;
        }
		
	}
}

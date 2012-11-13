package away3d.textures {
	import flash.display3D.Context3DTextureFormat;
	import flash.utils.ByteArray;
	/**
	 * @author simo
	 */
	public class ATFData {
		
		public var format		:String;
        public var width		:int;
        public var height		:int;
        public var numTextures	:int;
		public var cubeMap		:Boolean;
        public var data			:ByteArray;
        
        /** Create a new instance by parsing the given byte array. */
        public function ATFData(data:ByteArray)
        {
            var signature:String = String.fromCharCode(data[0], data[1], data[2]);
            if (signature != "ATF") throw new ArgumentError("Invalid ATF data");
            
			//trace("cubemap "+data[3]+" "+data[4]+" "+data[5]);
			/*
			switch (data[6])
            {
				case 0 : 
				case 1 : cubeMap = false;
				case 2 : 
				case 3 : cubeMap = true;
				case 4 : 
				case 5 : 
				
			}*/
			
            switch (data[6])
            {
                case 0:
                case 1: format = Context3DTextureFormat.BGRA; break;
                case 2:
                case 3: format = Context3DTextureFormat.COMPRESSED; break;
                case 4:
                case 5: format = "compressedAlpha"; break; // explicit string to stay compatible 
                                                            // with older versions
                default: throw new Error("Invalid ATF format "+data[6]);
                //default : format = Context3DTextureFormat.COMPRESSED; break;
            }
            
            this.width = Math.pow(2, data[7]); 
            this.height = Math.pow(2, data[8]);
            this.numTextures = data[9];
            this.data = data;
        }
		
	}
}

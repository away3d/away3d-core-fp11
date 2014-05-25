package away3d.materials {
	import away3d.materials.passes.DeferredPass;
	import away3d.textures.Texture2DBase;

	public class DeferredMaterial extends MaterialBase {
		private var _deferredPass:DeferredPass;

		public function DeferredMaterial() {
			_deferredPass = new DeferredPass();
			addPass(_deferredPass);
		}

		public function get deferredPass():DeferredPass {
			return _deferredPass;
		}

		public function set color(value:uint):void {
			_deferredPass.colorR = ((value >> 16) & 0xFF) / 0xFF;
			_deferredPass.colorG = ((value >> 8) & 0xFF) / 0xFF;
			_deferredPass.colorB = (value & 0xff) / 0xFF;
		}

		public function get color():uint {
			return (_deferredPass.colorR * 0xFF << 16) + (_deferredPass.colorG * 0xFF << 8) + _deferredPass.colorB * 0xFF;
		}

		public function get diffuseMap():Texture2DBase {
			return _deferredPass.diffuseMap;
		}

		public function set diffuseMap(value:Texture2DBase):void {
			_deferredPass.diffuseMap = value;
		}

		public function get diffuseMapUVChannel():String {
			return _deferredPass.diffuseMapUVChannel;
		}

		public function set diffuseMapUVChannel(value:String):void {
			_deferredPass.diffuseMapUVChannel = value;
		}

		public function get normalMap():Texture2DBase {
			return _deferredPass.normalMap;
		}

		public function set normalMap(value:Texture2DBase):void {
			_deferredPass.normalMap = value;
		}

		public function get normalMapUVChannel():String {
			return _deferredPass.normalMapUVChannel;
		}

		public function set normalMapUVChannel(value:String):void {
			_deferredPass.normalMapUVChannel = value;
		}

		public function get specularMap():Texture2DBase {
			return _deferredPass.specularMap;
		}

		public function set specularMap(value:Texture2DBase):void {
			_deferredPass.specularMap = value;
		}

		public function get specularPower():Number {
			return _deferredPass.specularPower;
		}

		public function set specularPower(value:Number):void {
			_deferredPass.specularPower = value;
		}

		public function get specularMapUVChannel():String {
			return _deferredPass.specularMapUVChannel;
		}

		public function set specularMapUVChannel(value:String):void {
			_deferredPass.specularMapUVChannel = value;
		}

		public function get opacityMap():Texture2DBase {
			return _deferredPass.opacityMap;
		}

		public function set opacityMap(value:Texture2DBase):void {
			_deferredPass.opacityMap = value;
		}

		public function get opacityChannel():String {
			return _deferredPass.opacityChannel;
		}

		public function set opacityChannel(value:String):void {
			_deferredPass.opacityChannel = value;
		}

		public function get opacityUVChannel():String {
			return _deferredPass.opacityUVChannel;
		}

		public function set opacityUVChannel(value:String):void {
			_deferredPass.opacityUVChannel = value;
		}

		public function get alphaThreshold():Number {
			return _deferredPass.alphaThreshold;
		}

		public function set alphaThreshold(value:Number):void {
			_deferredPass.alphaThreshold = value;
		}
	}
}

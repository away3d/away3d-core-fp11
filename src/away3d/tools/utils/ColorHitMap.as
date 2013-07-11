package away3d.tools.utils
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	public class ColorHitMap extends EventDispatcher
	{
		
		private var _colorMap:BitmapData;
		private var _colorObjects:Vector.<ColorObject>;
		private var _scaleX:Number;
		private var _scaleY:Number;
		private var _offsetX:Number;
		private var _offsetY:Number;
		
		/**
		 * Creates a new <code>ColorHitMap</code>
		 *
		 * @param    bitmapData        The bitmapdata with color regions to act as trigger.
		 * @param    scaleX                [optional]    A factor scale along the X axis. Default is 1.
		 * @param    scaleY                [optional]    A factor scale along the Y axis. Default is 1.
		 *
		 * Note that by default the class is considered as centered, like a plane at 0,0,0.
		 * Also by default coordinates offset are set. If a map of 256x256 is set, and no custom offsets are set.
		 * The read method using the camera position -128 x and -128 z would return the color value found at 0,0 on the map.
		 */
		public function ColorHitMap(bitmapData:BitmapData, scaleX:Number = 1, scaleY:Number = 1)
		{
			_colorMap = bitmapData;
			_scaleX = scaleX;
			_scaleY = scaleY;
			
			_offsetX = _colorMap.width*.5;
			_offsetY = _colorMap.height*.5;
		}
		
		/**
		 * If at the given coordinates a color is found that matches a defined color event, the color event will be triggered.
		 *
		 * @param    x            X coordinate on the source bmd
		 * @param    y            Y coordinate on the source bmd
		 */
		public function read(x:Number, y:Number):void
		{
			if (!_colorObjects)
				return;
			
			var color:uint = _colorMap.getPixel((x/_scaleX) + _offsetX, (y/_scaleY) + _offsetY);
			
			var co:ColorObject;
			for (var i:uint = 0; i < _colorObjects.length; ++i) {
				co = ColorObject(_colorObjects[i]);
				if (co.color == color) {
					fireColorEvent(co.eventID);
					break;
				}
			}
		}
		
		/**
		 * returns the color at x,y coordinates.
		 * This method is made to test if the color is indeed the expected one, (the one you set for an event), as due to compression
		 * for instance using the Flash IDE library, compression might have altered the color values.
		 *
		 * @param    x            X coordinate on the source bitmapData
		 * @param    y            Y coordinate on the source bitmapData
		 *
		 * @return        A uint, the color value at coordinates x, y
		 * @see        plotAt
		 */
		public function getColorAt(x:Number, y:Number):uint
		{
			return _colorMap.getPixel((x/_scaleX) + _offsetX, (y/_scaleY) + _offsetY);
		}
		
		/**
		 * Another method for debug, if you addChild your bitmapdata on screen, this method will colour a pixel at the coordinates
		 * helping you to visualize if your scale factors or entered coordinates are correct.
		 * @param    x            X coordinate on the source bitmapData
		 * @param    y            Y coordinate on the source bitmapData
		 */
		public function plotAt(x:Number, y:Number, color:uint = 0xFF0000):void
		{
			_colorMap.setPixel((x/_scaleX) + _offsetX, (y/_scaleY) + _offsetY, color);
		}
		
		/**
		 * Defines a color event for this class.
		 * If read method is called, and the target pixel color has the same value as a previously set listener, an event is triggered.
		 *
		 * @param    color            A color Number
		 * @param    eventID        A string to identify that event
		 * @param    listener        The function  that must be triggered
		 */
		public function addColorEvent(color:Number, eventID:String, listener:Function):void
		{
			if (!_colorObjects)
				_colorObjects = new Vector.<ColorObject>();
			
			var colorObject:ColorObject = new ColorObject();
			colorObject.color = color;
			colorObject.eventID = eventID;
			colorObject.listener = listener;
			
			_colorObjects.push(colorObject);
			
			addEventListener(eventID, listener, false, 0, false);
		}
		
		/**
		 * removes a color event by its id
		 *
		 * @param  eventID  The Event id
		 */
		public function removeColorEvent(eventID:String):void
		{
			if (!_colorObjects)
				return;
			
			var co:ColorObject;
			for (var i:uint = 0; i < _colorObjects.length; ++i) {
				co = ColorObject(_colorObjects[i]);
				if (co.eventID == eventID) {
					if (hasEventListener(eventID))
						removeEventListener(eventID, co.listener);
					
					_colorObjects.splice(i, 1);
					break;
				}
			}
		}
		
		/**
		 * The offsetX, offsetY
		 * by default offsetX and offsetY represent the center of the map.
		 */
		public function set offsetX(value:Number):void
		{
			_offsetX = value;
		}
		
		public function set offsetY(value:Number):void
		{
			_offsetY = value;
		}
		
		public function get offsetX():Number
		{
			return _offsetX;
		}
		
		public function get offsetY():Number
		{
			return _offsetY;
		}
		
		/**
		 * defines the  scaleX and scaleY. Defines the ratio map to the 3d world
		 */
		public function set scaleX(value:Number):void
		{
			_scaleX = value;
		}
		
		public function set scaleY(value:Number):void
		{
			_scaleY = value;
		}
		
		public function get scaleX():Number
		{
			return _scaleX;
		}
		
		public function get scaleY():Number
		{
			return _scaleY;
		}
		
		/**
		 * The source bitmapdata uses for colour readings
		 */
		public function set bitmapData(map:BitmapData):void
		{
			_colorMap = map;
			
			_offsetX = _colorMap.width*.5;
			_offsetY = _colorMap.height*.5;
		}
		
		public function get bitmapData():BitmapData
		{
			return _colorMap;
		}
		
		private function fireColorEvent(eventID:String):void
		{
			dispatchEvent(new Event(eventID));
		}
	
	}
}

class ColorObject
{
	public var color:uint;
	public var eventID:String;
	public var listener:Function;
}

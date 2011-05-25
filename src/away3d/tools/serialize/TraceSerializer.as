package away3d.tools.serialize
{
	import away3d.arcane;
	import away3d.core.math.Quaternion;
	
	import flash.geom.Vector3D;
	
	use namespace arcane;

	/**
	 * TraceSerializer is a concrete Serializer that will output its results to trace().  It has user settable tabSize and separator vars.
	 * 
	 * @see away3d.tools.serialize.Serialize
	 */
	public class TraceSerializer extends SerializerBase
	{
		private var _indent:uint = 0;
		public var separator:String = ": ";
		public var tabSize:uint = 2;
		
		/**
		 * Creates a new TraceSerializer object.
		 */
		public function TraceSerializer()
		{
			super();
		}
		
		/**
		 * @inheritDoc
		 */
		public override function beginObject(className:String, instanceName:String):void
		{
			writeString(className, instanceName);
			_indent += tabSize;
		}
		
    /**
		 * @inheritDoc
     */
    public override function writeInt(name:String, value:int):void
    {
      var outputString:String = _indentString();
      outputString += name;
      outputString += separator;
      outputString += value;
      trace(outputString);
    }
    
		/**
		 * @inheritDoc
		 */
		public override function writeUint(name:String, value:uint):void
		{
			var outputString:String = _indentString();
			outputString += name;
			outputString += separator;
			outputString += value;
			trace(outputString);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function writeBoolean(name:String, value:Boolean):void
		{
			var outputString:String = _indentString();
			outputString += name;
			outputString += separator;
			outputString += value;
			trace(outputString);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function writeString(name:String, value:String):void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value)
			{
				outputString += separator;
				outputString += value;
			}
			trace(outputString);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function writeVector3D(name:String, value:Vector3D):void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value)
			{
				outputString += separator;
				outputString += value;
			}
			trace(outputString);
		}

		/**
		 * @inheritDoc
		 */
		public override function writeTransform(name:String, value:Vector.<Number>):void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value)
			{
				outputString += separator;
				
				var matrixIndent:uint = outputString.length;
				
				for (var i:uint = 0; i < value.length; i++)
				{
					outputString += value[i];
					if ((i < (value.length - 1)) && (((i + 1) % 4) == 0))
					{
						outputString += "\n";
						for (var j:uint = 0; j < matrixIndent; j++)
						{
							outputString += " ";
						}
					}
					else
					{
						outputString += " ";
					}
				}
			}
			trace(outputString);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function writeQuaternion(name:String, value:Quaternion):void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value)
			{
				outputString += separator;
				outputString += value;
			}
			trace(outputString);
		}

		/**
		 * @inheritDoc
		 */
		public override function endObject():void
		{
			_indent -= tabSize;			
		}
		
		private function _indentString():String
		{
			var indentString:String = "";
			for (var i:uint = 0; i < _indent; i++)
			{
				indentString += " ";
			}
			return indentString;
		}
	}
}
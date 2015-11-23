package 
{
	import flash.display.Sprite;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	/**
	 * ...
	 * @author lizhi
	 */
	public class Test extends Sprite
	{
		
		public function Test() 
		{
			var a:Number = 0x123456789a;
			trace(a.toString(16));
			trace((a >> 0 & 0xff).toString(16));
			trace((a >> 8 & 0xff).toString(16));
			trace((a >> 16 & 0xff).toString(16));
			trace((a >> 24 & 0xff).toString(16));
			trace((a >> 32 & 0xff).toString(16));
			
			var byte:ByteArray = new ByteArray;
			byte.endian = Endian.LITTLE_ENDIAN;
			byte.writeDouble(a);
			byte.position = 0;
			trace(byte.readInt().toString(16));
		}
		
	}

}
package ;

/**
 * ...
 * @author Javier Munoz
 */
using haxe.BaseCode;
 

class Base64 {
	private static var chars:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
	public static function encode(str:String):String {
		var r = str.encode(chars);//also does utf-8 encoding
		//add padding:
		switch(r.length%4) {
			case 2: r += '==';
			case 3:  r += '=';
		}
		return r;
	}
	public static function decode(str:String):String {
		
		//return str.replaceEnd('=').replaceEnd('=').decode(chars);//remove padding, also does utf-8 decoding
		if(str == null) return null;
		if(str.lastIndexOf('=') > 0) 
			str=str.substr(0,str.lastIndexOf("=")-1);
			//trace("decoding "+str);
		return str.decode(chars);

	}
}

package ;

/**
 * ...
 * @author Javier Munoz
 */
interface ServerAdapter {
	public function setRequestHandler(handler:Int->String->Dynamic->(Dynamic->Void)->Void):Void;
	public function sendNotification(command:String,data:Dynamic):Void;
	public function sendAsyncResponse(tid:Int,responseObj:Dynamic):Void;
}

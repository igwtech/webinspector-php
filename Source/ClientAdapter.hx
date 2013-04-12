package ;

/**
 * ...
 * @author Javier Munoz
 */
interface ClientAdapter {
	public function sendRequest(method:String,params:Dynamic,?responseCallback:Dynamic->Void):Void;
	public function setNotificationHandler(handler:String->Dynamic->Void):Void;
}

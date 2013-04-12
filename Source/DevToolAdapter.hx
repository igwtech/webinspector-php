package ;
import js.Node;
import js.node.Connect;
import js.node.WebSocketNode;
/**
 * ...
 * @author Javier Munoz
 */
class DevToolAdapter implements ServerAdapter {
	var wsServer:WebSocketServer;
	var httpServer:Dynamic;
	var wsConnection:WebSocketConnection;
	var requestHandler:Int->String->Dynamic->(Dynamic->Void)->Void;

	public function new () {
		var connect:Connect = Node.require('connect');
		var WebSocketServer = Node.require('websocket').server;
		httpServer=connect.createServer(
			connect.errorHandler({showStack:true, showMessage:true, dumpExceptions:true}), 
		    Reflect.field(connect, "static")(Node.__dirname , {redirect:true})
		    
		    );
		var server = untyped __js__('this.httpServer.listen(8080)');

		log( ' Server is listening on port 8080');
		this.wsServer = untyped __js__(" new WebSocketServer({'httpServer': server,'autoAcceptConnections':false})");
		this.wsServer.on('request', function(request) {
		    var lastrequest=null;
		    var eventid=0;
		        
		    if (!originIsAllowed(request.origin)) {
		        // Make sure we only accept requests from an allowed origin
		        request.reject();
		        log( ' Connection from origin ' + request.origin + ' rejected.');
		        return;
		    }
		    var cookies=null;
		    this.wsConnection = request.accept(null, request.origin,cookies,function(){
		        this.handleDevToolsConnect();
		        log(' Connection accepted.');
		    });
		    
		    
		    this.wsConnection.on('message', function(message) {
		        if (message.type == 'utf8') {
		            log('Received Message: ' + message.utf8Data);		            
					this.handleDevToolRequest(message.utf8Data);
		            
		        }
		        else if (message.type == 'binary') {
		            log('Received Binary Message of ' + message.binaryData.length + ' bytes');
		            //this.wsConnection.sendBytes(message.binaryData);
		        }
		    });
		    this.wsConnection.on('close', function(reasonCode, description) {
		        log(' Peer ' + this.wsConnection.remoteAddress + ' disconnected.');
		        this.wsConnection=null;
		    });
		});
	}
	public function isConnected():Bool { 
		return (this.wsConnection !=null && this.wsConnection.connected);
	}
	private function originIsAllowed(origin) {
		log("Request from Origin:"+origin);
	    // put logic here to detect whether the specified origin is allowed.
	    return true;
	}
	private function handleDevToolsConnect() {
		//TODO
		this.sendNotification("Debugger.enabled",true);
	}
	private function handleDevToolRequest(buffer) {
			var clientRequest=Node.parse(buffer);
			
			this.requestHandler(clientRequest.id,clientRequest.method,clientRequest.params,function(result:Dynamic) {
				this.sendAsyncResponse(clientRequest.id,result);
			});
      
    }
	public function sendAsyncResponse(tid:Int,responseObj:Dynamic):Void {
		if(this.wsConnection == null) return;
		var packet=Node.stringify({ result:responseObj, id:tid });
		this.wsConnection.sendUTF(packet);
		log("Sent Response: "+packet);
	}
	
	
	public function setRequestHandler(handler:Int->String->Dynamic->(Dynamic->Void)->Void):Void {
		this.requestHandler=handler;
	}
	public function sendNotification(method:String,params:Dynamic):Void {
		if(this.wsConnection == null) return;
		var packet=Node.stringify({"method":method,"params":params});
		
		this.wsConnection.sendUTF(packet);
		log("Sent Notification: "+packet);
	}
	public function log(msg:String):Void {
		trace(Date.now()+" [DEVTOOL] "+msg);
	}
}

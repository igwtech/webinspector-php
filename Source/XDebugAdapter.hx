package ;
import js.Node;
/**
 * ...
 * @author Javier Munoz
 */
class XDebugAdapter implements ClientAdapter {
	var xmlParser:Dynamic;
	var xdebugSocket:Dynamic;
	var eventid:Int;
	var eventCallbacks:Hash<Dynamic>;
	var buffer:haxe.io.BytesBuffer;
	var notificationHandler:String->Dynamic->Void;
	public function new (xdebugSocket) {
		this.xmlParser = Node.require('xml2js').parseString;
		this.eventid=1;
		this.eventCallbacks=new Hash<Dynamic>();
		this.buffer=new haxe.io.BytesBuffer();
		this.xdebugSocket=xdebugSocket;
		
		//trace(c);
        //TODO: dispatch event connect
        this.xdebugSocket.on('end', function() {
            log('Server Disconnected');
            //TODO: Dispatch event disconnect
        });
        this.xdebugSocket.on('data',function(buffer:NodeBuffer) {
            log("Data Received <-- "+buffer);
            this.parseXdebugResponse(buffer);
        });
        this.xdebugSocket.on('error',function(error){
            log("Error Received: "+error);
        });
	}		

	private function log(msg:String):Void {
		trace(Date.now()+ " [XDEBUG] "+msg);
	}
	private function sendXdebugRequest(command,?args:Dynamic,?data:haxe.io.Bytes,?callBack:Dynamic->Void) {
		var packet = new haxe.io.BytesBuffer();
			var _cmdarg ='';
			
			for(i in Reflect.fields(args)) {
				_cmdarg +=' -'+i+' '+Reflect.field(args,i);
			}
			packet.add(haxe.io.Bytes.ofString(command+' -i '+this.eventid));
			if(_cmdarg!=null)
				packet.add(haxe.io.Bytes.ofString(_cmdarg));
			if(data!=null)
				packet.add(data);
			packet.addByte(0);
			if(null!=callBack && Reflect.isFunction(callBack) ) {
				this.eventCallbacks.set('request_'+this.eventid,callBack);
			}
			log("Sending --> " +packet);
			if(this.xdebugSocket == null) return;
			this.xdebugSocket.write(packet.getBytes().getData());
			this.eventid++;
	}

	private function parseXdebugResponse(buffer:NodeBuffer) {
		
	  this.buffer.add(haxe.io.Bytes.ofString(buffer.toString('utf8')));
      //log(this.buffer);
      var packetData:haxe.io.Bytes =  this.buffer.getBytes();
      
      var startPos:Int=0;
      
      var char:Int;
      var buflenStr:String;
      do {
      	  buflenStr='';
	      while(startPos < packetData.length && (char= packetData.get(startPos++)) != 0) {
	  		  buflenStr += String.fromCharCode(char);
	  	  }
	      var buflenInt = Std.parseInt(buflenStr);
		  if(buflenInt > packetData.length - startPos) 
		  	break;
		  var xmlpayload:String = packetData.readString(startPos,buflenInt);
		  this.xmlParser(xmlpayload, {trim: true},this.handleXDebugResponse); 
		  startPos+=buflenInt;
	  }while(startPos < packetData.length);
	  this.buffer = new haxe.io.BytesBuffer();
	  this.buffer.add(packetData.sub(startPos,packetData.length-startPos));

	}
    private function handleXDebugResponse (err:Dynamic, message:Dynamic):Void {
				if(err) {
					log("Response Error:"+err);
					return;
				}
				if(message == null)
					return;
				log("Message Parsed:"+message);
				var method='';
				for(fname in Reflect.fields(message)) {
					method=fname;
					break;
				}
				log("Method Requested:"+method);
				
				if(Reflect.hasField(message,'response')) {
					var txid=untyped __js__('message.response.$.transaction_id');
					if(this.eventCallbacks.exists('request_'+txid)){
						this.eventCallbacks.get('request_'+txid)(message);
						return;
					}
				}
				
				this.notificationHandler(method,message);
				
    }
		
	public function sendRequest(method:String,params:Dynamic,?responseCallback:Dynamic->Void):Void {
		this.sendXdebugRequest(method,params,responseCallback);
	}
	public function setNotificationHandler(handler:String->Dynamic->Void):Void {
		this.notificationHandler=handler;
	}
}

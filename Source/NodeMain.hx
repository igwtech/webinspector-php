package;
import js.Node;
import js.Lib;

//import js.node.WebSocketServer;
//import js.node.WebSocketConnection;
/**
 * ...
 * @author Javier Munoz
 */
class NodeMain {
	var devAdapter:DevToolAdapter;
	var xdebugAdapter:XDebugAdapter;
	var debuggerContext:Hash<Dynamic>;
	var server:NodeNetServer;
	public function new () {
		devAdapter=new DevToolAdapter();

		devAdapter.setRequestHandler(this.onDevToolRequest);
		this.StartXDebugServer();
		
		debuggerContext=new Hash<Dynamic>();
	}
	public function StartXDebugServer() {
        var net = Node.require('net');
        server = net.createServer(function(c) { //'connection' listener
            trace('Server Session Connected');
            if(this.xdebugAdapter !=null) {
            	this.xdebugAdapter =null;
            }
            this.xdebugAdapter=new XDebugAdapter(c);
           	xdebugAdapter.setNotificationHandler(this.onXDebugNotification);
           	c.on('end', function() {
	            trace('Server Disconnected');
	            this.xdebugAdapter=null;
	        });
        });
        server.listen(9000, function() { //'listening' listener
            trace('Server Started');
        });

	}
	public function onDevToolRequest(txid:Int,method:String,params:Dynamic,callBack:Dynamic->Void):Void {
		switch(method) {
			case 'Debugger.getScriptSource':
				callBack(this.getScriptSource(params));
			case 'Console.enable':
				callBack(true);
			case 'Debugger.enable':
				callBack(true);
			case 'Debugger.canSetScriptSource':
				callBack(true);
			case 'Debugger.stepOver':
				this.xdebugAdapter.sendRequest('step_over',null);
				callBack({});
			case 'Debugger.stepInto':
				this.xdebugAdapter.sendRequest('step_into',null);
				callBack({});
			case 'Debugger.resume':
				this.xdebugAdapter.sendRequest('run',null);
				callBack({});
			case 'Debugger.evaluateOnCallFrame':
				this.evaluateOnCallFrame(txid,params);
			case 'Debugger.setBreakpointByUrl':
				this.setBreakpointByURL(txid,params);
			case 'Debugger.removeBreakpoint':
				callBack(this.removeBreakpoint(params));
			case 'Debugger.pause':
				this.xdebugAdapter.sendRequest('break',null);	
				callBack({});
//			case 'Runtime.getProperties':
				
			default:
				callBack({});
		}
	}
	public function removeBreakpoint(params:Dynamic):Dynamic {
		this.xdebugAdapter.sendRequest('breakpoint_remove',{'d':params.breakpointId});
		return {};
	}
	public function setBreakpointByURL(txid:Int,params:Dynamic):Void {
		var breakPoint:Dynamic={};
		if(params.lineNumber !='' && params.condition=='' ) {
			breakPoint.t='line';
		} 
		breakPoint.s='enabled';
		breakPoint.f=params.url;
		breakPoint.n = params.lineNumber+1;
		this.xdebugAdapter.sendRequest('breakpoint_set',breakPoint,function(result:Dynamic){
			var response=untyped __js__('result.response.$');
			this.devAdapter.sendAsyncResponse(txid,{"breakpointId":response.id,'locations':[{
				columnNumber:0,
				lineNumber:params.lineNumber, //Zero Based
				scriptId: this.updateParsedScripts(params.url)
			}]});
		});
			
		//breakpoint_set -i 18 -t line -s enabled -f file:///Users/javiermunoz/NetBeansProjects/Visualizador_DEV/servicios/listener/lib/validationrule.class.php -n 36
	}
	public function onXDebugNotification(method:String,params:Dynamic):Void {
		
		switch(method) {
			case "init":
				this.onXDebugInit(untyped __js__('params.init.$'));
			case 'response':
				if(untyped __js__('params.response.$.status') !=null) {
					var command =untyped __js__('params.response.$.command'); 
					var status = untyped __js__('params.response.$.status');
					var reason = untyped __js__('params.response.$.reason') ;
					untyped __js__('delete params.response.$');
					this.onXDebugStatus(command,status,reason,untyped __js__('params.response'));
				}
		}
	}
	
	private function updateParsedScripts(fileuri):String {
		var md5=Node.crypto.createHash("MD5");
		var uri=Node.url.parse(fileuri);
		
		var ScriptID = Node.path.basename(uri.pathname);  //Base64.encode(md5.digest(fileuri));
		if(this.debuggerContext.exists(ScriptID))
			return ScriptID;
		
		var fileData:String=Node.fs.readFileSync(Node.queryString.unescape(uri.pathname));
		this.debuggerContext.set(ScriptID,fileData);
		trace(fileData);
		var lines=fileData.toString().split('\n');
		lines.pop(); //drop last. Why? dont know...
		var endLine:Int = lines.length;
		var endColumn:Int =lines.pop().length+1; //missing NEWLINE char at the end
 		
		this.devAdapter.sendNotification("Debugger.scriptParsed", 
			{
				"scriptId": ScriptID,
					  "url": fileuri,
					  "startLine": 0,
					  "startColumn": 0,
					  "endLine": endLine,
					  "endColumn": endColumn
			//		  "isContentScript": <boolean>,
			//		  "sourceMapURL": <string> 
			});
		return ScriptID;
	}
	
	private function onXDebugStatus(command:String,status:String,reason:String,data:Dynamic) {
		trace("onXDebugStatus");
		switch(status) {
			case 'break':
	        	var breakInfo=untyped __js__("data['xdebug:message'][0].$");
	        	trace(breakInfo);
	        	var scriptID=this.updateParsedScripts(breakInfo.filename);
	        	var frameID = scriptID+':'+Math.ceil( Math.random()*1000);
	        	//Get CallFrame
	        	//this.xdebugAdapter.sendRequest('stack_get',null);
	        	// stack_get
	        	//context_names
	        	// context_get -c 0|1
	        	this.devAdapter.sendNotification('Debugger.paused',
	        		{
					  "callFrames": [
							{
								callFrameId: frameID,
								functionName:'',
								location: {
									columnNumber:0,
									lineNumber: Std.parseInt(breakInfo.lineno)-1,  //Zero based
									scriptId: scriptID
								},
								scopeChain:[],
								'this':null
							}
							],
					  "reason": 'other',
					//  "data": <object> 
					});
			case 'stopping':
				trace("Terminted");
				js.Node.process.exit(0);
				
        }

	}
	private function onXDebugInit(xdebugInit:Dynamic) {
		if(this.devAdapter.isConnected()) {
			trace("New Debugging Session:"+xdebugInit);
			this.xdebugAdapter.sendRequest('feature_set', {'n': 'show_hidden', 'v': 1});
			this.xdebugAdapter.sendRequest('feature_set',{'n':'max_depth' ,'v': 3});
			this.xdebugAdapter.sendRequest('feature_set',{ 'n':'max_children', 'v': 30});
			this.xdebugAdapter.sendRequest('feature_get',{ 'n': 'max_data'});
			//this.xdebugAdapter.sendRequest('feature_set',{'n':'supports_async','v':1 });
			this.updateParsedScripts(xdebugInit.fileuri);
			this.xdebugAdapter.sendRequest('step_into',null);
			//this.xdebugAdapter.sendRequest('run',null);
		}else{
			this.xdebugAdapter.sendRequest('run',null);
			this.xdebugAdapter.sendRequest('run',null);
		}
	}

	public function getScriptSource(params:Dynamic):Dynamic {
		if(this.debuggerContext.exists(params.scriptId) ){
			return {"scriptSource": this.debuggerContext.get(params.scriptId).toString() };
		}else{
			return {};
		}
	}
	
	public function evaluateOnCallFrame(txid:Int,params:Dynamic):Void {
		var RemoteObject:Dynamic={};
		RemoteObject.type='undefined';
		this.xdebugAdapter.sendRequest('property_get',{'n': params.expression},function(result:Dynamic):Void{
			trace(result);
			if(result.response.error != null) {
				RemoteObject.description=untyped __js__('result.response.error._');
			}else{
				var returnArray:Array<Dynamic>=result.response.property;
				if(returnArray.length == 1) {
					var phpProperty:Dynamic=untyped __js__ ("returnArray[0].$");
					var phpValue:Dynamic=untyped __js__ ("returnArray[0]._");
					trace(phpProperty);
					RemoteObject.type=phpProperty.type;
					//Should be a switch Case
					
					if(RemoteObject.type == 'object' || RemoteObject.type == 'array') {
						debuggerContext.set(phpProperty.address,returnArray);
						RemoteObject.className=phpProperty.classname; //Object class (constructor) name. Specified for object type values only.
						RemoteObject.objectId=phpProperty.address;
						RemoteObject.subtype='array'; // enumerated string [ "array" , "date" , "node" , "null" , "regexp" ]
						RemoteObject.description=returnArray;
					}else{
						RemoteObject.description=(phpProperty.encoding=='base64')?Base64.decode(phpValue):phpValue;
					}
					if(params.returnByValue) {
						RemoteObject.value=(phpProperty.encoding=='base64')?Base64.decode(phpValue):phpValue;
					}
				}
			}
			this.devAdapter.sendAsyncResponse(txid,{"result":RemoteObject});
		});
	}
	static function main () {
		
		new NodeMain ();
		
	}

}


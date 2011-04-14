package nl.igorski.models 
{
    import flash.events.DataEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.*;
    import flash.system.Security;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.utils.setTimeout;
    import nl.igorski.config.Config;
    import nl.igorski.events.UDPEvent;
	/**
     * ...
     * @author Igor Zinken
     */
    public class UDPProxy extends EventDispatcher
    {
        private var socket          :*;
        private var ip              :String;
        private var port            :int;
        
        private var forceConnection :Boolean;
        private var locked          :Boolean;
        private var ival            :uint;
        
        private var useDatagram     :Boolean = false;
        
        public function UDPProxy( ip:String = "127.0.0.1", port:int = 7400, forceConnection:Boolean = true ) 
        {
            this.ip              = ip;
            this.port            = port;
            this.forceConnection = forceConnection;
            
            locked               = false;
        }
        
        public function connect( inIP:String = null, inPort:int = 0 ):void
        {
            if ( ival > 0 )
            {
                locked = false;
                clearInterval( ival );
                ival = 0;
            }
            
            if ( inIP != null )
                ip = inIP;
            
            if ( inPort != 0 )
                port = inPort;
            
            if ( socket != null )
                clearSocket();
            /*
            if ( DatagramSocket.isSupported && useDatagram )
            {
                socket = new DatagramSocket();
                
                socket.bind( port, ip );
                socket.addEventListener( DatagramSocketDataEvent.DATA, onSocketDataHandler, false, 0, true );
                socket.receive();
            }
            else
            {
            */
                socket = new Socket( ip, port );
			            
                socket.addEventListener( Event.CONNECT, onSocketConnectHandler, false, 0, true );
                socket.addEventListener( Event.CLOSE, onSocketCloseHandler, false, 0, true );
                socket.addEventListener( IOErrorEvent.IO_ERROR, onSocketErrorHandler, false, 0, true );
                socket.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler, false, 0, true );
                socket.addEventListener( DataEvent.DATA, onSocketDataHandler, false, 0, true );
                socket.addEventListener( ProgressEvent.SOCKET_DATA, onSocketDataHandler, false, 0, true );
                
//                socket.timeout = 2000;
                
                socket.connect( ip, port );
           // }
			myTrace( "CONNECTING socket => " + ip + ":" + port + " with clearance: " + Security.sandboxType.toUpperCase());
		}
 
		public function sendMessage( message:String ):void
        {
            message = message + "\n";
 
			myTrace( "sending message '" + message + "' => " + ip + ":" + port );
 
            if ( socket != null && socket.connected )
            { 
				socket.writeUTFBytes( message );
                socket.flush();
            }		
        } 
 
		private function onSocketConnectHandler( e:Event ):void
        {		
			myTrace( ip + ":" + port + " => CONNECTED" );
		}
 
		private function onSocketCloseHandler( e:Event ):void
        {			
			myTrace( ip + ":" + port + " => close handler" );
            
            if ( forceConnection )
                reconnect();		
		}
 
		private function onSocketErrorHandler( e:IOErrorEvent ):void
        {		
			myTrace( ip + ":" + port + " => ERROR " + e.type );
            
            if ( forceConnection )
                reconnect();
		}
        
        private function onSecurityErrorHandler( e:SecurityErrorEvent ):void
        {
            myTrace( "SECURITY VIOLATION => " + ip + ":" + port );
            forceConnection = false;
        }
 
		private function onSocketDataHandler( e:* ):void
        {
            if ( DatagramSocket.isSupported && useDatagram )
            {
                dispatchEvent( new UDPEvent( UDPEvent.DATA, e.data.readUTFBytes( e.data.bytesAvailable )));
            }
            else {
                dispatchEvent( new UDPEvent( UDPEvent.DATA, socket.readUTFBytes( socket.bytesAvailable )));
            }
		}
        
        private function reconnect():void
        {
            if ( locked )
                return;
                
            locked = true;
            
            ival = setInterval( function():void
            {
                connect();
            }, 1000 );
        }
        
        private function clearSocket():void
        {
            socket.removeEventListener( Event.CONNECT, onSocketConnectHandler );
			socket.removeEventListener( Event.CLOSE, onSocketCloseHandler );
			socket.removeEventListener( IOErrorEvent.IO_ERROR, onSocketErrorHandler );
            socket.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler );
			socket.removeEventListener( DataEvent.DATA, onSocketDataHandler );
			socket.removeEventListener( ProgressEvent.SOCKET_DATA, onSocketDataHandler );
        }
        
        private function myTrace( msg:String ):void
        {
            if ( Config.DEBUG )
            {
                dispatchEvent( new UDPEvent( UDPEvent.STATE, msg ));
            }
            else {
                trace( msg );
            }
        }
    }
}

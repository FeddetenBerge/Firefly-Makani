package nl.igorski.models 
{
    import flash.events.EventDispatcher;
    import flash.net.*;
    import flash.utils.ByteArray;
    import nl.igorski.config.Config;
    import nl.igorski.events.UDPEvent;
    /**
     * ...
     * @author Igor Zinken
     */
    public final class LCProxy extends EventDispatcher
    {
        private var connection      :LocalConnection;
        public var connectionName   :String;
        
        private var _lastPackage    :String;
        
        public function LCProxy( connectionName:String = "" ) 
        {
            this.connectionName  = connectionName;
            _lastPackage         = "";
            
            init();
        }
        
        private function init():void
        {
            connection = new LocalConnection();
            connection.allowDomain("*");
            connection.client = this;
        }
        
        public function connect():void
        {
            myTrace( "LCProxy::CONNECTING to => " + connectionName );

            try {
                connection.connect( connectionName );
            } catch( e:Error )
            {

            }
        }

        public function onData( data:Object ):void
        {
            if ( data is ByteArray )
            {
                var contents:String = data.readUTFBytes( data.bytesAvailable );
                
                // only process data if the reading differs from the previous reading
                if ( contents != _lastPackage )
                {
                    dispatchEvent( new UDPEvent( UDPEvent.DATA, contents, connectionName ));
                    _lastPackage = contents;
                }
            }
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

        public function destroy():void
        {
            if ( connection != null )
            {
                try {
                    connection.close();
                } catch( e:Error )
                {
                    // probably not connected...
                }
            }
        }
    }
}

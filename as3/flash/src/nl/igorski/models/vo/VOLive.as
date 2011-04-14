package nl.igorski.models.vo 
{
    /**
     * ...
     * @author Igor Zinken
     */
    public final class VOLive
    {
        /* -1 values are set by default to determine
         * which values have been passed during transfer
         * i.e. if value > -1, process it
         */
        public var bpm            :int = -1;
        public var playbacksize   :int = -1;
        public var playbackspeed  :int = -1;
        public var sampleronoff   :int = -1;
        public var envfollow      :int = -1;
        public var momsw          :int = -1;
        public var miep           :int = -1;
        
        /*
         * UDP data passed as String should be presented in this format:
         * /variable:value
         * i.e.: /bpm:120.00
         */
        public function VOLive( data:String )
        {
            var obj:Array = data.split( "/" );
            obj = obj[ obj.length - 1 ].split( ":" );

            if ( obj == null )
                return;
            //trace( obj[0] );
            try {
                this[ obj[0]] = Number( obj[1] );
            } catch( e:SecurityError )
            {
                // object didn't exist in VO object... check
                // what Max MSP is sending!!
            }
        }

        public function get momState():Boolean
        {
            var ms:String = momsw.toString();
            return ( ms.charAt( ms.length - 1 ) == "1" ) ? true : false;
        }

        public function get momIndex():int
        {
            var ms:String = momsw.toString();
            return int( ms.substr( 0, -1 ));
        }
    }
}

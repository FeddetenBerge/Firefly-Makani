package nl.igorski.definitions 
{
    /**
     * ...
     * @author Igor Zinken
     */
    public class DataChannels 
    {
        /*
         * data channel ports are unused within the AS3 application, but are here
         * for referencing with external setup, each name represents the LocalConnection
         * name to accept data on. Each callback triggered by udp-flashlc-bridge ( "onData" )
         * arrives in it's unique LCProxy
         */
        public static const INSTRUMENT_1_MIDI       :Object = { port: 3333, name: "_FFM" };
        public static const INSTRUMENT_1_AMPLITUDE  :Object = { port: 3334, name: "_FFMA" };
        public static const INSTRUMENT_2_MIDI       :Object = { port: 4444, name: "_FFM2" };
        public static const INSTRUMENT_2_AMPLITUDE  :Object = { port: 4445, name: "_FFM2A" };

        public function DataChannels() 
        {
            throw new Error( "CANNOT instantiate DataChannels" );
        }
        
        public static function get channels():Array
        {
            return [ INSTRUMENT_1_MIDI,
                     INSTRUMENT_1_AMPLITUDE,
                     INSTRUMENT_2_MIDI,
                     INSTRUMENT_2_AMPLITUDE ];
        }
    }
}

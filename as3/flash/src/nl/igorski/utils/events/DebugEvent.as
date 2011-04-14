package nl.igorski.utils.events 
{
    import flash.events.Event;
	/**
     * ...
     * @author Igor Zinken
     */
    public class DebugEvent extends Event
    {
        public static const TRACE   :String = "DebugEvent::TRACE";
        public var message          :String;
        
        public function DebugEvent( type:String = TRACE, message:String = "" ) 
        {
            this.message = message;
            super( type );
        }
    }
}

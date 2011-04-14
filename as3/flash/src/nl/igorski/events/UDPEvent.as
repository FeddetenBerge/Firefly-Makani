package nl.igorski.events 
{
    import flash.events.Event;
	/**
     * ...
     * @author Igor Zinken
     */
    public class UDPEvent extends Event
    {
        public static const DATA    :String = "UPDEvent::DATA";
        public static const STATE   :String = "UDPEvent::STATE";
        
        public var value            :String;
        public var source           :String;
        
        public function UDPEvent( type:String = DATA, value:String = "", source:String = "" )
        {
            this.value  = value;
            this.source = source;
            super( type );
        }        
    }
}

package nl.igorski.events 
{
    import flash.events.Event;
	/**
     * ...
     * @author Igor Zinken
     */
    public class InputEvent extends Event
    {
        public static const KEY_PRESS   :String = "InputEvent::KEY_PRESS";
        public var charCode             :int;
        
        public function InputEvent( type:String = KEY_PRESS, charCode:int = -1 ) 
        {
            this.charCode = charCode;
            super( type );
        }
    }
}

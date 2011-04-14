package nl.igorski.ui 
{
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldType;
	/**
     * ...
     * @author Igor Zinken
     */
    public class UDPEditor extends Sprite
    {
        public static const RECONNECT   :String = "UDPEditor::RECONNECT";
        
        private var tfIp                :TextField;
        private var tfPort              :TextField;
        private var connect             :Sprite;
        
        private var _ip                 :String;
        private var _port               :int;
        
        public function UDPEditor( ipText:String, portText:int ) 
        {
            _ip     = ipText;
            _port   = portText;
            
            addEventListener( Event.ADDED_TO_STAGE, init );
        }
        
        public function get ip():String
        {
            return tfIp.text;
        }
        
        public function get port():int
        {
            return int( tfPort.text );
        }
        
        private function init( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );
            
            tfIp             = new TextField();
            tfIp.type        = TextFieldType.INPUT;
            tfIp.text        = _ip;
            tfIp.textColor   = 0xFFFFFFF;
            
            tfPort           = new TextField();
            tfPort.text      = String( _port );
            tfPort.type      = TextFieldType.INPUT;
            tfPort.y         = 30;
            tfPort.textColor = 0xFFFFFFF;
            
            tfIp.border      = tfPort.border = true;
            tfIp.width       = tfPort.width  = 120;
            tfIp.height      = tfPort.height  = 25;
            
            connect = new Sprite();
            connect.graphics.beginFill( 0xFF0000, 1 );
            connect.graphics.drawCircle( 0, 0, 10 );
            connect.graphics.endFill();
            
            connect.x = 10;
            connect.y = 65;
            
            connect.buttonMode    =
            connect.useHandCursor = true;
            
            addChild( tfIp );
            addChild( tfPort );
            addChild( connect );
            
            connect.addEventListener( MouseEvent.CLICK, handleClick );
        }
        
        private function handleClick( e:MouseEvent ):void
        {
            dispatchEvent( new Event( RECONNECT ));
        }
    }
}

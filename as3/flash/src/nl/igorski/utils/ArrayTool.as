package nl.igorski.utils 
{
	/**
     * ...
     * @author Igor Zinken
     */
    public class ArrayTool 
    {
        
        public function ArrayTool() 
        {
            
        }
        
        public static function shuffle( array:Array ):Array
        {
            var l:Number = array.length - 1;
            for ( var i:int = 0; i < l; ++i )
            {
                var r:int = Math.round( Math.random() * l );
                var tmp:* = array[i];
                array[i]  = array[r];
                array[r]  = tmp;
            }
            return array;
        }
    }

}
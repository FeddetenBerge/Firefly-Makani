package nl.igorski.utils 
{
    import flash.display.BitmapData;
    import flash.geom.Point;
    import flash.geom.Rectangle;
	/**
     * ...
     * @author Igor Zinken
     */
    public class BitmapTool 
    {
        
        public function BitmapTool() 
        {
            
        }
        
        public static function divider( bitmapData:BitmapData, horizontalBlockAmount:int = 2, verticalBlockAmount:int = 2 ):Vector.<BitmapData>
        {
            var width:int       = Math.round( bitmapData.width / horizontalBlockAmount );
            var height:int      = Math.round( bitmapData.height / verticalBlockAmount );
            var totalBlocks:int = horizontalBlockAmount * verticalBlockAmount;
            
            var out:Vector.<BitmapData> = new Vector.<BitmapData>( totalBlocks );
            
            var row:int         = 0;
            var col:int         = 0;
            
            for ( var i:int = 0; i < totalBlocks; ++i )
            {
                var bmd:BitmapData = new BitmapData( width, height, true, 0x00000000 );
                bmd.copyPixels( bitmapData, new Rectangle( row * width, col * height, width, height ), new Point( 0, 0 ));
                
                ++row;
                if ( row >= horizontalBlockAmount )
                {
                    row = 0;
                    ++col;
                }
                out[ i ] = bmd;
            }
            return out;
        }
        
    }

}
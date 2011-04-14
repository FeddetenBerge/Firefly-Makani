package nl.igorski.visualisers 
{
    import flash.display.BitmapData;
    import flash.events.Event;

    import nl.igorski.config.Config;
    import nl.igorski.models.vo.VOLive;
    import nl.igorski.utils.BitmapTool;
    import nl.igorski.utils.MathTool;
    import nl.igorski.visualisers.base.BaseVisualiser;
    import nl.igorski.visualisers.components.photosplitter.BitmapWarper;
    import nl.igorski.visualisers.helpers.ThresholdCalculator;

    /**
     * ...
     * @author Igor Zinken
     */
    public class PhotoSplitter extends BaseVisualiser
    {
        private var blocks   :Vector.<BitmapWarper>;
        private var interval :uint;
        
        private var rows     :int = 10;
        private var cols     :int = rows;
        private var colWidth :int = 0;
        private var rowHeight:int = 0;
        
        private var thresholdCalculator:ThresholdCalculator;
        
        public function PhotoSplitter() 
        {
            addEventListener( Event.ADDED_TO_STAGE, init );
        }
        
        private function init( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );
            
            thresholdCalculator = new ThresholdCalculator();
            
            var parts:Vector.<BitmapData> = BitmapTool.divider( new FireFly( 0, 0 ), rows, cols );
            
            blocks = new Vector.<BitmapWarper>( parts.length );
            
            for ( var i:int = 0, j:int = rows * cols; i < j; ++i )
            {
                var bmp:BitmapWarper = new BitmapWarper( parts[ i ] );
                addChild( bmp );
                blocks[ i ] = bmp;  
            }
            reArrange( 0 );
        }
        
        private function reArrange( marginX:int = 0, marginY:int = 0 ):void
        {
            var row:int     = 0;
            var col:int     = 0;
            
            for each( var bmp:BitmapWarper in blocks )
            {
                if ( colWidth == 0 )
                    colWidth = bmp.width;
                    
                if ( rowHeight == 0 )
                    rowHeight = bmp.height;
                
                bmp.x = ( colWidth + marginX ) * row;
                bmp.y = ( rowHeight + marginY ) * col;
                ++row;
                if ( row >= rows )
                {
                    row = 0;
                    ++col;
                }
            }
            x = Config.width * .5 - width * .5;
            y = Config.height * .5 - height * .5;
        }
        
        private function distort():void
        {
            var positions:Array = [];
            
            for ( var i:int = 0; i < blocks.length; ++i )
                blocks[ i ].distort();
        
        }
        
        override public function process( data:VOLive ):void
        {
            super.process( data );
            
            if ( data.envfollow > -1 )
            {
                var beat:Boolean = thresholdCalculator.measure( data.envfollow );
                scaleX = ( beat ) ? 1 + MathTool.scale( data.envfollow, 127, .15 ) : 1;       
                scaleY = scaleX;
            }
            var xDistortion:int = 0;
            var yDistortion:int = 0;

            if ( data.playbacksize > -1 )
            {
                 xDistortion = MathTool.scale( data.playbacksize, 127, Math.round(( Config.height - ( rows * rowHeight )) / rows )/*Math.round(( Config.width - ( cols * colWidth )) / cols )*/);
                 yDistortion = MathTool.scale( data.playbacksize, 127, Math.round(( Config.height - ( rows * rowHeight )) / rows ));
            }
            reArrange( xDistortion, yDistortion );
        }
        
        override public function destroy():void
        {
            for ( var i:int = blocks.length - 1; i > 0; --i )
            {
                blocks[ i ].destroy();
                blocks.splice( 0, 1 );
            }
            thresholdCalculator = null;
            super.destroy();
        }
    }
}

package nl.igorski.visualisers.components.photosplitter 
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.events.Event;
    import flash.filters.BitmapFilter;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import nl.igorski.utils.MathTool;
	/**
     * ...
     * @author Igor Zinken
     */
    public class BitmapDistorter extends Bitmap
    {
        private var BMDRect     :Rectangle;
        private var nullPoint   :Point;
        
        public function BitmapDistorter( bitmapData:BitmapData, pixelSnapping:String = 'auto', smoothing:Boolean = true ) 
        {
            super( bitmapData, pixelSnapping, smoothing );
            
            BMDRect   = new Rectangle( 0, 0, bitmapData.width, bitmapData.height );
            nullPoint = new Point( 0, 0 );
            
            addEventListener( Event.ADDED_TO_STAGE, init );
        }
        
        private function init( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );
        }
        
        public function distort():void
        {
            var perlin:BitmapData = new BitmapData( BMDRect.width, BMDRect.height );
            perlin.perlinNoise( BMDRect.width, BMDRect.height, MathTool.rand( 0, 7 ), MathTool.rand( 0, 10 ), false, true );
            //bitmapData.pixelDissolve( perlin, BMDRect, nullPoint, 50, BMDRect.width * BMDRect.height * .35 );
            bitmapData.copyChannel( perlin, BMDRect, nullPoint, BitmapDataChannel.BLUE, BitmapDataChannel.BLUE );    
        }
        
        public function destroy():void
        {
            bitmapData.dispose();
        }
        
    }

}
package nl.igorski.visualisers.components.photosplitter 
{
    import com.greensock.easing.Sine;
    import com.greensock.TweenLite;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import nl.igorski.utils.MathTool;
	/**
     * ...
     * @author Igor Zinken
     */
    public class BitmapWarper extends Bitmap
    {
        public function BitmapWarper( bitmapData:BitmapData, pixelSnapping:String = 'auto', smoothing:Boolean = true ) 
        {
            super( bitmapData, pixelSnapping, smoothing );
            addEventListener( Event.ADDED_TO_STAGE, init );
        }
        
        private function init( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );
        }
        
        public function distort():void
        {
            TweenLite.to( this, .65, { rotationZ: MathTool.rand( -10, 10 ), ease: Sine.easeIn } );
        }
        
        public function destroy():void
        {
            bitmapData.dispose();
        }
        
    }

}
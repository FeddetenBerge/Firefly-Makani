package nl.igorski.utils 
{
    import flash.display.DisplayObject;
    import flash.geom.Matrix;
    import flash.geom.Point;
	/**
     * ...
     * @author Igor Zinken
     */
    public class DisplayObjectTool 
    {
        private static const PI_DIVIDED_BY_180  :Number = Math.PI / 180;
        
        public function DisplayObjectTool() 
        {
            
        }
        
        /**
         * rotates objects and sets their center point of rotation in the absolute center
         * NOTE: when repeatedly rotating the same object, pass the point variable containig the
         * registration of the object at it's initial / 0 rotation
         * 
         * @param	obj      DisplayObject to rotate
         * @param	rotation the amount to rotate in degress
         * @param	point    optional the preffered center registration point
         */
        public static function rotateAroundCenter( obj:DisplayObject, rotation:Number, point:Point = null ):void
        {
            if ( point == null )
                var p:Point  = new Point( obj.x + obj.width * .5, obj.y + obj.height * .5 );
            
            var m:Matrix = obj.transform.matrix;
            
            m.tx -= p.x;
            m.ty -= p.y;
            m.rotate( rotation * PI_DIVIDED_BY_180 );
            m.tx += p.x;
            m.ty += p.y;
            
            obj.transform.matrix = m;
        }
        
        public static function scaleAroundCenter( obj:DisplayObject, scaleX:Number = 1, scaleY:Number = NaN ):void
        {
            if ( isNaN( scaleY ))
                scaleY = scaleX;
            
            obj.x -= (( obj.width * scaleX ) - obj.width ) * .5;
            obj.y -= (( obj.height * scaleY ) - obj.height ) * .5;
            
            obj.scaleX = scaleX;
            obj.scaleY = scaleY;
        }
    }
}

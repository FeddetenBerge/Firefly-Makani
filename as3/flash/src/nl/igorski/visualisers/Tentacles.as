package nl.igorski.visualisers 
{
    import Box2D.Common.Math.b2Vec2;
    import com.actionsnippet.qbox.QuickBox2D;
    import com.actionsnippet.qbox.QuickObject;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.setInterval;
    import nl.igorski.models.vo.VOLive;
    import nl.igorski.utils.DisplayObjectTool;
    import nl.igorski.utils.MathTool;
    import nl.igorski.visualisers.base.BaseVisualiser;
    import nl.igorski.visualisers.helpers.Box2DHelper;
	/**
     * ...
     * @author Igor Zinken
     */
    public class Tentacles extends BaseVisualiser
    {
        public static const TENTACLE_AMOUNT :int = 3;
        public static const TENTACLE_LENGTH :int = 15;
        
        private var world                   :QuickBox2D;
        private var bmd                     :BitmapData;
        private var bmp                     :Bitmap;
        
        private var body                    :QuickObject;
        
        public function Tentacles() 
        {
            addEventListener( Event.ADDED_TO_STAGE, init );
        }
        
        private function init( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );
            
            // create box 2D world
            world = new QuickBox2D( this, { debug: false, gravityY: 0 } );
            createWorldBoundary();
            
            createBody();
            
            world.start();
            world.mouseDrag();
        }
        
        override public function process( data:VOLive ):void
        {
            super.process( data );
            
            if ( data.playbacksize > -1 )
            {
                /*
                var amount:int = MathTool.scale( data.playbacksize, 127, 20 );
                amount < 2 ? amount = 5 : amount = -amount;
                alterGravity( amount );
                */
                // rotate body
                body.body.SetAngularVelocity( MathTool.scale( data.playbacksize, 127, 500 ));
            }   
            if ( data.playbackspeed > -2 )
                DisplayObjectTool.scaleAroundCenter( this, MathTool.scale( data.playbackspeed, 127, 10 ) * .01 );
        }
        
        private function alterGravity( amount:int ):void
        {
            world.gravity = new b2Vec2( 0, amount );
        }
        
        private function pullArms( amount:int ):void
        {
            
        }
        
        private function createWorldBoundary():void
        {
            var margin:int = Box2DHelper.p2m( 40 );
            var sw:Number  = Box2DHelper.p2m( stage.stageWidth );
			var sh:Number  = Box2DHelper.p2m( stage.stageHeight );
			
			// bottom
            world.addBox({ x:sw * .5,      y:sh + margin, width:sw - 1, height:1, density:.0 });
			// top
            world.addBox({ x:sw * .5,      y:0 - margin,  width:sw - 1, height:1, density:.0 });
			// left
            world.addBox({ x: -margin,     y:sh * .5,     width:1, height:sh , density:.0 });
			// right
            world.addBox({ x: sw + margin, y:sh * .5,     width:1, height:sh, density:.0 });
        }
        
        private function createBody():void
        {
            var _x:Number = 250;
            var _y:Number = 210;
            
            body = world.addCircle( { x: Box2DHelper.p2m( _x ),
                                      y: Box2DHelper.p2m( _y ),
                                      radius:  Box2DHelper.p2m( 50 ),
                                      fillColor: 0x000000
                                  });
            var curr:QuickObject;
            
            for ( var i:int = 0; i < TENTACLE_AMOUNT; ++i )
            {
                var pre:QuickObject = body;
                
                for ( var j:int = 0, k:int = Math.ceil( TENTACLE_LENGTH / ( i + 1 )); j < k; ++j )
                {
                    _x = 10 + j;
                    _y = body.body.GetWorldCenter().y + i;
                    
                    curr = world.addCircle( { x: _x,
                                              y: _y,
                                              radius: .45,
                                              angularDamping:1,
                                              fillColor: 0x000000 } );
                    
                    world.addJoint( { a: pre.body,
                                      b: curr.body,
                                      x1: _x - 1,
                                      y1: _y,
                                      x2: _x,
                                      y2: _y,
                                      collideConnected: false } );
                    
                    pre = curr;
                }
            }
           // this.filters = [ new BlurFilter( 10, 10, 1 ) ];
            return;
            setInterval(
            function():void
            {
                bitmapCrap();      
            }, 2500 );
        }
        
        private function bitmapCrap():void
        {
            var bmd:BitmapData = new BitmapData( stage.width, stage.height, true, 0x00000000 );
            bmd.draw( this );
            if ( bmp == null )
            {
                var bmp:Bitmap = new Bitmap( bmd );
                addChild( bmp );
            }
            bmp.bitmapData.copyPixels( bmd, new Rectangle( 0, 0, bmd.width, bmd.height ), new Point( 0, 0 ));
        }
    }

}
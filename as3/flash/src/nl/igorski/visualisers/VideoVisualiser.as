package nl.igorski.visualisers {
import com.cheezeworld.utils.KeyCode;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.filters.ColorMatrixFilter;
import flash.geom.Point;
import flash.utils.clearInterval;
import flash.utils.getDefinitionByName;
import flash.utils.setInterval;

import nl.igorski.config.Config;
import nl.igorski.definitions.Videos;
import nl.igorski.events.InputEvent;
import nl.igorski.managers.InputManager;
import nl.igorski.managers.VideoManager;
import nl.igorski.models.vo.VOLive;
import nl.igorski.utils.MathTool;
import nl.igorski.visualisers.base.BaseVisualiser;
import nl.igorski.visualisers.components.videovisualiser.BitmapVideo;
import nl.igorski.visualisers.helpers.ThresholdCalculator;

    public class VideoVisualiser extends BaseVisualiser
    {
        private var video               :BitmapVideo;
        private var videoContainer      :Bitmap;
        private var count               :int = 0;
        private var duration            :Number;

        private var _grayscale          :Boolean = false;
        private var grayscaleFilter     :ColorMatrixFilter;
        
        private var stutterInterval     :uint;
        private var counter             :int;
        private var stutterRestorePoint :Number;
        private var stutterLock         :Boolean = false;
        
        private var thresholdCalculator :ThresholdCalculator;
        private const SCALE             :Number = 1.5;

        private var MASK                :Bitmap = new Bitmap( new VideoMask( 0, 0 ));

        public function VideoVisualiser()
        {
            if ( Config.DEBUG )
                InputManager.INSTANCE.addEventListener( InputEvent.KEY_PRESS, handleKeyboardInput, false, 0, true );

            grayscale           = true;
            thresholdCalculator = new ThresholdCalculator();

            scaleX = scaleY = SCALE;

            MASK.scaleX = 1 / scaleX;
            MASK.scaleY = 1 / scaleY;

            addChild( MASK );

            loadMovie();
        }
        
        public function get grayscale():Boolean
        {
            return _grayscale;
        }
        
        public function set grayscale( value:Boolean ):void
        {
            _grayscale = value;
            
            if ( value )
            {
                if ( grayscaleFilter == null )
                {
                    var b:Number  = 1 / 3;
                    var c:Number  = 1 - ( b * 2 );
                    var m:Array   = [ c, b, b, 0, 0,
                                      b, c, b, 0, 0,
                                      b, b, c, 0, 0,
                                      0, 0, 0, 1, 0 ];
                    
                    grayscaleFilter = new ColorMatrixFilter( m );
                }
                if ( videoContainer != null )
                    videoContainer.filters = [ grayscaleFilter ];
            }
            else {
                if ( videoContainer != null )
                    videoContainer.filters = [];
            }
        }

        private function loadMovie( inCount:int = -1 ):void
        {
            if ( inCount == -1 )
                inCount = ( Videos.videos.length > 1 ) ? MathTool.rand( 0, Videos.videos.length - 1 ) : 0;

            count = inCount;

            // video wasn't cached yet ? cache it to bitmaps
            if ( VideoManager.getVideo( Videos.videos[ count ] ) == null )
            {
                var vidClass:Class = getDefinitionByName( Videos.videos[ count ] ) as Class;
                video = new BitmapVideo( new vidClass());
                video.addEventListener( BitmapVideo.READY, startRender, false, 0, true );
                video.draw();
            }
            // video was cached, retrieve it's contents from the VideoManager
            else {
                video = VideoManager.getVideo( Videos.videos[ count ] );
                startRender( null );
            }
        }
        
        private function startRender( e:Event ):void
        {
            if ( video.hasEventListener( BitmapVideo.READY ))
            {
                video.removeEventListener( BitmapVideo.READY, startRender );
                VideoManager.setVideo( Videos.videos[ count ], video ); // cache video
            }
            duration = video.totalFrames;
            video.currentCount = 0;
            /*
            if ( Config.height > video.height )
            {
                scaleX =
                scaleY = Config.height / video.height;
            }
            */
            if ( videoContainer == null )
            {
                videoContainer = new Bitmap( new BitmapData( 500, 405 ));
                addChild( videoContainer );
                swapChildren( videoContainer, MASK );
            }
            if ( grayscale )
                videoContainer.filters = [ grayscaleFilter ];

            try {
                x = Config.width * .5 - ( video.width * scaleX ) * .5;
                y = Config.height * .5 - ( video.height * scaleY ) * .5;
            } catch( e:Error )
            {
                // most likely on destroy of previous video
            }
            addEventListener( Event.ENTER_FRAME, render );
        }
        
        private function render( e:Event ):void
        {
            if ( !stutterLock )
                ++video.currentCount;
            
            if ( video.currentCount >= video.countMax )
            {
                video.currentCount = 0;
                ++video.currentFrame;
                
                // video reached end, load new
                if ( video.currentFrame > video.totalFrames )
                {
                    removeEventListener( Event.ENTER_FRAME, render );
                    loadMovie();
                    return;
                }
            }
            videoContainer.bitmapData = video.frame.clone();
        }

        private function handleKeyboardInput( e:InputEvent ):void
        {
            if ( e.charCode == KeyCode.SPACEBAR )
                stutter();
        }

        override public function process( data:VOLive ):void
        {
            super.process( data );
            var beat:Boolean = false;

            if ( data.envfollow > -1 )
                beat = thresholdCalculator.measure( data.envfollow );

            grayscale = ( beat ) ? false : true;

            if ( data.playbacksize > -1 )
                video.currentFrame = video.currentFrame + MathTool.scale( data.playbacksize, 127, ( duration - video.currentFrame ));

            if ( data.momsw > -1 )
            {
                if ( !data.momState )
                    clearInterval( stutterInterval );

                if ( data.momState )
                    stutter( data.momIndex );
            }
        }
        
        private function stutter( position:Number = -1 ):void
        {
            if ( stutterLock )
                return;
            
            if ( position < 0 )
                position = video.currentFrame;
            
            clearInterval( stutterInterval );

            counter             = 0;
            stutterLock         = true;
            stutterRestorePoint = video.currentFrame;

            var targetFrame:int = position - 2;
            if ( targetFrame < 0 )
                targetFrame = 0;

            video.currentFrame  = targetFrame;
            stutterInterval     = setInterval( updateStutterProgress, Config.fps / 60 );
        }
        
        private function updateStutterProgress():void
        {
            var targetFrame:int = ( video.currentFrame - 2 + ( counter - stutterRestorePoint ));
            if ( targetFrame < 0 )
                targetFrame = MathTool.rand( 0, 5 );

            video.currentFrame = targetFrame;

            if ( ++counter >= Config.fps * .5 )
            {
                clearInterval( stutterInterval );
                video.currentCount = 0;
                video.currentFrame = stutterRestorePoint;
            }
            else {
                if ( counter > 5 )
                    stutterLock = false;
            }
        }

        override public function destroy():void
        {
            clearInterval( stutterInterval );

            removeEventListener( Event.ENTER_FRAME, render );

            super.destroy();
            /*
             video.destroy(); // CAUTION: clears cached reference !!
             video = null;
            */
            if ( videoContainer != null )
                videoContainer = null;

            thresholdCalculator = null;

            if ( Config.DEBUG )
                InputManager.INSTANCE.removeEventListener( InputEvent.KEY_PRESS, handleKeyboardInput );
        }
    }
}

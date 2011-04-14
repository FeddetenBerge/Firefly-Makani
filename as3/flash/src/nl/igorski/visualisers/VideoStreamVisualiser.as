package nl.igorski.visualisers {
import com.cheezeworld.utils.KeyCode;

import flash.display.DisplayObject;
import flash.events.AsyncErrorEvent;
import flash.events.DataEvent;
import flash.events.NetStatusEvent;
import flash.events.ProgressEvent;
import flash.filters.ColorMatrixFilter;
import flash.media.Video;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.clearInterval;
import flash.utils.setInterval;

import nl.igorski.config.Config;
import nl.igorski.events.InputEvent;
import nl.igorski.managers.InputManager;
import nl.igorski.models.vo.VOLive;
import nl.igorski.utils.MathTool;
import nl.igorski.visualisers.base.BaseVisualiser;
import nl.igorski.visualisers.helpers.ThresholdCalculator;

    public class VideoStreamVisualiser extends BaseVisualiser
    {
        private var videoConnection     :NetConnection = new NetConnection();
        private var loader              :URLLoader = new URLLoader( );
        private var videoStream         :NetStream;
        private var video               :Video;
        private var count               :int = 0;
        private var duration            :Number;
        private var vidArr              :Array = [ 'cpucrawl1.flv', 'cpucrawl2.flv', 'cpucrawl3.flv', 'cpucrawl4.flv',
                                                   'insect.flv', 'insectwalk.flv' ];
        private var vidArrAmbient       :Array = [ 'insectwalk.flv' ];
        private var file                :String = vidArr[0];

        private var _grayscale          :Boolean = false;
        private var grayscaleFilter     :ColorMatrixFilter;

        private var stutterInterval     :uint;
        private var counter      :int;
        private var stutterRestorePoint :Number;
        private var stutterLock         :Boolean = false;

        private var thresholdCalculator :ThresholdCalculator;

        public function VideoStreamVisualiser( ambient:Boolean = false )
        {
            if ( ambient )
                vidArr = vidArrAmbient;

            if ( Config.DEBUG )
                InputManager.INSTANCE.addEventListener( InputEvent.KEY_PRESS, handleKeyboardInput, false, 0, true );

            grayscale           = true;
            thresholdCalculator = new ThresholdCalculator();

            loadMovie( Math.round( Math.random() * 100 ) % vidArr.length );
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
                if ( video != null )
                    video.filters = [ grayscaleFilter ];
            }
            else {
                if ( video != null )
                    video.filters = [];
            }
        }

        private function loadMovie( inCount:int = 0 ):void
        {
            if ( inCount == 0 )
                inCount = count;

            file = 'video/' + vidArr[inCount];

            if ( inCount == vidArr.length - 1 )
            {
                count = 0;
            } else {
                ++count;
            }
            if ( numChildren > 1 )
            {
                var obj:DisplayObject = getChildAt( 0 );
                removeChild( obj );
                obj = null;
            }
            // Listen for the progress event to check download progress
            loader.addEventListener( ProgressEvent.PROGRESS, handleProgress );
            loader.load( new URLRequest(file ));
            videoConnection.connect( null );
            attachStream();
            video = new Video( Config.width, Config.height );
            video.cacheAsBitmap = true;

            if ( grayscale )
                video.filters = [ grayscaleFilter ];

            var client:Object  = new Object();
            client.onMetaData  = onMetaData;
            videoStream.client = client;
            video.attachNetStream( videoStream );
            addChild( video );
        }

        private function attachStream():void
        {
            if ( videoStream != null )
            {
                videoStream.removeEventListener( DataEvent.DATA, onMetaData );
                videoStream.removeEventListener( AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler );
                videoStream.removeEventListener( NetStatusEvent.NET_STATUS, onNetStat );
                videoStream = null;
            }
            videoStream = new NetStream( videoConnection );
            videoStream.addEventListener( DataEvent.DATA, onMetaData, false, 0, true );
            videoStream.addEventListener( AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler, false, 0, true );
            videoStream.addEventListener( NetStatusEvent.NET_STATUS, onNetStat, false, 0, true );
        }

        private function asyncErrorHandler( e:AsyncErrorEvent ):void
        {
            //trace( e.text );
        }

        private function handleProgress( e:ProgressEvent ):void
        {
            var percent:Number = Math.round( e.bytesLoaded / e.bytesTotal * 100 );

            if ( percent == 100 )
                playFLV();
        }

        private function playFLV():void
        {
            videoStream.play( file );
        }

        private function onMetaData( data:Object ):void
        {
            duration = data.duration;
    //			trace('filmlengte => ' + duration);
        }

        private function onNetStat( stats:NetStatusEvent ):void
        {
    //			trace(stats.info.code);
            if ( stats.info.code == "NetStream.Play.Stop" )
            {
                videoStream.pause();
                videoStream.seek( 0 );
                loadMovie();
            }
        }

        private function handleKeyboardInput( e:InputEvent ):void
        {
            if ( e.charCode == KeyCode.SPACEBAR )
                stutter();
        }

        override public function process( data:VOLive ):void
        {
            super.process( data );

            if ( data.envfollow > -1 )
                var beat:Boolean = thresholdCalculator.measure( data.envfollow );

            if ( data.playbacksize > -1 )
              //  stutter();
              stutter( videoStream.time + MathTool.scale( data.playbacksize, 127, ( duration - videoStream.time ) * .1 ));

            if ( data.playbackspeed > -1 )
            {
                grayscale = ( data.playbackspeed > thresholdCalculator.average ) ? false : true;
            }
            else {
                grayscale = true;
            }
        }

        private function stutter( position:Number = -1 ):void
        {
            if ( stutterLock )
                return;

            if ( position < 0 )
                position = videoStream.time;

            clearInterval( stutterInterval );
            counter      = 0;
            stutterLock         = true;
            stutterRestorePoint = videoStream.time;

            videoStream.seek( position - 2 );
            stutterInterval = setInterval( updateStutterProgress, 1 / Config.fps );
        }

        private function updateStutterProgress():void
        {
            videoStream.seek( videoStream.time - ( Config.fps * .5 ) + counter );

            if ( ++counter >= Config.fps * .5 )
            {
                clearInterval( stutterInterval );
                videoStream.seek( stutterRestorePoint );
            }
            else {
                if ( counter > 5 )
                    stutterLock = false;
            }
        }

        override public function destroy():void
        {
            clearInterval( stutterInterval );

            video           = null;
            videoConnection.close();
            videoStream.close();
            videoConnection = null;

            if ( videoStream != null )
            {
                videoStream.removeEventListener( DataEvent.DATA, onMetaData );
                videoStream.removeEventListener( AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler );
                videoStream.removeEventListener( NetStatusEvent.NET_STATUS, onNetStat );
                videoStream = null;
            }

            thresholdCalculator = null;

            if ( Config.DEBUG )
                InputManager.INSTANCE.removeEventListener( InputEvent.KEY_PRESS, handleKeyboardInput );

            super.destroy();
        }
    }
}

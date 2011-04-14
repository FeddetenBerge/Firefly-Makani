package nl.igorski
{
import avmplus.getQualifiedClassName;

import avmplus.variableXml;

import com.cheezeworld.utils.KeyCode;

import flash.desktop.NativeApplication;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageDisplayState;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.ui.Mouse;
import flash.utils.getQualifiedClassName;

import nl.igorski.config.Config;
import nl.igorski.definitions.DataChannels;
import nl.igorski.definitions.Videos;
import nl.igorski.definitions.Visualisers;
import nl.igorski.events.InputEvent;
import nl.igorski.events.UDPEvent;
import nl.igorski.managers.InputManager;
import nl.igorski.managers.VideoManager;
import nl.igorski.models.LCProxy;
import nl.igorski.models.vo.VOLive;
import nl.igorski.utils.Debug;
import nl.igorski.utils.MathTool;
import nl.igorski.utils.RandomActionTool;
import nl.igorski.utils.SystemMonitor;
import nl.igorski.utils.events.DebugEvent;
import nl.igorski.visualisers.base.BaseVisualiser;

    /**
     * ...
     * @author Igor Zinken
     */
    [SWF(backgroundColor="#000000", frameRate="60", width="800", height="600")]
    public class App extends Sprite
    {
        private var udp                     :Vector.<LCProxy>;

        private var visualisers             :Array;
        private var visualisationContainer  :Sprite;
        private var rasterContainer         :Sprite;
        private var sm                      :SystemMonitor;

        // internal debug vars ( check Config for full app-wide debug! )
        private var _debugUDP               :Boolean = false;
        private var debugTF                 :TextField;

        private var RAT                     :RandomActionTool;
        private var _doRandom               :Boolean = true;
        private var _precacheVideo          :Boolean = true;

        public function App():void
        {
            if ( stage ) init();
            else addEventListener( Event.ADDED_TO_STAGE, init );
        }

        private function init( e:Event = null ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );

            stage.addEventListener( Event.FULLSCREEN, handleResize );
            stage.addEventListener( Event.RESIZE, handleResize );

            stage.align        = StageAlign.TOP_LEFT;
            stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
            stage.scaleMode    = StageScaleMode.NO_SCALE;

            Mouse.hide();

            Config.fps         = stage.frameRate;

            visualisers        = [];

            visualisationContainer = new Sprite();
            addChild( visualisationContainer );

            rasterContainer = new Sprite();
            rasterContainer.graphics.beginBitmapFill( new Raster( 0, 0 ));
            rasterContainer.graphics.drawRect( 0, 0, Config.width, Config.height );
            rasterContainer.graphics.endFill();
            addChild( rasterContainer );

            if ( _precacheVideo )
            {
                VideoManager.INSTANCE.addEventListener( VideoManager.CACHE_READY, startApp );
                Videos.cacheAll();  // pre-cache all videos
            }
            else {
                startApp( null );
            }
            // debug performance
            if ( Config.DEBUG )
            {
                sm = new SystemMonitor();
                addChild( sm );

                Debug.INSTANCE.addEventListener( DebugEvent.TRACE, handleDebugTrace );
            }
        }

        private function startApp( e:Event ):void
        {
            if ( VideoManager.INSTANCE.hasEventListener( VideoManager.CACHE_READY ))
                VideoManager.INSTANCE.removeEventListener( VideoManager.CACHE_READY, startApp );

            InputManager.init( stage );
            InputManager.INSTANCE.addEventListener( InputEvent.KEY_PRESS, handleKeyboardInput );

            createUDPconnections();

            // RAT = new RandomActionTool( 0.05, 0.05, [ 10, 5000 ]);

            // start visualisation
            toggleVisualisation( Visualisers.PHOTO_SPLITTER );
        }

        private function createUDPconnections():void
        {
            udp = new Vector.<LCProxy>();

            for each( var channel:Object in DataChannels.channels )
            {
                var udpChannel:LCProxy = new LCProxy( channel.name );
                udpChannel.addEventListener( UDPEvent.DATA, handleUDPdata );

                if ( Config.DEBUG )
                    udpChannel.addEventListener( UDPEvent.STATE, handleUDPDebug );

                udp.push( udpChannel );
                udpChannel.connect();
            }
        }

        private function toggleVisualisation( visualiserType:String, clearAll:Boolean = false ):void
        {
            var visualiser:BaseVisualiser;
            var existed   :Boolean = false;

            // check if existed => if so remove
            if ( visualisers.length > 0 )
            {
                for ( var i:int = visualisers.length - 1; i >= 0; --i )
                {
                    if ( getQualifiedClassName( visualisers[i] ) == visualiserType )
                    {
                        visualisers[i].destroy();
                        visualisationContainer.removeChild( visualisers[i] );
                        visualisers[i] = null;
                        visualisers.splice( i, 1 );
                        existed = true;
                    }
                }
            }
            if ( clearAll && !existed )
                clearAllVisualisers();

            if ( clearAll && existed )
                return;

            if ( !existed )
            {
                visualiser = Visualisers.getVisualiser( visualiserType );
                visualisers.push( visualiser );
                visualisationContainer.addChild( visualiser );
            }
            for ( i = 0; i < visualisers.length; ++i )
                visualisationContainer.swapChildren( visualisers[i], visualisationContainer.getChildAt( visualisationContainer.numChildren - 1 ));
        }

        private function switchVisualiserByRandom():void
        {
            var visualiserType:String = "";
            var list          :Array  = Visualisers.getRandomVisualiserList();

            // if a visualiser is running, double check we're not replacing it
            // by the same visualiser ( which would essentially create a blank screen )
            if ( visualisers.length > 0 )
            {
                visualiserType = list[ MathTool.rand( 0, list.length - 1 )];
                while( visualiserType == visualisers[0] )
                    visualiserType = list[ MathTool.rand( 0, list.length - 1 ) ];
            }
            else {
                visualiserType = list[ MathTool.rand( 0, list.length - 1 )];
            }
            toggleVisualisation( visualiserType, true );
        }

        private function switchVisualiserGoNext():void
        {
            if ( visualisers.length == 0 )
            {
                switchVisualiserByRandom();
                return;
            }
            var current:String = getQualifiedClassName( visualisers[0] );
            if ( current == Visualisers.PHOTO_SPLITTER )
            {
                switchVisualiserByRandom();
                return;
            }
            var list:Array  = Visualisers.getRandomVisualiserList();

            for ( var i:uint = 0, j:uint = list.length; i < j; ++i )
            {
                if ( list[i] == current )
                {
                    if ( i < j - 1 )
                        toggleVisualisation( list[i + 1 ], true );
                    else
                        toggleVisualisation( list[0], true );
                }
            }
        }

        private function clearAllVisualisers():void
        {
            if ( visualisers.length > 0 )
            {
                for ( var i:int = visualisers.length - 1; i >= 0; --i )
                {
                    visualisers[i].destroy();
                    visualisationContainer.removeChild( visualisers[i] );
                    visualisers[i] = null;
                    visualisers.splice( i, 1 );
                }
            }
        }

        private function handleUDPdata( e:UDPEvent ):void
        {
            if ( _debugUDP )
                debugTrace( e.target.connectionName + "::" + e.value + "\n" );

            var vo      :VOLive  = new VOLive( e.value );
            var i       :uint    = visualisers.length;
            var special :Boolean = false;

            // randomly trigger visualisations
            /*
            if ( _doRandom && vo.envfollow > -1 )
            {
                if ( !RAT.idle )
                {
                    if ( RAT.performAction())
                        switchVisualiserByRandom();
                }
            }*/
            if ( vo.miep > -1 )
            {
                switch( vo.miep )
                {
                    case 1:
                        switchVisualiserGoNext();
                        return;
                        break;
                    case 2:
                        toggleVisualisation( Visualisers.PHOTO_SPLITTER );
                        return;
                        break;
                    case 3:
                        special = true;
                        break;
                }
            }
            while ( --i >= 0 )
            {
                visualisers[i].process( vo );
                if ( special )
                    visualisers[i].special();
            }
        }

        private function handleKeyboardInput( e:InputEvent ):void
        {
            switch( e.charCode )
            {
                default:
                break;
                case KeyCode.ONE:
                    toggleVisualisation( Visualisers.PHOTO_SPLITTER );
                    break;
                case KeyCode.TWO:
                    toggleVisualisation( Visualisers.PIXEL_BLITTER, true );
                    break;
                case KeyCode.THREE:
                    toggleVisualisation( Visualisers.PARTICLE_SYSTEM_WAVES );
                    break;
                case KeyCode.FOUR:
                    toggleVisualisation( Visualisers.PARTICLE_SYSTEM_MAP, true );
                    break;
                case KeyCode.FIVE:
                    toggleVisualisation( Visualisers.PARTICLE_SYSTEM_SHAPES, true );
                    break;
                case KeyCode.SIX:
                    toggleVisualisation( Visualisers.VIDEO_VISUALISER, true );
                    break;
                case KeyCode.SEVEN:
                    toggleVisualisation( Visualisers.PARTICLE_SYSTEM_VIDEO, true );
                    break;
                case KeyCode.EIGHT:
                    toggleVisualisation( Visualisers.PHOTO_TRACER );
                    break;

                /* note the letters might require caps lock... */
                case KeyCode.D:
                    _debugUDP = !_debugUDP;
                    if ( !_debugUDP && debugTF != null )
                        debugTF.text = "";
                    break;

                case KeyCode.F:
                    toggleFullscreen();
                    break;
            }
        }

        /*
         * PRESENTATION
         */
        private function handleResize( e:Event ):void
        {
            Config.width  = stage.stageWidth;
            Config.height = stage.stageHeight;
        }

        private function toggleFullscreen():void
        {
            switch( stage.displayState )
            {
                case StageDisplayState.FULL_SCREEN:
                case StageDisplayState.FULL_SCREEN_INTERACTIVE:
                    stage.displayState = StageDisplayState.NORMAL;
                    break;
                case StageDisplayState.NORMAL:
                    stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
                break;
            }
        }

        private function destroy( e:Event ):void
        {
            trace( "exit application" );

            for each( var udp:LCProxy in udp )
                udp.destroy();
        }

        /*
         *   DEBUG
         */
        private function debugTrace( msg:String ):void
        {
            // don't show envelope follower data
            //if ( msg.indexOf( "envfol") > -1 )
              // return;

            if ( debugTF == null )
                createDebuggerField();

            if ( debugTF.height > ( Config.height - ( debugTF.y + 20 )))
                debugTF.text = "";

            debugTF.appendText( msg );
        }

        private function createDebuggerField():void
        {
            debugTF              = new TextField();

            debugTF.textColor    = 0xFFFFFF;
            debugTF.autoSize     = TextFieldAutoSize.LEFT;
            debugTF.multiline    =
            debugTF.wordWrap     = true;
            debugTF.width        = 500;
            debugTF.height       = 50;
            debugTF.y            = 50;
            debugTF.mouseEnabled = false;

            addChild( debugTF );
        }

        private function handleUDPDebug( e:UDPEvent ):void
        {
            debugTrace( e.value + "\n" );
        }

        private function handleDebugTrace( e:DebugEvent ):void
        {
            debugTrace( e.message + "\n" );
        }
    }
}

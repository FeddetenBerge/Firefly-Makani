package nl.igorski.visualisers 
{
import com.cheezeworld.utils.Input;
import com.cheezeworld.utils.KeyCode;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Shader;
import flash.display.ShaderJob;
import flash.events.Event;
import flash.filters.ShaderFilter;
import flash.geom.Point;
import flash.utils.ByteArray;

import nl.igorski.config.Config;
import nl.igorski.models.vo.VOLive;
import nl.igorski.utils.MathTool;
import nl.igorski.visualisers.base.BaseVisualiser;

    /**
     * ...
     * @author Igor Zinken
     */
    public class PhotoTracer extends BaseVisualiser
    {
        public static const KALEIDOSCOPE    :String = "PhotoTracer::KALEIDOSCOPE";
        public static const MIRROR          :String = "PhotoTracer::MIRROR";
        public static const NONE            :String = "PhotoTracer::NONE";

        private var filterType              :String = MIRROR;

        private var _sourceBD               :BitmapData;
        private var bitmap                  :Bitmap;

        private static const PI_OVER_300    :Number = Math.PI / 300;

        private var shader                  :Shader;
        private var filter                  :ShaderFilter;

        private var angle                   :Number;

        [Embed(source="../../../../lib/pixel bender/kaleidoscope.pbj", mimeType="application/octet-stream")]
        private var kaleidoScopeClass       :Class;
        private var _sections               :uint = 2;

        [Embed(source="../../../../lib/pixel bender/pbDemo2.pbj", mimeType="application/octet-stream")]
        private var mirrorClass             :Class;
        private var _mirrorX                :int;
        private var _mirrorY                :int;

        private var shaderJob               :ShaderJob;


        public function PhotoTracer()
        {
            addEventListener( Event.ADDED_TO_STAGE, init );
        }
        
        private function init( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );

            createFilter( filterType );

            var bmd:BitmapData = new BitmapData( _sourceBD.width, _sourceBD.height, true, 0x00000000 );
            bitmap = new Bitmap( bmd );
            addChild( bitmap );

            x = Config.width * .5 - _sourceBD.width * .5;
            y = Config.height * .5 - _sourceBD.height * .5;

            addEventListener( Event.ENTER_FRAME, render );
        }

        private function createFilter( type:String ):void
        {
            _sourceBD = new FireFly( 0, 0 );

            switch( type )
            {
                case KALEIDOSCOPE:

                    shader = new Shader( new kaleidoScopeClass() as ByteArray );
                    shader.data.originX.value = [ _sourceBD.width * .5 ];
                    shader.data.originY.value = [ _sourceBD.height * .5 ];
                    shader.data.sections.value = [ _sections ];
                    shader.data.maxRadius.value = [ ( _sourceBD.width - 20 ) * .5 ];
                    filter = new ShaderFilter( shader );
                    angle = 0;
                    break;

                case MIRROR:

                    shader = new Shader( new mirrorClass() as ByteArray );
                    shader.data.src.input = _sourceBD;
                    _mirrorX =
                    _mirrorY = 0;
                    break;

                default:

                    shader = null;
                    filter = null;
                    break;
            }
        }

        private function render( e:Event ):void
        {
            if ( Config.DEBUG )
                handleInput();

            switch( filterType )
            {
                case KALEIDOSCOPE:

                    shader.data.reflectionAngle.value = [angle];
                    filter = new ShaderFilter( shader );
                    bitmap.bitmapData.applyFilter( _sourceBD, _sourceBD.rect, new Point(), filter );
                    angle += PI_OVER_300;
                    break;

                case MIRROR:

                    shader.data.xval.value = [ _mirrorX ];
                    shader.data.yval.value = [ _mirrorY ];
                    shaderJob = new ShaderJob( shader, bitmap.bitmapData );
                    shaderJob.start();

                    break;
            }
        }

        private function handleInput():void
        {
            if ( Input.instance.isKeyDown( KeyCode.SPACEBAR ))
            {
                filterType = ( filterType == KALEIDOSCOPE ) ? MIRROR : KALEIDOSCOPE;
                createFilter( filterType );
            }
            if ( Input.instance.isKeyDown( KeyCode.UP )) {
                if ( filterType == KALEIDOSCOPE )
                    shader.data.sections.value = [ ++_sections ];
                else if ( filterType == MIRROR && _mirrorX < 5 )
                    ++_mirrorX;
            }
            if ( Input.instance.isKeyDown( KeyCode.DOWN )) {
                if ( filterType == KALEIDOSCOPE && _sections > 1 )
                    shader.data.sections.value = [ --_sections ];
                else if ( filterType == MIRROR )
                    --_mirrorX;
            }
            if ( Input.instance.isKeyDown( KeyCode.LEFT )) {
                angle -= PI_OVER_300;
            }
            if ( Input.instance.isKeyDown( KeyCode.RIGHT )) {
                angle += PI_OVER_300;

            }
        }

        override public function process( data:VOLive ):void
        {
            super.process( data );

            if ( data.playbacksize > - 1 )
            {
                 if ( filterType == KALEIDOSCOPE )
                 {
                     shader.data.sections.value = [ 1 + MathTool.scale( data.playbacksize, 127, 30 ) ];
                 }
                 else if ( filterType == MIRROR )
                 {
                     _mirrorX = MathTool.scale( data.playbacksize, 127, Config.width / _sourceBD.width );
                     _mirrorY = MathTool.scale( data.playbacksize, 127, Config.height / _sourceBD.height );
                 }
            }
        }
        
        override public function destroy():void
        {
            removeEventListener( Event.ENTER_FRAME, render );
            
            _sourceBD.dispose();
            bitmap.bitmapData.dispose();

            shader = null;
            filter = null;

            super.destroy();
        }
    }
}

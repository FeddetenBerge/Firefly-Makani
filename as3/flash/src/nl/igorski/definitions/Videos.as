/**
 * Created by IntelliJ IDEA.
 * User: igor.zinken
 * Date: 17-3-11
 * Time: 16:13
 * To change this template use File | Settings | File Templates.
 */
package nl.igorski.definitions
{
import flash.events.Event;

import flash.utils.getDefinitionByName;

import nl.igorski.managers.VideoManager;
import nl.igorski.visualisers.components.videovisualiser.BitmapVideo;

public class Videos
    {
        /*
         * we add the class reference in this list
         * so the embedded SWC gets compiled with the app
         */
        public static const _videos     :Array = [
                                                    { name: "CPU_Crawl_1", classReference: CPU_Crawl_1 },
                                                    { name: "CPU_Crawl_2", classReference: CPU_Crawl_2 },
                                                    { name: "CPU_Crawl_3", classReference: CPU_Crawl_3 },
                                                    { name: "CPU_Crawl_4", classReference: CPU_Crawl_4 }
                                                 ];

        private static var _cacheIndex      :int = 0;

        public function Videos()
        {
            throw new Error( "cannot instantiate Videos" );
        }

        public static function get videos():Array
        {
            var out:Array = [];

            for each( var o:Object in _videos )
                out.push( o.name );

            return out;
        }

        /*
         * it's possible to pre-cache all videos before use
         * this will increase app start up time, but
         * will benefit in later performance
         */
        public static function cacheAll():void
        {
            var vidClass:Class = getDefinitionByName( Object( _videos[ _cacheIndex ] ).name ) as Class;
            var video:BitmapVideo = new BitmapVideo( new vidClass());
            video.addEventListener( BitmapVideo.READY, cacheNext, false, 0, true );
            video.draw();
        }

        private static function cacheNext( e:Event ):void
        {
            BitmapVideo( e.target ).removeEventListener( BitmapVideo.READY, cacheNext );
            VideoManager.setVideo( Object( _videos[ _cacheIndex ] ).name, e.target as BitmapVideo );
            ++_cacheIndex;

            if ( _cacheIndex < _videos.length )
                cacheAll();
            else
                VideoManager.INSTANCE.dispatchEvent( new Event( VideoManager.CACHE_READY ));
        }
    }
}

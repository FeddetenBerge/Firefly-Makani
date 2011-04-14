/**
 * Created by IntelliJ IDEA.
 * User: igor.zinken
 * Date: 17-3-11
 * Time: 15:30
 * To change this template use File | Settings | File Templates.
 */
package nl.igorski.managers
{
import flash.events.EventDispatcher;

import nl.igorski.visualisers.components.videovisualiser.BitmapVideo;
    /*
     * stores cached video for re-use
     * without the need for recaching
     */
    public class VideoManager extends EventDispatcher
    {
        public static const CACHE_READY :String = "VideoManager::CACHE_READY";
        public static var INSTANCE      :VideoManager = new VideoManager();

        private var videoData           :Vector.<BitmapVideo>;
        private var videos              :Vector.<Object>;

        public function VideoManager()
        {
            videoData = new Vector.<BitmapVideo>();
            videos    = new Vector.<Object>();
        }

        public static function setVideo( videoName:String, videoData:BitmapVideo ):void
        {
            INSTANCE.videoData.push( videoData );
            INSTANCE.videos.push( { name: videoName, index: INSTANCE.videoData.length - 1 });
        }

        public static function getVideo( videoName:String ):BitmapVideo
        {
            for each( var o:Object in INSTANCE.videos )
            {
                if ( o.name == videoName )
                    return INSTANCE.videoData[ o.index ];
            }
            return null;
        }
        /*
         * remove all cached videos
         */
        public static function flush():void
        {
            INSTANCE.videos = new Vector.<Object>();

            for ( var i:uint = INSTANCE.videoData.length - 1; i > 0; --i )
            {
                BitmapVideo( INSTANCE.videoData[i] ).destroy();
                INSTANCE.videoData.splice( i, 1 );
            }
            INSTANCE.videoData = new Vector.<BitmapVideo>();
        }
    }
}

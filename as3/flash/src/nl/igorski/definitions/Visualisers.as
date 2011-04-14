package nl.igorski.definitions 
{
import avmplus.getQualifiedClassName;
import avmplus.getQualifiedClassName;

import flash.utils.getDefinitionByName;

import flash.utils.getQualifiedClassName;

import nl.igorski.visualisers.ParticleSystemImageMap;
import nl.igorski.visualisers.ParticleSystemShapes;
import nl.igorski.visualisers.ParticleSystemVideo;
import nl.igorski.visualisers.ParticleSystemWaves;
import nl.igorski.visualisers.base.BaseVisualiser;
    import nl.igorski.visualisers.ParticleSystem;
    import nl.igorski.visualisers.PhotoRippler;
    import nl.igorski.visualisers.PhotoSplitter;
    import nl.igorski.visualisers.PhotoTracer;
    import nl.igorski.visualisers.PixelBlitter;
    import nl.igorski.visualisers.Tentacles;
    import nl.igorski.visualisers.VideoVisualiser;
	/**
     * ...
     * @author Igor Zinken
     */
    public class Visualisers 
    {
        public static const PARTICLE_SYSTEM         :String = getQualifiedClassName( ParticleSystem );
        public static const PARTICLE_SYSTEM_SHAPES  :String = getQualifiedClassName( ParticleSystemShapes );
        public static const PARTICLE_SYSTEM_WAVES   :String = getQualifiedClassName( ParticleSystemWaves );
        public static const PARTICLE_SYSTEM_MAP     :String = getQualifiedClassName( ParticleSystemImageMap );
        public static const PARTICLE_SYSTEM_VIDEO   :String = getQualifiedClassName( ParticleSystemVideo );
        public static const PHOTO_RIPPLER           :String = getQualifiedClassName( PhotoRippler );
        public static const PHOTO_SPLITTER          :String = getQualifiedClassName( PhotoSplitter );
        public static const PHOTO_TRACER            :String = getQualifiedClassName( PhotoTracer );
        public static const PIXEL_BLITTER           :String = getQualifiedClassName( PixelBlitter );
        public static const TENTACLES               :String = getQualifiedClassName( Tentacles );
        public static const VIDEO_VISUALISER        :String = getQualifiedClassName( VideoVisualiser );
        
        private static const MAPPING        :Array = [ 
                                                        { type: PARTICLE_SYSTEM, visualiser: ParticleSystem },
                                                        { type: PARTICLE_SYSTEM_SHAPES, visualiser: ParticleSystemShapes },
                                                        { type: PARTICLE_SYSTEM_WAVES, visualiser: ParticleSystemWaves },
                                                        { type: PARTICLE_SYSTEM_VIDEO, visualiser: ParticleSystemVideo },
                                                        { type: PARTICLE_SYSTEM_MAP, visualiser: ParticleSystemImageMap },
                                                        { type: PHOTO_RIPPLER,   visualiser: PhotoRippler },
                                                        { type: PHOTO_SPLITTER,  visualiser: PhotoSplitter },
                                                        { type: PHOTO_TRACER,    visualiser: PhotoTracer },
                                                        { type: PIXEL_BLITTER,   visualiser: PixelBlitter },
                                                        { type: TENTACLES,       visualiser: Tentacles },
                                                        { type: VIDEO_VISUALISER,visualiser: VideoVisualiser }
                                                     ];
        
        public function Visualisers() 
        {
            
        }
        
        public static function getVisualiser( visualiserType:String ):BaseVisualiser
        {
            for each( var o:Object in MAPPING )
            {
                if ( o.type == visualiserType )
                    return new o.visualiser() as BaseVisualiser;
            }
            return null;
          //  return getDefinitionByName( visualiserType ) as BaseVisualiser;
        }

        /*
         * returns the visualisers which are available
         * for the randomAction switching
         */
        public static function getRandomVisualiserList():Array
        {
            return [
                        PARTICLE_SYSTEM_MAP,
                        PARTICLE_SYSTEM_SHAPES,
                        PARTICLE_SYSTEM_WAVES,
                        PIXEL_BLITTER,
                        PHOTO_RIPPLER,
                        VIDEO_VISUALISER
                   ];
        }
    }
}

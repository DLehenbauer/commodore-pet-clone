/**
 * PET Clone - Open hardware implementation of the Commodore PET
 * by Daniel Lehenbauer (and contributors).
 * 
 * https://github.com/DLehenbauer/commodore-pet-clone
 *
 * To the extent possible under law, I, Daniel Lehenbauer, have waived all
 * copyright and related or neighboring rights to this project. This work is
 * published from the United States.
 *
 * @copyright CC0 http://creativecommons.org/publicdomain/zero/1.0/
 * @author Daniel Lehenbauer <DLehenbauer@users.noreply.github.com> and contributors
 */

#include "pch.hpp"
#pragma once

class CDisplay {
    public:
        CDisplay(
            const uint8_t* const pCharRom,
            const size_t charRomByteSize,
            const uint8_t* const pCharRomPage,
            const uint8_t* const pVideoMemory,
            const uint8_t* const pCrtcRegs,
            uint8_t keyMatrix[10]
        );
        
        void update();

        volatile static unsigned s_funcKey;

    private:
        void keyDown(SDL_Keysym key);
        void keyUp(SDL_Keysym key);
        void traceKey(const char* eventName, const unsigned char scanCode, const uint8_t row, const uint8_t colMask);

        unsigned get_crtc_horizontal_total();
        unsigned get_crtc_horizontal_displayed();
        unsigned get_crtc_horizontal_sync_position();
        unsigned get_crtc_horizontal_sync_width();
        unsigned get_crtc_vertical_total();
        unsigned get_crtc_vertical_total_adjust();
        unsigned get_crtc_vertical_displayed();
        unsigned get_crtc_vertical_sync_position();
        unsigned get_crtc_interlace_mode_and_skew();
        unsigned get_crtc_maximum_raster_address();
        unsigned get_crtc_display_start_address();

        SDL_Window* pWindow = nullptr;
        SDL_Renderer* pRenderer = nullptr;
        SDL_Texture* pTargetTex = nullptr;
        SDL_Texture* pCharTexs[2] = { nullptr, nullptr };
        
        const uint8_t* pCharRomPage;
        const uint8_t* const pVideoMemory;
        const uint8_t* const pCrtcRegs;
        uint8_t* const keyMatrix;
};

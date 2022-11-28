#include "../pch.h"
#include "../global.h"
#include "dvi.h"

#define FONT_CHAR_WIDTH 8
#define FONT_CHAR_HEIGHT 8

// 720x480p @ 60 Hz (270 MHz)
// Required by CEA for EDTV/HDTV displays.
const struct dvi_timing __not_in_flash_func(dvi_timing_720x480p_60hz) = {
	.h_sync_polarity   = false,
	.h_front_porch     = 16,
	.h_sync_width      = 62,
	.h_back_porch      = 60,
	.h_active_pixels   = 720,

	.v_sync_polarity   = false,
	.v_front_porch     = 9,
	.v_sync_width      = 6,
	.v_back_porch      = 30,
	.v_active_lines    = 480,

	.bit_clk_khz       = 270000
};

// For Monochrome:
//    # target_compile_definitions(firmware PRIVATE
//    #     DVI_VERTICAL_REPEAT=1
//    #     DVI_N_TMDS_BUFFERS=3
//    #     DVI_1BPP_BIT_REVERSE=1
//    #     DVI_MONOCHROME_TMDS)
//
// #define FRAME_WIDTH 720
// #define FRAME_HEIGHT 480
// #define DVI_TIMING dvi_timing_720x480p_60hz
// #define OFFSET_X 20
// #define OFFSET_Y 20

#define FRAME_WIDTH 360
#define FRAME_HEIGHT 240
#define DVI_TIMING dvi_timing_720x480p_60hz
#define OFFSET_X 20
#define OFFSET_Y 20

// #define FRAME_WIDTH 320
// #define FRAME_HEIGHT 240
// #define DVI_TIMING dvi_timing_640x480p_60hz
// #define OFFSET_X 0
// #define OFFSET_Y 0

#define VREG_VSEL VREG_VOLTAGE_1_20

struct dvi_inst dvi0;
struct semaphore dvi_start_sem;

#define CHAR_COLS 40
#define CHAR_ROWS 25

static inline uint16_t __not_in_flash_func(stretch_x)(uint16_t x) {
    x = (x | (x << 4)) & 0x0F0F;
    x = (x | (x << 2)) & 0x3333;
    x = (x | (x << 1)) & 0x5555;

    return x | (x << 1);
}

static inline void __not_in_flash_func(encode_1bpp)(const uint8_t* scanline_1bpp) {
	uint32_t* tmdsbuf;
	queue_remove_blocking(&dvi0.q_tmds_free, &tmdsbuf);
	tmds_encode_1bpp((const uint32_t*) scanline_1bpp, tmdsbuf, FRAME_WIDTH);
	queue_add_blocking(&dvi0.q_tmds_valid, &tmdsbuf);
}

// // Note: 'encode_rgb332' only appears to work if a single bit is set or all bits (white).
// static inline void __not_in_flash_func(encode_rgb332)(const uint8_t* rgb332_scanline) {
//     const uint32_t* scanbuf = (const uint32_t*) rgb332_scanline;

// 	   uint32_t *tmdsbuf;
// 	   queue_remove_blocking_u32(&dvi0.q_tmds_free, &tmdsbuf);
	
// 	   tmds_encode_data_channel_8bpp(
//            /* pixbuf: */ scanbuf,
//            /* symbuf: */ tmdsbuf,                              /* = tmdsbuf + 0 * h_active_pixels / DVI_SYMBOLS_PER_WORD */
//            /* n_pix: */ FRAME_WIDTH,
//            /* BLUE_MSB: */ 1,
//            /* BLUE_LSB: */ 0);
	
//     tmds_encode_data_channel_8bpp(
//         /* pixbuf: */ scanbuf,
//         /* symbuf: */ tmdsbuf + FRAME_WIDTH,                /* = tmdsbuf + 1 * h_active_pixels / DVI_SYMBOLS_PER_WORD */
//         /* n_pix: */ FRAME_WIDTH,
//         /* GREEN_MSB: */ 4,
//         /* GREEN_LSB: */ 2);

// 	   tmds_encode_data_channel_8bpp(
//            /* pixbuf: */ scanbuf,
//            /* symbuf: */ tmdsbuf + FRAME_WIDTH + FRAME_WIDTH,  /* = tmdsbuf + 2 * h_active_pixels / DVI_SYMBOLS_PER_WORD */
//            /* n_pix: */ FRAME_WIDTH,
//            /* RED_MSB: */ 7,
//            /* RED_LSB: */ 5);

// 	   queue_add_blocking_u32(&dvi0.q_tmds_valid, &tmdsbuf);
// }

static inline void __not_in_flash_func(encode_rgb565)(const uint16_t* rgb565_scanline) {
    const uint32_t* scanbuf = (const uint32_t*) rgb565_scanline;

	uint32_t *tmdsbuf;
	queue_remove_blocking_u32(&dvi0.q_tmds_free, &tmdsbuf);
	
	tmds_encode_data_channel_16bpp(
        /* pixbuf: */ scanbuf,
        /* symbuf: */ tmdsbuf,                              /* = tmdsbuf + 0 * h_active_pixels / DVI_SYMBOLS_PER_WORD */
        /* n_pix: */ FRAME_WIDTH,
        /* BLUE_MSB: */ 4,
        /* BLUE_LSB: */ 0);
	
    tmds_encode_data_channel_16bpp(
        /* pixbuf: */ scanbuf,
        /* symbuf: */ tmdsbuf + FRAME_WIDTH,                /* = tmdsbuf + 1 * h_active_pixels / DVI_SYMBOLS_PER_WORD */
        /* n_pix: */ FRAME_WIDTH,
        /* GREEN_MSB: */ 10,
        /* GREEN_LSB: */ 5);

	tmds_encode_data_channel_16bpp(
        /* pixbuf: */ scanbuf,
        /* symbuf: */ tmdsbuf + FRAME_WIDTH + FRAME_WIDTH,  /* = tmdsbuf + 2 * h_active_pixels / DVI_SYMBOLS_PER_WORD */
        /* n_pix: */ FRAME_WIDTH,
        /* RED_MSB: */ 15,
        /* RED_LSB: */ 11);

	queue_add_blocking_u32(&dvi0.q_tmds_valid, &tmdsbuf);
}

/*
static inline void prepare_scanline(const char *chars, int y) {
	static uint8_t scanline[FRAME_WIDTH / 8];

    y -= 40;

    if (y < 0 || y >= 400) {
        memset(scanline, 0, sizeof(scanline));
    } else {
        y >>= 1;

        // First blit font into 1bpp scanline buffer, then encode scanline into tmdsbuf
        for (uint i = 0, x = 5; i < CHAR_COLS; i++) {
            uint c = chars[i + y / FONT_CHAR_HEIGHT * CHAR_COLS];
            
            bool reverse = c & 0x80;
            c &= 0x7f;

            uint8_t p8 = p_video_font[c * FONT_CHAR_HEIGHT + (y % FONT_CHAR_HEIGHT)];
            if (reverse) {
                p8 ^= 0xff;
            }
            
            const uint16_t p16 = stretch_x(p8);
            scanline[x++] = p16 >> 8;
            scanline[x++] = p16 & 0xff;
    	}
    }

    encode_1bpp(scanline);
}
*/

static inline void __not_in_flash_func(prepare_scanline)(const char *chars, int16_t y) {
	static uint16_t __attribute__((aligned(4))) scanline[FRAME_WIDTH];

    y -= OFFSET_Y;

    if (y < 0 || y >= 200) {
        memset(scanline, 0x00, sizeof(scanline));
    } else {
        uint16_t x = OFFSET_X;

        for (uint8_t col = 0; col < CHAR_COLS; col++) {
            char ch = chars[col + y / FONT_CHAR_HEIGHT * CHAR_COLS];
            
            bool reverse = ch & 0x80;
            ch &= 0x7f;

            uint8_t p8 = p_video_font[ch * FONT_CHAR_HEIGHT + (y % FONT_CHAR_HEIGHT)];
            if (reverse) {
                p8 ^= 0xff;
            }

            const uint16_t fg = 0x07e4;
            const uint16_t bg = 0x0000;

            scanline[x++] = (p8 & 0x80) ? fg : bg;
            scanline[x++] = (p8 & 0x40) ? fg : bg;
            scanline[x++] = (p8 & 0x20) ? fg : bg;
            scanline[x++] = (p8 & 0x10) ? fg : bg;
            scanline[x++] = (p8 & 0x08) ? fg : bg;
            scanline[x++] = (p8 & 0x04) ? fg : bg;
            scanline[x++] = (p8 & 0x02) ? fg : bg;
            scanline[x++] = (p8 & 0x01) ? fg : bg;
    	}
    }

    encode_rgb565(scanline);
}

void __not_in_flash_func(core1_scanline_callback)() {
    static uint y = 1;
	prepare_scanline(video_char_buffer, y);
	y = (y + 1) % FRAME_HEIGHT;
}

void core1_main() {
	dvi_register_irqs_this_core(&dvi0, DMA_IRQ_0);
	sem_acquire_blocking(&dvi_start_sem);
	dvi_start(&dvi0);

	// The text display is completely IRQ driven.
	while (1) 
		__wfi();
	__builtin_unreachable();
}

void video_init() {
	vreg_set_voltage(VREG_VSEL);
	sleep_ms(10);
 	set_sys_clock_khz(DVI_TIMING.bit_clk_khz, true);

	setup_default_uart();

	printf("Configuring DVI\n");

	dvi0.timing = &DVI_TIMING;
	dvi0.ser_cfg = DVI_DEFAULT_SERIAL_CONFIG;
	dvi0.scanline_callback = core1_scanline_callback;
	dvi_init(&dvi0, next_striped_spin_lock_num(), next_striped_spin_lock_num());

	printf("Prepare first scanline\n");
    memset(video_char_buffer, 0, sizeof(video_char_buffer));
	prepare_scanline(video_char_buffer, 0);

	printf("Core 1 start\n");
	sem_init(&dvi_start_sem, 0, 1);
	hw_set_bits(&bus_ctrl_hw->priority, BUSCTRL_BUS_PRIORITY_PROC1_BITS);
	multicore_launch_core1(core1_main);
	sem_release(&dvi_start_sem);
}

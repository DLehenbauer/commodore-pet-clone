#include "../pch.h"
#include "dvi.h"

uint8_t const* font_8x8;
#define FONT_CHAR_WIDTH 8
#define FONT_CHAR_HEIGHT 8
#define FONT_N_CHARS 95
#define FONT_FIRST_ASCII 32

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

#define FRAME_WIDTH 720
#define FRAME_HEIGHT 480
#define VREG_VSEL VREG_VOLTAGE_1_20
#define DVI_TIMING dvi_timing_720x480p_60hz

struct dvi_inst dvi0;
struct semaphore dvi_start_sem;

#define CHAR_COLS 40
#define CHAR_ROWS 25
char charbuf[CHAR_ROWS * CHAR_COLS];

static inline uint16_t stretch_x(uint16_t x) {
    x = (x | (x << 4)) & 0x0F0F;
    x = (x | (x << 2)) & 0x3333;
    x = (x | (x << 1)) & 0x5555;

    return x | (x << 1);
}

static inline void prepare_scanline(const char *chars, int y) {
	static uint8_t scanbuf[FRAME_WIDTH / 8];

    y -= 40;

    if (y < 0 || y >= 400) {
        memset(scanbuf, 0, sizeof(scanbuf));
    } else {
        y >>= 1;

        // First blit font into 1bpp scanline buffer, then encode scanbuf into tmdsbuf
        for (uint i = 0, x = 5; i < CHAR_COLS; i++) {
            uint c = chars[i + y / FONT_CHAR_HEIGHT * CHAR_COLS];
            
            bool reverse = c & 0x80;
            c &= 0x7f;

            uint8_t p8 = font_8x8[c * FONT_CHAR_HEIGHT + (y % FONT_CHAR_HEIGHT)];
            if (reverse) {
                p8 ^= 0xff;
            }
            
            const uint16_t p16 = stretch_x(p8);
            scanbuf[x++] = p16 >> 8;
            scanbuf[x++] = p16 & 0xff;
    	}
    }

	uint32_t *tmdsbuf;
	queue_remove_blocking(&dvi0.q_tmds_free, &tmdsbuf);
	tmds_encode_1bpp((const uint32_t*)scanbuf, tmdsbuf, FRAME_WIDTH);
	queue_add_blocking(&dvi0.q_tmds_valid, &tmdsbuf);
}

void core1_scanline_callback() {
    static uint y = 1;
	prepare_scanline(charbuf, y);
	y = (y + 1) % FRAME_HEIGHT;
}

void __not_in_flash("main") core1_main() {
	dvi_register_irqs_this_core(&dvi0, DMA_IRQ_0);
	sem_acquire_blocking(&dvi_start_sem);
	dvi_start(&dvi0);

	// The text display is completely IRQ driven (takes up around 30% of cycles @
	// VGA). We could do something useful, or we could just take a nice nap
	while (1) 
		__wfi();
	__builtin_unreachable();
}

uint8_t* __not_in_flash("main") video_init(uint8_t const* p_char_rom) {
	font_8x8 = p_char_rom;

	vreg_set_voltage(VREG_VSEL);
	sleep_ms(10);
#ifdef RUN_FROM_CRYSTAL
	set_sys_clock_khz(12000, true);
#else
	// Run system at TMDS bit clock
	set_sys_clock_khz(DVI_TIMING.bit_clk_khz, true);
#endif

	setup_default_uart();

	printf("Configuring DVI\n");

	dvi0.timing = &DVI_TIMING;
	dvi0.ser_cfg = DVI_DEFAULT_SERIAL_CONFIG;
	dvi0.scanline_callback = core1_scanline_callback;
	dvi_init(&dvi0, next_striped_spin_lock_num(), next_striped_spin_lock_num());

	printf("Prepare first scanline\n");
	for (int i = 0; i < CHAR_ROWS * CHAR_COLS; ++i)
		charbuf[i] = FONT_FIRST_ASCII + i % FONT_N_CHARS;
	prepare_scanline(charbuf, 0);

	printf("Core 1 start\n");
	sem_init(&dvi_start_sem, 0, 1);
	hw_set_bits(&bus_ctrl_hw->priority, BUSCTRL_BUS_PRIORITY_PROC1_BITS);
	multicore_launch_core1(core1_main);
	sem_release(&dvi_start_sem);

    return charbuf;
}

#include "global.h"
#include "roms.h"

uint8_t key_matrix[10] = {
    /* row 0: */ 0xff,
    /* row 1: */ 0xff,
    /* row 2: */ 0xff,
    /* row 3: */ 0xff,
    /* row 4: */ 0xff,
    /* row 5: */ 0xff,
    /* row 6: */ 0xff,
    /* row 7: */ 0xff,
    /* row 8: */ 0xff,
    /* row 9: */ 0xff,
};

uint8_t video_char_buffer[VIDEO_CHAR_BUFFER_BYTE_SIZE];

uint8_t const* p_video_font;

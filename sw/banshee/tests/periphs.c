#include "runtime.h"

int main(uint32_t core_id, uint32_t core_num) {
    if (!core_id) {
        volatile uint8_t * p1 = (uint8_t *) 0x100000;
        volatile uint16_t * p2 = (uint16_t *) 0x100004;
        uint8_t x = *p1;
        *p2 = 0xCAFE;
    }
    return 0;
}

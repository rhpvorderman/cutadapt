#include <stdint.h>
#include <stddef.h>

#define A0 3564549947590ULL
#define A1_FACTOR 2098295387321ULL
#define A2_FACTOR 1631491391917ULL
#define B0 0ULL
#define B1_FACTOR 2645410211122869ULL
#define B2_FACTOR 2060128921258838ULL
#define EXPONENT_SHIFT 52ULL

static inline double 
approx_expected_errors(uint8_t *phreds, size_t phreds_length) {
    uint8_t *end_ptr = phreds + phreds_length;
    uint8_t *cursor = phreds;
    union {
        double f;
        uint64_t i;
    } prob;
    double expected_errors = 0.0;

    while (cursor < end_ptr) {
        uint64_t phred = *cursor - 33;
        if (phred > 93) {
            return -1.0;
        }
        uint64_t exp = 1023 - ((phred + 2) / 3);
        uint64_t mod = phred % 3;
        uint64_t a = A0 + mod * A1_FACTOR - (mod & 2) * A2_FACTOR;
        uint64_t b = B0 + mod * B1_FACTOR - (mod & 2) * B2_FACTOR;
        uint64_t significand = a * phred + b;
        prob.i = (exp << EXPONENT_SHIFT) | significand;
        expected_errors += prob.f;
        cursor += 1;
    }
    return expected_errors;
}
; ATTR（色）定義

#if exists MZ700
ATTR_WHITE   equ $70
ATTR_YELLOW  equ $60
ATTR_CYAN    equ $50
ATTR_GREEN   equ $40
ATTR_MAGENTA equ $30
ATTR_RED     equ $20
ATTR_BLUE    equ $10
ATTR_BLACK   equ $00

#elif exists PC8001
ATTR_WHITE   equ $e8
ATTR_YELLOW  equ $c8
ATTR_CYAN    equ $a8
ATTR_GREEN   equ $88
ATTR_MAGENTA equ $68
ATTR_RED     equ $48
ATTR_BLUE    equ $28
ATTR_BLACK   equ $08
#endif
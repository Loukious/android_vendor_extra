#
# Personal crDroid onyx board additions
#

WITH_GMS := true
BUILD_WITH_GAPPS := true

# PixelOS Pixel Launcher board configuration.
include vendor/pixel/launcher/products/board.mk

# PixelOS ThemePicker board configuration.
include vendor/pixel/themepicker/products/board.mk

# PixelOS clock faces board configuration.
include vendor/pixel/clocks/products/board.mk

# PixelOS sounds board configuration.
include vendor/pixel/sounds/products/board.mk


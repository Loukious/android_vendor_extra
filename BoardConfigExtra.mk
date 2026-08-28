#
# Personal Evolution X onyx board additions
#

# GApps are Evolution X's own; see product.mk for the full reasoning. Set on the
# board side as well because BoardConfig is parsed before the product config and
# vendor/lineage/config/BoardConfigLineage.mk reads WITH_GMS.
WITH_GMS := true

# The four PixelOS board includes that used to live here are gone along with the
# vendor/pixel/* projects themselves:
#
#   include vendor/pixel/launcher/products/board.mk
#   include vendor/pixel/themepicker/products/board.mk
#   include vendor/pixel/clocks/products/board.mk
#   include vendor/pixel/sounds/products/board.mk
#
# Evolution X's vendor/gms and vendor/pixel-style cover all four.

class_name CrossFlarePalette
extends ShaderMaterial

const ALL_VARIANTS: int = (1 << 0) | (1 << 1) | (1 << 2)

@export_range(0.0, 10.0, 0.1, "or_greater") var selection_weight: float = 1.0
@export_flags("Cross Only", "Single Ring", "Double Ring") var allowed_variants: int = ALL_VARIANTS


func is_variant_allowed(variant: int) -> bool:
	return (allowed_variants & (1 << variant)) != 0

NAME		= hollow_knight
SRCS_DIR	= srcs
LIB_DIR		= libs
ASM_DIR		= $(SRCS_DIR)/main
OBJ_DIR		= obj
BINS		= $(NAME).gb

ASM		= rgbasm
LINK	= rgblink
FIX		= rgbfix

FIX_FLAGS	= -v -p 0xFF

RM = rm -f

# https://stackoverflow.com/a/18258352
# Make does not offer a recursive wild card function, so here's one:
rwildcard = $(foreach d,\
		$(wildcard $(1:=/*)), \
		$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d) \
	)

# https://stackoverflow.com/a/16151140
# This makes it so every entry in a space-delimited list appears only once
unique = $(if $1,\
			$(firstword $1) $(call unique,$(filter-out $(firstword $1),$1)) \
		)

ASM_SOURCES_COLLECTED = \
			$(call rwildcard,$(ASM_DIR),*.asm) $(call rwildcard,$(LIB_DIR),*.asm)

OBJS = $(patsubst %.asm,$(OBJ_DIR)/%.o,$(notdir $(ASM_SOURCES_COLLECTED)))

# OBJS = $(patsubst $(SRCS_DIR)/%.asm,$(OBJ_DIR)/%.o,$(SRCS))
# OBJS += $(patsubst $(UTILS_DIR)/%.asm,$(OBJ_DIR)/%.o,$(SRCS))

# Build target
all: $(BINS)

# ANCHOR: generate-objects
# Extract directories from collected ASM sources and append "%.asm" to each one,
# creating a wildcard-rule.
ASM_SOURCES_DIRS = $(patsubst %,%%.asm,\
			$(call unique,$(dir $(ASM_SOURCES_COLLECTED))) \
		)

# This is a Makefile "macro".
# It defines a %.o target from a corresponding %.asm, ensuring the
# "prepare" step has ran and the graphics are already generated.
define object-from-asm
$(OBJ_DIR)/%.o: $1 | $(OBJ_DIR)
	$$(ASM) -o $$@ $$<
endef

# Run the macro for each directory listed in ASM_SOURCES_DIRS, thereby
# creating the appropriate targets.
$(foreach i, $(ASM_SOURCES_DIRS), $(eval $(call object-from-asm,$i)))
# ANCHOR_END: generate-objects

# Rule to build the ROM
$(BINS): $(OBJS)
	$(LINK) -o $@ $<
	$(FIX) $(FIX_FLAGS) $(BINS)

# # Rules to assemble each .asm file
# $(OBJ_DIR)/%.o: $(SRCS_DIR)/%.asm
# 	$(ASM) -o $@ $<

# $(OBJ_DIR)/%.o: $(UTILS_DIR)/%.asm
# 	$(ASM) -o $@ $<

# Create directories if they don't exist
$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

# Clean target
clean:
	$(RM) $(OBJ_DIR)/*.o
	$(RM) -r $(OBJ_DIR)

fclean: clean
	$(RM) $(BINS)
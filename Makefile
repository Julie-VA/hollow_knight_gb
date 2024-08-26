NAME = hollow_knight.gb

SRCS_DIR	= srcs
UTILS_DIR	= utils
GEN_DIR		= generated

SRCS =	$(SRCS_DIR)/main.asm	\
		$(UTILS_DIR)/utils.asm

ASM		= rgbasm
LINK	= rgblink
FIX		= rgbfix

FIXFLAGS = -v -p 0xFF

RM = rm -f

OBJS = $(patsubst $(SRCS_DIR)/%.asm,$(GEN_DIR)/%.o,$(SRCS))
OBJS += $(patsubst $(UTILS_DIR)/%.asm,$(GEN_DIR)/%.o,$(SRCS))

# Build target
all: $(GEN_DIR) $(NAME)

# Rule to build the ROM
$(NAME): $(OBJS)
	$(LINK) -o $@ $<
	$(FIX) $(FIXFLAGS) $(NAME)

# Rules to assemble each .asm file
$(GEN_DIR)/%.o: $(SRCS_DIR)/%.asm
	$(ASM) -o $@ $<

$(GEN_DIR)/%.o: $(UTILS_DIR)/%.asm
	$(ASM) -o $@ $<

# Create generated directory if it doesn't exist
$(GEN_DIR):
	mkdir -p $(GEN_DIR)

# Clean target
clean:
	$(RM) $(GEN_DIR)/*.o
	$(RM) -r $(GEN_DIR)

fclean: clean
	$(RM) $(NAME)
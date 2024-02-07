# source files
SRCS = main.s read_file.s init_table.s build_tree.s bit_length.s add_bit.s append_bits.s binary_out.s find_node.s table_lookup.s encode.s decode.s
# object files
OBJS = $(SRCS:.s=.o)
# target program
TARGET = huffman
# default
all: $(TARGET)
# compile source files into object files
%.o: %.s
	gcc -Wall -g -c $< -o $@

# link object files to create program
$(TARGET): $(OBJS)
	gcc -Wall -g $(OBJS) -o $(TARGET)
	
# clean up object files and program
clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean

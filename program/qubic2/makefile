VER=2.2
DIST=qubic$(VER)
PROGS=qubic
CXX_SRCS=struct.cpp read_array.cpp make_graph.cpp get_options.cpp write_block.cpp cluster.cpp main.cpp expand.cpp
OBJS=$(CXX_SRCS:.cpp=.o)

LDFLAGS+=-lm -fopenmp
CXXFLAGS+=-O3 -Wall -ansi -std=c++0x -fopenmp -DVER=$(VER)

all: $(PROGS)

${PROGS}: $(OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS)

clean:
	rm -f $(PROGS)
	rm -f *.o
	rm -f data/*.rules
	rm -f data/*.chars
	rm -f data/*.blocks
	rm -f data/*.expansion

dist:
	$(MAKE) clean
	cd .. && tar czvf $(DIST).tar.gz $(DIST)/

test: 
	$(MAKE)
	./${PROGS} -i data/example 

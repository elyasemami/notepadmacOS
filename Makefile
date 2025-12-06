CXX=clang++
CXXFLAGS=-std=c++17 -fobjc-arc
FRAMEWORKS=-framework Cocoa
SOURCES=src/main.mm src/AppController.mm src/EditorView.mm src/MenuBuilder.mm src/DocumentModel.cpp
TARGET=notepadxp

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CXX) $(CXXFLAGS) $(SOURCES) -o $(TARGET) $(FRAMEWORKS)

clean:
	rm -f $(TARGET)

.PHONY: all clean

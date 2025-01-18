gcc -o main.o -c src/*.c -mwindows
gcc -shared -o DeOppressoLiber.dll main.o

# Overview
MNIST-x86 is a small x86 nasm assembly project that opens a window and runs a two layer neural network for digit recognition.
The project uses the Windows API, and doesn't have any other dependencies.
## Assemble and link the project yourself
First assemble the three source files:
```
nasm -f win64 .\main.asm    
nasm -f win64 .\graphics.asm
nasm -f win64 .\network.asm
```
Then link them using:

- for MSVC
```
link graphics.obj network.obj main.obj /ENTRY:main /OUT:mnist_x86.exe user32.lib gdi32.lib kernel32.lib /LARGEADDRESSAWARE:NO
```
- for gcc
```
gcc -nostartfiles -Wl,-e,main main.obj graphics.obj network.obj -o mnist_x86.exe -luser32 -lgdi32 -lkernel32
```
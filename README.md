# Overview

<img align="left" src="./readme_assets/mnist-x86_demo.png?raw=true" alt="Alt text" width="330" style="margin-right: 20px; margin-bottom: 20px;"/>

MNIST-x86 is a small x86 nasm assembly project that opens a window and runs a two layer neural network for digit recognition. The project uses the Windows API, and doesn't have any other dependencies.

Assembly is not portable, so Windows is the only supported operating system.

*You can find an assembled binary file in the release section.*

<br clear="left"/>
<br><br>

The neural network has been trained using the [MNIST database](http://yann.lecun.com/exdb/mnist/). It consists of a 128 neuron layer with relu activation, and an unactivated 10 neuron output layer. No further processing of the dataset images has been made, so you will get better results if you write digits in the center of the screen, and similar to these:
<br><br>

![Alt text](./readme_assets/mnist_dataset_sample.png?raw=true)

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

# Technical details
This project uses the Windows API to open a set size window, and uses GDI to draw pixels to the screen. I don't know about any gdi tutorials in assembly, so I took inspiration on a C tutorial that you can find [here](https://croakingkero.com/tutorials/drawing_pixels_win32_gdi/). As for assembly resources, I mostly used this [document](https://www.cs.virginia.edu/~evans/cs216/guides/x86.html), this series of [videos](https://youtube.com/playlist?list=PLmxT2pVYo5LB5EzTPZGfFN0c2GDiSXgQe&si=ztnpkqfNEtrZ3LC5) as well as the [compiler explorer](https://godbolt.org/).
For step by step execution, I use x64dbg, which has proven to be very useful.

---

Here is a diagram I made for the x64 calling convention to help me get my offsets right. _Note that all windows API functions expect a 16 byte aligned stack pointer._

```
     ┌─────────────┐                    
     │top of stack │◄──── rsp   ▲       
     ├─────────────┤            │       
     │    ....     │            │       
     ├─────────────┤            │stack  
     │  saved rbp  │◄──── rbp   │growth 
     ├─────────────┤            │       
     │return adress│            │       
     ├─────────────┤            │       
     │   rcx home  │                    
     ├─────────────┤                    
     │   rdx home  │                    
     ├─────────────┤                    
     │   r8 home   │                    
     ├─────────────┤            │       
     │   r9 home   │ rbp+40     │       
     ├─────────────┤            │ high  
     │ parameter 1 │ rbp+48     │ adress
     ├─────────────┤            │       
     │ parameter 2 │            │       
     ├─────────────┤            │       
     │    ....     │            ▼       
     └─────────────┘                    
```

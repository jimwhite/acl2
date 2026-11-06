#include <stdio.h>
#include <dlfcn.h>
int main(void){void*h=dlopen("side.wasm",RTLD_NOW);if(!h){printf("dlopen failed: %s\n",dlerror());return 1;}int(*f)(int)=(int(*)(int))dlsym(h,"side_double");if(!f){printf("dlsym failed: %s\n",dlerror());return 1;}printf("side_double(21) = %d\n",f(21));return 0;}

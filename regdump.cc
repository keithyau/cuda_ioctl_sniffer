#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <assert.h>
#include <sys/stat.h>
#include <sys/mman.h>

void hexdump(void *d, int l) {
  for (int i = 0; i < l; i++) {
    if (i%0x10 == 0 && i != 0) printf("\n");
    if (i%0x10 == 0) printf("%8X: ", i);
    printf("%2.2X ", ((uint8_t*)d)[i]);
  }
  printf("\n");
}

int main(int argc, char* argv[]) {
  // sudo chmod 666 /sys/bus/pci/devices/0000:61:00.0/resource0
  const char *bar_file = "/sys/bus/pci/devices/0000:61:00.0/resource0";
  int bar_fd = open(bar_file, O_RDWR | O_SYNC);
  assert(bar_fd >= 0);
  struct stat st;
  fstat(bar_fd, &st);
  printf("**** BAR0(%d) %.2f MB\n", bar_fd, st.st_size*1.0/(1024*1024));
  char *bar = (char *)mmap(0, st.st_size, PROT_READ | PROT_WRITE, MAP_SHARED, bar_fd, 0);
  assert(bar != MAP_FAILED);

  // NV_P2P
  unsigned long long addr = strtoull(argv[1], NULL, 0x10);
  unsigned long long len = strtoull(argv[2], NULL, 0x10);
  //*(uint32_t*)(bar+addr) = 0xffffffff;
  //*(uint32_t*)(bar+addr+4) = 0xffffffff;
  printf("dumping 0x%llx-0x%llx\n", addr, addr+len);
  hexdump(bar+addr, len);
}
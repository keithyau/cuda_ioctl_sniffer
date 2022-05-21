#include <stdio.h>
#include <cuda.h>
#include <signal.h>

__global__
void saxpy(int n, float a, float *x, float *y)
{
  int i = blockIdx.x*blockDim.x + threadIdx.x;
  if (i < n) y[i] = a*x[i] + y[i];
}

int main(void)
{
  int N = 1<<20;
  float *x, *y, *d_x, *d_y;
  x = (float*)malloc(N*sizeof(float));
  y = (float*)malloc(N*sizeof(float));

  printf("***** init\n");
  cuInit(0);

  printf("***** get device\n");
  CUdevice pdev;
  cuDeviceGet(&pdev, 0);

  printf("***** create context\n");
  CUcontext pctx;
  cuCtxCreate(&pctx, 0, pdev);

  printf("***** print memory\n");
  size_t free_byte, total_byte;
  cudaMemGetInfo(&free_byte, &total_byte);
  printf("%.2f MB used\n", (total_byte-free_byte)/1e6);

  printf("***** entry malloc\n");
  cudaMalloc(&d_x, N*sizeof(float)); 
  printf("***** entry malloc 2\n");
  cudaMalloc(&d_y, N*sizeof(float));

  for (int i = 0; i < N; i++) {
    x[i] = 1.0f;
    y[i] = 2.0f;
  }

  printf("***** entry memcpy\n");
  cudaMemcpy(d_x, x, N*sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(d_y, y, N*sizeof(float), cudaMemcpyHostToDevice);

  // Perform SAXPY on 1M elements
  printf("***** launch\n");
  raise(SIGTRAP);
  /*
  __cudaPushCallConfiguration
    __cudart657
    __cudart656
    __cudart1612
    __cudart656
    __cudart657
    __cudart530
    __cudart657
  */

  saxpy<<<(N+255)/256, 256>>>(N, 2.0f, d_x, d_y);

  printf("***** exit memcpy\n");
  cudaMemcpy(y, d_y, N*sizeof(float), cudaMemcpyDeviceToHost);

  float maxError = 0.0f;
  for (int i = 0; i < N; i++)
    maxError = max(maxError, abs(y[i]-4.0f));
  printf("Max error: %f\n", maxError);

  printf("***** print memory 2\n");
  cudaMemGetInfo(&free_byte, &total_byte);
  printf("%.2f MB used\n", (total_byte-free_byte)/1e6);

  printf("***** exit free\n");
  cudaFree(d_x);
  cudaFree(d_y);
  free(x);
  free(y);

}

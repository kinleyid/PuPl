#include <string.h>
#include "matrix.h"
#include "mex.h"

static FILE  *fp = NULL;

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    char *fname;
    fname = mxArrayToString(prhs[0]);
    mexPrintf("%s\n", fname);
    mxFree(fname);
	fp = fopen("eg.txt", "r");
    nlhs = 1;
	char buffer[BUFFER_SIZE];
	while (fgets(buffer, sizeof buffer, stream) != NULL) {
		
	}
	if (feof(stream)) {
	
	}
	else
	{
	// some other error interrupted the read
	}
}
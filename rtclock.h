double rtclock()
{
    struct timezone Tzp;
    struct timeval Tp;
    int stat;
    stat = gettimeofday (&Tp, &Tzp);
    if (stat != 0) fprintf(stderr,"Error return from gettimeofday: %d",stat);
    
    return(Tp.tv_sec + Tp.tv_usec*1.0e-6);
}

/*
 * Placed into the Public Domain.
 * written by Walter Bright
 * www.digitalmars.com
 */

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with the Ares project.
 */

private
{
    import tango.stdc.stdlib;
    import tango.stdc.string;
    import tango.stdc.stdio;
    import util.utf;
}

extern (Windows) void*     LocalFree(void*);
extern (Windows) wchar_t*  GetCommandLineW();
extern (Windows) wchar_t** CommandLineToArgvW(wchar_t*, int*);
pragma(lib, "shell32.lib"); // needed for CommandLineToArgvW

extern (C) void _STI_monitor_staticctor();
extern (C) void _STD_monitor_staticdtor();
extern (C) void _STI_critical_init();
extern (C) void _STD_critical_term();
extern (C) void gc_init();
extern (C) void gc_term();
extern (C) void _minit();
extern (C) void _moduleCtor();
extern (C) void _moduleDtor();
extern (C) void _moduleUnitTests();

/***********************************
 * These functions must be defined for any D program linked
 * against this library.
 */
extern (C) void onAssertError( char[] file, uint line );
extern (C) void onAssertErrorMsg( char[] file, uint line, char[] msg );
extern (C) void onArrayBoundsError( char[] file, uint line );
extern (C) void onSwitchError( char[] file, uint line );
// this function is called from the utf module
//extern (C) void onUnicodeError( char[] msg, size_t idx );

/***********************************
 * These are internal callbacks for various language errors.
 */
extern (C) void _d_assert( char[] file, uint line )
{
    onAssertError( file, line );
}

extern (C) static void _d_assert_msg( char[] msg, char[] file, uint line )
{
    onAssertErrorMsg( file, line, msg );
}

extern (C) void _d_array_bounds( char[] file, uint line )
{
    onArrayBoundsError( file, line );
}

extern (C) void _d_switch_error( char[] file, uint line )
{
    onSwitchError( file, line );
}

extern (C) bool no_catch_exceptions = false;

/***********************************
 * The D main() function supplied by the user's program
 */
int main(char[][] args);

/***********************************
 * Substitutes for the C main() function.
 * It's purpose is to wrap the call to the D main()
 * function and catch any unhandled exceptions.
 */
extern (C) int main(int argc, char **argv)
{
    char[][] args;
    int result;

    version (linux)
    {
	    _STI_monitor_staticctor();
	    _STI_critical_init();
	    gc_init();
    }
    else version (Win32)
    {
	    gc_init();
	    _minit();
    }
    else
    {
        static assert( false );
    }

    void run()
    {
	    _moduleCtor();
	    _moduleUnitTests();

        version (Win32)
        {
            int       wargc = 0;
            wchar_t** wargs = CommandLineToArgvW(GetCommandLineW(), &wargc);
            assert(wargc == argc);

            args = new char[][wargc];
            for (int i = 0; i < wargc; i++)
            {
                args[i] = toUTF8(wargs[i][0..wcslen(wargs[i])]);
            }
            LocalFree(wargs);
            wargs = null;
            wargc = 0;
        }
        else
        {
            char[]* am = cast(char[]*) malloc(argc * (char[]).sizeof);
            scope(exit) free(am);

        	for (int i = 0; i < argc; i++)
        	{
        	    int len = strlen(argv[i]);
        	    am[i] = argv[i][0 .. len];
        	}
    	    args = am[0 .. argc];
    	}

    	result = main(args);
	    _moduleDtor();
	    gc_term();
    }

    if (no_catch_exceptions)
    {
        run();
    }
    else
    {
        try
        {
            run();
        }
        catch (Exception e)
        {
            while (e)
            {
                if (e.file)
        	        fprintf(stderr, "%.*s(%u): %.*s\n", e.file, e.line, e.msg);
        	    else
        	        fprintf(stderr, "%.*s\n", e.toString());
        	    e = e.next;
        	}
    	    exit(EXIT_FAILURE);
        }
        catch (Object o)
        {
    	    fprintf(stderr, "%.*s\n", o.toString());
    	    exit(EXIT_FAILURE);
        }
    }

    version (linux)
    {
	    _STD_critical_term();
	    _STD_monitor_staticdtor();
    }
    return result;
}
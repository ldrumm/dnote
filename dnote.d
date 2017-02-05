module dnote;

import std.stdio;
//import std.process : system;
import std.path : dirSeparator, baseName;
import std.file;

/*
syntax:
dnote
- create|c [-n <Name>] <Message>
- show|s <Name>
- modify|m <Name> <Message>
- list|l
- delete|d [-y] {-a|<Name>}
*/

const enum { // App constants
    APP_NAME    = "dnote",
    APP_VERSION = "0.0.0",
    FOLDER_NAME = ".dnote",
}

const enum { // CLI Error list, to use/defined later
    E_S = 0,
    // Main CLI

    // Other operations

    // Create
    E_CG,        // Generic create error
    E_CNN,       // Create No Name defined
    // Show

    // Modify

    // List

    // Delete
}

static string dnote_folder;

// OPTLINK automatically links shell32 it appears.
version (Windows) extern (Windows) {
    import core.sys.windows.windows;
    HRESULT SHGetFolderPathW(
        HWND hwndOwner, int nFolder, HANDLE hToken, DWORD dwFlags, LPWSTR pszPath
    );
}

/*
 * CLI
 */

int main(string[] args)
{
    size_t l = args.length;
    
    if (l <= 1)
    {
        print_help(args[0]);
        return 0;
    }

    switch (args[1]) // Command
    {
        case "-h", "--help", "/?":
            print_help(args[0]);
            return 0;
        case "-v", "--version":
            print_version(args[0]);
            return 0;

        case "h", "help":
            if (l > 2)
                showhelp(args[2]);
            else
                print_help(args[0]);
            break;

        case "c", "create":
            if (l > 2)
                create(args[2..$]);
            else
                showhelp("create");
            break;
        case "s", "show":
            if (l > 2)
                show(args[2..$]);
            else
                showhelp("show");
            break;
        case "m", "modify":
            if (l > 2)
                modify(args[2..$]);
            else
                showhelp("modify");
            break;
        case "l", "list":
            if (l > 2)
                showhelp("list");
            else
                list();
            break;
        case "d", "delete":
            if (l > 2)
                delete_(args[2..$]);
            else
                showhelp("delete");
            break;
        default:
            writefln(`"%s" is an invalid command.`, args[1]);
            break;
    }
    
    return 0;
}

void print_help(string app = APP_NAME)
{
    writefln("%s [<Command>] <Arguments>", app);
    writeln("Commands:");
    writeln("  c, create   Create a new note.");
    writeln("  s, show     Show the content of a note.");
    writeln("  m, modify   Modify the content of a note.");
    writeln("  l, list     List existing notes.");
    writeln("  d, delete   Delete an existing notes.\n");
    writeln("Arguments:");
    writeln("  -h, --help, /?   Show the help screen and quits.");
    writeln("  -v, --version    Show the version screen and quits.\n");
    writefln(`To get help on a command, see "%s <Command> --help" or "%s help <Command>".`, app, app);
}

void print_version(string app = APP_NAME)
{
    writefln("%s - v%s", app, APP_VERSION);
    writeln("Copyright (c) 2017 dd86k");
    writeln("License: MIT");
    writeln("Project page: <https://github.com/dd86k/dnote>");
    writefln("Compiled %s on %s with %s v%s",
        __FILE__, __TIMESTAMP__, __VENDOR__, __VERSION__);
}

/*
 * Application
 */

void create(string[] args)
{
    size_t l = args.length;

    switch (args[0])
    {
        case "--help":
            showhelp("create");
            return;
        default: {
            size_t si = 0; // Starting [slice] index
            bool cname; // List of 
            string name;

            // CLI
            for (size_t i = 0; i < l; ++i)
            {
                switch (args[i])
                {
                    case "-n":
                        if (++i < l) {
                            debug writeln("-n Name: ", args[i]);
                            name = args[i];
                            cname = true;
                            si += 2;
                        } else {
                            writeln("-n : Missing name.");
                            return;
                        }
                        break;
                    default:
                }
            }

            if (si >= l)
            {
                writeln("Missing note content.");
                return;
            }

            string up = get_userfolder;

            if (up == null)
            {
                writeln("There was an error getting the userfolder.");
                return;
            }

            dnote_folder = get_dnote_folder(up);
            
            if (exists(dnote_folder))
            {
                if (isFile(dnote_folder))
                {
                    writefln("Can't create folder, %s already exists as a file.", FOLDER_NAME);
                    return;
                }
            }
            else
            {
                mkdir(dnote_folder);
                writefln("A %s folder was created in your user profile.", FOLDER_NAME);
            }

            if (cname == false)
            {
                import std.range.primitives, std.format;
                size_t n = dirEntries(dnote_folder, SpanMode.shallow).walkLength!() + 1;
                name = format("%d", n);
                cname = true;
            }

            string fullname = dnote_folder ~ dirSeparator ~ name;

            debug writeln("Name: ", name);

            if (exists(fullname))
            {
                writefln(`Note "%s" already exists.`, name);
                return;
            }

            string data = args[si];
            foreach(s; args[si + 1..$])
                data ~= ' ' ~ s;

            std.file.write(fullname, data);
        }
            break;
    }
} // create

void show(string[] args)
{
    switch (args[0])
    {
        case "--help":
            showhelp("show");
            return;
        default:

            break;
    }
} // show

void modify(string[] args)
{
    switch (args[0])
    {
        case "--help":
            showhelp("modify");
            return;
        default:
        
            break;
    }
} // modify

void list()
{
    string up = get_userfolder;

    if (up == null)
    {
        writeln("There was an error getting the userfolder.");
        return;
    }

    dnote_folder = get_dnote_folder(up);

    foreach(e; dirEntries(dnote_folder, SpanMode.shallow))
        writeln(baseName(e.name));
} // list

void delete_(string[] args)
{
    switch (args[0])
    {
        case "--help":
            showhelp("delete");
            return;
        default:
            
            break;
    }
} // delete

void showhelp(string command)
{
    switch (command)
    {
        case "c", "create":
            writeln("create [-n <Name>] <Note>");
            writeln("Creates a new note.");
            writeln("  -n   Name the new note.\n");
            writeln(`By default, when unamed, names will start at "1" and still increment until a valid name is found.`);
            break;
        case "s", "show":
            writeln("show <Name>");
            writeln("Show the content of a note.");
            //writeln();
            //writeln();
            break;
        case "m", "modify":
            writeln("modify <Name> <Note>");
            writeln("Modify the content of a note.");
            //writeln("");
            //writeln("");
            break;
        case "l", "list":
            writeln("list");
            writeln("Lists all notes.");
            //writeln("");
            //writeln("");
            break;
        case "d", "delete":
            writeln("delete [-y] {<Note>|-a}");
            writeln("Delete a note.");
            writeln("  -y   Automatically confirm yes.");
            writeln("  -a   All notes.\n");
            writeln("By default, there will be a confirmation ");
            break;
        default:
            writefln("%s is not a valid command.", command);
            break;
    }
}

string get_userfolder()
{
    version (Windows)
    {
        enum folder = 0x28; // CSIDL_PROFILE from
        // http://www.installmate.com/support/im9/using/symbols/functions/csidls.htm
        import core.stdc.wchar_ : wcslen;
        import std.utf : toUTF8;

        wchar[MAX_PATH] buffer;
        wchar* ptr = buffer.ptr;
        if (!SHGetFolderPathW(null, folder, null, 0, ptr)) // Works from XP to 10
            return buffer[0 .. wcslen(ptr)].toUTF8();

        debug writeln("get_userfolder: null");
        return null;
    }
    else version (linux)
    {
        static assert(0, "get_userfolder : Not implemented in Linux.");
        import core.sys.linux.unistd, core.stdc.stdlib;
        /* unistd:
        - getuid()
           stdlib:
        - getenv()
        
        #include <unistd.h>
        #include <sys/types.h>
        #include <pwd.h>

        const char *homedir;

        if ((homedir = getenv("HOME")) == NULL) {
            homedir = getpwuid(getuid())->pw_dir;
        }
        */
    }
    else version (OSX)
    {
        static assert(0, "get_userfolder : Not implemented in OSX.");
    }
    else
        static assert(0, "Target operating system is not supported.");
}

string get_dnote_folder(string userprofile)
{
    return userprofile ~ dirSeparator ~ FOLDER_NAME;
}
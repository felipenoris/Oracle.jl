
const PREFIX = joinpath(@__DIR__, "usr")
const DOWNLOADS = joinpath(PREFIX, "downloads")
const DEPS_FILE = joinpath(@__DIR__, "deps.jl")
const SRC_DIR = joinpath(PREFIX, "src")
const LIB_DIR = joinpath(PREFIX, "lib")

# upstream odpi
const ODPI_VERSION_NUMBER = v"4.2.1"
const ODPI_SOURCE_URL = "https://github.com/oracle/odpi/archive/refs/tags/v$(ODPI_VERSION_NUMBER).tar.gz"

# patched odpi: see issue #21
#const ODPI_VERSION_NUMBER = "3.1.2-dev-numeric"
#const ODPI_SOURCE_URL = "https://github.com/felipenoris/odpi/archive/refs/tags/v$(ODPI_VERSION_NUMBER).tar.gz"

const ODPI_SOURCE_LOCAL_FILEPATH = joinpath(DOWNLOADS, "odpi_source.tar.gz")

@static if Sys.islinux()
    const SHARED_LIB = joinpath(PREFIX, "lib", "libdpi.so.$(ODPI_VERSION_NUMBER)")
elseif Sys.isapple()
    const SHARED_LIB = joinpath(PREFIX, "lib", "libdpi.$(ODPI_VERSION_NUMBER).dylib")
else
    error("Target system not supported.")
end

function mkdir_if_not_exists(dir; verbose::Bool=false)
    if !isdir(dir)
        verbose && println("Creating $dir.")
        mkdir(dir)
    end
end

function rmdir_if_exists(dir; verbose::Bool=false)
    if isdir(dir)
        verbose && println("Removing directory $dir.")
        rm(dir, recursive=true)
    end
end

function download_source_files(; verbose::Bool=false)

    function untar_source_files(; verbose::Bool=false)
        # tar -xf $ODPI_SOURCE_LOCAL_FILEPATH -C $SRC_DIR --strip-components=1
        mkdir_if_not_exists(SRC_DIR, verbose=verbose)
        cmd_array = ["tar", "-xf", ODPI_SOURCE_LOCAL_FILEPATH, "-C", SRC_DIR, "--strip-components=1"]
        actual_cmd = Cmd(cmd_array)
        verbose && println(actual_cmd)
        run(Cmd(actual_cmd, dir=PREFIX))
    end

    mkdir_if_not_exists(PREFIX, verbose=verbose)
    mkdir_if_not_exists(DOWNLOADS, verbose=verbose)

    if !isfile(ODPI_SOURCE_LOCAL_FILEPATH)
        verbose && println("Downloading $ODPI_SOURCE_URL...")
        download(ODPI_SOURCE_URL, ODPI_SOURCE_LOCAL_FILEPATH)
    end

    untar_source_files(verbose=verbose)
end

function clean_src_files(;verbose::Bool=false)
    rmdir_if_exists(SRC_DIR, verbose=verbose)
    rmdir_if_exists(DOWNLOADS, verbose=verbose)
end

function clean_all(;verbose::Bool=false)
    rmdir_if_exists(PREFIX, verbose=verbose)
    if isfile(DEPS_FILE)
        verbose && println("Removing file $DEPS_FILE.")
        rm(DEPS_FILE)
    end
end

function patch(original_file, patch_file, output_file; verbose::Bool=false)
    verbose && println("Applying patch $patch_file to $original_file.")
    @assert isfile(original_file) && isfile(patch_file)

    function copy_content(io_in, io_out)
        while !eof(io_in)
            write(io_out, read(io_in, UInt8))
        end
    end

    open(output_file, "w") do io_out
        open(original_file, "r") do io_in
            copy_content(io_in, io_out)
        end

        open(patch_file, "r") do io_in
            copy_content(io_in, io_out)
        end
    end

    verbose && println("$output_file was generated.")
end

function build_shared_library(; verbose::Bool=false)
    mkdir_if_not_exists(LIB_DIR, verbose=verbose)

    # apply patch
    original_file = joinpath(SRC_DIR, "embed", "dpi.c")
    patch_file = joinpath(@__DIR__, "dpi_patch.c")
    patched_file = joinpath(SRC_DIR, "embed", "dpi_patched.c")
    patch(original_file, patch_file, patched_file, verbose=verbose)

    if Sys.islinux()
        #=
        cc -c -fPIC -I ../include -ldl -o dpi.o dpi_patched.c
        cc -shared -fPIC -Wl,-soname,libdpi.so.3 -o ../../lib/libdpi.so.3.1.0 dpi.o -lc
        =#

        build_script = [
            ["cc", "-c", "-fPIC", "-I", joinpath(SRC_DIR, "include"), "-ldl", "-o", joinpath(SRC_DIR, "embed", "dpi.o"), patched_file],
            ["cc", "-shared", "-fPIC", "-Wl,-soname,libdpi.so.3", "-o", SHARED_LIB, joinpath(SRC_DIR, "embed", "dpi.o"), "-lc"]
        ]

    elseif Sys.isapple()

        # cc -dynamiclib -I ../include -o ../../lib/libdpi.3.1.0.dylib dpi_patched.c

        build_script = [
            ["cc", "-dynamiclib", "-I", joinpath(SRC_DIR, "include"), "-o", SHARED_LIB, patched_file]
        ]

    else
        error("Target system not supported.")
    end

    for cmd_array in build_script
        actual_cmd = Cmd(cmd_array)
        verbose && println(actual_cmd)
        run(Cmd(actual_cmd, dir=PREFIX))
    end

    @assert isfile(SHARED_LIB) "Failed building libdpi shared library."
end

function write_deps_file(;verbose::Bool=false)
    @assert isfile(SHARED_LIB) "Couldn't find shared library $SHARED_LIB."
    lib_file = basename(SHARED_LIB)

    deps_file_content = """
# This file is generated by build.jl and should be called
# from `check_deps()` from within your module's `__init__()` method
import Libdl

const libdpi = joinpath(@__DIR__, "usr", "lib", "$lib_file")
function check_deps()
    global libdpi
    if !isfile(libdpi)
        error("\$(libdpi) does not exist, Please re-run Pkg.build(\\"Oracle\\"), and restart Julia.")
    end

    if Libdl.dlopen_e(libdpi) in (C_NULL, nothing)
        error("\$(libdpi) cannot be opened, Please re-run Pkg.build(\\"Oracle\\"), and restart Julia.")
    end
end
"""

    open(DEPS_FILE, "w") do f
        write(f, deps_file_content)
    end
    verbose && println("Created deps file $DEPS_FILE.")
end

function main(;verbose::Bool=false)
    clean_all(verbose=verbose)
    download_source_files(verbose=verbose)
    build_shared_library(verbose=verbose)
    write_deps_file(verbose=verbose)
    clean_src_files(verbose=verbose)
end

main()

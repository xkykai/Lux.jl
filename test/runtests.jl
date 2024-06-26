using ReTestItems, Pkg, Test

const BACKEND_GROUP = lowercase(get(ENV, "BACKEND_GROUP", "all"))
const ALL_LUX_TEST_GROUPS = ["core_layers", "contrib", "helpers", "distributed",
    "normalize_layers", "others", "autodiff", "recurrent_layers"]

__INPUT_TEST_GROUP = lowercase(get(ENV, "LUX_TEST_GROUP", "all"))
const LUX_TEST_GROUP = if startswith("!", __INPUT_TEST_GROUP[1])
    exclude_group = lowercase.(split(__INPUT_TEST_GROUP[2:end], ","))
    filter(x -> x ∉ exclude_group, ALL_LUX_TEST_GROUPS)
else
    [__INPUT_TEST_GROUP]
end
@info "Running tests for group: $LUX_TEST_GROUP"

const EXTRA_PKGS = String[]

if ("all" in LUX_TEST_GROUP || "distributed" in LUX_TEST_GROUP)
    BACKEND_GROUP != "amdgpu" && push!(EXTRA_PKGS, "MPI")
    (BACKEND_GROUP == "all" || BACKEND_GROUP == "cuda") && push!(EXTRA_PKGS, "NCCL")
end
("all" in LUX_TEST_GROUP || "others" in LUX_TEST_GROUP) && push!(EXTRA_PKGS, "Flux")
(BACKEND_GROUP == "all" || BACKEND_GROUP == "cuda") && push!(EXTRA_PKGS, "LuxCUDA")
(BACKEND_GROUP == "all" || BACKEND_GROUP == "amdgpu") && push!(EXTRA_PKGS, "AMDGPU")

if !isempty(EXTRA_PKGS)
    @info "Installing Extra Packages for testing" EXTRA_PKGS=EXTRA_PKGS
    Pkg.add(EXTRA_PKGS)
    Pkg.update()
    Base.retry_load_extensions()
    Pkg.instantiate()
end

for tag in LUX_TEST_GROUP
    @info "Running tests for group: $tag"
    if tag == "all"
        ReTestItems.runtests(@__DIR__)
    else
        ReTestItems.runtests(@__DIR__; tags=[Symbol(tag)])
    end
end

# Distributed Tests
if ("all" in LUX_TEST_GROUP || "distributed" in LUX_TEST_GROUP) && BACKEND_GROUP != "amdgpu"
    using MPI

    nprocs_str = get(ENV, "JULIA_MPI_TEST_NPROCS", "")
    nprocs = nprocs_str == "" ? clamp(Sys.CPU_THREADS, 2, 4) : parse(Int, nprocs_str)
    testdir = @__DIR__
    isdistributedtest(f) = endswith(f, "_distributedtest.jl")
    distributedtestfiles = String[]
    for (root, dirs, files) in walkdir(testdir)
        for file in files
            if isdistributedtest(file)
                push!(distributedtestfiles, joinpath(root, file))
            end
        end
    end

    @info "Running Distributed Tests with $nprocs processes"

    cur_proj = dirname(Pkg.project().path)

    include("setup_modes.jl")

    @testset "MODE: $(mode)" for (mode, aType, dev, ongpu) in MODES
        if mode == "amdgpu"
            # AMDGPU needs to cause a deadlock, needs to be investigated
            @test_broken 1 == 2
            continue
        end
        backends = mode == "cuda" ? ("mpi", "nccl") : ("mpi",)
        for backend_type in backends
            np = backend_type == "nccl" ? min(nprocs, length(CUDA.devices())) : nprocs
            @testset "Backend: $(backend_type)" begin
                @testset "$(basename(file))" for file in distributedtestfiles
                    @info "Running $file with $backend_type backend on $mode device"
                    run(`$(MPI.mpiexec()) -n $(np) $(Base.julia_cmd()) --color=yes \
                        --code-coverage=user --project=$(cur_proj) --startup-file=no $(file) \
                        $(mode) $(backend_type)`)
                    Test.@test true
                end
            end
        end
    end
end

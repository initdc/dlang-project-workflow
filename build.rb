require "./version"
require "./get-version"
require "./get-gdc-targets"

PROGRAM = "d-demo"
# VERSION = "v0.0.1"
SOURCE = "main.d source/*.d"
OUTPUT_ARG = "-o"
RELEASE_BUILD = true
RELEASE_ARG = RELEASE_BUILD == true ? "-O2" : ""
RELEASE = RELEASE_BUILD == true ? "release" : "debug"
# used in this way:
# GDC SOURCE RELEASE_ARG OUTPUT_ARG OUTPUT_PATH
TEST_CMD = "dub test --compiler=ldc2"

TARGET_DIR = "target"
DOCKER_DIR = "docker"
UPLOAD_DIR = "upload"

def doCleanAll
    puts "doCleanAll..."
    `rm -rf #{TARGET_DIR} #{UPLOAD_DIR}`
end

def doClean
    puts "doClean..."
    `rm -rf #{TARGET_DIR}/#{DOCKER_DIR} #{UPLOAD_DIR}`
end

# go tool dist list
# linux only for docker
GO_D = {
    "linux/386": "i686-linux-gnu-gdc",
    "linux/amd64": ["x86_64-linux-gnu-gdc", "musl-gdc"],
    "linux/arm": ["arm-linux-gnueabi-gdc", "arm-linux-gnueabihf-gdc"],
    "linux/arm64": "aarch64-linux-gnu-gdc",
    "linux/mips": "mips-linux-gnu-gdc",
    "linux/mips64": "mips64-linux-gnuabi64-gdc",
    "linux/mips64le": "mips64el-linux-gnuabi64-gdc",
    "linux/mipsle": "mipsel-linux-gnu-gdc",
    "linux/ppc64": "powerpc64-linux-gnu-gdc",
    "linux/ppc64le": "powerpc64le-linux-gnu-gdc",
    "linux/riscv64": "riscv64-linux-gnu-gdc",
    "linux/s390x": "s390x-linux-gnu-gdc",
}

ARM = ["5", "6", "7"]

# ls -1 /usr/bin/*-gdc
TARGETS = [
    "aarch64-linux-gnu-gdc",
    "arm-linux-gnueabi-gdc",
    "arm-linux-gnueabihf-gdc",
    "i686-linux-gnu-gdc",
    "mips64el-linux-gnuabi64-gdc",
    "mips64-linux-gnuabi64-gdc",
    "mipsel-linux-gnu-gdc",
    "mips-linux-gnu-gdc",
    "powerpc64le-linux-gnu-gdc",
    "powerpc64-linux-gnu-gdc",
    "powerpc-linux-gnu-gdc",
    "riscv64-linux-gnu-gdc",
    "s390x-linux-gnu-gdc",
    "x86_64-linux-gnu-gdc",
    "x86_64-linux-gnux32-gdc"
]

TEST_TARGETS = [
    "aarch64-linux-gnu-gdc",
    "arm-linux-gnueabi-gdc",
    "arm-linux-gnueabihf-gdc",
    "riscv64-linux-gnu-gdc",
    "x86_64-linux-gnu-gdc",
]

LESS_TARGETS = [
    "aarch64-linux-gnu-gdc",
    "x86_64-linux-gnu-gdc",
]

GDC = [
    "gdc-aarch64-linux-gnu",
    "gdc-arm-linux-gnueabi",
    "gdc-arm-linux-gnueabihf",
    "gdc-mips-linux-gnu",
    "gdc-mips64-linux-gnuabi64",
    "gdc-mips64el-linux-gnuabi64",
    "gdc-mipsel-linux-gnu",
    "gdc-powerpc-linux-gnu",
    "gdc-powerpc64-linux-gnu",
    "gdc-powerpc64le-linux-gnu",
    "gdc-riscv64-linux-gnu",
    "gdc-s390x-linux-gnu",
    "gdc-i686-linux-gnu",
    "gdc",
    "gdc-x86-64-linux-gnux32"
]

LDC = [
    "ldc",
    "dub"
]

def run_install cmds
    cmd = "sudo apt-get install -y #{cmds.join(" ")}"
    puts cmd
    IO.popen(cmd) do |r|
        puts r.readlines
    end
end

version = get_version ARGV, 0, VERSION

test_bin = ARGV[0] == "test" || false
less_bin = ARGV[0] == "less" || false

install_gdc = ARGV.include? "--install-gdc" || false
install_ldc = ARGV.include? "--install-ldc" || false
clean_all = ARGV.include? "--clean-all" || false
clean = ARGV.include? "--clean" || false
run_test = ARGV.include? "--run-test" || false
catch_error = ARGV.include? "--catch-error" || false

if install_gdc
    run_install GDC
    return
end

if install_ldc
  run_install LDC
  return
end

targets = get_gdc_targets || TARGETS
targets = TEST_TARGETS if test_bin
targets = LESS_TARGETS if less_bin

if run_test
    puts TEST_CMD
    test_result = system TEST_CMD
    if catch_error and !test_result
        return
    end
end

if clean_all
    doCleanAll
elsif clean
    doClean
    # on local machine, you may re-run this script
elsif test_bin || less_bin
    doClean
end
`mkdir -p #{TARGET_DIR} #{UPLOAD_DIR}`
`mkdir -p #{TARGET_DIR}/#{DOCKER_DIR}`

def existsThen(cmd, src, dest)
    if system "test -f #{src}"
        `#{cmd} #{src} #{dest}`
    end
end

def notExistsThen(cmd, dest, src)
    if not system "test -f #{dest}"
        if system "test -f #{src}"
            cmd = "#{cmd} #{src} #{dest}"
            puts cmd
            IO.popen(cmd) do |r|
                puts r.readlines
            end
        else
            puts "!! #{src} not exists"
        end
    end
end

for target in targets
    tp_array = target.split("-")
    architecture = tp_array[0]
    os = tp_array[1]

    windows = os == "w64"
    
    program_bin = !windows ? PROGRAM : "#{PROGRAM}.exe"
    target_bin = !windows ? target : "#{target}.exe"

    gdc = target

    dir = "#{TARGET_DIR}/#{target}/#{RELEASE}"
    `mkdir -p #{dir}`

    cmd = "#{gdc} #{SOURCE} #{RELEASE_ARG} #{OUTPUT_ARG} #{dir}/#{program_bin}"
    puts cmd
    system cmd

    existsThen "ln", "#{dir}/#{program_bin}", "#{UPLOAD_DIR}/#{target_bin}"
end

GO_D.each do |target_platform, targets|
    tp_array = target_platform.to_s.split("/")
    os = tp_array[0]
    architecture = tp_array[1]

    if architecture == "arm"
        for variant in ARM
            docker = "#{TARGET_DIR}/#{DOCKER_DIR}/#{os}/#{architecture}/v#{variant}"
            puts docker
            `mkdir -p #{docker}`

            if targets.kind_of?(Array)
                for target in targets
                    tg_array = target.split("-")
                    abi = tg_array[2]

                    existsThen "ln", "#{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM}", "#{docker}/#{PROGRAM}-#{abi}"
                    Dir.chdir docker do
                        notExistsThen "ln -s", PROGRAM, "#{PROGRAM}-#{abi}"
                    end
                end
            else
                target = targets
                existsThen "ln", "#{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM}", "#{docker}/#{PROGRAM}"
            end
        end
    else
        docker = "#{TARGET_DIR}/#{DOCKER_DIR}/#{os}/#{architecture}"
        puts docker
        `mkdir -p #{docker}`

        if targets.kind_of?(Array)
            for target in targets
                tg_array = target.split("-")
                abi = tg_array[2]

                existsThen "ln", "#{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM}", "#{docker}/#{PROGRAM}-#{abi}"
                Dir.chdir docker do
                    notExistsThen "ln -s", PROGRAM, "#{PROGRAM}-#{abi}"
                end
            end
        else
            target = targets
            existsThen "ln", "#{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM}", "#{docker}/#{PROGRAM}"
        end
    end
end

# cmd = "file #{UPLOAD_DIR}/**"
# IO.popen(cmd) do |r|
#         puts r.readlines
# end

file = "#{UPLOAD_DIR}/BINARYS"
IO.write(file, "")

cmd = "tree #{TARGET_DIR}/#{DOCKER_DIR}"
IO.popen(cmd) do |r|
    rd = r.readlines
    puts rd

    for o in rd
        IO.write(file, o, mode: "a")
    end
end

Dir.chdir UPLOAD_DIR do
    file = "SHA256SUM"
    IO.write(file, "")

    cmd = "sha256sum *"
    IO.popen(cmd) do |r|
        rd = r.readlines

        for o in rd
            if !o.include? "SHA256SUM" and !o.include? "BINARYS"
                print o
                IO.write(file, o, mode: "a")
            end
        end
    end
end

# `docker buildx build --platform linux/amd64 -t demo:amd64 . --load`
# cmd = "docker run demo:amd64"
# IO.popen(cmd) do |r|
#         puts r.readlines
# end

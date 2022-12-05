def get_cross_libs
  cmd = "ls -d1 /usr/* | grep linux"
    IO.popen(cmd) do |r|
        lines = r.readlines
        return nil if lines.empty?
  
        libs = []
        for line in lines
            lib = line.delete_suffix("\n")
            libs.push lib
        end
        return libs
    end
rescue
    return nil
end

def get_qemu_runners
    cmd = "ls -1 /usr/bin/qemu-*"
      IO.popen(cmd) do |r|
        lines = r.readlines
        return nil if lines.empty?

        runners = []
        for line in lines
            runner = line.delete_suffix("\n").delete_prefix("/usr/bin/")
            runners.push runner
        end
        return runners
      end
rescue
    return nil
end

def qemu_test dir
    results = {}

    d = Dir.new dir
    d.children.sort!.each do |child|
        file = "#{d.path}/#{child}"
        if File.executable?(file)
            tg_array = child.split("-")
            arch = tg_array[0]
            os = tg_array[1]
            abi = tg_array[2]

            next if os != "linux"

            qemu = "qemu-#{arch}"
            # qemu = "" if arch == "x86_64"
            qemu = "qemu-i386" if arch.end_with?("86")
            lib_arch = arch.end_with?("86") ? "i686" : arch
            
            qemu_env = qemu != "" ? "QEMU_LD_PREFIX=/usr/#{lib_arch}-#{os}-#{abi}" : ""
            cmd = qemu != "" ? "#{qemu_env} #{qemu} #{file}" : "./#{file}"
            
            puts cmd
            result = system cmd
            results[child.to_sym] = result
        end
    end
    return results
end

if __FILE__ == $0
    # pp get_cross_libs
    # pp get_qemu_runners
    pp qemu_test "upload"
end
